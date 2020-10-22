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
struct Rv32PageTableEntry
{
    union {
        uint32_t value;
        
        struct {
            uint32_t valid  : 1;
            uint32_t read   : 1;
            uint32_t write  : 1;
            uint32_t exec   : 1;
            uint32_t user   : 1;
            uint32_t global : 1;
            uint32_t access : 1;
            uint32_t dirty  : 1;
            uint32_t        : 2;
            uint32_t ppn    : 22;
        };
    };
};

inline bool
RtlSimDriver::translateVaddr(uint64_t vaddr, bool read, bool write, bool exec,
                             bool trans, int priv, uint64_t base_ppn,
                             uint64_t &paddr)
{
    if (!trans) {
        paddr = vaddr;
        return true;
    }
    
    uint64_t ppn = 0;
    Rv32PageTableEntry entry = { .value = 0 };
    
    uint32_t idx1 = (vaddr >> 22) & 0x3ff;
    uint64_t table1_paddr = base_ppn << 12;
    uint64_t entry1_paddr = table1_paddr + idx1 * 4;
    
    log_printf("[TRN] Base PPN @ %lx, idx: %d, table @ %lx, entry1_paddr @ %lx, vaddr @ %lx\n",
               base_ppn, idx1, table1_paddr, entry1_paddr, vaddr);
    
    entry.value = as->read_atomic(entry1_paddr, 4);
    if (!entry.valid || (!entry.read && entry.write)) { // invalid
        log_printf("[TRN] invalid superpage\n");
        return false;
    } else if (entry.read || entry.exec) {
        if (entry.ppn & 0x3ff) { // misaligned superpage
            log_printf("[TRN] misaligned superpage\n");
            return false;
        } else { // superpage
            ppn = entry.ppn;
            paddr = (ppn << 12) | (vaddr & 0x3fffffull);
            log_printf("[TRN] Super PPN @ %lx\n", ppn);
        }
    }
    
    // 2-level
    else {
        uint32_t idx2 = (vaddr >> 12) & 0x3ff;
        uint64_t table2_paddr = (uint64_t)entry.ppn << 12;
        uint64_t entry2_paddr = table2_paddr + idx2 * 4;
        entry.value = as->read_atomic(entry2_paddr, 4);
        
        if (!entry.valid || (!entry.read && entry.write) ||
            (!entry.read && !entry.exec)
        ) { // invalid
            return false;
        } else { // normal page
            ppn = entry.ppn;
            paddr = (ppn << 12) | (vaddr & 0xfffull);
            log_printf("[TRN] Final PPN @ %lx\n", ppn);
        }
    }
    
    // first access or write
    if (!entry.access || (!entry.dirty && write)) {
        return false;
    }
    
    // permission violation
    if ((priv == 0 && !entry.user) ||
        //(priv == PRIV_SUPERVISOR && entry.user && !state.status.sum) ||
        //(read && !entry.read && (!state.status.mxr || !entry.exec)) ||
        (read && !entry.read && !entry.exec) ||
        (exec && !entry.exec) ||
        (write && !entry.write)
    ) {
        return false;
    }
    
    log_printf("[TRN] translated %lx -> %lx\n", (uint64_t)vaddr, paddr);
    return true;
}

inline void
RtlSimDriver::handleFetch()
{
    top->revive->ifetch->fetch_data0 = 0;
    top->revive->ifetch->fetch_data1 = 0;
    top->revive->ifetch->page_fault = 0;
    
    if (top->revive->ifetch->valid) {
        uint64_t pc = (uint64_t)top->revive->ifetch->addr;
        uint64_t fetch_addr = (uint64_t)top->revive->ifetch->fetch_addr;
        
        int priv = (int)top->revive->lsu->priv;
        int trans_enabled = (int)top->revive->lsu->trans_enabled;
        bool trans = priv <= 1 && trans_enabled;
        uint64_t base_ppn = top->revive->lsu->trans_base_ppn;
        
        uint64_t paddr = 0;
        int lsu_in_except = (int)top->revive->lsu->in_except;
        int exe_in_except = (int)top->revive->exec->in_except;
        bool ok = !exe_in_except && !lsu_in_except &&
                  translateVaddr(fetch_addr, false, false, true,
                                 trans, priv, base_ppn, paddr);
        
        if (ok) {
            uint32_t fetch_data = (uint32_t)as->read_atomic(paddr, 4);
            uint16_t half0 = fetch_data & 0xffff;
            uint16_t half1 = fetch_data >> 16;
            top->revive->ifetch->fetch_data0 = half0;
            top->revive->ifetch->fetch_data1 = half1;
            
            log_printf("[SIM] Fetch @ %lx, PC @ %lx, Word: %x, Half0: %x, Half1: %x\n",
                       fetch_addr, pc, fetch_data, half0, half1);
        } else if (!exe_in_except && !lsu_in_except) {
            top->revive->ifetch->page_fault = 1;
            
            log_printf("[SIM] Fetch @ %lx, PC @ %lx, Page fault\n",
                       fetch_addr, pc);
        }
    }
}

inline void
RtlSimDriver::handleLSU()
{
    top->revive->lsu->page_fault_ld = 0;
    top->revive->lsu->page_fault_st = 0;
    
    if (top->revive->lsu->op_ignore) {
        return;
    }
    
    int op = top->revive->lsu->op;
    int size = top->revive->lsu->op_size;
    uint32_t vaddr = top->revive->lsu->addr;
    uint64_t base_ppn = top->revive->lsu->trans_base_ppn;
    
    int in_except = (int)top->revive->lsu->in_except;
    int priv = (int)top->revive->lsu->priv;
    int trans_enabled = (int)top->revive->lsu->trans_enabled;
    bool trans = priv <= 1 && trans_enabled;
    
    if (top->revive->lsu->is_mem_op) {
        uint64_t paddr = 0;
        bool ok = 
                  translateVaddr(vaddr, op <= 1, op == 2, false,
                                 trans, priv, base_ppn, paddr);
        
        if (ok) {
            if (op == 0) { // LD
                uint32_t data = 0;
                if (size == 0) {
                    uint8_t ld8 = (uint8_t)as->read_atomic(paddr, 1);
                    data = (int32_t)(int8_t)ld8;
                } else if (size == 1) {
                    uint16_t ld16 = (uint16_t)as->read_atomic(paddr, 2);
                    data = (int32_t)(int16_t)ld16;
                } else if (size == 2) {
                    uint32_t ld32 = (uint32_t)as->read_atomic(paddr, 4);
                    data = (int32_t)ld32;
                }
                top->revive->lsu->ld_data = data;
                
                log_printf("[SIM] Mem LD @ %lx, Size: %d, Data: %lx\n",
                           paddr, size, (uint64_t)data);
            }
            
            else if (op == 1) { // LDU
                uint32_t data = 0;
                if (size == 0) {
                    uint8_t ld8 = (uint8_t)as->read_atomic(paddr, 1);
                    data = ld8;
                } else if (size == 1) {
                    uint16_t ld16 = (uint16_t)as->read_atomic(paddr, 2);
                    data = ld16;
                } else if (size == 2) {
                    uint32_t ld32 = (uint32_t)as->read_atomic(paddr, 4);
                    data = ld32;
                }
                top->revive->lsu->ld_data = data;
                
                log_printf("[SIM] Mem LDU @ %lx, Size: %d, Data: %lx\n",
                           paddr, size, (uint64_t)data);
            }
            
            else if (op == 2) { // ST
                uint32_t data = top->revive->lsu->st_data;
                if (size == 0) {
                    as->write_atomic(paddr, 1, (uint8_t)data);
                } else if (size == 1) {
                    as->write_atomic(paddr, 2, (uint16_t)data);
                } else if (size == 2) {
                    as->write_atomic(paddr, 4, (uint32_t)data);
                }
                
                log_printf("[SIM] Mem ST @ %lx, Size: %d, Data: %lx\n",
                           paddr, size, (uint64_t)data);
            }
        }
        
        else {
            if (op <= 1) {
                top->revive->lsu->page_fault_ld = 1;
            } else if (op == 2) {
                top->revive->lsu->page_fault_st = 1;
            }
        }
    }
    
    else if (top->revive->lsu->is_amo_op && op <= 10) {
        uint64_t paddr = 0;
        bool ok = !in_except &&
                  translateVaddr(vaddr, true, true, false,
                                 trans, priv, base_ppn, paddr);
        
        if (ok) {
            uint32_t rs2 = top->revive->lsu->st_data;
            
            uint32_t ld_data = 0, st_data = 0;
            if (op == 1) { // SC
                top->revive->lsu->ld_data = 0;
            } else { // Other
                ld_data = (uint32_t)as->read_atomic(paddr, 4);
                top->revive->lsu->ld_data = ld_data;
            }
            
            switch (op) {
            case 0: break;                          // LR
            case 1: st_data = rs2; break;           // SC
            case 2: st_data = rs2; break;           // SWAP
            case 3: st_data = ld_data + rs2; break; // ADD
            case 4: st_data = ld_data ^ rs2; break; // XOR
            case 5: st_data = ld_data & rs2; break; // AND
            case 6: st_data = ld_data | rs2; break; // OR
            case 7: st_data = (int32_t)ld_data < (int32_t)rs2 ? ld_data : rs2; break; // MIN
            case 8: st_data = (int32_t)ld_data > (int32_t)rs2 ? ld_data : rs2; break; // MAX
            case 9: st_data = ld_data < rs2 ? ld_data : rs2; break;  // MINU
            case 10: st_data = ld_data > rs2 ? ld_data : rs2; break; // MAXU
            default: panic("Unknown AMO op: ", op);
            }
            
            if (op) {
                as->write_atomic(paddr, 4, (uint32_t)st_data);
            }
        }
        
        else {
            top->revive->lsu->page_fault_st = 1;
        }
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
        commitf = openOutputFile(commit_filename);
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
    
    // Interrupt
    top->i_int_ext = 0;
    top->i_int_timer = 0;
    top->i_int_soft = 0;
    
    // Time
    top->i_mtime = 0;
    
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

