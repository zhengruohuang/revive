#include <iostream>
#include "base.hh"
#include "cmd.hh"
#include "sim.hh"


static ArgParser *cmd = nullptr;
static SimulatedMachine *mach = nullptr;

ArgParser *getArgParser()
{
    return cmd;
}

SimulatedMachine *getMachine()
{
    return mach;
}


/*
 * In/Output files
 */
bool openInputFile(const char *name, std::ifstream &fs)
{
    std::cout << "[SIM] Open input file @ " << name << std::endl;
    
    fs.open(name);
    if (!fs.is_open()) {
        //notify(NOTIFY_WARN)
        //    << "Unable to open input file @ " << name << endl;
        return false;
    }
    
    return true;
}

bool openOutputFile(const char *name, std::ofstream &fs)
{
    std::cout << "[SIM] Open output file @ " << name << std::endl;
    
    fs.open(name, std::ios::out | std::ios::trunc);
    if (!fs.is_open()) {
        //notify(NOTIFY_WARN)
        //    << "Unable to open output file @ " << name << endl;
        return false;
    }
    
    return true;
}


/*
 * Main
 */
int main(int argc, char **argv)
{
    cmd = new ArgParser(argc, argv);
    mach = new SimulatedMachine("machine", cmd);
    if (!cmd->validate()) {
        cmd->usage();
        return -1;
    }
    
    mach->printConfig();
    
    int err = startupAllObjects();
    if (err) {
        return -1;
    }
    
    mach->run();
    
    err = cleanupAllObjects();
    if (err) {
        return -1;
    }
    
    return 0;
}

