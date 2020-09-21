#ifndef __CMD_HH__
#define __CMD_HH__


class ArgParser
{
public:
    int argc;
    char **argv;
    
    ArgParser(int argc, char **argv)
        : argc(argc), argv(argv) { }
    
    bool validate() { return true; }
    void usage() { }
};


#endif

