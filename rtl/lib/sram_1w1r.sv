`ifndef __SRAM_1W1R_SV__
`define __SRAM_1W1R_SV__

// Derived from Xilinx Simple Dual Port Single Clock RAM
// When reading and writing to the same address, the old value resides on the output port

module sram_1w1r #(
    parameter WIDTH = 32,   // RAM data width
    parameter DEPTH = 8,    // RAM depth (number of entries)
    parameter INIT = ""     // name/location of RAM initialization file if using one (leave blank if not)
) (
    input                           i_w_e,      // Write enable
    input   [$clog2(DEPTH) - 1:0]   i_w_addr,
    input   [WIDTH - 1:0]           i_w_data,
    
    input                           i_r_e,      // Read Enable, for additional power savings, disable when not in use
    input   [$clog2(DEPTH) - 1:0]   i_r_addr,
    output  [WIDTH - 1:0]           o_r_data,
    
    input i_clk
);

// The RAM
reg [WIDTH - 1:0] block_ram [DEPTH - 1:0];

// Init the ram
generate
    if (INIT != "") begin
        initial begin
            $readmemh(INIT, block_ram, 0, DEPTH - 1);
        end
    end else begin
        integer i;
        initial begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                block_ram[i] = { WIDTH{1'b0} };
            end
        end
    end
endgenerate

// Read
reg [WIDTH - 1:0] ram_data = { WIDTH{1'b0} };
assign o_r_data = ram_data;

always @(posedge i_clk) begin
    if (i_r_e) begin
        ram_data <= block_ram[i_r_addr];
    end
end

// Write
always @(posedge i_clk) begin
    if (i_w_e) begin
        block_ram[i_w_addr] <= i_w_data;
    end
end

endmodule

`endif

