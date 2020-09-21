`include "include/config.svh"
`include "include/pc.svh"
`include "include/ps.svh"
`include "include/caches.svh"
`include "include/instr.svh"
`include "include/except.svh"

`include "lib/array_or.sv"
`include "caches/extract_fetch_data.sv"


module instr_fetch2 (
    input                       i_stall,
    input                       i_flush,
    
    input                       i_valid,
    input   program_counter_t   i_pc,
    input   program_state_t     i_ps,
    
    input   itlb_tag_entry_t    i_itlb_tag      [0:`ITLB_ASSOC - 1],
    input   itlb_data_entry_t   i_itlb_data     [0:`ITLB_ASSOC - 1],
    input   icache_tag_entry_t  i_icache_tag    [0:`ICACHE_ASSOC - 1],
    input   icache_data_entry_t i_icache_data   [0:`ICACHE_ASSOC - 1],
    
    output                      o_valid,
    output  program_counter_t   o_pc,
    output  fetch_data_t        o_data,
    output  except_t            o_except,
    
    input   i_clk,
    input   i_rst_n
);

    genvar i;
    
    /*
     * Valid and PC
     */
    logic               valid;
    program_counter_t   pc;
    assign  o_valid     = valid;
    assign  o_pc        = pc;
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush) begin
            valid <= 1'b0;
            pc <= '0;
        end
        
        else begin
            if (i_stall) begin
                valid <= valid;
                pc <= pc;
            end else begin
                valid <= i_valid;
                pc <= i_pc;
            end
        end
    end
    
    /*
     * ITLB match logic
     */
    wire    itlb_tag_entry_t    itlb_match_value        = compose_itlb_tag_entry(i_ps.asid, i_pc);
    
    wire    itlb_data_entry_t   itlb_matching_values    [0:`ITLB_ASSOC - 1];
    wire                        itlb_matching           [0:`ITLB_ASSOC - 1];
    wire    itlb_data_entry_t   itlb_matched_value;
    wire                        itlb_matched;
    
    generate
        for (i = 0; i < `ITLB_ASSOC; i = i + 1) begin
            assign itlb_matching[i] = i_valid && i_itlb_tag[i] == itlb_match_value ? 1'b1 : 1'b0;
            assign itlb_matching_values[i] = itlb_matching[i] ? i_itlb_data[i] : '0;
        end
    endgenerate
    
    array_or #(
        .WIDTH  ($bits(itlb_data_entry_t)),
        .COUNT  (`ITLB_ASSOC)
    ) itlb_matched_value_reduce (
        .i_data (itlb_matching_values),
        .o_data (itlb_matched_value)
    );
    
    array_or #(
        .WIDTH  (1),
        .COUNT  (`ITLB_ASSOC)
    ) itlb_matched_reduce (
        .i_data (itlb_matching),
        .o_data (itlb_matched)
    );
    
    /*
     * ICache match logic
     */
    wire    paddr_t             pc_paddr                = compose_paddr(itlb_matched_value.ppn, i_pc);
    wire    icache_tag_entry_t  icache_match_value      = compose_icache_tag_entry(pc_paddr);
    
    wire    icache_data_entry_t icache_matching_values  [0:`ICACHE_ASSOC - 1];
    wire                        icache_matching         [0:`ICACHE_ASSOC - 1];
    wire    icache_data_entry_t icache_matched_value;
    wire                        icache_matched;
    
    generate
        for (i = 0; i < `ICACHE_ASSOC; i = i + 1) begin
            assign icache_matching[i] = i_valid && itlb_matched && i_icache_tag[i] == icache_match_value ? 1'b1 : 1'b0;
            assign icache_matching_values[i] = icache_matching[i] ? i_icache_data[i] : '0;
        end
    endgenerate
    
    array_or #(
        .WIDTH  ($bits(icache_data_entry_t)),
        .COUNT  (`ICACHE_ASSOC)
    ) icache_matched_value_reduce (
        .i_data (icache_matching_values),
        .o_data (icache_matched_value)
    );
    
    array_or #(
        .WIDTH  (1),
        .COUNT  (`ICACHE_ASSOC)
    ) icache_matched_reduce (
        .i_data (icache_matching),
        .o_data (icache_matched)
    );
    
    /*
     * Extract ICache data
     */
    wire    pc_unalign_fault    = i_pc[0];
    wire    itlb_match_fault    = 1'b0;
    wire    fetch_data_t        fetched_data;
    
    extract_fetch_data extract (
        .i_data (icache_matched_value.data),
        .i_pc   (i_pc),
        .o_data (fetched_data)
    );
    
    /*
     * Data and except
     */
    fetch_data_t    data, reg_data;
    except_t        except, reg_except;
    assign          o_data      = reg_data;
    assign          o_except    = reg_except;
    
    always_comb begin
        if (pc_unalign_fault) begin
            data = '0;
            except = { 1'b1, EXCEPT_PC_MISALIGN };
        end else if (itlb_match_fault) begin
            data = '0;
            except = { 1'b1, EXCEPT_ITLB_PAGE_FAULT };
        end else begin
            data = fetched_data;
            except = '0;
        end
    end
    
    always_ff @ (posedge i_clk) begin
        if (~i_rst_n || i_flush || ~i_valid) begin
            reg_data <= '0;
            reg_except <= '0;
        end
        
        else if (~i_stall) begin
            reg_data <= data;
            reg_except <= except;
            
            $display("[IF2] Valid: %d, Fetch @ %h, Data: %h, Except: %h, icache tag 0: %h, tag match: %h, itlb_matched: %d",
                     i_valid, i_pc, data, except, i_icache_tag[0], icache_match_value, itlb_matched);
        end
    end

endmodule

