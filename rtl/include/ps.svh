`ifndef __PS_SVH__
`define __PS_SVH__


`include "include/config.svh"


typedef logic [`ASID_WIDTH - 1:0] asid_t;

typedef enum logic [2:0] {
    PRIV_MODE_MACHINE,
    PRIV_MODE_HYPERVISOR,
    PRIV_MODE_SUPERVISOR,
    PRIV_MODE_USER
} priv_mode_t;


/*
 * Program State
 */
typedef struct packed {
    asid_t              asid;
    priv_mode_t         mode;
    logic               mmu_enabled;
} program_state_t;


`endif

