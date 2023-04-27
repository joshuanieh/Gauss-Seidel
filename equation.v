
module equation (
    x_out,
    b_in,
    x1_in,
    x2_in,
    x3_in,
    x4_in,
    x5_in,
    x6_in
);
    input  [16-1:0] b_in;
    input  [32-1:0] x1_in, x2_in, x3_in, x4_in, x5_in, x6_in;
    output [32-1:0] x_out;

    assign x_out = (1 / 20) * (b_in + 13 * (x1_in + x2_in) - 6 * (x3_in + x4_in) + (x5_in + x6_in))

endmodule