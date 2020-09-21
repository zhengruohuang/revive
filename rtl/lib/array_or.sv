`ifndef __ARRAY_OR_SV__
`define __ARRAY_OR_SV__

module array_or #(
    parameter WIDTH = 2,
    parameter COUNT = 2
) (
    input   [WIDTH - 1:0]   i_data [0:COUNT - 1],
    output  [WIDTH - 1:0]   o_data
);

    generate
        if (COUNT == 1) begin
            assign o_data = i_data[0];
        end else if (COUNT == 2) begin
            assign o_data = i_data[0] | i_data[1];
        end else if (COUNT == 4) begin
            assign o_data = i_data[0] | i_data[1] | i_data[3] | i_data[4];
        end else begin
            initial $error("Unsupported array size!");
        end
    endgenerate

endmodule

`endif

