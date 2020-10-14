`include "config.sv"
`include "types.sv"

module sys_unit (
    input                               i_enabled,
    decoded_alu_op_t                    i_op,
    
    input   [`DATA_WIDTH - 1:0]         i_src1,
    input   [`DATA_WIDTH - 1:0]         i_src2,
    
    output  [`DATA_WIDTH - 1:0]         o_dest,
    
    input   [31:0] i_log_fd,
    
    input   i_clk,
    input   i_rst_n
);

    reg [`DATA_WIDTH - 1:0] dest;
    assign o_dest = dest;
    
    always @ (posedge i_clk) begin
        if (~i_rst_n) begin
            dest <= '0;
        end
        
        else if (i_enabled) begin
            dest <= '0;
        end
    end

endmodule

