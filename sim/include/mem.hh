#ifndef __MEM_HH__
#define __MEM_HH__


#include <cstdint>
#include "as.hh"


class MainMemory: public AddressRange
{
private:
    void *store;

public:
    MainMemory(uint64_t start, uint64_t size);
    ~MainMemory();
    
    virtual uint64_t read(uint64_t addr, int size) override;
    virtual void write(uint64_t addr, int size, uint64_t data) override;
};


#endif

