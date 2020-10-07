ENTRY(_start)

MEMORY
{
    sbi : ORIGIN = 0x8000, LENGTH = 0x800000
    vmlinux : ORIGIN = 0x1000000, LENGTH = 0x1000000
    initrd : ORIGIN = 0x2000000, LENGTH = 0x200000
}

SECTIONS
{
    . = 0x8000;
    __start = .;
    
    .text :
    {
        __text_start = .;
        *(.text.boot)
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        __text_end = .;
    } >sbi
    
    .data :
    {
        __data_start = .;
        *(.data)
        *(.data*)
        __data_end = .;
    } >sbi
    
    .bss :
    {
        __bss_start = .;
        *(.bss)
        *(.bss*)
        *(.*bss)
        *(.*bss*)
        *(COMMON)
        __bss_end = .;
    } >sbi
    
    .sdata :
    {
         *(.sdata)
         *(.sdata.*)
    } >sbi
    
    .scommon :
    {
        *(.scommon)
        *(.scommon.*)
    } >sbi
    
    .payload1 :
    {
        *(.payload.dtb)
    } >sbi
    
    .payload2 :
    {
        *(.payload.vmlinux)
    } >vmlinux
    
    .payload3 :
    {
        *(.payload.initrd)
    } >initrd
    
    __end = .;
}

