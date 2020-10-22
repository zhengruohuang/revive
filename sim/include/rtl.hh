#ifndef __RTL_HH__
#define __RTL_HH__


#include <cstdio>
#include <cstdint>
#include "sim.hh"

#include <verilated.h>
#include "Vrevive.h"
#include "Vrevive_revive.h"
#include "Vrevive_fetch.h"
#include "Vrevive_execute.h"
#include "Vrevive_ldst_unit.h"


class RtlSimDriver: public SimDriver
{
private:
    Vrevive *top;
    FILE *commitf;
    
    bool translateVaddr(uint64_t vaddr, bool read, bool write, bool exec,
                        bool trans, int priv, uint64_t base_ppn,
                        uint64_t &paddr);
    
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
    
    void fire(uint32_t type) {
        top->i_int_ext   = (type & (0x1 << 11)) ? 1 : 0;
        top->i_int_timer = (type & (0x1 <<  7)) ? 1 : 0;
        top->i_int_soft  = (type & (0x1 <<  3)) ? 1 : 0;
    }
    void clear(uint32_t type) {
        top->i_int_ext   = (type & (0x1 << 11)) ? 0 : 1;
        top->i_int_timer = (type & (0x1 <<  7)) ? 0 : 1;
        top->i_int_soft  = (type & (0x1 <<  3)) ? 0 : 1;
    }
    
    void set_mtime(uint64_t value) { top->i_mtime = value; }
};


extern Vrevive *newVerilatorRtlTop(int argc, char **argv);
extern int createVerilatorFileDescriptor(FILE *f);


#endif

