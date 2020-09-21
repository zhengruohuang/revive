#include <iostream>
#include <iomanip>
#include <cstdlib>
#include "debug.hh"
#include "sim.hh"
#include "rtl.hh"


/*
 * Simulated emory access
 */
inline void
RtlSimDriver::handleFetch()
{
    if (top->revive->ifetch->valid) {
        uint64_t pc = (uint64_t)top->revive->ifetch->addr;
        top->revive->ifetch->ld_data0 = (uint16_t)as->read_atomic(pc + 0,      2);
        top->revive->ifetch->ld_data1 = (uint16_t)as->read_atomic(pc + 0x2ull, 2);
        
//        uint32_t instr = 0;
//        if (pc & 0x3ull) {
//            instr  = (uint32_t)as->read_atomic(pc + 0x2ull, 2) << 16;
//            instr |= (uint32_t)as->read_atomic(pc, 2);
//        } else {
//            instr = (uint32_t)as->read_atomic(pc, 4);
//        }
//        
//        top->revive->ifetch->ld_data = instr;
        std::cout << "[SIM] "
            << "PC @ " << std::hex << pc << std::dec
            << ", Instr: " << std::hex << 0 << std::dec
            << std::endl;
    } else {
        top->revive->ifetch->ld_data0 = 0;
        top->revive->ifetch->ld_data1 = 0;
    }
}

inline void
RtlSimDriver::handleLSU()
{
    if (top->revive->lsu->is_mem_op) {
        uint32_t addr = top->revive->lsu->addr;
        int op = top->revive->lsu->op;
        int size = top->revive->lsu->op_size;
        
        if (op == 0) { // LD
            uint32_t data = 0;
            if (size == 0) {
                uint8_t ld8 = (uint8_t)as->read_atomic(addr, 1);
                data = (int32_t)(int8_t)ld8;
            } else if (size == 1) {
                uint16_t ld16 = (uint16_t)as->read_atomic(addr, 2);
                data = (int32_t)(int16_t)ld16;
            } else if (size == 2) {
                uint32_t ld32 = (uint32_t)as->read_atomic(addr, 4);
                data = (int32_t)ld32;
            }
            top->revive->lsu->ld_data = data;
            
            std::cout << "[SIM] "
                << "Mem LD @ " << std::hex << addr << std::dec
                << ", Size: " << size
                << ", Data: " << std::hex << data << std::dec
                << std::endl;
        }
        
        else if (op == 1) { // LDU
            uint32_t data = 0;
            if (size == 0) {
                uint8_t ld8 = (uint8_t)as->read_atomic(addr, 1);
                data = ld8;
            } else if (size == 1) {
                uint16_t ld16 = (uint16_t)as->read_atomic(addr, 2);
                data = ld16;
            } else if (size == 2) {
                uint32_t ld32 = (uint32_t)as->read_atomic(addr, 4);
                data = ld32;
            }
            top->revive->lsu->ld_data = data;
            
            std::cout << "[SIM] "
                << "Mem LDU @ " << std::hex << addr << std::dec
                << ", Size: " << size
                << ", Data: " << std::hex << data << std::dec
                << std::endl;
        }
        
        else if (op == 2) { // ST
            uint32_t data = top->revive->lsu->st_data;
            if (size == 0) {
                as->write_atomic(addr, 1, (uint8_t)data);
            } else if (size == 1) {
                as->write_atomic(addr, 2, (uint16_t)data);
            } else if (size == 2) {
                as->write_atomic(addr, 4, (uint32_t)data);
            }
            
            std::cout << "[SIM] "
                << "Mem ST @ " << std::hex << addr << std::dec
                << ", Size: " << size
                << ", Data: " << std::hex << data << std::dec
                << std::endl;
        }
    }
    
    else if (top->revive->lsu->is_amo_op) {
    }
}


/*
 * The simulation
 */
RtlSimDriver::RtlSimDriver(const char *name, ArgParser *cmd,
                           SimulatedMachine *mach)
    : SimDriver(name, cmd),
      top(nullptr), mach(mach), as(mach->getPhysicalAddressSpace())
{
}

inline void
RtlSimDriver::advance()
{
    top->i_clk = 0;
    top->eval();
    top->i_clk = 1;
    top->eval();
}

int
RtlSimDriver::startup()
{
    // Init verilator
    top = newVerilatorRtlTop(cmd->argc, cmd->argv);
    //Verilated::commandArgs(cmd->argc, cmd->argv);
    //top = new Vrevive;
    if (!top) {
        return -1;
    }
    
    return 0;
}

int
RtlSimDriver::cleanup()
{
    delete top;
    return 0;
}

int
RtlSimDriver::reset(uint64_t entry)
{
    // Init PC
    top->i_init_pc = (uint32_t)entry;
    
    // Reset
    top->i_rst_n = 0;
    advance();
    top->i_rst_n = 1;
    
    return 0;
}

int
RtlSimDriver::cycle(uint64_t num_cycles)
{
    if (Verilated::gotFinish()) {
        mach->terminate(0);
    } else {
        std::cout
            << "[SIM] Cycle @ " << num_cycles
            << ", Read: " << (int)top->revive->ifetch->valid
            << ", Fetch @ " << std::hex << top->revive->ifetch->addr << std::dec
            << std::endl;
        
        handleFetch();
        handleLSU();
        
        advance();
    }
    
    return 0;
}

