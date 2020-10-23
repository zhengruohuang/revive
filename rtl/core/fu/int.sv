`include "include/config.svh"
`include "include/instr.svh"

module interrupt_unit (
    input   [31:0] i_log_fd,
    
    //input                           i_e,
    input                           i_stall,
    input                           i_valid,
    input   [11:0]                  i_intp,
    input   [11:0]                  i_inte,
    input   [11:0]                  i_mideleg,
    input   program_state_t         i_ps,
    
    output                          o_valid,
    output  reg_data_t              o_data
);

    wire            i_e         = ~i_stall & i_valid;

    wire    [11:0]  int_mask    = i_intp & i_inte;
    wire    [11:0]  int_mask_m  = int_mask & 12'b100010001000;
    wire    [11:0]  int_mask_s  = int_mask & 12'b001000100010;
    
    wire    [11:0]  dest_m      = int_mask_m & ~i_mideleg;
    wire    [11:0]  dest_s      = int_mask_s | (int_mask_m & i_mideleg);
    
    wire            handle_m    = dest_m != 12'b0 & (i_ps.mie | i_ps.priv != PRIV_MODE_MACHINE);
    wire            handle_s    = dest_s != 12'b0 & (i_ps.sie & i_ps.priv != PRIV_MODE_MACHINE) & ~handle_m;
    
    logic   [3:0]   int_code;
    
    always_comb begin
        if (~i_e) begin
            int_code = '0;
        end
        
        // MEI/MSI/MTI
        else if ((handle_m & dest_m[11]) | (handle_s & dest_s[11])) begin
            int_code = 4'd11;
        end else if ((handle_m & dest_m[3]) | (handle_s & dest_s[3])) begin
            int_code = 4'd3;
        end else if ((handle_m & dest_m[7]) | (handle_s & dest_s[7])) begin
            int_code = 4'd7;
        end
        
        // SEI/SSI/STI
        else if (handle_s & dest_s[9]) begin
            int_code = 4'd9;
        end else if (handle_s & dest_s[1]) begin
            int_code = 4'd1;
        end else if (handle_s & dest_s[5]) begin
            int_code = 4'd5;
        end
        
        // Other
        else begin
            int_code = 4'd15;
        end
    end
    
    assign  o_valid = i_e & (handle_m | handle_s) & int_code != 4'd15;
    assign  o_data = {
                handle_m ? 2'b11 : handle_s ? 2'b01 : 2'b00,
                26'b0,
                int_code
            };

endmodule

