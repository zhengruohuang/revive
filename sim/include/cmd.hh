#ifndef __CMD_HH__
#define __CMD_HH__


#include <string>
#include <unordered_set>
#include <unordered_map>


struct ArgRecord
{
    enum ArgType {
        INT,
        UINT,
        INT64,
        UINT64,
        SET_TRUE,
        SET_FALSE,
        STRING,
        CUSTOM,
    };
    
    const char *nameShort;
    const char *nameFull;
    
    char *desp;
    
    ArgType type;
    bool set;
    union {
        int valueInt;
        unsigned int valueUInt;
        int64_t valueInt64;
        uint64_t valueUInt64;
        bool valueBool;
        const char *valueString;
        struct {
            int count;
            char **args;
        } valueCustom;
    };
};

class ArgParser
{
private:
    std::unordered_map<std::string, ArgRecord *> args;
    std::unordered_set<int> parsedArgIndices;
    
    void parse(ArgRecord *record);
    
    ArgRecord *add(const char *name_search,
        const char *name_short, const char *name_full, ArgRecord::ArgType type)
    {
        ArgRecord *record = new ArgRecord();
        record->nameShort = name_short;
        record->nameFull = name_full;
        record->type = type;
        record->set = false;
        std::string name = name_search;
        args[name] = record;
        return record;
    }
    
public:
    int argc;
    char **argv;
    ArgParser(int argc, char **argv)
        : argc(argc), argv(argv) { }
    
    bool validate();
    void usage();
    
    ArgRecord *get(std::string name)
    {
        auto it = args.find(name);
        return it == args.end() ? nullptr : it->second;
    }
    
    ArgRecord *addSetTrue(const char *name_search,
        const char *name_short, const char *name_full)
    {
        ArgRecord *record = add(name_search, name_short, name_full, ArgRecord::SET_TRUE);
        record->valueBool = false;
        parse(record);
        return record;
    }
    
    ArgRecord *addString(const char *name_search,
        const char *name_short, const char *name_full, const char *def)
    {
        ArgRecord *record = add(name_search, name_short, name_full, ArgRecord::STRING);
        record->valueString = def;
        parse(record);
        return record;
    }
    
    ArgRecord *addInt(const char *name_search,
        const char *name_short, const char *name_full, int def)
    {
        ArgRecord *record = add(name_search, name_short, name_full, ArgRecord::INT);
        record->valueInt = def;
        parse(record);
        return record;
    }
    
    ArgRecord *addUInt64(const char *name_search,
        const char *name_short, const char *name_full, uint64_t def)
    {
        ArgRecord *record = add(name_search, name_short, name_full, ArgRecord::UINT64);
        record->valueUInt64 = def;
        parse(record);
        return record;
    }
    
    ArgRecord *addCustom(const char *name_search,
        const char *name_short, const char *name_full, int def_count, char **def_args)
    {
        ArgRecord *record = add(name_search, name_short, name_full, ArgRecord::UINT64);
        record->valueCustom.count = def_count;
        record->valueCustom.args = def_args;
        parse(record);
        return record;
    }
};


#endif

