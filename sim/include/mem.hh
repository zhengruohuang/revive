#ifndef __MEM_HH__
#define __MEM_HH__


#include <cstdint>
#include "as.hh"


class MainMemory: public AddressRange
{
private:
    void *store;

public:
    MainMemory(const char *name, ArgParser *cmd, uint64_t start, uint64_t size);
    ~MainMemory();
    
    virtual int startup() override { return 0; }
    virtual int cleanup() override { return 0; }
    
    virtual uint64_t read_atomic(uint64_t addr, int size) override;
    virtual void write_atomic(uint64_t addr, int size, uint64_t data) override;
};


#endif

