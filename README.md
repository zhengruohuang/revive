# Revive32-1000

An in-order superpipelined single-issue Linux-capable RISC-V core.

## Core version

Revive/Revolve | 32/64 | 1 | 00 | 0

Revive - Inorder, Revolve - OoO

32/64 - Data width

1 - Narrowest pipeline width

00 - Major micro-architecture revision

0 - Minor micro-architecture/Feature revision

## ISA

RV32I - 2.1

RV32M - 2.0

RV32C - 2.0

RV32A - 2.1 (WIP)

RV32Zifencei - 2.0 (WIP)

RV32Zicsr - 2.0 (WIP)

RVWMO - 2.0 (WIP)

Machine - 1.11 (WIP)

Supervisor - 1.11 (WIP)

## Pipeline

Fetch 1 - ITLB and ICache Tag

Fetch 2 - Match

Fetch 3 - ICache Data

Align - Decompress and concatenate

Decode

Sched - Register scoreboard

RegFetch

Execute - ALU/MUL/DIV/AGU

LSU

Writeback

## Directories

rtl - The SystemVerilog core source

sim - C++- RTL and functional simulator

tests - RISC-V tests

common - Utilities and headers shared by sim and tests

## Plan

01 - (Active) Working pipeline with simulated arbitrary latency memory, user only

02 - (Planned) Caches

03 - (Planned) Machine, supervisor and user privilege levels

04 - (Planned) Virtual memory

05 - (Planned) FPGA and boot Linux

06 - (Planned) ROB thus OoO ALU and MUL/DIV completion and in-order commit

07 - (Planned) Lock-up free data caches and thus OoO memory instruction completion

08 - (Planned) Forwarding network

09 - (Planned) Dynamic branch predictor

10 - (Planned) Release (Revive32-1100)

11 - (Planned) Branch predictor-directed ICache prefetch

12 - (Planned) DCache prefetch
