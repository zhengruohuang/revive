#ifndef __SIM_HH__
#define __SIM_HH__


#include <cstdint>
#include <cstdio>
#include <cstdarg>
#include "base.hh"
#include "cmd.hh"


//extern int logLevel;
#define LOG(any) if (0) { (any); } else do { } while (0)



class SimDriver;
class PhysicalAddressSpace;
class MainMemory;
class SimulationControl;
class CoreLocalInterruptor;
class UniAsyncRxTx;

class SimulatedMachine : public SimObject
{
private:
    SimDriver *driver;
    uint64_t entry;
    
    bool term;
    int termCode;
    uint64_t termCycle;
    
    PhysicalAddressSpace *as;
    MainMemory *mainMemory;
    SimulationControl *simCtrl;
    CoreLocalInterruptor *clint;
    UniAsyncRxTx *uart0;
    
    uint64_t numCycles;
    uint64_t maxCycles;

public:
    SimulatedMachine(const char *name, ArgParser *cmd);
    ~SimulatedMachine();
    
    PhysicalAddressSpace *getPhysicalAddressSpace() { return as; }
    
    bool loadElf(const char *filename);
    void printConfig();
    
    void run();
    void terminate(int code, uint64_t delay = 0);
};

class SimDriver : public SimObject
{
protected:
    SimulatedMachine *mach;
    PhysicalAddressSpace *as;
    
public:
    enum InterruptType {
        INT_USER_SOFTWARE = 0x1,
        INT_SUPERVISOR_SOFTWARE = 0x2,
        INT_HYPERVISOR_SOFTWARE = 0x4,
        INT_MACHINE_SOFTWARE = 0x8,
        INT_USER_TIMER = 0x10,
        INT_SUPERVISOR_TIMER = 0x20,
        INT_HYPERVISOR_TIMER = 0x40,
        INT_MACHINE_TIMER = 0x80,
        INT_USER_EXTERNAL = 0x100,
        INT_SUPERVISOR_EXTERNAL = 0x200,
        INT_HYPERVISOR_EXTERNAL = 0x400,
        INT_MACHINE_EXTERNAL = 0x800,
    };
    
    SimDriver(const char *name, ArgParser *cmd,
              SimulatedMachine *mach)
        : SimObject(name, cmd),
          mach(mach), as(mach->getPhysicalAddressSpace()) { }
    virtual ~SimDriver() { }
    
    virtual int reset(uint64_t entry) = 0;
    virtual int cycle(uint64_t num_cycles) = 0;
    
    virtual void fire(uint32_t type) = 0;
    virtual void clear(uint32_t type) = 0;
    
    virtual void set_mtime(uint64_t value) = 0;
};


extern ArgParser *getArgParser();
extern SimulatedMachine *getMachine();

extern bool openInputFile(const char *name, std::ifstream &fs);
extern bool openOutputFile(const char *name, std::ofstream &fs);

extern FILE *openInputFile(const char *name, const char *mode = "r");
extern FILE *openOutputFile(const char *name, const char *mode = "w");

extern FILE *logFile;
extern int logLevel;

static inline void log_printf(int level, const char *fmt, ...)
{
    if (!logFile || !logLevel || level > logLevel) {
        return;
    }
    
    va_list args;
    va_start(args, fmt);
    vfprintf(logFile, fmt, args);
    va_end(args);
}

static inline void log_printf(const char *fmt, ...)
{
    if (!logFile || !logLevel) {
        return;
    }
    
    va_list args;
    va_start(args, fmt);
    vfprintf(logFile, fmt, args);
    va_end(args);
}


#endif

