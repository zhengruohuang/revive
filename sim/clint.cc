#include <iostream>
#include <iomanip>
#include <fstream>
#include <cstdint>
#include <vector>
#include "sim.hh"
#include "as.hh"
#include "clint.hh"
#include "debug.hh"


CoreLocalInterruptor::CoreLocalInterruptor(const char *name, ArgParser *cmd,
                                           uint64_t start, uint64_t size)
    : AddressRange(name, cmd)
{
    setRange(start, size);
    mtime = 0;
}

CoreLocalInterruptor::~CoreLocalInterruptor()
{
}

int
CoreLocalInterruptor::startup()
{
    return 0;
}

int
CoreLocalInterruptor::cleanup()
{
    return 0;
}

uint64_t
CoreLocalInterruptor::read_atomic(uint64_t addr, int size)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic read addr @ ", addr);
    
    if (offset >= MTIME_START && offset < MTIME_LIMIT) {
        if (size == 4) {
            if (offset & 0x4ull) {
                return mtime >> 32;
            } else {
                return mtime & 0xffffffffull;
            }
        } else if (size == 8) {
            return mtime;
        } else {
            panic("Unsupported access size: ", size);
            return 0;
        }
    }
    
    else if (offset >= MTIMECMP_START && offset < MTIMECMP_LIMIT) {
        int idx = (offset - MTIMECMP_START) / 8;
        if (size == 4) {
            if (offset & 0x4ull) {
                return read_mtimecmp(idx, 2);
            } else {
                return read_mtimecmp(idx, 1);
            }
        } else if (size == 8) {
            return read_mtimecmp(idx, 3);
        } else {
            panic("Unsupported access size: ", size);
            return 0;
        }
    }
    
    else if (offset >= MSIP_START && offset < MSIP_LIMIT) {
        panic_if(size != 4, "Unsupported access size: ", size);
        int idx = (offset - MSIP_START) / 4;
        return read_msip(idx);
    }
    
    return 0;
}

void
CoreLocalInterruptor::write_atomic(uint64_t addr, int size, uint64_t data)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic write addr @ ", addr);
    
    if (offset >= MTIME_START && offset < MTIME_LIMIT) {
        if (size == 4) {
            if (offset & 0x4ull) {
                mtime = (mtime & ~0xffffffffull) | (data & 0xffffffffull);
            } else {
                mtime = (mtime & 0xffffffffull) | (data << 32);;
            }
        } else if (size == 8) {
            mtime = data;
        } else {
            panic("Unsupported access size: ", size);
        }
    }
    
    else if (offset >= MTIMECMP_START && offset < MTIMECMP_LIMIT) {
        int idx = (offset - MTIMECMP_START) / 8;
        if (size == 4) {
            if (offset & 0x4ull) {
                write_mtimecmp(idx, data, 2);
            } else {
                write_mtimecmp(idx, data, 1);
            }
        } else if (size == 8) {
            write_mtimecmp(idx, data, 2);
        } else {
            panic("Unsupported access size: ", size);
        }
    }
    
    else if (offset >= MSIP_START && offset < MSIP_LIMIT) {
        panic_if(size != 4, "Unsupported access size: ", size);
        int idx = (offset - MSIP_START) / 4;
        write_msip(idx, data);
    }
}

void
CoreLocalInterruptor::attachCore(SimDriver *core)
{
    slots.push_back(core);
}

int
CoreLocalInterruptor::cycle(uint64_t num_cycles)
{
    mtime++;
    
    for (auto &c: slots) {
        if (c.mtimecmp_enabled && c.mtimecmp == mtime) {
            fire_mtime(c.core);
        }
    }
    
    return 0;
}


/*
 * MSIP
 */
inline uint64_t
CoreLocalInterruptor::read_msip(int idx)
{
    if ((size_t)idx >= slots.size())
        return 0;
    
    return slots[idx].msip;
}

inline void
CoreLocalInterruptor::write_msip(int idx, uint32_t value)
{
    if ((size_t)idx >= slots.size())
        return;
    
    slots[idx].msip = value & 0x1;
}


/*
 * MTIMECMP
 */
inline uint64_t
CoreLocalInterruptor::read_mtimecmp(int idx, int pos)
{
    if ((size_t)idx >= slots.size())
        return 0;
    
    switch (pos) {
    case 1: return slots[idx].mtimecmp & 0xffffffffull;
    case 2: return slots[idx].mtimecmp >> 32;
    case 3: return slots[idx].mtimecmp;
    default: return 0;
    }
    
    return 0;
}

inline void
CoreLocalInterruptor::write_mtimecmp(int idx, uint64_t value, int pos)
{
    if ((size_t)idx >= slots.size())
        return;
    
    slots[idx].mtimecmp_enabled = true;
    switch (pos) {
    case 1: slots[idx].mtimecmp = (slots[idx].mtimecmp & ~0xffffffffull) | (value & 0xffffffffull); break;
    case 2: slots[idx].mtimecmp = (slots[idx].mtimecmp & 0xffffffffull) | (value << 32); break;
    case 3: slots[idx].mtimecmp = value; break;
    default: break;
    }
}

