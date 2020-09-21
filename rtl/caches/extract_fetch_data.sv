`include "include/config.svh"
`include "include/pc.svh"
`include "include/caches.svh"
`include "include/instr.svh"

module extract_fetch_data (
    input   cacheline_t         i_data,
    input   program_counter_t   i_pc,
    output  fetch_data_t        o_data
);

    fetch_data_t    data;
    assign          o_data = data;

    generate
        // 32-byte cacheline and 8-byte fetch size
        if (`CACHELINE_WIDTH == 256 && `FETCH_DATA_WIDTH == 64) begin
            always_comb begin
                case (i_pc[4:3])
                2'h0: data = i_data[ 63:  0];
                2'h1: data = i_data[127: 64];
                2'h2: data = i_data[191:128];
                2'h3: data = i_data[255:192];
                endcase
            end
        end
        
        else begin
            initial $error("Unsupported cacheline size!");
        end
    endgenerate

endmodule

