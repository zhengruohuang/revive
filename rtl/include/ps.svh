`ifndef __PS_SVH__
`define __PS_SVH__


`include "include/config.svh"


typedef logic [`ASID_WIDTH - 1:0] asid_t;

typedef enum logic [1:0] {
    PRIV_MODE_USER,
    PRIV_MODE_SUPERVISOR,
    PRIV_MODE_HYPERVISOR,
    PRIV_MODE_MACHINE
} priv_mode_t;


/*
 * Program State
 */
typedef struct packed {
    priv_mode_t         priv;
    logic               isa_c;
    logic               trans;
    asid_t              asid;
    logic [21:0]        base;
} program_state_t;


`endif

