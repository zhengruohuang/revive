#include <string>
#include <cstring>
#include <iostream>
#include <vector>
#include "cmd.hh"

void
ArgParser::parse(ArgRecord *record)
{
    for (int i = 1; i < argc; i++) {
        char *v = argv[i];
        if (!strcmp(v, record->nameShort) || !strcmp(v, record->nameFull)) {
            if (record->type == ArgRecord::SET_TRUE) {
                record->valueBool = true;
                parsedArgIndices.insert(i);
            } else if (record->type == ArgRecord::SET_FALSE) {
                record->valueBool = false;
                parsedArgIndices.insert(i);
            } else if (i + 1 < argc) {
                switch (record->type) {
                case ArgRecord::STRING:
                    parsedArgIndices.insert(i);
                    parsedArgIndices.insert(i + 1);
                    record->valueString = argv[i + 1];
                    break;
                case ArgRecord::UINT64:
                    parsedArgIndices.insert(i);
                    parsedArgIndices.insert(i + 1);
                    record->valueUInt64 = strtoull(argv[i + 1], nullptr, 10);
                    break;
                default:
                    std::cout
                        << "Bad positional argument for " << record->nameFull
                        << std::endl;
                    break;
                }
            } else if (record->type != ArgRecord::CUSTOM) {
                std::cout
                    << "Missing positional argument for " << record->nameFull
                    << std::endl;
            }
        }
    }
}

bool
ArgParser::validate()
{
    bool validated = true;
    std::vector<char *> unknowns;
    
    for (int i = 1; i < argc; i++) {
        auto it = parsedArgIndices.find(i);
        if (it == parsedArgIndices.end()) {
            validated = false;
            unknowns.push_back(argv[i]);
        }
    }
    
    if (!validated) {
        std::cout << "Unknown command arguments:";
        for (auto &v: unknowns) {
            std::cout << " " << v;
        }
        std::cout << std::endl;
    }
    
    return validated;
}

void
ArgParser::usage()
{
}

