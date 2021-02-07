`include "include/config.svh"
`include "include/instr.svh"


module fetch (
    input                       i_flush,
    input                       i_stall,
    
    // From and to PC and PS
    input   program_counter_t   i_pc,
    input   program_state_t     i_ps,
    output                      o_stall,
    
    // To next stage - IA
    output  fetched_data_t      o_data,
    
    // Log
    input   [31:0] i_log_fd,
    
    // Clock and Reset
    input   i_clk,
    input   i_rst_n
);

    wire                        valid       = ~i_flush & ~i_stall;
    wire    reg_data_t          addr        = i_pc;
    wire    reg_data_t          fetch_addr  = { i_pc[31:2], 2'b0 };

    wire                        page_fault = 1'b0;
            short_instr_t       fetch_data0;
            short_instr_t       fetch_data1;
            logic               empty_out;
            short_instr_t       instr_ram [0:1023];

    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            empty_out <= 1'b1;
        end else if (~i_stall) begin
            empty_out <= 1'b0;
            fetch_data0 <= instr_ram[{ fetch_addr[10:2], 1'b0 }];
            fetch_data1 <= instr_ram[{ fetch_addr[10:2], 1'b1 }];
        end
    end

    /*
     * Output
     */
    assign  o_stall = i_stall;
    assign  o_data  = empty_out ? '0 : compose_fetched_data(i_pc, fetch_data0, fetch_data1, `EXCEPT_NONE, valid);
    
//    always_ff @ (posedge i_clk) begin
//        if (~i_rst_n || i_flush) begin
//            o_data <= '0;
//        end
//        
//        else if (~i_stall) begin
//            o_data <= compose_fetched_data(i_pc, fetch_data0, fetch_data1, page_fault ? `EXCEPT_ITLB_PAGE_FAULT(i_pc) : `EXCEPT_NONE, valid);
//            
//            if (i_log_fd != '0) begin
//                $fdisplay(i_log_fd, "[IF ] Valid: %d, PC @ %h, Data: %h-%h",
//                          valid, i_pc, fetch_data0, fetch_data1);
//            end
//        end
//    end

endmodule

