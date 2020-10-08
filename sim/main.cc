#include <iostream>
#include <fstream>
#include <csignal>
#include "base.hh"
#include "cmd.hh"
#include "sim.hh"


static ArgParser *cmd = nullptr;
static SimulatedMachine *mach = nullptr;
int logLevel = 0;

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
        return false;
    }
    
    return true;
}

bool openOutputFile(const char *name, std::ofstream &fs)
{
    std::cout << "[SIM] Open output file @ " << name << std::endl;
    
    fs.open(name, std::ios::out | std::ios::trunc);
    if (!fs.is_open()) {
        return false;
    }
    
    return true;
}


/*
 * Force terminate
 */
void forceTerminate()
{
    cleanupAllObjects();
    std::cout << std::endl << std::flush;
    std::cerr << std::endl
        << "[SIM] Simulation terminated unexpectedly"
        << std::endl << std::flush;
    exit(-1);
}

static void sigintHandler(int sig_num)
{
    cleanupAllObjects();
    std::cout << std::endl << std::flush;
    std::cerr << std::endl
        << "[SIM] Simulation interrupted by user"
        << std::endl << std::flush;
    exit(0);
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
    
    signal(SIGINT, sigintHandler);
    mach->run();
    signal(SIGINT, SIG_DFL);
    
    err = cleanupAllObjects();
    if (err) {
        return -1;
    }
    
    return 0;
}

