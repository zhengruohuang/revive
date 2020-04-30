`ifndef __FIFO_1I1O_SV__
`define __FIFO_1I1O_SV__

`include "lib/sram_1w1r.sv"

module fifo_1i1o #(
    parameter WIDTH = 32,   // Data width per entry
    parameter DEPTH = 8,    // Number of entries per bank, must be a power of 2
    parameter ALWAYS_READ = 0
) (
    input                   i_w_e,
    input   [WIDTH - 1:0]   i_w_data,
    output                  o_w_ack,
    output                  o_w_avail,
    
    input                   i_r_e,
    output  [WIDTH - 1:0]   o_r_data,
    output                  o_r_valid,
    output                  o_r_ack,
    output                  o_r_avail,
    
    input                   i_flush,
    output                  o_full,
    output                  o_empty,
    
    input   i_clk,
    input   i_rst_n
);

// Avail entry count
reg     [$clog2(DEPTH + 1) - 1:0]   free_count;

// Consts
wire    [$clog2(DEPTH + 1) - 1:0]   TOTAL_COUNT = DEPTH;
wire    [$clog2(DEPTH + 1) - 1:0]   EMPTY_COUNT = 0;
wire    [$clog2(DEPTH + 1) - 1:0]   ONE_COUNT = 1;

// Internal full/empty signals
wire    full = free_count == EMPTY_COUNT;
wire    empty = free_count == TOTAL_COUNT;

// Generate output
assign  o_w_avail = ~full;
assign  o_r_avail = ~empty;
assign  o_full = full;
assign  o_empty = empty;

// SRAM control signals
wire    w_e = i_w_e & ~full;
wire    r_e = i_r_e & ~empty;

// Write and read acks
reg     w_ack;
reg     r_valid;
reg     r_ack;

assign  o_w_ack = w_ack;
assign  o_r_valid = r_valid;
assign  o_r_ack = r_ack;

always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        w_ack <= 0;
        r_valid <= 0;
        r_ack <= 0;
    end
    
    else begin
        if (i_flush) begin
            w_ack <= 0;
            r_valid <= 0;
            r_ack <= 0;
        end else begin
            w_ack <= w_e;
            r_valid <= ~empty;
            r_ack <= r_e;
        end
    end
end

// Update free count
always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        free_count <= TOTAL_COUNT;
    end
    
    else begin
        if (i_flush) begin
            free_count <= TOTAL_COUNT;
        end else begin
            case ({ w_e, r_e })
            2'b00: free_count <= free_count;
            2'b11: free_count <= free_count;
            2'b01: free_count <= free_count + ONE_COUNT;
            2'b10: free_count <= free_count - ONE_COUNT;
            endcase
        end
    end
end

// Last read and write index
reg     [$clog2(DEPTH) - 1:0]   w_addr;
reg     [$clog2(DEPTH) - 1:0]   r_addr;

// Consts
wire    [$clog2(DEPTH) - 1:0]   ONE_ADDR = 1;

// Update write index
always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        w_addr <= 0;
    end
    
    else begin
        if (i_flush) begin
            w_addr <= 0;
        end else if (w_e) begin
            w_addr <= w_addr + ONE_ADDR;
        end
    end
end

// Update read index
always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        r_addr <= 0;
    end
    
    else begin
        if (i_flush) begin
            r_addr <= 0;
        end else if (r_e) begin
            r_addr <= r_addr + ONE_ADDR;
        end
    end
end

// The actual SRAM
// Note that this FIFO does not allow write-thru, i.e. bypass the SRAM
// if FIFO is currently empty, therefore the simple sram_1w1r is used
sram_1w1r #(
    .WIDTH      (WIDTH),
    .DEPTH      (DEPTH)
) fifo_bank (
    .i_w_e      (w_e),
    .i_w_addr   (w_addr),
    .i_w_data   (i_w_data),
    
    .i_r_e      (ALWAYS_READ ? 1'b1 : r_e),
    .i_r_addr   (r_addr),
    .o_r_data   (o_r_data),
    
    .i_clk      (i_clk)
);

endmodule

`endif

