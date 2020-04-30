`ifndef __SRAM_1W1R_WF_SV__
`define __SRAM_1W1R_WF_SV__

// When reading and writing to the same address, the new data being written to resides on the output port

module sram_1w1r_wf #(
    parameter WIDTH = 32,   // RAM data width
    parameter DEPTH = 8,    // RAM depth (number of entries)
    parameter INIT = ""     // name/location of RAM initialization file if using one (leave blank if not)
) (
    input                               i_w_e,      // Write enable
    input   [$clog2(DEPTH) -1:0]   i_w_addr,
    input   [WIDTH - 1:0]               i_w_data,
    
    input                           i_r_e,      // Read Enable, for additional power savings, disable when not in use
    input   [$clog2(DEPTH) - 1:0]   i_r_addr,
    output  [WIDTH - 1:0]           o_r_data,
    
    input   i_clk
);

// A simple non-confict SRAM
wire [WIDTH - 1:0] simple_data;

sram_1w1r #(
    .WIDTH      (WIDTH),
    .DEPTH      (DEPTH),
    .INIT       (INIT)
) simple_sram (
    .i_w_e      (i_w_e),
    .i_w_addr   (i_w_addr),
    .i_w_data   (i_w_data),
    .i_r_e      (i_r_e),
    .i_r_addr   (i_r_addr),
    .o_r_data   (simple_data),
    .i_clk      (i_clk)
);

// Handle the confict
reg [WIDTH - 1:0] saved_data;
assign o_r_data = { i_w_e, i_w_addr } == { i_r_e, i_r_addr } ? saved_data : simple_data;

always @ (posedge i_clk) begin
    if (i_w_e) begin
        saved_data <= i_w_data;
    end
end

endmodule

`endif

