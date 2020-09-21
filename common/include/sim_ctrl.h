#ifndef __COMMON_SIM_CTRL_H__
#define __COMMON_SIM_CTRL_H__


#define SIM_PHYS_MEM_START  (0x0)
#define SIM_PHYS_MEM_SIZE   (0x8000000ul)


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

