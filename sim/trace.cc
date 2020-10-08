#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstdint>
#include "debug.hh"
#include "sim.hh"
#include "as.hh"
#include "trace.hh"


/*
 * Page table entry
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


/*
 * Helpers
 */
#define EXTRACT_BITS(value, range) extractBits(value, 1 ? range, 0 ? range)

static inline uint32_t
extractBits(uint32_t value, int hi, int lo)
{
    uint32_t mask = (0x1 << (hi - lo + 1)) - 0x1;
    return (value >> lo) & mask;
}

inline bool
TraceSimDriver::checkPaddr(uint64_t paddr, bool read, bool write, bool exec,
                           int &fault, int access_fault)
{
    return true;
}

inline bool
TraceSimDriver::translateVaddr(uint64_t vaddr, bool read, bool write, bool exec,
                               uint64_t &paddr, int &fault, int page_fault, int access_fault)
{
    bool need_trans = state.trans.mode && 
        (state.status.mprv ? state.status.mpp : state.priv) != PRIV_MACHINE;
    
    if (!need_trans) {
        paddr = vaddr;
    } else {
        uint64_t ppn = 0;
        Rv32PageTableEntry entry = { .value = 0 };
        
        uint32_t idx1 = (vaddr >> 22) & 0x3ff;
        uint64_t table1_paddr = (uint64_t)state.trans.ppn << 12;
        uint64_t entry1_paddr = table1_paddr + idx1 * 4;
        if (!checkPaddr(entry1_paddr, true, false, false, fault, access_fault)) {
            return false;
        }
        
        LOG(std::cout
            << "[TRN] Base PPN @ " << std::hex << state.trans.ppn << std::dec
            << ", idx: " << idx1
            << ", table1 @ " << std::hex << table1_paddr << std::dec
            << ", entry1_paddr @ " << std::hex << entry1_paddr << std::dec
            << ", vaddr @ " << std::hex << vaddr << std::dec
            << std::endl);
        
        entry.value = as->read_atomic(entry1_paddr, 4);
        if (!entry.valid || (!entry.read && entry.write)) { // invalid
            fault = page_fault;
            LOG(std::cout << "[TRN] invalid superpage" << std::endl);
            return false;
        } else if (entry.read || entry.exec) {
            if (entry.ppn & 0x3ff) { // misaligned superpage
                fault = page_fault;
                LOG(std::cout << "[TRN] misaligned superpage" << std::endl);
                return false;
            } else { // superpage
                ppn = entry.ppn;
                paddr = (ppn << 12) | (vaddr & 0x3fffffull);
                LOG(std::cout
                    << "[TRN] Super PPN @ " << std::hex << ppn << std::dec
                    << std::endl);
            }
        }
        
        // 2-level
        else {
            uint32_t idx2 = (vaddr >> 12) & 0x3ff;
            uint64_t table2_paddr = (uint64_t)entry.ppn << 12;
            uint64_t entry2_paddr = table2_paddr + idx2 * 4;
            entry.value = as->read_atomic(entry2_paddr, 4);
            if (!checkPaddr(entry2_paddr, true, false, false, fault, access_fault)) {
                return false;
            }
            
            if (!entry.valid || (!entry.read && entry.write) ||
                (!entry.read && !entry.exec)
            ) { // invalid
                fault = page_fault;
                return false;
            } else { // normal page
                ppn = entry.ppn;
                paddr = (ppn << 12) | (vaddr & 0xfffull);
                LOG(std::cout
                    << "[TRN] Final PPN @ " << std::hex << ppn << std::dec
                    << std::endl);
            }
        }
        
        // first access or write
        if (!entry.access || (!entry.dirty && write)) {
            fault = page_fault;
            return false;
        }
        
        // permission violation
        if ((state.priv == PRIV_USER && !entry.user) ||
            (state.priv == PRIV_SUPERVISOR && entry.user && !state.status.sum) ||
            (read && !entry.read && (!state.status.mxr || !entry.exec)) ||
            (exec && !entry.exec) ||
            (write && !entry.write)
        ) {
            fault = page_fault;
            return false;
        }
    }
    
    if (need_trans) {
        LOG(std::cout
            << "[TRN] translated " << std::hex << vaddr << std::dec
            << " -> " << std::hex << paddr << std::dec
            << std::endl);
    }
    
    return checkPaddr(paddr, read, write, exec, fault, access_fault);
}

inline bool
TraceSimDriver::readCSR(uint32_t csr, uint32_t &value)
{
    int min_priv = EXTRACT_BITS(csr, 9:8);
    if (state.priv < min_priv)
        return false;
    
    // Machine ISA
    if (csr == 0x301) {         // misa
        value = state.isa.value;
        return true;
    }
    
    // Machine status/ie/ip
    if (csr == 0x300) {  // mstatus
        value = state.status.value;
        return true;
    } else if (csr == 0x304) {  // mie
        value = state.inte.value;
        return true;
    } else if (csr == 0x344) {  // mip
        value = state.intp.value | state.inthw.value;
        return true;
    } else if (csr == 0x341) {  // mepc
        value = state.csr[0x341] & ~(state.isa.c ? 0x1 : 0x3);
        return true;
    }
    
    // Supervisor status/ie/ip
    if (csr == 0x100) {  // sstatus
        value = state.status.value;
        return true;
    } else if (csr == 0x104) {  // sie
        value = state.inte.value;
        return true;
    } else if (csr == 0x144) {  // sip
        value = state.intp.value | state.inthw.value;
        return true;
    } else if (csr == 0x141) {  // sepc
        value = state.csr[0x141] & ~(state.isa.c ? 0x1 : 0x3);
        return true;
    } else if (csr == 0x180) {  // satp
        value = state.trans.value;
        return true;
    }
    
    // User status/ie/ip
    if (csr == 0x000) {  // ustatus
        value = state.status.value;
        return true;
    } else if (csr == 0x004) {  // uie
        value = state.inte.value;
        return true;
    } else if (csr == 0x044) {  // uip
        value = state.intp.value | state.inthw.value;
        return true;
    } else if (csr == 0x041) {  // uepc
        value = state.csr[0x041] & ~(state.isa.c ? 0x1 : 0x3);
        return true;
    }
    
    // Machine CSRs
    if ((csr >= 0xf11 && csr <= 0xf14) ||   // mvendorid/marchid/mimpid/mhartid
        (csr == 0x302 || csr == 0x303) ||   // medeleg/mideleg
        (csr == 0x305 || csr == 0x306) ||   // mtvec/mcounteren
        (csr == 0x340)                 ||   // mscratch
        (csr == 0x342 || csr == 0x343) ||   // mcause/mtval
        (csr >= 0x3a0 && csr <= 0x3a3) ||   // pmpcfg0..3
        (csr >= 0x3b0 && csr <= 0x3bf) ||   // pmpaddr0..15
        (csr == 0x320)                 ||   // mcountinhibit
        (csr >= 0x323 && csr <= 0x33f)      // mhpmevent3..31
    ) {
        value = state.csr[csr];
        return true;
    }
    
    // Supervisor CSRs
    if ((csr == 0x102 || csr == 0x103) ||   // sedeleg/sideleg
        (csr == 0x105 || csr == 0x106) ||   // stvec/scounteren
        (csr == 0x140)                 ||   // sscratch
        (csr == 0x142 || csr == 0x143)      // scause/stval
    ) {
        value = state.csr[csr];
        return true;
    }
    
    // User CSRs
    if ((csr == 0x005)                 ||   // utvec
        (csr == 0x040)                 ||   // uscratch
        (csr == 0x042 || csr == 0x043) ||   // ucause/utval
        (csr >= 0x001 && csr <= 0x003)      // fflags/frm/fcsr
    ) {
        value = state.csr[csr];
        return true;
    }
    
    // Machine performance counters
    if ((csr >= 0xb00 && csr <= 0xb1f) ||   // mcycle/minstret/mhpmcounter3..31
        (csr >= 0xb80 && csr <= 0xb9f)      // mcycleh/minstreth/mhpmcounter3h..31h
    ) {
        bool hi = csr & 0x80;
        uint64_t full = state.perf[csr & 0x1f];
        value = hi ? (full >> 32) : (full & 0xffffffff);
        return true;
    }
    
    // Supervisor/User performance counters
    if ((csr >= 0xc00 && csr <= 0xc1f) ||   // cycle/time/instret/hpmcounter3..31
        (csr >= 0xc80 && csr <= 0xc9f)      // cycleh/time/instreth/hpmcounter3h..31h
    ) {
        uint32_t mask = 0x1 << (csr & 0x1f);
        bool acc = state.priv == 3 ? true :
                   state.priv == 1 ? (mask & state.csr[0x306] ? true : false) :
                   state.priv == 0 ? (mask & state.csr[0x306] & state.csr[0x106] ? true : false) :
                   false;
        if (!acc)
            return false;
        
        bool hi = csr & 0x80;
        uint64_t full = state.perf[csr & 0x1f];
        value = hi ? (full >> 32) : (full & 0xffffffffull);
        return true;
    }
    
    return false;
}

inline bool
TraceSimDriver::writeCSR(uint32_t csr, uint32_t value)
{
    bool ro = EXTRACT_BITS(csr, 11:10) == 0b11;
    if (ro)
        return false;
    
    int min_priv = EXTRACT_BITS(csr, 9:8);
    if (state.priv < min_priv)
        return false;
    
    // Machine ISA
    if (csr == 0x301) {         // misa
        state.isa.value = value;
        return true;
    }
    
    // Machine status/ie/ip
    if (csr == 0x300) {  // mstatus
        state.status.value = value;
        return true;
    } else if (csr == 0x304) {  // mie
        state.inte.value = value;
        return true;
    } else if (csr == 0x344) {  // mip
        state.intp.value = value;
        return true;
    }
    
    // Supervisor status/ie/ip
    if (csr == 0x100) {  // sstatus
        state.status.value = value;
        return true;
    } else if (csr == 0x104) {  // sie
        state.inte.value = value;
        return true;
    } else if (csr == 0x144) {  // sip
        state.intp.value = value;
        return true;
    } else if (csr == 0x180) {  // satp
        state.trans.value = value;
        return true;
    }
    
    // User status/ie/ip
    if (csr == 0x000) {  // ustatus
        state.status.value = value;
        return true;
    } else if (csr == 0x004) {  // uie
        state.inte.value = value;
        return true;
    } else if (csr == 0x044) {  // uip
        state.intp.value = value;
        return true;
    }
    
    // Machine CSRs
    if ((csr >= 0xf11 && csr <= 0xf14) ||   // mvendorid/marchid/mimpid/mhartid
        (csr == 0x302 || csr == 0x303) ||   // medeleg/mideleg
        (csr == 0x305 || csr == 0x306) ||   // mtvec/mcounteren
        (csr >= 0x340 && csr <= 0x343) ||   // mscratch/mepc/mcause/mtval
        (csr >= 0x3a0 && csr <= 0x3a3) ||   // pmpcfg0..3
        (csr >= 0x3b0 && csr <= 0x3bf) ||   // pmpaddr0..15
        (csr == 0x320) ||                   // mcountinhibit
        (csr >= 0x323 && csr <= 0x33f)      // mhpmevent3..31
    ) {
        state.csr[csr] = value;
        return true;
    }
    
    // Supervisor CSRs
    if ((csr == 0x102 || csr == 0x103) ||   // sedeleg/sideleg
        (csr == 0x105 || csr == 0x106) ||   // stvec/scounteren
        (csr >= 0x140 && csr <= 0x143)      // sscratch/sepc/scause/stval
    ) {
        state.csr[csr] = value;
        return true;
    }
    
    // User CSRs
    if ((csr == 0x005) ||                   // utvec
        (csr >= 0x040 && csr <= 0x043) ||   // uscratch/uepc/ucause/utval
        (csr >= 0x001 && csr <= 0x003)      // fflags/frm/fcsr
    ) {
        state.csr[csr] = value;
        return true;
    }
    
    // Machine performance counters
    if ((csr >= 0xb00 && csr <= 0xb1f) ||   // mcycle/minstret/mhpmcounter3..31
        (csr >= 0xb80 && csr <= 0xb9f)      // mcycleh/minstreth/mhpmcounter3h..31h
    ) {
        bool hi = csr & 0x80;
        uint64_t full = state.perf[csr & 0x1f];
        if (hi) {
            full = ((uint64_t)value << 32) | (full & 0xffffffffull);
        } else {
            full = (full & 0xffffffff00000000ull) | (uint64_t)value;
        }
        state.perf[csr & 0x1f] = full;
        return true;
    }
    
    return false;
}


/*
 * Decode
 */
struct InstrEncode
{
    union {
        uint32_t value;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t func7  : 7;
        };
        
        struct {
            uint32_t quad   : 2;
            uint32_t crs2   : 5;
            uint32_t crdrs1 : 5;
            uint32_t cfunc1 : 1;
            uint32_t cfunc3 : 3;
            uint32_t        : 11;
            uint32_t rs3    : 5;
        };
        
        struct {
            uint32_t        : 2;
            uint32_t crdrs2p: 3;
            uint32_t cfunc21: 2;
            uint32_t crdrs1p: 3;
            uint32_t cfunc22: 2;
            uint32_t        : 4;
            uint32_t        : 16;
        };
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t func7  : 7;
        } typeR;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t func2  : 2;
            uint32_t rs3    : 5;
        } typeR4;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t imm110 : 12;
        } typeI;
        
        struct {
            uint32_t opcode : 7;
            uint32_t imm40  : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t imm115 : 7;
        } typeS;
        
        struct {
            uint32_t opcode : 7;
            uint32_t imm11  : 1;
            uint32_t imm41  : 4;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t imm105 : 6;
            uint32_t imm12  : 1;
        } typeB;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t imm3112: 20;
        } typeU;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t imm1912: 8;
            uint32_t imm11  : 1;
            uint32_t imm101 : 10;
            uint32_t imm20  : 1;
        } typeJ;
        
        struct {
            uint32_t opcode : 7;
            uint32_t rd     : 5;
            uint32_t func3  : 3;
            uint32_t rs1    : 5;
            uint32_t rs2    : 5;
            uint32_t rl     : 1;
            uint32_t aq     : 1;
            uint32_t func5  : 5;
        } typeAMO;
    };
};

static inline uint32_t
extendSignBit(uint32_t value, int sign_bit_idx)
{
    uint32_t sign_bit_mask = 0x1 << sign_bit_idx;
    if (value & sign_bit_mask) {
        return value | ~(sign_bit_mask - 0x1);
    } else {
        return value;
    }
}

static inline uint32_t
extendImmTypeI(InstrEncode &encode)
{
    uint32_t value = 0;
    value = encode.typeI.imm110;
    value = extendSignBit(value, 11);
    return value;
}

static inline uint32_t
extendImmTypeS(InstrEncode &encode)
{
    uint32_t value = 0;
    value = encode.typeS.imm115;
    value = (value << 5) | encode.typeS.imm40;
    value = extendSignBit(value, 11);
    return value;
}

static inline uint32_t
extendImmTypeB(InstrEncode &encode)
{
    uint32_t value = 0;
    value = encode.typeB.imm12;
    value = (value << 1) | encode.typeB.imm11;
    value = (value << 6) | encode.typeB.imm105;
    value = (value << 4) | encode.typeB.imm41;
    value = (value << 1);
    value = extendSignBit(value, 12);
    return value;
}

static inline uint32_t
extendImmTypeU(InstrEncode &encode)
{
    uint32_t value = 0;
    value = encode.typeU.imm3112;
    value = value << 12;
    return value;
}

static inline uint32_t
extendImmTypeJ(InstrEncode &encode)
{
    uint32_t value = 0;
    value = encode.typeJ.imm20;
    value = (value << 8) | encode.typeJ.imm1912;
    value = (value << 1) | encode.typeJ.imm11;
    value = (value << 10) | encode.typeJ.imm101;
    value = (value << 1);
    value = extendSignBit(value, 20);
    return value;
}

static inline uint32_t
extendZimm(InstrEncode &encode)
{
    uint32_t value = encode.typeI.rs1;
    return value;
}

static inline uint32_t
extendCSR(InstrEncode &encode)
{
    uint32_t value = encode.typeI.imm110;
    return value;
}

static inline uint32_t
extendImmCSLLI(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 5) | EXTRACT_BITS(encode.value, 6:2);
    return value;
}

static inline uint32_t
extendImmCLWSP(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 3:2);
    value = (value << 1) | EXTRACT_BITS(encode.value, 12:12);
    value = (value << 3) | EXTRACT_BITS(encode.value, 6:4);
    value = (value << 2);
    return value;
}

static inline uint32_t
extendImmCSWSP(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 8:7);
    value = (value << 4) | EXTRACT_BITS(encode.value, 12:9);
    value = (value << 2);
    return value;
}

static inline uint32_t
extendImmCADDI4SPN(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 10:7);
    value = (value << 2) | EXTRACT_BITS(encode.value, 12:11);
    value = (value << 1) | EXTRACT_BITS(encode.value, 5:5);
    value = (value << 1) | EXTRACT_BITS(encode.value, 6:6);
    value = (value << 2);
    return value;
}

static inline uint32_t
extendImmCLWSW(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 5:5);
    value = (value << 3) | EXTRACT_BITS(encode.value, 12:10);
    value = (value << 1) | EXTRACT_BITS(encode.value, 6:6);
    value = (value << 2);
    return value;
}

static inline uint32_t
extendImmCADDI(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 5) | EXTRACT_BITS(encode.value, 6:2);
    value = extendSignBit(value, 5);
    return value;
}

static inline uint32_t
extendImmCJ(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 1) | EXTRACT_BITS(encode.value, 8:8);
    value = (value << 2) | EXTRACT_BITS(encode.value, 10:9);
    value = (value << 1) | EXTRACT_BITS(encode.value, 6:6);
    value = (value << 1) | EXTRACT_BITS(encode.value, 7:7);
    value = (value << 1) | EXTRACT_BITS(encode.value, 2:2);
    value = (value << 1) | EXTRACT_BITS(encode.value, 11:11);
    value = (value << 3) | EXTRACT_BITS(encode.value, 5:3);
    value = (value << 1);
    value = extendSignBit(value, 11);
    return value;
}

static inline uint32_t
extendImmCADDI16SP(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 2) | EXTRACT_BITS(encode.value, 4:3);
    value = (value << 1) | EXTRACT_BITS(encode.value, 5:5);
    value = (value << 1) | EXTRACT_BITS(encode.value, 2:2);
    value = (value << 1) | EXTRACT_BITS(encode.value, 6:6);
    value = (value << 4);
    value = extendSignBit(value, 9);
    return value;
}

static inline uint32_t
extendImmCLUI(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 5) | EXTRACT_BITS(encode.value, 6:2);
    value = (value << 12);
    value = extendSignBit(value, 17);
    return value;
}

static inline uint32_t
extendImmCSRL(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 5) | EXTRACT_BITS(encode.value, 6:2);
    return value;
}

static inline uint32_t
extendImmCB(InstrEncode &encode)
{
    uint32_t value;
    value = EXTRACT_BITS(encode.value, 12:12);
    value = (value << 2) | EXTRACT_BITS(encode.value, 6:5);
    value = (value << 1) | EXTRACT_BITS(encode.value, 2:2);
    value = (value << 2) | EXTRACT_BITS(encode.value, 11:10);
    value = (value << 2) | EXTRACT_BITS(encode.value, 4:3);
    value = (value << 1);
    value = extendSignBit(value, 8);
    return value;
}


/*
 * Trace
 */
inline void
TraceSimDriver::trace(uint64_t pc, InstrEncode &encode,
                      bool alter_pc, uint32_t next_pc,
                      bool wb_valid, int wb_idx, uint32_t wb_data)
{
    return;
    out << "[Cycle " << std::setw(5) << numInstrs << "] Instr # " << std::setw(5) << numInstrs
        << " | PC @ " << std::hex << std::setw(8) << std::setfill('0') << pc << std::dec
        << " | Encode: " << std::hex << std::setw(8) << std::setfill(' ') << encode.value << std::dec
        << " | PC Alter: " << alter_pc
            << " @ " << std::hex << std::setw(8) << std::setfill('0') << next_pc << std::dec
        << " | WB Valid: " << wb_valid
            << " @ " << std::setw(2) << std::setfill(' ') << wb_idx
            << " = " << std::hex << std::setw(8) << std::setfill('0') << wb_data << std::dec
        << std::setw(0) << std::setfill(' ') << std::endl;
}


/*
 * Trap
 */
static inline uint32_t
calculateTrapHandlerBase(uint32_t tvec, bool is_int, uint32_t int_code)
{
    int mode = tvec & 0x3;
    uint32_t base = tvec & ~0x3;
    if (!mode || !is_int) {
        return base;
    } else {
        return base + int_code * 4;
    }
}

inline void
TraceSimDriver::exceptEnter(uint32_t code, uint32_t tval)
{
    uint32_t cause = (uint32_t)code;
    
    uint32_t delegate_mask = 0x1 << code;
    uint32_t delegate_m = state.csr[0x302];
    uint32_t delegate_s = state.csr[0x102];
    
    LOG(std::cout
        << "[TRA] code: " << code
        << ", tval: " << std::hex << tval << std::dec
        << ", del U: " << ((delegate_mask & delegate_m & delegate_s) && state.priv == PRIV_USER)
        << ", del S: " << ((delegate_mask & delegate_m) && state.priv <= PRIV_SUPERVISOR)
        << std::endl);
    
    // delegate to U
    if ((delegate_mask & delegate_m & delegate_s) && state.priv == PRIV_USER) {
        state.csr[0x041] = state.pc;
        state.csr[0x042] = cause;
        state.csr[0x043] = tval;
        //state.status.upp = state.priv;
        state.status.upie = state.status.uie;
        state.status.uie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x005], false, 0);
        state.priv = PRIV_USER;
    }
    
    // delegate to S
    else if ((delegate_mask & delegate_m) && state.priv <= PRIV_SUPERVISOR) {
        state.csr[0x141] = state.pc;
        state.csr[0x142] = cause;
        state.csr[0x143] = tval;
        state.status.spp = state.priv;
        state.status.spie = state.status.sie;
        state.status.sie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x105], false, 0);
        state.priv = PRIV_SUPERVISOR;
    }
    
    // no delegation
    else {
        state.csr[0x341] = state.pc;
        state.csr[0x342] = cause;
        state.csr[0x343] = tval;
        state.status.mpp = state.priv;
        state.status.mpie = state.status.mie;
        state.status.mie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x305], false, 0);
        state.priv = PRIV_MACHINE;
    }
}

inline void
TraceSimDriver::trapReturn(int from_priv)
{
    // return to U
    if (from_priv == PRIV_USER) {
        state.status.uie = state.status.upie;
        state.pc = state.csr[0x041];
        state.priv = PRIV_USER; // state.status.upp;
    }
    
    // delegate to S
    else if (from_priv == PRIV_SUPERVISOR) {
        state.status.sie = state.status.spie;
        state.pc = state.csr[0x141];
        state.priv = state.status.spp;
    }
    
    // return to M
    else {
        state.status.mie = state.status.mpie;
        state.pc = state.csr[0x341];
        state.priv = state.status.mpp;
    }
    
    state.pc &= ~(state.isa.c ? 0x1 : 0x3);
    
    LOG(std::cout << "[RET] PC @ " << std::hex << state.pc << std::dec << std::endl);
}


/*
 * Interrupt
 */
static uint32_t findFirstIntCode(uint32_t mask)
{
    static const int int_prio_count = 9;
    static uint32_t int_prio[] = {
        TraceSimDriver::INT_MACHINE_EXTERNAL, TraceSimDriver::INT_MACHINE_SOFTWARE, TraceSimDriver::INT_MACHINE_TIMER,
        TraceSimDriver::INT_SUPERVISOR_EXTERNAL, TraceSimDriver::INT_SUPERVISOR_SOFTWARE, TraceSimDriver::INT_SUPERVISOR_TIMER,
        TraceSimDriver::INT_USER_EXTERNAL, TraceSimDriver::INT_USER_SOFTWARE, TraceSimDriver::INT_USER_TIMER
    };
    static uint32_t int_prio_code[] = {
        11, 3, 7,
        9, 1, 5,
        8, 0, 4
    };
    
    for (int i = 0; i < int_prio_count; i++) {
        uint32_t code = int_prio[i];
        if (code & mask) {
            return int_prio_code[i];
        }
    }
    
    panic("Unknown int mask: ", mask);
    return -1;
}

inline void
TraceSimDriver::interrupt()
{
    uint32_t int_mask = state.inte.value & (state.intp.value | state.inthw.value);
    
    // any int to be handled in M?
    uint32_t int_mask_m = int_mask & ~state.csr[0x303];
    if (int_mask_m &&(state.priv < PRIV_MACHINE || state.status.mie)) {
        uint32_t code = findFirstIntCode(int_mask_m);
        state.csr[0x341] = state.pc;
        state.csr[0x342] = 0x80000000 | code;
        state.csr[0x343] = 0;
        state.status.mpp = state.priv;
        state.status.mpie = state.status.mie;
        state.status.mie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x305], true, code);
        state.priv = PRIV_MACHINE;
        return;
    }
    
    // any int to be handled in S?
    uint32_t int_mask_s = int_mask & state.csr[0x303] & ~state.csr[0x103];
    if (int_mask_s && (state.priv < PRIV_SUPERVISOR ||
                       (state.priv == PRIV_SUPERVISOR && state.status.sie))
    ) {
        uint32_t code = findFirstIntCode(int_mask_s);
        state.csr[0x141] = state.pc;
        state.csr[0x142] = 0x80000000 | code;
        state.csr[0x143] = 0;
        state.status.spp = state.priv;
        state.status.spie = state.status.sie;
        state.status.sie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x105], true, code);
        state.priv = PRIV_SUPERVISOR;
        return;
    }
    
    // any int to be handled in U?
    uint32_t int_mask_u = int_mask & state.csr[0x303] & state.csr[0x103];
    if (int_mask_u && state.priv == PRIV_USER && state.status.sie) {
        uint32_t code = findFirstIntCode(int_mask_u);
        state.csr[0x041] = state.pc;
        state.csr[0x042] = 0x80000000 | code;
        state.csr[0x043] = 0;
        //state.status.upp = state.priv;
        state.status.upie = state.status.uie;
        state.status.uie = 0;
        state.pc = calculateTrapHandlerBase(state.csr[0x005], true, code);
        state.priv = PRIV_USER;
        return;
    }
}


/*
 * Execute
 */
#define OP_ADD(src1, src2)  ((src1) + (src2))
#define OP_SUB(src1, src2)  ((src1) - (src2))
#define OP_AND(src1, src2)  ((src1) & (src2))
#define OP_OR(src1, src2)   ((src1) | (src2))
#define OP_XOR(src1, src2)  ((src1) ^ (src2))

#define OP_SLT(src1, src2)  ((int32_t)(src1) < (int32_t)(src2) ? 1 : 0)
#define OP_SLTU(src1, src2) ((uint32_t)(src1) < (uint32_t)(src2) ? 1 : 0)

#define OP_SLL(src1, src2)  ((uint32_t)(src1) << (src2))
#define OP_SRL(src1, src2)  ((uint32_t)(src1) >> (src2))
#define OP_SRA(src1, src2)  ((int32_t)(src1) >> (src2))

#define OP_MUL(src1, src2)  ((uint32_t)(src1) * (uint32_t)(src2))
#define OP_DIV(src1, src2)  ((uint32_t)(src1) == 0x80000000 && ((uint32_t)(src2) == 0x1 || (int32_t)(src2) == -1) ? 0x80000000 : \
                             (src2) ? (int32_t)(src1) / (int32_t)(src2) : (-0x1))
#define OP_DIVU(src1, src2) ((src2) ? (uint32_t)(src1) / (uint32_t)(src2) : (-0x1))
#define OP_REM(src1, src2)  ((uint32_t)(src1) == 0x80000000 && ((uint32_t)(src2) == 0x1 || (int32_t)(src2) == -1) ? 0 : \
                             (src2) ? (int32_t)(src1) % (int32_t)(src2) : (src1))
#define OP_REMU(src1, src2) ((src2) ? (uint32_t)(src1) % (uint32_t)(src2) : (src1))

#define OP_EQ(src1, src2)  ((src1) == (src2))
#define OP_NE(src1, src2)  ((src1) != (src2))
#define OP_LT(src1, src2)  ((int32_t)(src1) < (int32_t)(src2))
#define OP_LTU(src1, src2) ((uint32_t)(src1) < (uint32_t)(src2))
#define OP_GE(src1, src2)  ((int32_t)(src1) >= (int32_t)(src2))
#define OP_GEU(src1, src2) ((uint32_t)(src1) >= (uint32_t)(src2))

#define OP_AMO_OK(src1, src2)   (0)
#define OP_AMO_LL(src1, src2)   (src1)
#define OP_AMO_SWAP(src1, src2) (src2)
#define OP_AMO_MIN(src1, src2)  ((int32_t)(src1) < (int32_t)(src2) ? (src1) : (src2))
#define OP_AMO_MINU(src1, src2)  ((src1) < (src2) ? (src1) : (src2))
#define OP_AMO_MAX(src1, src2)  ((int32_t)(src1) > (int32_t)(src2) ? (src1) : (src2))
#define OP_AMO_MAXU(src1, src2)  ((src1) > (src2) ? (src1) : (src2))

#define OP_CSR_SWAP(src1, src2)     (src2)
#define OP_CSR_SET(src1, src2)      ((src1) | (src2))
#define OP_CSR_CLEAR(src1, src2)    ((src1) & ~(src2))

#define EXECUTE_UNKNOWN(encode) do { \
        trace(state.pc, encode, false, state.pc, false, 0, 0); \
        std::cerr << "PC @ " << std::hex << state.pc << std::dec \
            << ", encode: " << std::hex << encode.value << std::dec \
            << ", len: " << instr_len \
            << std::endl; \
        panic("Unknown instr\n"); \
        mach->terminate(-1); \
    } while (0)

#define EXECUTE_ALU(dst, src1, src2, op, w32) do { \
        uint32_t value = op((src1), (src2)); \
        writeGPR(dst, value); \
        uint32_t target = state.pc + instr_len; \
        trace(state.pc, encode, \
              false, target, \
              true, (dst), value); \
        LOG(std::cout \
            << "[ALU] dst: " << (dst) \
            << ", src1: " << std::hex << (src1) << std::dec \
            << ", src2: " << std::hex << (src2) << std::dec \
            << ", op: " << #op << std::dec \
            << ", val: " << std::hex << value << std::dec \
            << std::endl); \
        state.pc = target;  \
    } while (0)

#define EXECUTE_MUH(dst, src1, sign1, src2, sign2, w32) do { \
        uint32_t usrc1 = src1; \
        uint32_t usrc2 = src2; \
        bool neg1 = sign1 && (src1 & 0x80000000); \
        bool neg2 = sign2 && (src2 & 0x80000000); \
        if (neg1) usrc1 = ~usrc1 + 0x1; \
        if (neg2) usrc2 = ~usrc2 + 0x1; \
        uint64_t value = (uint64_t)usrc1 * (uint64_t)usrc2; \
        if (neg1 != neg2) value = ~value + 0x1ull; \
        uint32_t high = value >> 32; \
        writeGPR(dst, high); \
        uint32_t target = state.pc + instr_len; \
        trace(state.pc, encode, \
              false, target, \
              true, (dst), high); \
        LOG(std::cout \
            << "[MUH] dst: " << (dst) \
            << ", src1: " << (neg1 ? "-" : "+") << std::hex << (src1) << std::dec \
            << ", src2: " << (neg2 ? "-" : "+") << std::hex << (src2) << std::dec \
            << ", val: " << std::hex << value << std::dec \
            << ", hi: " << std::hex << high << std::dec \
            << std::endl); \
        state.pc = target;  \
    } while (0)

#define EXECUTE_JAL(dst, base, offset) do { \
        uint32_t target = ((base) + (offset)) & ~0x1; \
        uint32_t link = state.pc + instr_len; \
        LOG(std::cout \
            << "[JAL] dst: " << (dst) \
            << ", base: " << std::hex << (base) << std::dec \
            << ", offset: " << std::hex << (offset) << std::dec \
            << ", target: " << std::hex << (target) << std::dec \
            << ", link: " << std::hex << (link) << std::dec \
            << std::endl); \
        if (!state.isa.c && target & 0x3) { \
            exceptEnter(INSTR_ADDR_MISALIGN, target); \
        } else { \
            trace(state.pc, encode, \
                  true, target, \
                  true, (dst), link); \
            writeGPR(dst, link); \
            state.pc = target; \
        } \
    } while (0)

#define EXECUTE_BRANCH(src1, src2, op, offset) do { \
        bool taken = op((src1), (src2)); \
        uint32_t taken_pc = state.pc + offset; \
        uint32_t ntaken_pc = state.pc + instr_len; \
        uint32_t target = taken ? taken_pc : ntaken_pc; \
        LOG(std::cout \
            << "[BRA] taken: " << taken \
            << ", src1: " << std::hex << (src1) << std::dec \
            << ", src2: " << std::hex << (src2) << std::dec \
            << ", op: " << #op \
            << ", offset: " << std::hex << (offset) << std::dec \
            << ", target: " << std::hex << (target) << std::dec \
            << std::endl); \
        if (!state.isa.c && target & 0x3) { \
            exceptEnter(INSTR_ADDR_MISALIGN, target); \
        } else { \
            trace(state.pc, encode, \
                  true, target, \
                  false, 0, 0); \
            state.pc = target; \
        } \
    } while (0)

#define EXECUTE_LD(dst, base, offset, sign, size) do { \
        uint32_t addr = base + offset; \
        uint32_t value = 0; \
        int fault = 0; \
        bool ok = executeG_LD(addr, sign, size, value, fault); \
        LOG(std::cout \
            << "[LD ] dst: " << (dst) \
            << ", base: " << std::hex << (base) << std::dec \
            << ", offset: " << std::hex << (offset) << std::dec \
            << ", addr: " << std::hex << addr << std::dec \
            << ", sign: " << (sign) \
            << ", size: " << (size) \
            << ", value: " << std::hex << value << std::dec \
            << std::endl); \
        if (!ok) { \
            exceptEnter(fault, addr); \
        } else { \
            uint32_t target = state.pc + instr_len; \
            trace(state.pc, encode, \
                  false, target, \
                  true, (dst), value); \
            writeGPR(dst, value); \
            state.pc = target;  \
        } \
    } while (0)

#define EXECUTE_ST(value, base, offset, size) do { \
        uint32_t addr = base + offset; \
        int fault = 0; \
        bool ok = executeG_ST(addr, size, value, fault); \
        LOG(std::cout \
            << "[ST ] value: " << std::hex << value << std::dec \
            << ", base: " << std::hex << (base) << std::dec \
            << ", offset: " << std::hex << (offset) << std::dec \
            << ", addr: " << std::hex << addr << std::dec \
            << ", size: " << (size) \
            << std::endl); \
        if (!ok) { \
            exceptEnter(fault, addr); \
        } else { \
            uint32_t target = state.pc + instr_len; \
            trace(state.pc, encode, \
                  false, target, \
                  false, 0, 0); \
            state.pc = target;  \
        } \
    } while (0)

#define EXECUTE_AMO(dst, addr, rs2, op_name, op_ld, op_st, size) do { \
        uint32_t addrval = addr; \
        uint32_t rs2val = rs2; \
        uint32_t ldval = 0; \
        uint32_t stval = 0; \
        int fault = 0; \
        bool ok = true; \
        uint32_t align_mask = (0x1 << size) - 0x1; \
        if (addrval & align_mask) { \
            ok = false; \
            fault = STORE_ADDR_MISALIGN; \
        } else { \
            uint64_t paddr = 0; \
            ok = translateVaddr(addr, true, true, false, paddr, fault, \
                                STORE_PAGE_FAULT, STORE_ACCESS_FAULT); \
            if (ok) { \
                ok = executeG_LD(addrval, false, size, ldval, fault); \
                if (ok) { \
                    ldval = op_ld(ldval, rs2val); \
                    writeGPR(dst, ldval); \
                    stval = op_st(ldval, rs2val); \
                    ok = executeG_ST(addrval, size, stval, fault); \
                } \
            } \
        } \
        LOG(std::cout \
            << "[AMO] dst: " << (dst) \
            << ", addr: " << std::hex << addrval << std::dec \
            << ", src: " << std::hex << rs2val << std::dec \
            << ", op: " << (op_name) \
            << ", op_ld: " << #op_ld \
            << ", op_st: " << #op_st \
            << ", size: " << (size) \
            << ", ldval: " << std::hex << ldval << std::dec \
            << ", stval: " << std::hex << stval << std::dec \
            << ", ok: " << ok \
            << std::endl); \
        if (!ok) { \
            exceptEnter(fault, addr); \
        } else { \
            uint32_t target = state.pc + instr_len; \
            trace(state.pc, encode, \
                  false, target, \
                  true, (dst), ldval); \
            state.pc = target;  \
        } \
    } while (0)

#define EXECUTE_FENCE(flush_icache) do { \
        uint32_t target = state.pc + instr_len; \
        trace(state.pc, encode, \
              false, target, \
              false, 0, 0); \
        LOG(std::cout \
            << "[FEN] flush i$: " << (flush_icache) \
            << std::endl); \
        state.pc = target;  \
    } while (0)

#define EXECUTE_CSR(dst, src, csr, rd_csr, wr_csr, op) do { \
        uint32_t ldval = 0, stval = 0, srcval = (src); \
        bool rd_ok = true, wr_ok = true; \
        if (rd_csr) rd_ok = readCSR(csr, ldval); \
        if (rd_ok) { \
            writeGPR(dst, ldval); \
            if (wr_csr) { \
                stval = op(ldval, srcval); \
                wr_ok = writeCSR(csr, stval); \
            } \
        } \
        LOG(std::cout \
            << "rd_ok: " << rd_ok << ", wr_ok: " << wr_ok \
            << ", csr: " << std::hex << csr << std::dec \
            << std::endl); \
        if (!rd_ok || !wr_ok) { \
            EXECUTE_UNKNOWN(encode); \
        } \
        uint32_t target = state.pc + instr_len; \
        trace(state.pc, encode, \
              false, target, \
              true, (dst), ldval); \
        LOG(std::cout \
            << "[CSR] dst: " << (dst) \
            << ", src: " << std::hex << (srcval) << std::dec \
            << ", csr: " << std::hex << (csr) << std::dec \
            << ", op: " << #op \
            << ", ldval: " << std::hex << ldval << std::dec \
            << ", stval: " << std::hex << stval << std::dec \
            << std::endl); \
        state.pc = target;  \
    } while (0)

#define EXECUTE_ECALL() do { \
        int code = ECALL_FROM_U; \
        code += state.priv; \
        LOG(std::cout \
            << "[ECL] code: " << code \
            << std::endl); \
        exceptEnter(code, 0); \
    } while (0)

#define EXECUTE_EBREAK() do { \
        int code = BREAKPOINT; \
        LOG(std::cout \
            << "[EBK] code: " << code \
            << std::endl); \
        exceptEnter(code, state.pc); \
    } while (0)

#define EXECUTE_RET(from) do { \
        if ((from) > state.priv) { \
            EXECUTE_UNKNOWN(encode); \
        } else { \
            if ((from) == PRIV_SUPERVISOR && state.status.tsr) { \
                EXECUTE_UNKNOWN(encode); \
            } else { \
                LOG(std::cout \
                    << "[RET] priv: " << (from) \
                    << std::endl); \
                trapReturn(from); \
            } \
        } \
    } while (0)

inline bool
TraceSimDriver::executeG_LD(uint32_t addr, bool sign, int size, uint32_t &value, int &fault)
{
    uint32_t align_mask = (0x1 << size) - 0x1;
    if (addr & align_mask) {
        fault = LOAD_ADDR_MISALIGN;
        return false;
    }
    
    uint64_t paddr = 0;
    bool trans_ok = translateVaddr(addr, true, false, false, paddr, fault,
                                   LOAD_PAGE_FAULT, LOAD_ACCESS_FAULT);
    if (!trans_ok) {
        return false;
    }
    
    if (size == 0) {
        uint8_t ld8 = (uint8_t)as->read_atomic(paddr, 1);
        value = sign ? (uint32_t)(int32_t)(int8_t)ld8 : ld8;
    } else if (size == 1) {
        uint16_t ld16 = (uint16_t)as->read_atomic(paddr, 2);
        value = sign ? (uint32_t)(int32_t)(int16_t)ld16 : ld16;
    } else if (size == 2) {
        uint32_t ld32 = (uint32_t)as->read_atomic(paddr, 4);
        value = ld32;
    }
    
    LOG(std::cout
        << "[SIM] Mem LD @ " << std::hex << addr << std::dec
        << ", Trans @ " << std::hex << paddr << std::dec
        << ", Size: " << size
        << ", Data: " << std::hex << value << std::dec
        << std::endl);
    
    return true;
}

inline bool
TraceSimDriver::executeG_ST(uint32_t addr, int size, uint32_t value, int &fault)
{
    uint32_t align_mask = (0x1 << size) - 0x1;
    if (addr & align_mask) {
        fault = STORE_ADDR_MISALIGN;
        return false;
    }
    
    uint64_t paddr = 0;
    bool trans_ok = translateVaddr(addr, false, true, false, paddr, fault,
                                   STORE_PAGE_FAULT, STORE_ACCESS_FAULT);
    if (!trans_ok) {
        return false;
    }
    
    if (size == 0) {
        as->write_atomic(paddr, 1, (uint8_t)value);
    } else if (size == 1) {
        as->write_atomic(paddr, 2, (uint16_t)value);
    } else if (size == 2) {
        as->write_atomic(paddr, 4, (uint32_t)value);
    }
    
    LOG(std::cout
        << "[SIM] Mem ST @ " << std::hex << addr << std::dec
        << ", Trans @ " << std::hex << paddr << std::dec
        << ", Size: " << size
        << ", Data: " << std::hex << value << std::dec
        << std::endl);
    
    return true;
}

inline void
TraceSimDriver::executeG(InstrEncode &encode)
{
    const int instr_len = 4;
    
    switch (encode.opcode) {
    case 0b0110111: // LUI
        EXECUTE_ALU(encode.rd, 0, extendImmTypeU(encode), OP_ADD, false);
        break;
    case 0b0010111: // AUIPC
        EXECUTE_ALU(encode.rd, state.pc, extendImmTypeU(encode), OP_ADD, false);
        break;
    case 0b1101111: // JAL
        EXECUTE_JAL(encode.rd, state.pc, extendImmTypeJ(encode));
        break;
    case 0b1100111: // JALR
        EXECUTE_JAL(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode));
        break;
    case 0b1100011: // BEQ/BNE/BLT/BGE/BLTU/BGEU
        switch (encode.func3) {
        case 0b000: // BEQ
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_EQ, extendImmTypeB(encode));
            break;
        case 0b001: // BNE
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_NE, extendImmTypeB(encode));
            break;
        case 0b100: // BLT
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_LT, extendImmTypeB(encode));
            break;
        case 0b101: // BGE
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_GE, extendImmTypeB(encode));
            break;
        case 0b110: // BLTU
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_LTU, extendImmTypeB(encode));
            break;
        case 0b111: // BGEU
            EXECUTE_BRANCH(readGPR(encode.rs1), readGPR(encode.rs2), OP_GEU, extendImmTypeB(encode));
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b0000011: // LB/LH/LW/LBU/LHU
        switch (encode.func3) {
        case 0b000: // LB
            EXECUTE_LD(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), true, 0);
            break;
        case 0b001: // LH
            EXECUTE_LD(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), true, 1);
            break;
        case 0b010: // LW
            EXECUTE_LD(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), true, 2);
            break;
        case 0b100: // LBU
            EXECUTE_LD(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), false, 0);
            break;
        case 0b101: // LHU
            EXECUTE_LD(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), false, 1);
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b0100011: // SB/SH/SW
        switch (encode.func3) {
        case 0b000: // SB
            EXECUTE_ST(readGPR(encode.rs2), readGPR(encode.rs1), extendImmTypeS(encode), 0);
            break;
        case 0b001: // SH
            EXECUTE_ST(readGPR(encode.rs2), readGPR(encode.rs1), extendImmTypeS(encode), 1);
            break;
        case 0b010: // SW
            EXECUTE_ST(readGPR(encode.rs2), readGPR(encode.rs1), extendImmTypeS(encode), 2);
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b0010011: // ADDI/SLTI/SLTU/XORI/ORI/ANDI/SLLLI/SRLI/SRAI
        switch (encode.func3) {
        case 0b000: // ADDI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_ADD, false);
            break;
        case 0b010: // SLTI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), (int32_t)extendImmTypeI(encode), OP_SLT, false);
            break;
        case 0b011: // SLTIU
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_SLTU, false);
            break;
        case 0b100: // XORI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_XOR, false);
            break;
        case 0b110: // ORI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_OR, false);
            break;
        case 0b111: // ANDI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_AND, false);
            break;
        case 0b001: // SLLI
            EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_SLL, false);
            break;
        case 0b101: // SRLI/SRAI
            if (encode.value & 0x40000000) // SRAI
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), (int32_t)extendImmTypeI(encode), OP_SRA, false);
            else // SRLI
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), extendImmTypeI(encode), OP_SRL, false);
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b0110011: // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND/MUL*/DIV*/REM*
        if (encode.func7 == 0b0000001) { // MUL*/DIV*/REM*
            switch (encode.func3) {
            case 0b000: // MUL
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_MUL, false);
                break;
            case 0b001: // MULH
                EXECUTE_MUH(encode.rd, readGPR(encode.rs1), true, readGPR(encode.rs2), true, false);
                break;
            case 0b010: // MULHSU
                EXECUTE_MUH(encode.rd, readGPR(encode.rs1), true, readGPR(encode.rs2), false, false);
                break;
            case 0b011: // MULHU
                EXECUTE_MUH(encode.rd, readGPR(encode.rs1), false, readGPR(encode.rs2), false, false);
                break;
            case 0b100: // DIV
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_DIV, false);
                break;
            case 0b101: // DIVU
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_DIVU, false);
                break;
            case 0b110: // REM
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_REM, false);
                break;
            case 0b111: // REMU
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_REMU, false);
                break;
            default:
                EXECUTE_UNKNOWN(encode);
                break;
            }
        } else { // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
            switch (encode.func3) {
            case 0b000: // ADD/SUB
                if (encode.value & 0x40000000) // SUB
                    EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SUB, false);
                else // ADD
                    EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_ADD, false);
                break;
            case 0b010: // SLT
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SLT, false);
                break;
            case 0b011: // SLTU
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SLTU, false);
                break;
            case 0b100: // XOR
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_XOR, false);
                break;
            case 0b110: // OR
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_OR, false);
                break;
            case 0b111: // AND
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_AND, false);
                break;
            case 0b001: // SLL
                EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SLL, false);
                break;
            case 0b101: // SRL/SRA
                if (encode.value & 0x40000000) // SRA
                    EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SRA, false);
                else // SRL
                    EXECUTE_ALU(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), OP_SRL, false);
                break;
            default:
                EXECUTE_UNKNOWN(encode);
                break;
            }
        }
        break;
    case 0b0101111: // AMO
        if (encode.func3 == 0b010) {
            switch (encode.typeAMO.func5) {
            case 0b00010: // LR
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "ll", OP_AMO_LL, OP_AMO_LL, 2);
                break;
            case 0b00011: // SC
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "sc", OP_AMO_OK, OP_AMO_SWAP, 2);
                break;
            case 0b00001: // AMO.SWAP
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "swap", OP_AMO_LL, OP_AMO_SWAP, 2);
                break;
            case 0b00000: // AMO.ADD
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "add", OP_AMO_LL, OP_ADD, 2);
                break;
            case 0b00100: // AMO.XOR
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "xor", OP_AMO_LL, OP_XOR, 2);
                break;
            case 0b01100: // AMO.AND
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "and", OP_AMO_LL, OP_AND, 2);
                break;
            case 0b01000: // AMO.OR
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "or", OP_AMO_LL, OP_OR, 2);
                break;
            case 0b10000: // AMO.MIN
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "min", OP_AMO_LL, OP_AMO_MIN, 2);
                break;
            case 0b11000: // AMO.MINU
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "minu", OP_AMO_LL, OP_AMO_MINU, 2);
                break;
            case 0b10100: // AMO.MAX
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "max", OP_AMO_LL, OP_AMO_MAX, 2);
                break;
            case 0b11100: // AMO.MAXU
                EXECUTE_AMO(encode.rd, readGPR(encode.rs1), readGPR(encode.rs2), "maxu", OP_AMO_LL, OP_AMO_MAXU, 2);
                break;
            default:
                EXECUTE_UNKNOWN(encode);
                break;
            }
        } else {
            EXECUTE_UNKNOWN(encode);
        }
        break;
    case 0b0001111: // FENCE/FENCE.I
        switch (encode.func3) {
        case 0b000: // FENCE
            EXECUTE_FENCE(false);
            break;
        case 0b001: // FENCE.I
            EXECUTE_FENCE(true);
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b1110011: // ECALL/EBREAK/CSRRW/CSRRS/CSRRC/CSRRWI/CSRRSI/CSRRCI
        switch (encode.func3) {
        case 0b000: // ECALL/EBREAK/URET/SRET/MRET/WFI/SFENCE.VMA
            if (encode.func7 == 0b0001001) { // SFENCE.VMA
                EXECUTE_FENCE(false);
            } else if (encode.rs2 == 0b00101 && encode.func7 == 0b0001000) { // WFI
                EXECUTE_FENCE(false);
            } else if (encode.rs2 == 0b00010) { // URET/SRET/MRET
                switch (encode.func7) {
                case 0b0000000: // URET
                    EXECUTE_RET(0);
                    break;
                case 0b0001000: // SRET
                    EXECUTE_RET(1);
                    break;
                case 0b0011000: // MRET
                    EXECUTE_RET(3);
                    break;
                default:
                    EXECUTE_UNKNOWN(encode);
                    break;
                }
            } else if (encode.typeI.imm110 == 0) { // ECALL
                EXECUTE_ECALL();
            } else if (encode.typeI.imm110 == 1) { // EBREAK
                EXECUTE_EBREAK();
            } else {
                EXECUTE_UNKNOWN(encode);
            }
            break;
        case 0b001: // CSRRW
            EXECUTE_CSR(encode.rd, readGPR(encode.rs1), extendCSR(encode), encode.rd, true, OP_CSR_SWAP);
            break;
        case 0b010: // CSRRS
            EXECUTE_CSR(encode.rd, readGPR(encode.rs1), extendCSR(encode), true, encode.rs1, OP_CSR_SET);
            break;
        case 0b011: // CSRRC
            EXECUTE_CSR(encode.rd, readGPR(encode.rs1), extendCSR(encode), true, encode.rs1, OP_CSR_CLEAR);
            break;
        case 0b101: // CSRRWI
            EXECUTE_CSR(encode.rd, extendZimm(encode), extendCSR(encode), encode.rd, true, OP_CSR_SWAP);
            break;
        case 0b110: // CSRRSI
            EXECUTE_CSR(encode.rd, extendZimm(encode), extendCSR(encode), true, encode.rs1, OP_CSR_SET);
            break;
        case 0b111: // CSRRCI
            EXECUTE_CSR(encode.rd, extendZimm(encode), extendCSR(encode), true, encode.rs1, OP_CSR_CLEAR);
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    }
}

inline void
TraceSimDriver::executeQ2(InstrEncode &encode)
{
    const int instr_len = 2;
    
    switch (encode.cfunc3) {
    case 0b000: // C.SLLI
        // slli rd, rd, shamt[5:0]
        EXECUTE_ALU(encode.crdrs1, readGPR(encode.crdrs1), extendImmCSLLI(encode), OP_SLL, false);
        break;
    case 0b010: // C.LWSP
        // lw rd, offset[7:2](x2)
        EXECUTE_LD(encode.crdrs1, readGPR(2), extendImmCLWSP(encode), true, 2);
        break;
    case 0b100: // C.JR/C.MV/C.EBREAK/C.JALR/C.ADD
        if (encode.crdrs1 && encode.crs2) { // func1 ? C.ADD : C.MV
            // 1 ~ C.ADD -> add rd, rd, rs2
            // 0 ~ C.MV  -> add rd, x0, rs2
            EXECUTE_ALU(encode.crdrs1, encode.cfunc1 ? readGPR(encode.crdrs1) : 0, readGPR(encode.crs2), OP_ADD, false);
        } else if (encode.crdrs1) { // func1 ? C.JALR : C.JR
            // 1 ~ C.JALR -> jalr x1, 0(rs1)
            // 0 ~ C.JR   -> jalr x0, 0(rs1)
            EXECUTE_JAL(encode.cfunc1 ? 1 : 0, readGPR(encode.crdrs1), 0);
        } else { // C.EBREAK
            EXECUTE_EBREAK();
        }
        break;
    case 0b110: // C.SWSP
        // sw rs2, offset[7:2](x2)
        EXECUTE_ST(readGPR(encode.crs2), readGPR(2), extendImmCSWSP(encode), 2);
        break;
    default:
        EXECUTE_UNKNOWN(encode);
        break;
    }
}

inline void
TraceSimDriver::executeQ1(InstrEncode &encode)
{
    const int instr_len = 2;
    
    switch (encode.cfunc3) {
    case 0b000: // C.NOP/C.ADDI
        // addi rd, rd, nzimm[5:0]
        EXECUTE_ALU(encode.crdrs1, readGPR(encode.crdrs1), extendImmCADDI(encode), OP_ADD, false);
        break;
    case 0b001: // C.JAL
        // jal x1, offset[11:1]
        EXECUTE_JAL(1, state.pc, extendImmCJ(encode));
        break;
    case 0b010: // C.LI
        // addi rd, x0, imm[5:0]
        EXECUTE_ALU(encode.crdrs1, 0, extendImmCADDI(encode), OP_ADD, false);
        break;
    case 0b011: // C.ADDI16SP/C.LUI
        // rd == 2      ~ addi x2, x2, nzimm[9:4]
        // rs != {0, 2} ~ lui rd, nzimm[17:12]
        if (encode.crdrs1 == 2) {
            EXECUTE_ALU(2, readGPR(2), extendImmCADDI16SP(encode), OP_ADD, false);
        } else {
            EXECUTE_ALU(encode.crdrs1, 0, extendImmCLUI(encode), OP_ADD, false);
        }
        break;
    case 0b100: // ALU
        switch (encode.cfunc22) {
        case 0b00:  // C.SRLI
            // srli rd', rd', shamt[5:0]
            EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), extendImmCSRL(encode), OP_SRL, false);
            break;
        case 0b01:  // C.SRAI
            // srai rd', rd', shamt[5:0]
            EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), extendImmCSRL(encode), OP_SRA, false);
            break;
        case 0b10:  // C.ANDI
            // andi rd',rd', imm[5:0]
            EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), extendImmCADDI(encode), OP_AND, false);
            break;
        case 0b11:  // ALU
            switch (encode.cfunc21) {
            case 0b00:  // C.SUB
                // sub rd', rd', rs2'
                EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), readGPR(encode.crdrs2p + 8), OP_SUB, false);
                break;
            case 0b01:  // C.XOR
                // xor rd', rd', rs2'
                EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), readGPR(encode.crdrs2p + 8), OP_XOR, false);
                break;
            case 0b10:  // C.OR
                // or rd', rd', rs2'
                EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), readGPR(encode.crdrs2p + 8), OP_OR, false);
                break;
            case 0b11:  // C.AND
                // and rd', rd', rs2'
                EXECUTE_ALU(encode.crdrs1p + 8, readGPR(encode.crdrs1p + 8), readGPR(encode.crdrs2p + 8), OP_AND, false);
                break;
            default:
                EXECUTE_UNKNOWN(encode);
                break;
            }
            break;
        default:
            EXECUTE_UNKNOWN(encode);
            break;
        }
        break;
    case 0b101: // C.J
        // jal x0, offset[11:1]
        EXECUTE_JAL(0, state.pc, extendImmCJ(encode));
        break;
    case 0b110: // C.BEQZ
        // beq rs1', x0, offset[8:1]
        EXECUTE_BRANCH(readGPR(encode.crdrs1p + 8), 0, OP_EQ, extendImmCB(encode));
        break;
    case 0b111: // C.BNEZ
        // bne rs1', x0, offset[8:1]
        EXECUTE_BRANCH(readGPR(encode.crdrs1p + 8), 0, OP_NE, extendImmCB(encode));
        break;
    default:
        EXECUTE_UNKNOWN(encode);
        break;
    }
}

inline void
TraceSimDriver::executeQ0(InstrEncode &encode)
{
    const int instr_len = 2;
    
    switch (encode.cfunc3) {
    case 0b000: // C.ADDI4SPN
        // addi rd', x2, nzuimm[9:2]
        EXECUTE_ALU(encode.crdrs2p + 8, readGPR(2), extendImmCADDI4SPN(encode), OP_ADD, false);
        break;
    case 0b010: // C.LW
        // lw rd', offset[6:2](rs1')
        EXECUTE_LD(encode.crdrs2p + 8, readGPR(encode.crdrs1p + 8), extendImmCLWSW(encode), true, 2);
        break;
    case 0b110: // C.SW
        // sw rs2',offset[6:2](rs1')
        EXECUTE_ST(readGPR(encode.crdrs2p + 8), readGPR(encode.crdrs1p + 8), extendImmCLWSW(encode), 2);
        break;
    default:
        EXECUTE_UNKNOWN(encode);
        break;
    }
}


/*
 * Fetch
 */
inline void
TraceSimDriver::fetch(uint32_t &instr, int &size, const bool double_fault)
{
    int fault = 0;
    uint64_t paddr = 0;
    bool trans_ok = translateVaddr(state.pc, false, false, true, paddr, fault,
                                   INSTR_PAGE_FAULT, INSTR_ACCESS_FAULT);
    if (!trans_ok) {
        panic_if(double_fault, "Double fault!\n");
        exceptEnter(fault, state.pc);
        fetch(instr, size, true);
        return;
    }
    
    int len = 2;
    uint32_t data = as->read_atomic(paddr, 2);
    if ((data & 0x3) == 0x3) {
        uint64_t paddr2 = paddr + 0x2;
        if ((paddr >> 12) != (paddr2 >> 12)) {
            bool trans2_ok = translateVaddr(state.pc + 0x2, false, false, true, paddr2, fault,
                                            INSTR_PAGE_FAULT, INSTR_ACCESS_FAULT);
            if (!trans2_ok) {
                panic_if(double_fault, "Double fault!\n");
                exceptEnter(fault, state.pc);
                fetch(instr, size, true);
                return;
            }
        }
        
        len += 2;
        data |= as->read_atomic(paddr2, 2) << 16;
    }
    
    instr = data;
    size = len;
}


/*
 * The simulation
 */
TraceSimDriver::TraceSimDriver(const char *name, ArgParser *cmd,
                           SimulatedMachine *mach)
    : SimDriver(name, cmd),
      mach(mach), as(mach->getPhysicalAddressSpace()),
      numInstrs(0), incomingInterrupts(0)
{
}

int
TraceSimDriver::startup()
{
    if (!openOutputFile("target/commit.txt", out)) {
        return -1;
    }
    
    return 0;
}

int
TraceSimDriver::cleanup()
{
    out.close();
    return 0;
}

int
TraceSimDriver::reset(uint64_t entry)
{
    numInstrs = 0;
    incomingInterrupts = 0;
    
    state.pc = entry;
    for (int i = 0; i < 32; i++) {
        state.gpr[i] = 0;
    }
    
    state.priv = PRIV_MACHINE;
    state.isa.value = 0;
    state.isa.c = 1; // compressed
    state.isa.e = 1; // embedded
    state.isa.g = 1; // general
    state.isa.n = 1; // user-level interrupts
    state.isa.m = 1; // mul/div
    state.isa.s = 1; // supervisor
    state.isa.u = 1; // user
    state.isa.mxl = 1; // 32-bit
    state.status.value = 0;
    state.inte.value = 0;
    state.intp.value = 0;
    state.inthw.value = 0;
    state.trans.value = 0;
    
    for (int i = 0; i < 32; i++) {
        state.perf[i] = 0;
    }
    
    return 0;
}

int
TraceSimDriver::cycle(uint64_t num_cycles)
{
    // Fetch
    int instr_len = 0;
    uint32_t instr = 0;
    fetch(instr, instr_len);
    
    LOG(std::cout
        << "[SIM] Cycle @ " << num_cycles
        << ", PC: " << std::hex << state.pc << std::dec
        << ", Instr: " << std::hex << instr << std::dec
        << ", (" << instr_len << "B)"
        << std::endl);
    
//    if (state.pc == 0xc00480d4) {
//        std::cerr << "sys_ni_syscall @ c00480d4"
//            << ", a7 = " << std::hex << readGPR(17) << std::dec
//            << std::endl;
//    } else if (state.pc == 0xc0025f20) {
//        std::cerr << "handle_syscall @ c0025f20"
//            << ", a7 = " << std::hex << readGPR(17) << std::dec
//            << std::endl;
//        
////        if (readGPR(17) == 0x62) {
////            mach->terminate(-1, 10000);
////        }
//    }
    
    // Execute
    InstrEncode encode = { .value = instr };
    
    if (encode.quad == 0x3) { // normal
        executeG(encode);
    } else { // compressed
        if (!state.isa.c) {
            EXECUTE_UNKNOWN(encode);
        } else {
            switch (encode.quad) {
            case 0: executeQ0(encode); break;
            case 1: executeQ1(encode); break;
            case 2: executeQ2(encode); break;
            default: EXECUTE_UNKNOWN(encode); break;
            }
        }
    }
    
    // Update counters
    state.perf[0]++;
    state.perf[1]++;
    state.perf[2]++;
    
    // Interrupt
    interrupt();
    
    numInstrs++;
    return 0;
}

