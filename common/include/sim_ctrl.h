#ifndef __COMMON_SIM_CTRL_H__
#define __COMMON_SIM_CTRL_H__


#define SIM_PHYS_MEM_START  (0x0)
#define SIM_PHYS_MEM_SIZE   (0x8000000ul)


#define SIM_CLINT_START     (0xe0000000ul)
#define SIM_CLINT_SIZE      (0xc000ul)
#define SIM_CLINT_END       (0xe000c000ul)

#define SIM_PLIC_START      (0xe1000000ul)
#define SIM_PLIT_SIZE       (0x4000000ul)
#define SIM_PLIT_END        (0xe5000000ul)


#define SIM_UART0_START     (0xe5000000ul)
#define SIM_UART0_SIZE      (0x100ul)
#define SIM_UART0_END       (0xe5000100ul)

#define SIM_UART1_START     (0xe5000100ul)
#define SIM_UART1_SIZE      (0x100ul)
#define SIM_UART1_END       (0xe5000200ul)


#define SIM_CTRL_BASE       (0xf0000000ul)
#define SIM_CTRL_SIZE       (0x4000ul)

#define SIM_CTRL_ARGS       (SIM_CTRL_BASE + 0x0ul)
#define SIM_CTRL_CMD        (SIM_CTRL_BASE + 0x1000ul)
#define SIM_CTRL_PSEUDO_IN  (SIM_CTRL_BASE + 0x2000ul)
#define SIM_CTRL_PSEUDO_OUT (SIM_CTRL_BASE + 0x3000ul)

#define SIM_CTRL_PUTCHAR    (SIM_CTRL_CMD + 0x4ul)
#define SIM_CTRL_TERM       (SIM_CTRL_CMD + 0xcul)
#define SIM_CTRL_DUMP_BEGIN (SIM_CTRL_CMD + 0x10ul)
#define SIM_CTRL_DUMP_END   (SIM_CTRL_CMD + 0x14ul)
#define SIM_CTRL_DUMP_SAVE  (SIM_CTRL_CMD + 0x18ul)


#endif

