#include <iostream>
#include <iomanip>
#include <cstdlib>
#include "sim_ctrl.h"
#include "debug.hh"
#include "sim.hh"
#include "as.hh"
#include "mem.hh"
#include "ctrl.hh"
#include "clint.hh"

#include "rtl.hh"
#include "trace.hh"


/*
 * The simulation
 */
SimulatedMachine::SimulatedMachine(const char *name, ArgParser *cmd)
    : SimObject(name, cmd),
      entry(0), term(false), termCode(0)
{
    // Parse arguments
    cmd->addSetTrue("trace", "-T", "--trace");
    cmd->addString("kernel", "-K", "--kernel", nullptr);
    cmd->addUInt64("cycles", "-C", "--cycles", 0);
    
    // Set up physical memory space
    mainMemory = new MainMemory("main_memory", cmd,
                                SIM_PHYS_MEM_START, SIM_PHYS_MEM_SIZE);
    simCtrl = new SimulationControl("sim_ctrl", cmd,
                                    SIM_CTRL_BASE, SIM_CTRL_SIZE);
    clint = new CoreLocalInterruptor("clint", cmd,
                                     SIM_CLINT_START, SIM_CLINT_SIZE);
    
    as = new PhysicalAddressSpace("phys_addr_space", cmd);
    as->addRange(mainMemory);
    as->addRange(simCtrl);
    as->addRange(clint);
    
    // Load kernel
    bool loaded = loadElf(cmd->get("kernel")->valueString);
    if (!loaded) {
        std::cout << "[SIM] Unable to load kernel" << std::endl;
        exit(-1);
    }
    
    // Set up sim
    numCycles = 0;
    maxCycles = cmd->get("cycles")->valueUInt64;
    
    // Create driver
    if (cmd->get("trace")->valueBool) {
        driver = new TraceSimDriver(name, cmd, this);
    } else {
        driver = new RtlSimDriver(name, cmd, this);
    }
    
    // Attach to interrupt controllers
    clint->attachCore(driver);
}

SimulatedMachine::~SimulatedMachine()
{
    delete as;
}

void
SimulatedMachine::printConfig()
{
    std::cout << "[SIM] Simulation Configuration" << std::endl
        << "[SIM]   Max num cycles: " << maxCycles << std::endl
        << "[SIM]   Entry @ " << std::hex << entry << std::dec << std::endl
        << std::endl;
}

void
SimulatedMachine::run()
{
    // Init input
    simCtrl->setPseudoIn(0, 10);
    
    // Reset
    driver->reset(entry);
    
    // Real simulation
    int err = 0;
    while (!err) {
        std::cout
            << "---------------------------------------------------------------"
            << std::endl
            << "[SIM] Cycle @ " << numCycles
            << std::endl;
        
        err = driver->cycle(numCycles);
        err |= clint->cycle(numCycles);
        numCycles++;
        
        std::cout
            << "---------------------------------------------------------------"
            << std::endl << std::endl;
        
        if (maxCycles && numCycles >= maxCycles) {
            std::cout
                << "[SIM] Max cycle reached: " << maxCycles
                << std::endl;
            break;
        } else if (term) {
            std::cout
                << "[SIM] Termination signal received: " << termCode
                << std::endl;
            break;
        } else if (err) {
            std::cout
                << "[SIM] Termination error received: " << err
                << std::endl;
            break;
        }
    }
    
    // Done
    std::cout
        << "[SIM] Simulation done, simulated number of cycles: " << numCycles
        << std::endl;
}

void
SimulatedMachine::terminate(int code)
{
    term = true;
    termCode = code;
}

