`include "include/config.svh"
`include "include/instr.svh"
`include "include/caches.svh"


/*
 * Instr Fetch 3 - Data read
 */
module instr_fetch3 (
    input                       i_stall,
    input                       i_flush,
    
    // From Fetch2
    input                       i_valid,
    input                       i_icache_miss,
    input   reg_data_t          i_icache_miss_data,
    input   program_counter_t   i_pc,
    input                       i_page_fault,
    
    // From IData
    input   reg_data_t          i_data,
    
    // To next stage - IA
    output  fetched_data_t      o_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

            logic               next_valid;
            logic               next_icache_miss;
            reg_data_t          next_icache_miss_data;
            program_counter_t   next_pc;
            except_t            next_except;
    
    wire    reg_data_t          next_data = next_icache_miss ? next_icache_miss_data : i_data;
    wire    short_instr_t       next_data0 = next_data[15:0];
    wire    short_instr_t       next_data1 = next_data[31:16];
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n | i_flush) begin
            next_valid <= '0;
            next_icache_miss <= '0;
            next_icache_miss_data <= '0;
            next_pc <= '0;
            next_except <= '0;
        end
        
        else if (~i_stall) begin
            next_valid <= i_valid;
            next_icache_miss <= i_icache_miss;
            next_icache_miss_data <= i_icache_miss_data;
            next_pc <= i_pc;
            next_except <= i_except;
            
            if (i_log_fd != '0) begin
                $fdisplay(i_log_fd, "[IF3] Valid: %d, PC @ %h, Data: %h-%h",
                          i_valid, i_pc, next_data0, next_data1);
            end
        end
    end
    
    wire    fetched_data_t  next_data = compose_fetched_data(next_pc, next_data0, next_data1, next_except, next_valid);
    assign  o_data = next_data;

endmodule

