#ifndef __AS_HH__
#define __AS_HH__


#include <cstdint>
#include <map>
#include "base.hh"


class AddressRange : public SimObject
{
protected:
    uint64_t start;
    uint64_t size;

public:
    AddressRange(const char *name, ArgParser *cmd)
        : SimObject(name, cmd) { start = 0; size = 0; }
    virtual ~AddressRange() { }
    
    void setRange(uint64_t start, uint64_t size)
    {
        this->start = start;
        this->size = size;
    }
    
    uint64_t getStart()
    {
        return start;
    }
    
    uint64_t getRange(uint64_t *size)
    {
        if (size) *size = this->size;
        return start;
    }
    
    bool inRange(uint64_t start, uint64_t size)
    {
        return start >= this->start &&
               size <= this->size &&
               start <= this->start + this->size - size;
    }
    
    bool overlapRange(uint64_t start, uint64_t size)
    {
        uint64_t end = start + size;
        uint64_t this_end = this->start + this->size;
        
        return (start >= this->start && start < this_end) ||
               (end > this->start && end <= this_end) ||
               (start < this->start && end > this_end);
    }
    
    bool overlapRange(AddressRange *other)
    {
        uint64_t size;
        uint64_t start = other->getRange(&size);
        return overlapRange(start, size);
    }
    
    // uint64_t data are assumed little-endian
    virtual uint64_t read_atomic(uint64_t addr, int size) = 0;
    virtual void write_atomic(uint64_t addr, int size, uint64_t data) = 0;
    
    virtual void read(uint64_t addr, uint64_t size, void *buf);
    virtual void write(uint64_t addr, uint64_t size, void *buf);
    virtual void memset(uint64_t addr, int c, uint64_t size);
};


class PhysicalAddressSpace : public SimObject
{
private:
    uint64_t limit;
    std::map<uint64_t, AddressRange *> ranges;
    AddressRange *find(uint64_t addr, int size);

public:
    PhysicalAddressSpace(const char *name, ArgParser *cmd);
    virtual ~PhysicalAddressSpace();
    
    // uint64_t data are assumed little-endian
    uint64_t read_atomic(uint64_t addr, int size);
    void write_atomic(uint64_t addr, int size, uint64_t data);
    
    void read(uint64_t addr, uint64_t size, void *buf);
    void write(uint64_t addr, uint64_t size, void *buf);
    void memset(uint64_t addr, int c, uint64_t size);
    
    void addRange(AddressRange *r);
};


#endif

