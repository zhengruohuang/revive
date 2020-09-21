#include <set>
#include "base.hh"


static std::set<SimObject *> objs;


SimObject::SimObject(const char *name, ArgParser *cmd)
    : name(name), cmd(cmd)
{
    objs.insert(this);
}


int startupAllObjects()
{
    int err_all = 0;
    
    for (auto &obj: objs) {
        int err = obj->startup();
        if (err) {
            err_all -= 1;
        }
    }
    
    return err_all;
}

int cleanupAllObjects()
{
    int err_all = 0;
    
    for (auto &obj: objs) {
        int err = obj->cleanup();
        if (err) {
            err_all -= 1;
        }
    }
    
    return err_all;
}

