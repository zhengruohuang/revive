#include <iostream>
#include <iomanip>
#include "sim.hh"
#include "mem.hh"
#include "as.hh"


SimulatedMachine::SimulatedMachine(ArgParser *cmd)
{
    Verilated::commandArgs(cmd->argc, cmd->argv);
    top = new Vrevive;
    
    as = new PhysicalAddressSpace();
    as->addRange(new MainMemory(0, 0x8000000ull));
    
    loadElf("/home/ruohuangz/Projects/revive/target/tests/stop");
    
    num_cycles = 0;
    max_cycles = 10;
}

SimulatedMachine::~SimulatedMachine()
{
    delete top;
    delete as;
}

inline void
SimulatedMachine::advance()
{
    top->i_clk = 0;
    top->eval();
    top->i_clk = 1;
    top->eval();
    
    num_cycles++;
}

void
SimulatedMachine::run()
{
    // Reset
    top->i_rst_n = 0;
    advance();
    top->i_rst_n = 1;
    
    // Real simulation
    while (!Verilated::gotFinish()) {
        std::cout
            << "---------------------------------------------------------------"
            << std::endl
            << "[SIM] Cycle @ " << num_cycles
            << ", read: " << (int)top->revive->icache->i_read
            << ", fetch @ " << std::hex << top->revive->icache->i_pc << std::dec
            << std::endl;
        
        if (top->revive->icache->i_read) {
            uint8_t cacheline[32];
            as->read(top->revive->icache->i_pc, 32, cacheline);
            memcpy(top->revive->icache->icache_data, cacheline, 32);
            
            uint32_t tag = ((top->revive->icache->i_pc >> (5 + 5)) << 1) | 0x1;
            top->revive->icache->icache_tag[0] = tag;
            
            std::cout << "[I$] ";
            for (int i = 0; i < 32; i++) {
                std::cout << std::hex << std::setw(2) << (uint32_t)cacheline[i] << std::dec << " ";
            }
            std::cout << std::endl;
        } else {
            memset(top->revive->icache->icache_data, 0, 8);
        }
        
        advance();
        
        std::cout
            << "---------------------------------------------------------------"
            << std::endl << std::endl;
        
        if (max_cycles && num_cycles >= max_cycles) {
            std::cout
                << "[SIM] Max cycle reached: " << max_cycles
                << std::endl;
            break;
        }
    }
    
    // Done
    std::cout << "[SIM] Simulation done, num_cycles: " << num_cycles << std::endl;
}

