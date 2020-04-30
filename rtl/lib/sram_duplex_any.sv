`ifndef __SRAM_DUPLEX_ANY_SV__
`define __SRAM_DUPLEX_ANY_SV__

// Eventually to be implemented using the XOR approach
// When reading from and writing to the same address, the old value resides on the output port
// Multiple ports writing to the same address is internally resolved and therefore allowed

module sram_duplex_any #(
    parameter W_PORTS = 2,
    parameter R_PORTS = 4,
    parameter WIDTH = 32,   // RAM data width
    parameter DEPTH = 8,    // RAM depth (number of entries)
    parameter INIT = ""     // name/location of RAM initialization file if using one (leave blank if not)
) (
    input   [W_PORTS - 1:0]         i_w_e,
    input   [$clog2(DEPTH) - 1:0]   i_w_addr    [0:W_PORTS - 1],
    input   [WIDTH - 1:0]           i_w_data    [0:W_PORTS - 1],
    
    input   [R_PORTS - 1:0]         i_r_e,
    input   [$clog2(DEPTH) - 1:0]   i_r_addr    [0:R_PORTS - 1],
    output  [WIDTH - 1:0]           o_r_data    [0:R_PORTS - 1],
    
    input i_clk
);

    genvar i;

    // The actual data
    reg     [WIDTH - 1:0]   data    [0:DEPTH - 1];

    // Write
    reg                     w_e     [0:W_PORTS - 1];

    generate
        for (i = 0; i < W_PORTS; i = i + 1) begin
            always_comb begin
                w_e[i] = i_w_e[i] & i_w_addr[i] != { $clog2(DEPTH){1'b0} };
                
                for (int j = 0; j < i; j = j + 1) begin
                    w_e[i] &= i_w_addr[j] != i_w_addr[i];
                end
            end
            
            always @ (posedge i_clk) begin
                if (w_e[i]) begin
                    data[i_w_addr[i]] <= i_w_data[i];
                end
            end
        end
    endgenerate

    // Read
    reg     [WIDTH - 1:0]   r_data  [0:R_PORTS - 1];

    generate
        for (i = 0; i < R_PORTS; i = i + 1) begin
            assign o_r_data[i] = r_data[i];
            
            always @ (posedge i_clk) begin
                if (i_r_e[i]) begin
                    r_data[i] <= data[i_r_addr[i]];
                end
            end
        end
    endgenerate
    


endmodule

`endif

