#include <cstdint>
#include <cinttypes>
#include <map>
#include "as.hh"
#include "debug.hh"


/*
 * Address Range
 */
void
AddressRange::read(uint64_t addr, uint64_t size, void *buf)
{
    uint8_t *buf8 = (uint8_t *)buf;
    for (uint64_t i = 0; i < size; i++, addr++) {
        uint64_t data = read_atomic(addr, 1);
        buf8[i] = (uint8_t)(data & 0xffull);
    }
}

void
AddressRange::write(uint64_t addr, uint64_t size, void *buf)
{
    uint8_t *buf8 = (uint8_t *)buf;
    for (uint64_t i = 0; i < size; i++, addr++) {
        uint64_t data = buf8[i];
        write_atomic(addr, 1, data);
    }
}

void
AddressRange::memset(uint64_t addr, int c, uint64_t size)
{
    uint64_t data = (uint64_t)(int64_t)c;
    for (uint64_t i = 0; i < size; i++, addr++) {
        write_atomic(addr, 1, data);
    }
}


/*
 * Address Space
 */
PhysicalAddressSpace::PhysicalAddressSpace(const char *name, ArgParser *cmd)
    : SimObject(name, cmd)
{
    limit = 0x1ull << 32;
}

PhysicalAddressSpace::~PhysicalAddressSpace()
{
    for (auto &pair: ranges) {
        delete pair.second;
    }
}

AddressRange *
PhysicalAddressSpace::find(uint64_t addr, int size)
{
    for (auto &pair: ranges) {
        AddressRange *r = pair.second;
        if (r->inRange(addr, size)) {
            return r;
        }
    }
    
    return nullptr;
}

uint64_t
PhysicalAddressSpace::read_atomic(uint64_t addr, int size)
{
    AddressRange *r = find(addr, size);
    panic_if(!r, "Unknown read region @ ", addr, ", size: ", size);
    return r->read_atomic(addr, size);
}

void
PhysicalAddressSpace::write_atomic(uint64_t addr, int size, uint64_t data)
{
    AddressRange *r = find(addr, size);
    panic_if(!r, "Unknown write region @ ", addr, ", size: ", size);
    r->write_atomic(addr, size, data);
}

void
PhysicalAddressSpace::read(uint64_t addr, uint64_t size, void *buf)
{
    AddressRange *r = find(addr, size);
    panic_if(!r, "Unknown read region @ ", addr, ", size: ", size);
    r->read(addr, size, buf);
}

void
PhysicalAddressSpace::write(uint64_t addr, uint64_t size, void *buf)
{
    AddressRange *r = find(addr, size);
    panic_if(!r, "Unknown write region @ ", addr, ", size: ", size);
    r->write(addr, size, buf);
}

void
PhysicalAddressSpace::memset(uint64_t addr, int c, uint64_t size)
{
    AddressRange *r = find(addr, size);
    panic_if(!r, "Unknown memset region @ ", addr, ", size: ", size);
    r->memset(addr, size, c);
}

void
PhysicalAddressSpace::addRange(AddressRange *r)
{
    for (auto &pair: ranges) {
        AddressRange *r0 = pair.second;
        panic_if(r->overlapRange(r0), "Range overlap!");
    }
    
    ranges[r->getStart()] = r;
}

