#include <iostream>
#include <iomanip>
#include <cstdlib>
#include "debug.hh"
#include "sim.hh"
#include "as.hh"
#include "rtl.hh"


/*
 * Simulated emory access
 */
inline void
RtlSimDriver::handleFetch()
{
    if (top->revive->ifetch->valid) {
        uint64_t pc = (uint64_t)top->revive->ifetch->addr;
        uint64_t fetch_addr = (uint64_t)top->revive->ifetch->fetch_addr;
        uint32_t fetch_data = (uint32_t)as->read_atomic(fetch_addr, 4);
        uint16_t half0 = fetch_data & 0xffff;
        uint16_t half1 = fetch_data >> 16;
        top->revive->ifetch->fetch_data0 = half0;
        top->revive->ifetch->fetch_data1 = half1;
        
        log_printf("[SIM] Fetch @ %lx, PC @ %lx, Word: %x, Half0: %x, Half1: %x\n",
                   fetch_addr, pc, fetch_data, half0, half1);
    } else {
        top->revive->ifetch->fetch_data0 = 0;
        top->revive->ifetch->fetch_data1 = 0;
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
            
            log_printf("[SIM] Mem LD @ %lx, Size: %d, Data: %lx\n",
                       (uint64_t)addr, size, (uint64_t)data);
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
            
            log_printf("[SIM] Mem LDU @ %lx, Size: %d, Data: %lx\n",
                       (uint64_t)addr, size, (uint64_t)data);
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
            
            log_printf("[SIM] Mem ST @ %lx, Size: %d, Data: %lx\n",
                       (uint64_t)addr, size, (uint64_t)data);
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
    : SimDriver(name, cmd, mach),
      top(nullptr), commitf(nullptr)
{
    cmd->addString("commit_file", "-c", "--commit-file", "target/commit.txt");
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
    if (!top) {
        return -1;
    }
    
    // Open output files
    const char *commit_filename = cmd->get("commit_file")->valueString;
    if (strcmp(commit_filename, "none")) {
        if (!strcmp(commit_filename, "stdout")) {
            commitf = stdout;
        } else if (!strcmp(commit_filename, "stderr")) {
            commitf = stderr;
        } else {
            commitf = openOutputFile(commit_filename);
        }
        
        if (!commitf) {
            return -1;
        }
    }
    
    return 0;
}

int
RtlSimDriver::cleanup()
{
    if (commitf) {
        fflush(commitf);
        fclose(commitf);
    }
    delete top;
    return 0;
}

int
RtlSimDriver::reset(uint64_t entry)
{
    // Output FDs
    top->i_log_fd = createVerilatorFileDescriptor(logFile);
    top->i_commit_fd = createVerilatorFileDescriptor(commitf);
    
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
        log_printf("[SIM] Fetch Valid %d, PC @ %lx\n",
                   (int)top->revive->ifetch->valid,
                   (uint64_t)top->revive->ifetch->addr);
        
        handleFetch();
        handleLSU();
        
        advance();
    }
    
    return 0;
}

