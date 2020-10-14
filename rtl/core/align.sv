`include "include/config.svh"
`include "include/instr.svh"

`include "core/decode/decompress.sv"

module align (
    input                       i_flush,
    input                       i_stall,
    
    // From and to previous stage - IF
    input   fetched_data_t      i_data,
    output                      o_stall,
    
    // To next stage - ID
    output  aligned_instr_t     o_instr,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    /*
     * Second half instr
     * Third and forth halves are in i_data
     */
    logic               second_half_valid;
    short_instr_t       second_half_instr;
    program_counter_t   second_half_pc;
    except_t            second_half_except;
    
    wire    second_half_is_short = second_half_valid & second_half_instr[1:0] != 2'b11;
    wire    second_half_is_long = second_half_valid & second_half_instr[1:0] == 2'b11;
    wire    second_half_combine = second_half_is_long & i_data.valid;
    
    wire    third_half_is_short = ~second_half_valid & i_data.valid & ~i_data.pc[1] & i_data.data0[1:0] != 2'b11;
    wire    third_half_is_long  = ~second_half_valid & i_data.valid & ~i_data.pc[1] & i_data.data0[1:0] == 2'b11;
    wire    forth_half_is_short = ~second_half_valid & i_data.valid &  i_data.pc[1] & i_data.data1[1:0] != 2'b11;
    wire    forth_half_is_long  = ~second_half_valid & i_data.valid &  i_data.pc[1] & i_data.data1[1:0] == 2'b11;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            second_half_valid <= 1'b0;
            second_half_instr <= '0;
            second_half_pc <= '0;
            second_half_except <= '0;
        end
        
        else if (~i_stall) begin
            if (second_half_is_short | ~i_data.valid | third_half_is_long | forth_half_is_short) begin
                second_half_valid <= 1'b0;
                second_half_instr <= '0;
                second_half_pc <= '0;
                second_half_except <= '0;
            end
            
            else if (second_half_combine | third_half_is_short | forth_half_is_long) begin
                second_half_valid <= 1'b1;
                second_half_instr <= i_data.data1;
                second_half_pc <= { { i_data.pc[31:2], 2'b0 } + 32'h2 };
                second_half_except <= i_data.except;
            end
            
            else begin
                $display("Unknown align condition for saving second half, second half valid: %d, third_half_is_short: %d, third_half_is_long: %d",
                         second_half_valid, third_half_is_short, third_half_is_long);
                $finish;
            end
        end
    end
    
    /*
     * Decompress
     */
    wire                    need_decomp = second_half_is_short | third_half_is_short | forth_half_is_short;
    wire    short_instr_t   before_decomp_instr = second_half_is_short  ? second_half_instr :
                                                  third_half_is_short   ? i_data.data0      :
                                                  forth_half_is_short   ? i_data.data1      :
                                                  '0;
    wire    instr_t         after_decomp_instr;
    wire                    unknown_instr;
    
    instr_decompressor idc (
        .i_instr    (before_decomp_instr),
        .o_instr    (after_decomp_instr),
        .o_unknown  (unknown_instr)
    );
    
    /*
     * Next instr
     */
    short_instr_t   next_instr_encode_short;
    instr_t         next_instr_encode;
    aligned_instr_t next_instr;
    
    always_comb begin
        if (~i_data.valid & ~second_half_valid) begin
            next_instr = compose_aligned_instr('0, `NOP_ENCODING, `EXCEPT_NONE, 1'b0, 1'b0);
            next_instr_encode = `NOP_ENCODING;
            next_instr_encode_short = '0;
        end
        
        else if (second_half_is_short) begin
            next_instr = compose_aligned_instr(second_half_pc, after_decomp_instr, second_half_except, 1'b1, 1'b1);
            next_instr_encode = after_decomp_instr;
            next_instr_encode_short = before_decomp_instr;
        end
        
        else if (second_half_combine) begin
            next_instr = compose_aligned_instr(second_half_pc, { i_data.data0, second_half_instr },
                            second_half_except.valid ? second_half_except : i_data.except, 1'b0, 1'b1);
            next_instr_encode = { i_data.data0, second_half_instr };
            next_instr_encode_short = '0;
        end
        
        else if (third_half_is_short) begin
            next_instr = compose_aligned_instr(i_data.pc, after_decomp_instr, i_data.except, 1'b1, 1'b1);
            next_instr_encode = after_decomp_instr;
            next_instr_encode_short = before_decomp_instr;
        end
        
        else if (third_half_is_long) begin
            next_instr = compose_aligned_instr(i_data.pc, { i_data.data1, i_data.data0 }, i_data.except, 1'b0, 1'b1);
            next_instr_encode = { i_data.data0, i_data.data1 };
            next_instr_encode_short = '0;
        end
        
        else if (forth_half_is_short) begin
            next_instr = compose_aligned_instr(i_data.pc, after_decomp_instr, i_data.except, 1'b1, 1'b1);
            next_instr_encode = after_decomp_instr;
            next_instr_encode_short = before_decomp_instr;
        end
        
        else begin
            if (~forth_half_is_long) begin
                $display("Unknown align condition for next instr!");
                $finish;
            end
            next_instr = compose_aligned_instr('0, `NOP_ENCODING, `EXCEPT_NONE, 1'b0, 1'b0);
            next_instr_encode = `NOP_ENCODING;
            next_instr_encode_short = '0;
        end
    end
    
    /*
     * Output
     */
    assign  o_stall = i_stall | second_half_is_short;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            o_instr <= '0;
        end
        
        else if (~i_stall) begin
            o_instr <= next_instr;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[IA ] Valid: %d PC @ %h, InValid: %d, InPC @ %h, Instr: %h, Short: %h",
                          next_instr.valid, next_instr.pc, i_data.valid, i_data.pc, next_instr_encode, next_instr_encode_short);
            end
        end
    end

endmodule

