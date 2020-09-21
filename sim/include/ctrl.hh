#ifndef __CTRL_HH__
#define __CTRL_HH__


#include <fstream>
#include <cstdint>
#include "as.hh"


class SimulationControl: public AddressRange
{
private:
    void *store;
    
    std::ofstream out;
    std::ofstream dump;
    
    static const int numPseudoIOEntries = 32;
    struct PseudoOutput
    {
        int size;
        uint64_t value;
    } pseudoOutputs[32];
    uint64_t pseudoInputs[32];
    
    uint64_t dumpDataStart;
    uint64_t dumpDataEnd;
    void dumpData();
    
    void displayPseudoOut();

public:
    SimulationControl(const char *name, ArgParser *cmd, uint64_t start, uint64_t size);
    ~SimulationControl();
    
    virtual int startup() override;
    virtual int cleanup() override;
    
    virtual uint64_t read_atomic(uint64_t addr, int size) override;
    virtual void write_atomic(uint64_t addr, int size, uint64_t data) override;
    
    void setPseudoIn(int idx, uint64_t value);
};


#endif

