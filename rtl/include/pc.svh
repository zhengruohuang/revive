`ifndef __PC_SVH__
`define __PC_SVH__


`include "include/config.svh"


/*
 * Program Counter
 */
typedef logic [`VADDR_WIDTH - 1:0] program_counter_t;


function program_counter_t get_next_fetch_block_pc;
    input program_counter_t pc;
    begin
        get_next_fetch_block_pc = { pc[`VADDR_WIDTH - 1:3] + 29'h1, 3'b0 };
    end
endfunction


`endif

