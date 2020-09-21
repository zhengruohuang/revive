`include "include/config.svh"
`include "include/instr.svh"

module instr_queue (
    input                       i_flush,
    
    input                       i_enqueue,
    input   aligned_instr_t     i_instrs    [0:`FETCH_WIDTH - 1],
    input                       i_dequeue,
    output  aligned_instr_t     o_instrs    [0:`FETCH_WIDTH - 1],
    
    output                      o_can_enqueue,
    output                      o_can_dequeue,
    
    input   i_clk,
    input   i_rst_n
);

    logic           buf_avail;
    aligned_instr_t buf_instrs  [0:`FETCH_WIDTH - 1];
    
    // Bypass the queue if enqueue and dequeue at the same time
    assign          o_can_enqueue = buf_avail;
    assign          o_can_dequeue = ~buf_avail | i_enqueue;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            buf_avail = 1'b1;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                buf_instrs[i] <= '0;
            end
        end
        
        // Dequeue
        else if (i_dequeue & ~i_enqueue) begin
            buf_avail = 1'b1;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                buf_instrs[i] <= '0;
            end
        end
        
        // Enqueue
        else if (~i_dequeue & i_enqueue) begin
            buf_avail = 1'b0;
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                buf_instrs[i] <= i_instrs[i];
            end
            
            $display("[IQ] Enqueue");
        end
    end
    
    wire aligned_instr_t next_instrs [0:`FETCH_WIDTH - 1];
    
    for (genvar i = 0; i < `FETCH_WIDTH; i = i + 1) begin
        assign next_instrs[i] = i_enqueue ? i_instrs[i] : buf_instrs[i];
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                o_instrs[i] <= '0;
            end
        end
        
        else if (i_dequeue) begin
            for (integer i = 0; i < `FETCH_WIDTH; i = i + 1) begin
                o_instrs[i] <= next_instrs[i];
            end
            
            $display("[IQ] Dequeue, bypass: %d", i_enqueue & i_dequeue);
        end
    end

endmodule

