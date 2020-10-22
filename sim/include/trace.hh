#ifndef __TRACE_HH__
#define __TRACE_HH__


#include <cstdint>
#include <cstdio>
#include "sim.hh"
#include "decode.hh"


struct TraceMachineState
{
    uint32_t pc;
    uint32_t gpr[32];
    
    CSRisa isa;
    uint32_t vendorid;
    uint32_t marchid;
    uint32_t impid;
    uint32_t hartid;
    
    int priv;
    CSRstatus status;
    CSRint inte;
    CSRint intp;
    CSRint inthw;
    CSRatp trans;
    uint32_t scratch[4];
    uint32_t tvec[4];
    uint32_t epc[4];
    uint32_t cause[4];
    uint32_t tval[4];
    
    uint32_t pmpcfg[4];
    uint32_t pmpaddr[16];
    
    uint32_t countinhibit;
    uint32_t counteren[4];
    uint32_t hpmevent[32];
    uint64_t perf[32];
    
    uint32_t csr[4096];
};

struct InstrEncode;

class TraceSimDriver: public SimDriver
{
private:
    enum PrivilegeLevel {
        PRIV_USER,
        PRIV_SUPERVISOR,
        PRIV_HYPERVISOR,
        PRIV_MACHINE,
    };
    
    enum InterruptCode {
        USER_SOFTWARE,
        SUPERVISOR_SOFTWARE,
        HYPERVISOR_SOFTWARE,
        MACHINE_SOFTWARE,
        USER_TIMER,
        SUPERVISOR_TIMER,
        HYPERVISOR_TIMER,
        MACHINE_TIMER,
        USER_EXTERNAL,
        SUPERVISOR_EXTERNAL,
        HYPERVISOR_EXTERNAL,
        MACHINE_EXTERNAL,
    };
    
    enum ExceptCode {
        INSTR_ADDR_MISALIGN,
        INSTR_ACCESS_FAULT,
        INSTR_ILLEGAL,
        BREAKPOINT,
        LOAD_ADDR_MISALIGN,
        LOAD_ACCESS_FAULT,
        STORE_ADDR_MISALIGN,
        STORE_ACCESS_FAULT,
        ECALL_FROM_U,
        ECALL_FROM_S,
        ECALL_FROM_H,
        ECALL_FROM_M,
        INSTR_PAGE_FAULT,
        LOAD_PAGE_FAULT,
        RESERVED,
        STORE_PAGE_FAULT,
    };
    
    FILE *commitf;
    
    uint64_t numInstrs;
    uint32_t incomingInterrupts;
    TraceMachineState state;
    
    bool checkPaddr(uint64_t paddr, bool read, bool write, bool exec, int &fault, int access_fault);
    bool translateVaddr(uint64_t vaddr, bool read, bool write, bool exec, uint64_t &paddr, int &fault, int page_fault, int access_fault);
    
    bool readCSR(uint32_t csr, uint32_t &value);
    bool writeCSR(uint32_t csr, uint32_t value);
    
    uint32_t readGPR(int idx) { return idx ? state.gpr[idx] : 0; }
    void writeGPR(int idx, uint32_t value) { state.gpr[idx] = idx ? value : 0; }
    
    void trace(uint64_t pc, InstrEncode &encode,
               bool alter_pc, uint32_t next_pc,
               bool wb_valid, int wb_idx, uint32_t wb_data);
    
    void exceptEnter(uint32_t code, uint32_t tval);
    void trapReturn(int from_priv);
    void interrupt();
    
    bool executeG_LD(uint32_t addr, bool sign, int size, uint32_t &value, int &fault);
    bool executeG_ST(uint32_t addr, int size, uint32_t value, int &fault);
    void executeG(InstrEncode &encode);
    void executeQ2(InstrEncode &encode);
    void executeQ1(InstrEncode &encode);
    void executeQ0(InstrEncode &encode);
    
    void fetch(uint32_t &instr, int &size, const bool double_fault = false);

public:
    TraceSimDriver(const char *name, ArgParser *cmd, SimulatedMachine *mach);
    virtual ~TraceSimDriver() { }
    
    int startup() override;
    int cleanup() override;
    
    int reset(uint64_t entry);
    int cycle(uint64_t num_cycles);
    
    void fire(uint32_t type) { state.inthw.value |= type; }
    void clear(uint32_t type) { state.inthw.value &= ~type; }
    
    void set_mtime(uint64_t value) { state.perf[1] = value; }
};


#endif

