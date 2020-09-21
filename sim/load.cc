#include <iostream>
#include <fstream>
#include "as.hh"
#include "mem.hh"
#include "sim.hh"


#ifndef packed4_struct
#define packed4_struct      __attribute__((packed, aligned(4)))
#endif


#define ELF_EI_NIDENT   16
#define ELF_SHN_UNDEF   0

typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef int32_t  Elf32_Sword;
typedef uint32_t Elf32_Word;

struct Elf32Header {
    unsigned char   elf_ident[ELF_EI_NIDENT];
    Elf32_Half      elf_type;
    Elf32_Half      elf_machine;
    Elf32_Word      elf_version;
    Elf32_Addr      elf_entry;
    Elf32_Off       elf_phoff;
    Elf32_Off       elf_shoff;
    Elf32_Word      elf_flags;
    Elf32_Half      elf_ehsize;
    Elf32_Half      elf_phentsize;
    Elf32_Half      elf_phnum;
    Elf32_Half      elf_shentsize;
    Elf32_Half      elf_shnum;
    Elf32_Half      elf_shstrndx;
} packed4_struct;

struct Elf32Program {
    Elf32_Word      program_type;
    Elf32_Off       program_offset;
    Elf32_Addr      program_vaddr;
    Elf32_Addr      program_paddr;
    Elf32_Word      program_filesz;
    Elf32_Word      program_memsz;
    Elf32_Word      program_flags;
    Elf32_Word      program_align;
} packed4_struct;


void
SimulatedMachine::loadElf(const char *filename)
{
    // Read entire file
    std::ifstream ifs(filename, std::ios::binary | std::ios::ate);
    
    std::ifstream::pos_type pos = ifs.tellg();
    size_t file_len = pos;
    char *file_data = new char[file_len];
    
    ifs.seekg(0, std::ios::beg);
    ifs.read(file_data, file_len);
    ifs.close();
    
    // Parse ELF32
    Elf32Header *elf = (Elf32Header *)file_data;
    Elf32Program *prog = nullptr;
    
    for (int i = 0; i < elf->elf_phnum; i++) {
        if (i) {
            prog = (Elf32Program *)((unsigned long)prog + elf->elf_phentsize);
        } else {
            prog = (Elf32Program *)((unsigned long)elf + elf->elf_phoff);
        }
        
        uint64_t target = prog->program_vaddr;
        if (prog->program_memsz) {
            as->memset(target, 0, prog->program_memsz);
        }
        
        // Copy program data
        if (prog->program_filesz) {
            as->write(target, prog->program_filesz, (void *)((unsigned long)elf + prog->program_offset));
        }
    }
    
    delete file_data;
}

