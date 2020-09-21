#include "rtl.hh"

Vrevive *
newVerilatorRtlTop(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vrevive *top = new Vrevive;
    return top;
}

