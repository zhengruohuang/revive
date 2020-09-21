#ifndef __RTL_HH__
#define __RTL_HH__


#include <cstdint>
#include "sim.hh"

#include <verilated.h>
#include "Vrevive.h"
#include "Vrevive_revive.h"
#include "Vrevive_fetch.h"
#include "Vrevive_ldst_unit.h"


class RtlSimDriver: public SimDriver
{
private:
    Vrevive *top;
    
    SimulatedMachine *mach;
    PhysicalAddressSpace *as;
    
    void handleFetch();
    void handleLSU();
    
    void advance();

public:
    RtlSimDriver(const char *name, ArgParser *cmd, SimulatedMachine *mach);
    virtual ~RtlSimDriver() { }
    
    int startup() override;
    int cleanup() override;
    
    int reset(uint64_t entry);
    int cycle(uint64_t num_cycles);
};


extern Vrevive *newVerilatorRtlTop(int argc, char **argv);


#endif

