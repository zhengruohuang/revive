#ifndef __CLINT_HH__
#define __CLINT_HH__


#include <vector>
#include "sim.hh"


class CoreLocalInterruptor: public AddressRange
{
private:
    const uint64_t MSIP_START = 0;
    const uint64_t MSIP_LIMIT = 0x4000ull;
    const uint64_t MTIMECMP_START = 0x4000;
    const uint64_t MTIMECMP_LIMIT = 0xbff8ull;
    const uint64_t MTIME_START = 0xbff8ull;
    const uint64_t MTIME_LIMIT = 0xc000ull;
    
    struct CoreTimer {
        SimDriver *core;
        
        bool mtimecmp_enabled;
        uint64_t mtimecmp;
        uint32_t msip;
        
        CoreTimer(SimDriver *c)
        {
            core = c;
            mtimecmp_enabled = false;
            mtimecmp = 0;
            msip = 0;
        }
    };
    
    std::vector<CoreTimer> slots;
    uint64_t mtime;
    
    uint64_t read_msip(int idx);
    void write_msip(int idx, uint32_t value);
    
    // pos = 1 - low, 2 - high, 3 - full
    uint64_t read_mtimecmp(int idx, int pos);
    void write_mtimecmp(int idx, uint64_t value, int pos);
    
    void fire_msip(SimDriver *core) { core->fire(SimDriver::INT_MACHINE_SOFTWARE); }
    void clear_msip(SimDriver *core) { core->clear(SimDriver::INT_MACHINE_SOFTWARE); }
    
    void fire_mtime(SimDriver *core) { core->fire(SimDriver::INT_MACHINE_TIMER); }
    void clear_mtime(SimDriver *core) { core->clear(SimDriver::INT_MACHINE_TIMER); }

public:
    CoreLocalInterruptor(const char *name, ArgParser *cmd, uint64_t start, uint64_t size);
    ~CoreLocalInterruptor();
    
    virtual int startup() override;
    virtual int cleanup() override;
    
    virtual uint64_t read_atomic(uint64_t addr, int size) override;
    virtual void write_atomic(uint64_t addr, int size, uint64_t data) override;
    
    void attachCore(SimDriver *core);
    int cycle(uint64_t num_cycles);
};


#endif

