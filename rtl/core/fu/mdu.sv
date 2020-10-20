`include "include/config.svh"
`include "include/instr.svh"

module mul_div_unit (
    input                           i_flush,
    input                           i_stall,
    
    input                           i_e,
    input   decode_alu_op_t         i_op,
    input                           i_w32,
    
    input   reg_data_t              i_src1,
    input   reg_data_t              i_src2,
    
    output  logic                   o_valid,
    output  reg_data_t              o_dest,
    
    input   [31:0] i_log_fd,
    
    input   i_clk,
    input   i_rst_n
);

    /*
     * Decode
     */
    wire    mul = i_op == OP_MDU_MUL;
    wire    muh = i_op == OP_MDU_MUL_HIGH | i_op == OP_MDU_MULU_HIGH | i_op == OP_MDU_MULSU_HIGH;
    wire    div = i_op == OP_MDU_DIV | i_op == OP_MDU_DIVU;
    wire    rem = i_op == OP_MDU_REM | i_op == OP_MDU_REMU;
    wire    neg = (i_op == OP_MDU_MUL_HIGH & i_src1[31] != i_src2[31]) | (i_op == OP_MDU_MULSU_HIGH & i_src1[31]) |
                  (i_op == OP_MDU_DIV & i_src1[31] != i_src2[31]) |
                  (i_op == OP_MDU_REM & i_src1[31] != i_src2[31]);
    
    wire    reg_data_t  src1 = ((i_op == OP_MDU_MUL_HIGH | i_op == OP_MDU_MULSU_HIGH |
                                 i_op == OP_MDU_DIV | i_op == OP_MDU_REM) & i_src1[31]) ? (~i_src1 + 32'b1) : i_src1;
    wire    reg_data_t  src2 = ((i_op == OP_MDU_MUL_HIGH |
                                 i_op == OP_MDU_DIV | i_op == OP_MDU_REM) & i_src2[31]) ? (~i_src2 + 32'b1) : i_src2;
    
    /*
     * States
     */
    logic           busy;
    logic           calc;
    
    logic   [63:0]  multiplicant;
    reg_data_t      multiplier;
    logic   [63:0]  product;
    wire    [63:0]  product_neg = calc & muh & neg ? ~product + 64'b1 : '0;
    
    reg_data_t      divident; // also remainder
    wire    [63:0]  divident64 = { 32'b0, divident };
    logic   [63:0]  divisor;
    reg_data_t      quotient;
    logic   [5:0]   step;
    
    logic           valid;
    reg_data_t      dest;
    
    /*
     * State control
     */
    always_ff @ (posedge i_clk) begin
        // Reset or terminate
        if (~i_rst_n | i_flush) begin
            busy <= '0;
            calc <= '0;
            valid <= '0;
            dest <= '0;
            o_valid <= '0;
            o_dest <= '0;
        end
        
        // Terminate?
        else if (~i_e & busy) begin
            // TODO: error
        end
        
        // Output
        else if (~i_stall & valid) begin
            busy <= '0;
            valid <= '0;
            dest <= '0;
            o_valid <= 1'b1;
            o_dest <= dest;
        end
        
        // Done
        else if (~i_stall & o_valid) begin
            o_valid <= '0;
            o_dest <= '0;
        end
        
        // New job
        else if (i_e & ~busy) begin
            busy <= 1'b1;
            if (muh | mul) begin
                if ((i_src1 | i_src1) == '0) begin
                    valid <= 1'b1;
                    dest <= '0;
                end else begin
                    calc <= 1'b1;
                    multiplicant <= {32'b0, src1 };
                    multiplier <= src2;
                    product <= '0;
                end
            end else if (div | rem) begin
                if (src2 == 0) begin
                    valid <= 1'b1;
                    dest <= div ? 32'hffffffff : i_src1;
                end else begin
                    calc <= 1'b1;
                    divident <= src1;
                    divisor <= { 1'b0, src2, 31'b0 };
                    quotient <= '0;
                    step <= 6'b0;
                end
            end
            
            //$display("[MDU] New job, src1: %h, src2: %h", src1, src2);
        end
        
        // Mul
        else if (calc & (muh | mul)) begin
            if (multiplicant == '0 | multiplier == '0) begin
                calc <= '0;
                valid <= 1'b1;
                dest <= neg ? product_neg[63:32] :
                        muh ? product[63:32] : product[31:0];
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[MUL] Done, multiplicant: %h, multiplier: %h, product: %h, dest: %h\n",
                              multiplicant, multiplier, product, dest);
                end
            end else begin
                product <= (multiplicant & {64{multiplier[0]}}) + product;
                multiplicant <= { multiplicant[62:0], 1'b0 }; // multiplicant <<= 1
                multiplier <= { 1'b0, multiplier[31:1] }; // multiplier >>= 1
            end
        end
        
        // Div
        else if (calc & (div | rem)) begin
            if (step == 6'd32) begin
                calc <= '0;
                valid <= 1'b1;
                if (div) begin
                    if (neg) begin
                        dest <= ~quotient + 32'b1;
                    end else begin
                        dest <= quotient;
                    end
                end else if (rem) begin
                    if (i_op == OP_MDU_REM & i_src1[31]) begin
                        dest <= ~divident + 32'b1;
                    end else begin
                        dest <= divident;
                    end
                end
                
                if (i_log_fd != '0) begin
                    $fdisplay(i_log_fd, "[DIV] Done, divident64: %h, divisor: %h, quotient: %h, step: %d\n",
                              divident64, divisor[31:0], quotient, step);
                end
            end
            
            else begin
                if (divisor <= divident64) begin
                    divident <= divident - divisor[31:0];
                    quotient <= { quotient[30:0], 1'b1 };
                end else begin
                    quotient <= { quotient[30:0], 1'b0 };
                end
                divisor <= { 1'b0, divisor[63:1] };
                step <= step + 6'b1;
                
                //$display("[DIV] divident64: %h, divisor: %h, quotient: %h, step: %d\n",
                //        divident64, divisor[31:0], quotient, step);
            end
        end
    end

endmodule

