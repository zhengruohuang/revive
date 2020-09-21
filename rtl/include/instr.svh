`ifndef __INSTR_SVH__
`define __INSTR_SVH__


`include "include/config.svh"
`include "include/pc.svh"
`include "include/ps.svh"
`include "include/reg.svh"
`include "include/decode.svh"


`define NOP_ENCODING 32'hbeefbeef


/*
 * Generic instruction
 */
typedef logic [`SHORT_INSTR_WIDTH - 1:0]    short_instr_t;
typedef logic [`INSTR_WIDTH - 1:0]          instr_t;


/*
 * Fetched instr
 */
typedef struct packed {
    program_counter_t   pc;
    //logic               aligned;
    short_instr_t       data0;
    short_instr_t       data1;
    except_t            except;
    logic               valid;
} fetched_data_t;

function fetched_data_t compose_fetched_data;
    input program_counter_t pc;
    input short_instr_t     data0;
    input short_instr_t     data1;
    input except_t          except;
    input logic             valid;
    begin
        compose_fetched_data = { pc, data0, data1, except, valid };
    end
endfunction


/*
 * Aligned instr
 */
typedef struct packed {
    program_counter_t   pc;
    instr_t             instr;
    except_t            except;
    logic               half;
    logic               valid;
} aligned_instr_t;

function aligned_instr_t compose_aligned_instr;
    input program_counter_t pc;
    input instr_t           instr;
    input except_t          except;
    input logic             half;
    input logic             valid;
    begin
        compose_aligned_instr = { pc, instr, except, half, valid };
    end
endfunction


/*
 * Decoded instr
 */
typedef struct packed {
    program_counter_t   pc;
    decode_t            decode;
    except_t            except;
    logic               valid;
} decoded_instr_t;

function decoded_instr_t compose_decoded_instr;
    input program_counter_t pc;
    input decode_t          decode;
    input except_t          except;
    input logic             valid;
    begin
        compose_decoded_instr = { pc, decode, except, valid };
    end
endfunction


/*
 * Issued instr
 */
typedef struct packed {
    program_counter_t   pc;
    decode_t            decode;
    except_t            except;
    logic               valid;
} issued_instr_t;

function issued_instr_t compose_issued_instr;
    input program_counter_t pc;
    input decode_t          decode;
    input except_t          except;
    input logic             valid;
    begin
        compose_issued_instr = { pc, decode, except, valid };
    end
endfunction


`endif

