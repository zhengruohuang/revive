#ifndef __SIM_HH__
#define __SIM_HH__


#include <cstdint>
#include "base.hh"
#include "as.hh"
#include "cmd.hh"
#include "mem.hh"
#include "ctrl.hh"


class SimDriver : public SimObject
{
public:
    SimDriver(const char *name, ArgParser *cmd) : SimObject(name, cmd) { }
    virtual ~SimDriver() { }
    
    virtual int reset(uint64_t entry) = 0;
    virtual int cycle(uint64_t num_cycles) = 0;
};


class SimulatedMachine : public SimObject
{
private:
    SimDriver *driver;
    uint64_t entry;
    
    bool term;
    int termCode;
    
    PhysicalAddressSpace *as;
    MainMemory *mainMemory;
    SimulationControl *simCtrl;
    
    uint64_t numCycles;
    uint64_t maxCycles;

public:
    SimulatedMachine(const char *name, ArgParser *cmd);
    ~SimulatedMachine();
    
    PhysicalAddressSpace *getPhysicalAddressSpace() { return as; }
    
    bool loadElf(const char *filename);
    void printConfig();
    
    void run();
    void terminate(int code);
};


extern ArgParser *getArgParser();
extern SimulatedMachine *getMachine();


extern bool openInputFile(const char *name, std::ifstream &fs);
extern bool openOutputFile(const char *name, std::ofstream &fs);


#endif

