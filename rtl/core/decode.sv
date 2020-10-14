`include "include/config.svh"
`include "include/instr.svh"

`include "core/decode/decode.sv"

module decode (
    input                       i_flush,
    input                       i_stall,
    
    // From previous stage - IA
    input   aligned_instr_t     i_instr,
    
    // To next stage - Sched
    output  decoded_instr_t     o_instr,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Decoder
     */
    decode_t    decoded_fields;
    wire        invalid_decode;
    
    instr_field_decoder ifd (
        .i_instr    (i_instr),
        .i_half    (i_instr.half),
        .o_decode   (decoded_fields),
        .o_unknown  (invalid_decode)
    );
    
    /*
     * Next instr
     */
    decoded_instr_t next_instr;
    
    always_comb begin
        if (~i_instr.valid) begin
            next_instr = compose_decoded_instr(`INVALID_PC, `NOP_DECODE, `EXCEPT_NONE, 1'b0);
        end else if (i_instr.except.valid | invalid_decode) begin
            next_instr = compose_decoded_instr(i_instr.pc, `NOP_DECODE, i_instr.except, 1'b1);
        end else begin
            next_instr = compose_decoded_instr(i_instr.pc, decoded_fields, `EXCEPT_NONE, 1'b1);
        end
    end
    
    /*
     * Output
     */
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            o_instr <= '0;
        end
        
        else if (~i_stall) begin
            o_instr <= next_instr;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[ID ] Valid: %d, PC @ %h, Instr: %h, Decode: %h",
                          i_instr.valid, i_instr.pc, i_instr.instr, next_instr.decode);
            end
        end
    end

endmodule

