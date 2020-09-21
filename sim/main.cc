#include <iostream>
#include "cmd.hh"
#include "sim.hh"


int main(int argc, char **argv)
{
    ArgParser *cmd = new ArgParser(argc, argv);
    SimulatedMachine *mach = new SimulatedMachine(cmd);
    
    if (!cmd->validate()) {
        cmd->usage();
        return -1;
    }
    
    mach->run();
    return 0;
}

