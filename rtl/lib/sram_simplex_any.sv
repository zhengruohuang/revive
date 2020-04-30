`ifndef __SRAM_SIMPLEX_ANY_SV__
`define __SRAM_SIMPLEX_ANY_SV__

`include "lib/value_match.sv"

// Eventually to be implemented using the XOR approach
// When reading from and writing at the same time, the old value resides on the output port
// Multiple ports writing to the same address is internally resolved and therefore allowed

module sram_simplex_any #(
    parameter PORTS = 2,
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter INIT_FILE = ""    // name/location of RAM initialization file if using one (leave blank if not)
) (
    input   [PORTS - 1:0]           i_e,
    input   [PORTS - 1:0]           i_w_e,
    input   [$clog2(DEPTH) - 1:0]   i_addr      [0:PORTS - 1],
    input   [WIDTH - 1:0]           i_w_data    [0:PORTS - 1],
    output  [WIDTH - 1:0]           o_r_data    [0:PORTS - 1],
    input   i_clk
);

    genvar i;
    
    // The actual data
    reg     [WIDTH - 1:0]   data    [0:DEPTH - 1];
    
    // Write
    wire    [$clog2(DEPTH) + 1:0]   ext_addr    [0:PORTS - 1];
    wire    [PORTS - 1:0]           dup_write;
    wire    [PORTS - 1:0]           w_e;
    
    generate
        for (i = 0; i < PORTS; i = i + 1) begin
            assign ext_addr = { i_e[i], i_w_e[i], ext_addr[i] };
        end
        
        for (i = 0; i < PORTS; i = i + 1) begin
            value_match_1vsN #(
                .WIDTH  ($clog2(DEPTH) + 1),
                .N      (PORTS)
            ) matcher (
                .i_value_1  ({ 2'b11, i_addr }),
                .i_value_n  (ext_addr[i]),
                .o_matched  (dup_write[i])
            )
        end
        
        for (i = 0; i < PORTS; i = i + 1) begin
            assign w_e = i_e[i] & i_w_e[i] & ~dup_write[i];
            
            always @ (posedge i_clk) begin
                if (w_e[i]) begin
                    data[i_addr[i]] <= i_w_data[i];
                end
            end
        end
    endgenerate
    
    // Read
    reg     [WIDTH - 1:0]   r_data  [0:PORTS - 1];
    
    generate
        for (i = 0; i < R_PORTS; i = i + 1) begin
            assign o_r_data[i] = r_data[i];
            
            always @ (posedge i_clk) begin
                if (i_r_e[i]) begin
                    r_data[i] <= data[i_addr[i]];
                end
            end
        end
    endgenerate

endmodule

`endif

