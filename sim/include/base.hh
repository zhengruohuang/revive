#ifndef __BASE_HH__
#define __BASE_HH__


class ArgParser;

class SimObject
{
protected:
    const char *name;
    ArgParser *cmd;

public:
    SimObject(const char *name, ArgParser *cmd);
    virtual ~SimObject() { }
    
    const char *getName() { return name; }
    
    virtual int startup() { return 0; }
    virtual int cleanup() { return 0; }
};


extern int startupAllObjects();
extern int cleanupAllObjects();


#endif

