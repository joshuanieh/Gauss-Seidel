module GSIM (
    clk,
    reset,
    in_en,
    b_in,
    x_out,
    out_valid
);

    parameter RUN = 100;

    input           clk, reset, in_en;
    input  [16-1:0] b_in;
    output [32-1:0] x_out;
    output          out_valid;

    wire [32-1:0] x;
    wire [32-1:0] x1, x2, x3, x4, x5, x6;
    wire [16-1:0] b;
    reg  [4-1:0]  cycle_count_r;
    reg  [4-1:0]  cycle_count_w;
    reg  [10-1:0]  run_count_r;
    reg  [10-1:0]  run_count_w;

    register_file register_file (
        .clk_in(clk),
        .rst_in(reset),
        .en_in(in_en),
        .b_in(b_in),
        .x_in(x),
        .b_out(b),
        .x1_out(x1),
        .x2_out(x2),
        .x3_out(x3),
        .x4_out(x4),
        .x5_out(x5),
        .x6_out(x6)
    );

    equation equation (
        .x_out(x),
        .b_in(b),
        .x1_in(x1),
        .x2_in(x2),
        .x3_in(x3),
        .x4_in(x4),
        .x5_in(x5),
        .x6_in(x6)
    );

    always @(*) begin
        if (in_en == 1'b1)
            cycle_count_w = 4'd0;
        else
            cycle_count_w = cycle_count_r + 1;
    end

    always @(posedge clk) begin
        cycle_count_r <= cycle_count_w;
    end

    always @(*) begin
        if (in_en == 1'b1)
            run_count_w = 6'd0;
        else if (cycle_count_r == 4'd15)
            run_count_w = run_count_r + 1;
        else
            run_count_w = run_count_r;
    end

    always @(posedge clk) begin
        run_count_r <= run_count_w;
    end

    assign x_out = x;
    assign out_valid = (run_count_r == RUN) ? 1'b1 : 1'b0;
    
endmodule