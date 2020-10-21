#include <iostream>
#include <iomanip>
#include <cstdint>
#include <cstring>
#include <map>
#include <sys/mman.h>
#include "sim.hh"
#include "ctrl.hh"
#include "debug.hh"


SimulationControl::SimulationControl(const char *name, ArgParser *cmd,
                                     uint64_t start, uint64_t size)
    : AddressRange(name, cmd), outf(nullptr), dumpf(nullptr)
{
    cmd->addString("simctrl_out", "", "--ctrl-out", "target/out.txt");
    cmd->addString("simctrl_dump", "", "--ctrl-dump", "target/dump.txt");
    
    setRange(start, size);
    store = mmap(0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    
    dumpDataStart = dumpDataEnd = 0;
    
    for (int i = 0; i < numPseudoIOEntries; i++) {
        pseudoInputs[i] = 0;
        pseudoOutputs[i].size = 0;
        pseudoOutputs[i].value = 0;
    }
    
    /*
     * Args:        [0,      0x1000)
     * Commands     [0x1000, 0x2000)
     * Pseudo In    [0x2000, 0x3000)
     * Pseudo Out   [0x3000, 0x4000)
     */
}

SimulationControl::~SimulationControl()
{
    munmap(store, size);
}

int
SimulationControl::startup()
{
    const char *out_filename = cmd->get("simctrl_out")->valueString;
    if (strcmp(out_filename, "none")) {
        outf = openOutputFile(out_filename);
        if (!outf) {
            return -1;
        }
    }
    
    const char *dump_filename = cmd->get("simctrl_dump")->valueString;
    if (strcmp(dump_filename, "none")) {
        dumpf = openOutputFile(dump_filename);
        if (!dumpf) {
            return -1;
        }
    }
    
    return 0;
}

int
SimulationControl::cleanup()
{
    displayPseudoOut();
    
    if (outf) {
        fclose(outf);
    }
    
    if (dumpf) {
        fclose(dumpf);
    }
    
    return 0;
}

uint64_t
SimulationControl::read_atomic(uint64_t addr, int size)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic read addr @ ", addr);
    
    switch (offset) {
    case 0x1000 + 0x0: // stdin
        return 0;
    default:
        break;
    }
    
    if (offset >= 0x2000 && offset < 0x2000 + sizeof(uint64_t) * numPseudoIOEntries) {
        int idx = (offset - 0x2000) / size;
        return pseudoInputs[idx];
    }
    
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
SimulationControl::write_atomic(uint64_t addr, int size, uint64_t data)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    
    switch (offset) {
    case 0x1000 + 0x4: // stdout
        if (outf) {
            fprintf(outf, "%c", (char)data);
            fflush(outf);
        }
        //out << (char)data << std::flush;
        return;
    case 0x1000 + 0x8: // stderr
        if (outf) {
            fprintf(outf, "%c", (char)data);
            fflush(outf);
        }
        //out << (char)data << std::flush;
        return;
    case 0x1000 + 0xc: // terminate
        getMachine()->terminate((uint32_t)data);
        return;
    case 0x1000 + 0x10: // dump data start
        dumpDataStart = data;
        return;
    case 0x1000 + 0x14: // dump data end
        dumpDataEnd = data;
        return;
    case 0x1000 + 0x18: // compliance data dump
        dumpData();
        return;
    default:
        break;
    }
    
    if (offset >= 0x2000 && offset < 0x2000 + sizeof(uint64_t) * numPseudoIOEntries) {
        int idx = (offset - 0x2000) / size;
        pseudoInputs[idx] = data;
    }
    
    if (offset >= 0x3000 && offset < 0x3000 + sizeof(uint64_t) * numPseudoIOEntries) {
        int idx = (offset - 0x3000) / size;
        pseudoOutputs[idx].size = size;
        pseudoOutputs[idx].value = data;
    }
    
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

void
SimulationControl::setPseudoIn(int idx, uint64_t value)
{
    if (idx < numPseudoIOEntries) {
        pseudoInputs[idx] = value;
    }
}

void
SimulationControl::displayPseudoOut()
{
    for (int i = 0; i < numPseudoIOEntries; i++) {
        if (pseudoOutputs[i].size) {
            std::cout << "[SIM] Pseudo out #" << i << ": "
                << std::hex << pseudoOutputs[i].value << std::dec
                << " (" << pseudoOutputs[i].value << ")"
                << ", size: " << pseudoOutputs[i].size
                << std::endl;
        }
    }
}

void
SimulationControl::dumpData()
{
    for (uint64_t addr = dumpDataStart; addr < dumpDataEnd; addr += 4) {
        SimulatedMachine *mach = getMachine();
        PhysicalAddressSpace *as = mach->getPhysicalAddressSpace();
        
        uint64_t word = as->read_atomic(addr, 4);
        if (dumpf) {
            fprintf(dumpf, "%08lx\n", word);
        }
        //dump << std::hex << std::setfill('0') << std::setw(8)
        //    << word << std::dec << std::endl;
    }
}

