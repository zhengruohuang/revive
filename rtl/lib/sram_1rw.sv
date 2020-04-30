
// Derived from Xilinx Single Port Read First RAM
// When data is written to the memory, the output reflects the prior contents
// at that memory location

module sram_1rw #(
    parameter WIDTH = 18,       // Specify RAM data width
    parameter DEPTH = 1024,     // Specify RAM depth (number of entries)
    parameter INIT_FILE = ""        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
    input                           i_e,
    input                           i_w_e,
    input   [$clog2(DEPTH-1) - 1:0] i_addr,
    input   [WIDTH - 1:0]           i_w_data,
    output  [WIDTH - 1:0]           o_r_data,
    input   i_clk
);

    reg [WIDTH-1:0] block_ram [DEPTH-1:0];
    reg [WIDTH-1:0] r_data = {WIDTH{1'b0}};

    // Init the RAM
    generate
        if (INIT_FILE != "") begin
            initial $readmemh(INIT_FILE, block_ram, 0, DEPTH-1);
        end else begin: init_block_ram_to_zero
            integer i;
            initial begin
                for (i = 0; i < DEPTH; i = i + 1)
                    block_ram[i] = { WIDTH{1'b0} };
                end
            end
        end
    endgenerate

    // Read and write
    assign o_r_data = r_data;
    
    always @ (posedge i_clk) begin
        if (i_e) begin
            if (i_w_e) begin
                block_ram[i_addr] <= i_w_data;
            end
            r_data <= block_ram[i_addr];
        end
    end

endmodule

