#include <cstdint>
#include "as.hh"
#include "cmd.hh"

#include <verilated.h>
#include "Vrevive.h"
#include "Vrevive_revive.h"
#include "Vrevive_instr_cache.h"


class SimulatedMachine
{
private:
    Vrevive *top;
    PhysicalAddressSpace *as;
    uint64_t num_cycles;
    
    uint64_t max_cycles;

public:
    SimulatedMachine(ArgParser *cmd);
    ~SimulatedMachine();
    
    void advance();
    void run();
    
    void loadElf(const char *filename);
};

