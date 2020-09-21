`ifndef __INSTR_SVH__
`define __INSTR_SVH__


`include "include/config.svh"
`include "include/pc.svh"
`include "include/rob.svh"
`include "include/decode.svh"


`define NOP_ENCODING 32'hbeefbeef

typedef logic [`FETCH_DATA_WIDTH - 1:0]     fetch_data_t;

typedef logic [`SHORT_INSTR_WIDTH - 1:0]    short_instr_t;
typedef logic [`INSTR_WIDTH - 1:0]          instr_t;


typedef struct packed {
    program_counter_t   pc;
    instr_t             instr;
    except_t            except;
    logic               valid;
} aligned_instr_t;

function aligned_instr_t compose_aligned_instr;
    input program_counter_t pc;
    input instr_t           instr;
    input except_t          except;
    input logic             valid;
    begin
        compose_aligned_instr = { pc, instr, except, valid };
    end
endfunction


typedef struct packed {
    program_counter_t   pc;
    decode_t            decode;
    except_t            except;
    logic               valid;
} decoded_instr_t;


typedef struct packed {
    program_counter_t   pc;
    decode_t            decode;
    except_t            except;
    logic               valid;
} issued_instr_t;

function issued_instr_t compose_issued_instr;
    input decoded_instr_t   instr;
    input rob_idx_t         rob_idx;
    input logic             valid;
    begin
        compose_issued_instr = '0;
    end
endfunction


`endif

