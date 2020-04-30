`ifndef __FIFO_ANY_SV__
`define __FIFO_ANY_SV__

`include "lib/fifo_1i1o.sv"
`include "lib/fifo_permute.sv"
`include "lib/popcount.sv"

module fifo_any #(
    parameter WIDTH = 32,   // Data width per entry
    parameter DEPTH = 8,    // Number of entries per bank, must be a power of 2
    parameter W_CNT = 2,
    parameter R_CNT = 2,
    parameter ALWAYS_READ = 0
) (
    input   [W_CNT - 1:0]   i_w_e,      // Bitmap, ones after the first zero are ignored
    input   [WIDTH - 1:0]   i_w_data    [0:W_CNT - 1],
    output  [W_CNT - 1:0]   o_w_ack,    // Bitmap, entries successfully written are set to 1
    output                  o_w_avail,  // Can accept W_CNT number of write requests
    
    input   [R_CNT - 1:0]   i_r_e,
    output  [WIDTH - 1:0]   o_r_data    [0:R_CNT - 1],
    output  [R_CNT - 1:0]   o_r_valid,  // If the read data is valid, useful when ALWAYS_READ is set, otherwise same as o_r_ack
    output  [R_CNT - 1:0]   o_r_ack,
    output                  o_r_avail,  // Can supply R_CNT number of read results
    
    input                   i_flush,
    output                  o_full,     // Can accept no more requests
    output                  o_empty,
    
    input   i_clk,
    input   i_rst_n
);

localparam BANKS = W_CNT > R_CNT ? W_CNT : R_CNT;
genvar i;

// Bank index where the first read/write starts from
reg     [$clog2(BANKS) - 1:0]   w_bank;
reg     [$clog2(BANKS) - 1:0]   r_bank;

// Write and read control signals
// Inputs have to be permuted based on current initial bank index
// while outputs have to be de-permuted
/*
wire    [W_CNT - 1:0]   w_e_permute;
wire    [WIDTH - 1:0]   w_data_permute  [0:W_CNT - 1];
wire    [W_CNT - 1:0]   w_ack_permute;
wire    [W_CNT - 1:0]   w_ack;

wire    [R_CNT - 1:0]   r_e_permute;
wire    [WIDTH - 1:0]   r_data_permute  [0:R_CNT - 1];
wire    [WIDTH - 1:0]   r_data          [0:R_CNT - 1];
wire    [R_CNT - 1:0]   r_valid_permute;
wire    [R_CNT - 1:0]   r_valid;
wire    [R_CNT - 1:0]   r_ack_permute;
wire    [R_CNT - 1:0]   r_ack;

assign o_w_ack = w_ack;
assign o_r_valid = r_valid;
assign o_r_ack = r_ack;

// Permute and de-permute write and read signals
generate
    for (i = 0; i < W_CNT; i = i + 1) begin
        assign w_e_permute[i] = i_w_e[w_bank + i];
        assign w_data_permute[i] = i_w_data[w_bank + i];
        assign w_ack[i] = w_ack_permute[i - w_bank];
    end
    
    for (i = 0; i < R_CNT; i = i + 1) begin
        assign r_e_permute[i] = i_r_e[r_bank + i];
        assign r_data[i] = r_data_permute[i - r_bank];
        assign r_valid[i] = r_valid_permute[i - r_bank];
        assign r_ack[i] = r_ack_permute[i - r_bank];
        
        assign o_r_data[i] = r_data[i];
    end
endgenerate
*/


wire    [BANKS - 1:0]   w_e;
wire    [BANKS - 1:0]   w_e_permute;
wire    [WIDTH - 1:0]   w_data          [0:BANKS - 1];
wire    [WIDTH - 1:0]   w_data_permute  [0:BANKS - 1];
wire    [BANKS - 1:0]   w_ack_permute;
wire    [BANKS - 1:0]   w_ack;

wire    [BANKS - 1:0]   r_e;
wire    [BANKS - 1:0]   r_e_permute;
wire    [WIDTH - 1:0]   r_data_permute  [0:BANKS - 1];
wire    [WIDTH - 1:0]   r_data          [0:BANKS - 1];
wire    [BANKS - 1:0]   r_valid_permute;
wire    [BANKS - 1:0]   r_valid;
wire    [BANKS - 1:0]   r_ack_permute;
wire    [BANKS - 1:0]   r_ack;

assign o_w_ack = w_ack;
assign o_r_valid = r_valid;
assign o_r_ack = r_ack;

generate
    for (i = 0; i < R_CNT; i = i + 1) begin
        assign o_r_data[i] = r_data[i];
    end
    
    // Extend i_w_* to BANKS bits
    for (i = 0; i < W_CNT; i = i + 1) begin
        assign w_e[i] = i_w_e[i];
        assign w_data[i] = i_w_data[i];
    end
    
    for (i = W_CNT; i < BANKS; i = i + 1) begin
        assign w_e[i] = 1'b0;
        assign w_data[i] = '0;
    end
    
    // Extend i_r_* to BANKS bits
    for (i = 0; i < R_CNT; i = i + 1) begin
        assign r_e[i] = i_r_e[i];
    end
    
    for (i = R_CNT; i < BANKS; i = i + 1) begin
        assign r_e[i] = 1'b0;
    end
endgenerate

fifo_permute_packed     #(.COUNT(BANKS))
    permute_w_e          (.i_data(w_e), .i_shift(w_bank), .o_data(w_e_permute));
fifo_permute_unpacked   #(.WIDTH(WIDTH), .COUNT(BANKS))
    permute_w_data       (.i_data(w_data), .i_shift(w_bank), .o_data(w_data_permute));
fifo_depermute_packed   #(.COUNT(BANKS))
    depermute_w_ack      (.i_data(w_ack_permute), .i_shift(w_bank), .o_data(w_ack));

fifo_permute_packed     #(.COUNT(BANKS))
    permute_r_e          (.i_data(r_e), .i_shift(r_bank), .o_data(r_e_permute));
fifo_depermute_unpacked #(.WIDTH(WIDTH), .COUNT(BANKS))
    depermute_r_data     (.i_data(r_data_permute), .i_shift(r_bank), .o_data(r_data));
fifo_depermute_packed   #(.COUNT(BANKS))
    depermute_r_valid    (.i_data(r_valid_permute), .i_shift(r_bank), .o_data(r_valid));
fifo_depermute_packed   #(.COUNT(BANKS))
    depermute_r_ack      (.i_data(r_ack_permute), .i_shift(r_bank), .o_data(r_ack));

// Successful writes and reads
wire    [$clog2(BANKS + 1) - 1:0]   w_count_ext;
wire    [$clog2(BANKS + 1) - 1:0]   r_count_ext;

wire    [$clog2(BANKS) - 1:0]       w_count;
wire    [$clog2(BANKS) - 1:0]       r_count;

popcount #(.WIDTH(BANKS)) w_popcnt (.i_data(w_ack_permute), .o_count(w_count_ext));
popcount #(.WIDTH(BANKS)) r_popcnt (.i_data(r_ack_permute), .o_count(r_count_ext));

assign  w_count = w_count_ext[$clog2(BANKS) - 1:0];
assign  r_count = r_count_ext[$clog2(BANKS) - 1:0];

// Update bank index
always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        w_bank <= 0;
        r_bank <= 0;
    end
    
    else begin
        if (i_flush) begin
            w_bank <= 0;
            r_bank <= 0;
        end else begin
            w_bank <= w_bank + w_count;
            r_bank <= r_bank + r_count;
        end
    end
end

// Total avail/full/empty
wire    [BANKS - 1:0]   each_w_avail_permute;
wire    [BANKS - 1:0]   each_w_avail_extend;
wire    [W_CNT - 1:0]   each_w_avail;
wire    [BANKS - 1:0]   each_r_avail_permute;
wire    [BANKS - 1:0]   each_r_avail_extend;
wire    [R_CNT - 1:0]   each_r_avail;
wire    [BANKS - 1:0]   each_full;
wire    [BANKS - 1:0]   each_empty;

fifo_depermute_packed   #(.COUNT(BANKS))
    depermute_each_w_avail (.i_data(each_w_avail_permute), .i_shift(w_bank), .o_data(each_w_avail_extend));
fifo_depermute_packed   #(.COUNT(BANKS))
    depermute_each_r_avail (.i_data(each_r_avail_permute), .i_shift(r_bank), .o_data(each_r_avail_extend));

generate
    for (i = 0; i < W_CNT; i = i + 1) begin
        assign each_w_avail[i] = each_w_avail_extend[i];
    end
    
    for (i = 0; i < R_CNT; i = i + 1) begin
        assign each_r_avail[i] = each_r_avail_extend[i];
    end
endgenerate

wire    agg_w_avail = each_w_avail == { W_CNT{1'b1} };
wire    agg_r_avail = each_r_avail == { R_CNT{1'b1} };
wire    agg_full = each_full == { BANKS{1'b1} };
wire    agg_empty = each_empty == { BANKS{1'b0} };

assign  o_w_avail = agg_w_avail;
assign  o_r_avail = agg_r_avail;
assign  o_full = agg_full;
assign  o_empty = agg_empty;

// The actual 1i1o FIFOs
generate
    for (i = 0; i < BANKS; i = i + 1) begin
        fifo_1i1o #(
            .WIDTH          (WIDTH),
            .DEPTH          (DEPTH),
            .ALWAYS_READ    (ALWAYS_READ)
        ) fifo (
            .i_w_e          (w_e_permute[i]),
            .i_w_data       (w_data_permute[i]),
            .o_w_ack        (w_ack_permute[i]),
            .o_w_avail      (each_w_avail_permute[i]),
            
            .i_r_e          (r_e_permute[i]),
            .o_r_data       (r_data_permute[i]),
            .o_r_valid      (r_valid_permute[i]),
            .o_r_ack        (r_ack_permute[i]),
            .o_r_avail      (each_r_avail_permute[i]),
            
            .i_flush        (i_flush),
            .o_full         (each_full[i]),
            .o_empty        (each_empty[i]),
            
            .i_clk          (i_clk),
            .i_rst_n        (i_rst_n)
        );
    end
endgenerate

endmodule

`endif

