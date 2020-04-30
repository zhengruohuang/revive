`ifndef __VALUE_MATCH_SV__
`define __VALUE_MATCH_SV__

module value_match_1vsN #(
    parameter WIDTH = 32,
    parameter N = 2,
    parameter SKIP = -1     // Exclude this index from comparison
) (
    input   [WIDTH - 1:0]   i_value_1,
    input   [WIDTH - 1:0]   i_value_n   [0:COUNT - 1],
    output                  o_matched
);

    wire    [COUNT - 1:0]   match_each;
    assign  o_matched = match_each != { COUNT{1'b0} };

    genvar i;
    generate
        for (i = 0; i < COUNT; i++) begin
            if (i == SKIP) begin
                assign match_each[i] = 1'b0;
            end else begin
                assign match_each[i] = i_value_1 == i_value_n[i];
            end
        end
    endgenerate

endmodule

`endif

