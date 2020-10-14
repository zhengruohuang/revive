#include <iostream>
#include <fstream>
#include <csignal>
#include <cstdarg>
#include <cstdio>
#include <cstring>
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

FILE *openInputFile(const char *name, const char *mode)
{
    std::cout << "[SIM] Open input file @ " << name << std::endl;
    
    FILE *f = fopen(name, mode);
    return f;
}

FILE *openOutputFile(const char *name, const char *mode)
{
    std::cout << "[SIM] Open output file @ " << name << std::endl;
    
    FILE *f = fopen(name, mode);
    return f;
}


/*
 * Terminate
 */
static void cleanupGlobal()
{
    if (logFile) {
        fflush(logFile);
        fclose(logFile);
    }
}

void forceTerminate()
{
    cleanupAllObjects();
    cleanupGlobal();
    
    std::cout << std::endl << std::flush;
    std::cerr << std::endl
        << "[SIM] Simulation terminated unexpectedly"
        << std::endl << std::flush;
    
    exit(-1);
}

static void sigintHandler(int sig_num)
{
    cleanupAllObjects();
    cleanupGlobal();
    
    std::cout << std::endl << std::flush;
    std::cerr << std::endl
        << "[SIM] Simulation interrupted by user"
        << std::endl << std::flush;
    
    exit(0);
}


/*
 * Log
 */
FILE *logFile = nullptr;
int logLevel = 0;


/*
 * Main
 */
int main(int argc, char **argv)
{
    // Argument parser
    cmd = new ArgParser(argc, argv);
    
    // Log
    cmd->addString("log_file", "-l", "--log-file", "target/log.txt");
    cmd->addInt("log_level", "-L", "--log-level", 1);
    const char *log_filename = cmd->get("log_file")->valueString;
    if (strcmp(log_filename, "none")) {
        logLevel = cmd->get("log_level")->valueInt;
        
        if (!strcmp(log_filename, "stdout")) {
            logFile = stdout;
        } else if (!strcmp(log_filename, "stderr")) {
            logFile = stderr;
        } else {
            logFile = openOutputFile(log_filename, "w");
        }
        
        if (!logFile) {
            std::cerr
                << "[SIM] Unable to open log file @ " << log_filename
                << std::endl;
            return -1;
        }
    }
    
    // Create machine
    mach = new SimulatedMachine("machine", cmd);
    if (!cmd->validate()) {
        cmd->usage();
        return -1;
    }
    
    // Start up all objects
    int err = startupAllObjects();
    if (err) {
        return -1;
    }
    
    // Start real simulation
    signal(SIGINT, sigintHandler);
    mach->printConfig();
    mach->run();
    signal(SIGINT, SIG_DFL);
    
    // Cleanup
    cleanupAllObjects();
    cleanupGlobal();
    
    return 0;
}

