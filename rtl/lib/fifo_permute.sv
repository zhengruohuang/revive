`ifndef __FIFO_PERMUTE_SV__
`define __FIFO_PERMUTE_SV__

module fifo_permute_unpacked #(
    parameter WIDTH = 32,
    parameter COUNT = 2
) (
    input   [WIDTH - 1:0]           i_data  [0:COUNT - 1],
    input   [$clog2(COUNT) - 1:0]   i_shift,
    output  [WIDTH - 1:0]           o_data  [0:COUNT - 1]
);

    reg [WIDTH - 1:0] data_permute  [0:COUNT - 1];

    genvar i;
    generate
        // High-level description
        // for (i = 0; i < COUNT; i = i + 1) begin
        //     assign data_permute[i] = i_data[i_shift + i];
        // end
        
        if (COUNT == 2) begin
            // 2 entries, 1 bit
            always_comb begin
                case (i_shift)
                1'b0: begin
                    data_permute[0] = i_data[0];
                    data_permute[1] = i_data[1];
                end
                1'b1: begin
                    data_permute[0] = i_data[1];
                    data_permute[1] = i_data[0];
                end
                endcase
            end
        end else begin
            initial $error("Unsupported permute count!");
        end
        
        for (i = 0; i < COUNT; i = i + 1) begin
            assign o_data[i] = data_permute[i];
        end
    endgenerate

endmodule

module fifo_depermute_unpacked #(
    parameter WIDTH = 32,
    parameter COUNT = 2
) (
    input   [WIDTH - 1:0]           i_data  [0:COUNT - 1],
    input   [$clog2(COUNT) - 1:0]   i_shift,
    output  [WIDTH - 1:0]           o_data  [0:COUNT - 1]
);

    reg [WIDTH - 1:0] data_permute  [0:COUNT - 1];

    genvar i;
    generate
        // High-level description
        // for (i = 0; i < COUNT; i = i + 1) begin
        //     assign data_permute[i] = i_data[i - i_shift];
        // end
        
        if (COUNT == 2) begin
            // 2 entries, 1 bit
            always_comb begin
                case (i_shift)
                1'b0: begin
                    data_permute[0] = i_data[0];
                    data_permute[1] = i_data[1];
                end
                1'b1: begin
                    data_permute[0] = i_data[1];
                    data_permute[1] = i_data[0];
                end
                endcase
            end
        end else begin
            initial $error("Unsupported permute count!");
        end
        
        for (i = 0; i < COUNT; i = i + 1) begin
            assign o_data[i] = data_permute[i];
        end
    endgenerate

endmodule

module fifo_permute_packed #(
    parameter COUNT = 2
) (
    input   [COUNT - 1:0]           i_data,
    input   [$clog2(COUNT) - 1:0]   i_shift,
    output  [COUNT - 1:0]           o_data
);

    reg [COUNT - 1:0] data_permute;
    assign o_data = data_permute;

    genvar i;
    generate
        if (COUNT == 2) begin
            // 2 entries, 1 bit
            always_comb begin
                case (i_shift)
                1'b0: begin
                    data_permute[0] = i_data[0];
                    data_permute[1] = i_data[1];
                end
                1'b1: begin
                    data_permute[0] = i_data[1];
                    data_permute[1] = i_data[0];
                end
                endcase
            end
        end else begin
            initial $error("Unsupported permute count!");
        end
        
        for (i = 0; i < COUNT; i = i + 1) begin
            assign o_data[i] = data_permute[i];
        end
    endgenerate

endmodule

module fifo_depermute_packed #(
    parameter COUNT = 2
) (
    input   [COUNT - 1:0]           i_data,
    input   [$clog2(COUNT) - 1:0]   i_shift,
    output  [COUNT - 1:0]           o_data
);

    reg [COUNT - 1:0] data_permute;
    assign o_data = data_permute;

    genvar i;
    generate
        if (COUNT == 2) begin
            // 2 entries, 1 bit
            always_comb begin
                case (i_shift)
                1'b0: begin
                    data_permute[0] = i_data[0];
                    data_permute[1] = i_data[1];
                end
                1'b1: begin
                    data_permute[0] = i_data[1];
                    data_permute[1] = i_data[0];
                end
                endcase
            end
        end else begin
            initial $error("Unsupported permute count!");
        end
        
        for (i = 0; i < COUNT; i = i + 1) begin
            assign o_data[i] = data_permute[i];
        end
    endgenerate

endmodule

`endif

