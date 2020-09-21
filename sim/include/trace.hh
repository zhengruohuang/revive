#ifndef __TRACE_HH__
#define __TRACE_HH__


#include <cstdint>
#include "sim.hh"


struct TraceMachineState
{
    uint32_t pc;
    uint32_t gpr[32];
};

struct InstrEncode;

class TraceSimDriver: public SimDriver
{
private:
    SimulatedMachine *mach;
    PhysicalAddressSpace *as;
    
    std::ofstream out;
    
    uint64_t numInstrs;
    TraceMachineState state;
    
    uint32_t readGPR(int idx) { return idx ? state.gpr[idx] : 0; }
    void writeGPR(int idx, uint32_t value) { state.gpr[idx] = idx ? value : 0; }
    
    void trace(uint64_t pc, InstrEncode &encode,
               bool alter_pc, uint32_t next_pc,
               bool wb_valid, int wb_idx, uint32_t wb_data);
    void except();
    
    uint32_t executeG_LD(uint32_t addr, bool sign, int size);
    void executeG_ST(uint32_t addr, int size, uint32_t value);
    void executeG(InstrEncode &encode);
    void executeQ2(InstrEncode &encode);
    void executeQ1(InstrEncode &encode);
    void executeQ0(InstrEncode &encode);

public:
    TraceSimDriver(const char *name, ArgParser *cmd, SimulatedMachine *mach);
    virtual ~TraceSimDriver() { }
    
    int startup() override;
    int cleanup() override;
    
    int reset(uint64_t entry);
    int cycle(uint64_t num_cycles);
};


#endif

