`ifndef __ROB_SVH__
`define __ROB_SVH__


`include "include/config.svh"


typedef logic [`ROB_SIZE_BITS - 1:0] rob_idx_t;


typedef struct packed {
    rob_idx_t   idx;
    logic       valid;
} rob_sel_t;


`endif

