`ifndef __POPCOUNT_SV__
`define __POPCOUNT_SV__

module popcount #(
    parameter WIDTH = 2
) (
    input   [WIDTH - 1:0]               i_data,
    output  [$clog2(WIDTH + 1) - 1:0]   o_count
);

    reg [$clog2(WIDTH + 1) - 1:0]   count;
    assign o_count = count;

    generate
        if (WIDTH == 2) begin
            always_comb begin
                case (i_data)
                2'b00: count = 2'd0;
                2'b01, 2'b10: count = 2'd1;
                2'b11: count = 2'd2;
                endcase
            end
        end else begin
            initial $error("Unsupported popcount width!");
        end
    endgenerate

endmodule

`endif

