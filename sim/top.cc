#include <cstdio>
#include "rtl.hh"

#define _VERILATED_CPP_
#include <verilated_imp.h>
#undef _VERILATED_CPP_

Vrevive *
newVerilatorRtlTop(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vrevive *top = new Vrevive;
    return top;
}

int
createVerilatorFileDescriptor(FILE *f)
{
    return (int)VerilatedImp::fdNew(f);
}

