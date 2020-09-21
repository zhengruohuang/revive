#include <cstdint>
#include <map>
#include <sys/mman.h>
#include "mem.hh"
#include "debug.hh"


MainMemory::MainMemory(const char *name, ArgParser *cmd,
                       uint64_t start, uint64_t size)
    : AddressRange(name, cmd)
{
    setRange(start, size);
    store = mmap(0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
}

MainMemory::~MainMemory()
{
    munmap(store, getStart());
}

uint64_t
MainMemory::read_atomic(uint64_t addr, int size)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic read addr @ ", addr);
    
    void *store_addr = (char *)store + offset;
    switch (size) {
    case 1:
        return *(uint8_t *)store_addr;
    case 2:
        return *(uint16_t *)store_addr;
    case 4:
        return *(uint32_t *)store_addr;
    case 8:
        return *(uint64_t *)store_addr;
    default:
        panic("Unsupported access size: ", size);
        return 0;
    }
    
    return 0;
}

void
MainMemory::write_atomic(uint64_t addr, int size, uint64_t data)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic write addr @ ", addr);
    
    void *store_addr = (char *)store + offset;
    switch (size) {
    case 1:
        *(uint8_t *)store_addr = (uint8_t)data;
        break;
    case 2:
        *(uint16_t *)store_addr = (uint16_t)data;
        break;
    case 4:
        *(uint32_t *)store_addr = (uint32_t)data;
        break;
    case 8:
        *(uint64_t *)store_addr = (uint64_t)data;
        break;
    default:
        panic("Unsupported access size: ", size);
        break;
    }
}

