#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <chrono>

#include "sim_ctrl.h"
#include "debug.hh"
#include "sim.hh"

#include "as.hh"
#include "mem.hh"
#include "ctrl.hh"
#include "clint.hh"
#include "uart.hh"

#include "rtl.hh"
#include "trace.hh"


/*
 * The simulation
 */
SimulatedMachine::SimulatedMachine(const char *name, ArgParser *cmd)
    : SimObject(name, cmd),
      entry(0), term(false), termCode(0), termCycle(0)
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
    uart0 = new UniAsyncRxTx("uart0", cmd, 0,
                            SIM_UART0_START, SIM_UART0_SIZE);
    
    as = new PhysicalAddressSpace("phys_addr_space", cmd);
    as->addRange(mainMemory);
    as->addRange(simCtrl);
    as->addRange(clint);
    as->addRange(uart0);
    
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
    std::cout << "[SIM] Simulation Configuration\n"
        << "[SIM]   Max num cycles: " << maxCycles << "\n"
        << "[SIM]   Entry @ " << std::hex << entry << std::dec
        << std::endl;
}

static uint64_t
durationSeconds(std::chrono::steady_clock::time_point &start_time)
{
    auto end_time = std::chrono::steady_clock::now();
    uint64_t s = std::chrono::duration_cast<std::chrono::seconds>(end_time - start_time).count();
    return s;
}

void
SimulatedMachine::run()
{
    // Init input
    simCtrl->setPseudoIn(0, 10);
    
    // Reset
    driver->reset(entry);
    
    // Real simulation
    std::cout << "[SIM] Simulation started" << std::endl;
    std::chrono::steady_clock::time_point start_time = std::chrono::steady_clock::now();
    
    int err = 0;
    while (!err) {
        log_printf("--------------------------------------------------\n"
                   "[SIM] Cycle @ %lu\n", numCycles);
        
        err = driver->cycle(numCycles);
        err |= clint->cycle(numCycles);
        numCycles++;
        
        log_printf("--------------------------------------------------\n\n");
        
        if (numCycles % 100000000 == 0) {
            uint64_t seconds = durationSeconds(start_time);
            std::cout
                << "[SIM] Cycles: " << numCycles
                << ", seconds: " << seconds
                << ", " << (seconds ? numCycles / seconds : 0) << " cycles/s"
                << std::endl;
        }
        
        if (maxCycles && numCycles >= maxCycles) {
            std::cout
                << "[SIM] Max cycle reached: " << maxCycles
                << std::endl;
            break;
        } else if (term && numCycles >= termCycle) {
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
        
//        if (numCycles == 25730000ul) {
//            logLevel = 1;
//            logFile = openOutputFile("target/last.txt");
//        }
    }
    
    // Done
    uint64_t seconds = durationSeconds(start_time);
    std::cout
        << "[SIM] Simulation done"
        << ", cycles: " << numCycles
        << ", seconds: " << seconds
        << ", " << (seconds ? numCycles / seconds : 0) << " cycles/s"
        << std::endl;
}

void
SimulatedMachine::terminate(int code, uint64_t delay)
{
    term = true;
    termCode = code;
    termCycle = numCycles + delay;
}

