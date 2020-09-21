`ifndef __SRAM_1W2R_WF_SV__
`define __SRAM_1W2R_WF_SV__

// When reading and writing to the same address, the new data being written to resides on the output port

module sram_1w2r_wf #(
    parameter WIDTH = 32,   // RAM data width
    parameter DEPTH = 8,    // RAM depth (number of entries)
    parameter INIT = ""     // name/location of RAM initialization file if using one (leave blank if not)
) (
    input                           i_flush,
    input                           i_stall,
    
    // Write enable
    input                           i_w_e,
    input   [$clog2(DEPTH) -1:0]    i_w_addr,
    input   [WIDTH - 1:0]           i_w_data,
    
    // Read Enable, for additional power savings, disable when not in use
    input                           i_r0_e,
    input   [$clog2(DEPTH) - 1:0]   i_r0_addr,
    output  [WIDTH - 1:0]           o_r0_data,
    
    input                           i_r1_e,
    input   [$clog2(DEPTH) - 1:0]   i_r1_addr,
    output  [WIDTH - 1:0]           o_r1_data,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    // A simple non-confict SRAM
    logic   [WIDTH - 1:0]   simple_r0_data;
    logic   [WIDTH - 1:0]   simple_r1_data;

    sram_1w2r #(
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH),
        .INIT       (INIT)
    ) simple_sram (
        .i_w_e      (i_w_e),
        .i_w_addr   (i_w_addr),
        .i_w_data   (i_w_data),
        .i_r0_e     (~i_stall & i_r0_e),
        .i_r0_addr  (i_r0_addr),
        .o_r0_data  (simple_r0_data),
        .i_r1_e     (~i_stall & i_r1_e),
        .i_r1_addr  (i_r1_addr),
        .o_r1_data  (simple_r1_data),
        .i_clk      (i_clk)
    );
    
    // Handle the confict
    logic                   bypass0;
    logic                   bypass1;
    logic   [WIDTH - 1:0]   bypass_r_data;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            bypass_r_data <= '0;
        end
        
        else if (~i_stall & (bypass0 | bypass1)) begin
            bypass_r_data <= i_w_data;
            bypass0 <= i_w_e & i_r0_e & i_w_addr == i_r0_addr;
            bypass1 <= i_w_e & i_r1_e & i_w_addr == i_r1_addr;
        end
    end
    
    // Output
    assign  o_r0_data = bypass0 ? bypass_r_data : simple_r0_data;
    assign  o_r1_data = bypass1 ? bypass_r_data : simple_r1_data;

endmodule

`endif

