`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);

    input   clk ;
    input   reset ;
    input   in_en;
    output  out_valid;
    input   [15:0]  b_in;
    output  [31:0]  x_out;

    parameter RUN = 50; //after this run number, the out_valid will be pulled up

    wire [32-1:0] x;
    wire [32-1:0] x1, x2, x3, x4, x5, x6;
    wire [16-1:0] b;
    reg  [4-1:0]  cycle_count_r;
    reg  [4-1:0]  cycle_count_w;
    reg  [6-1:0]  run_count_r;
    reg  [6-1:0]  run_count_w;
    wire          start;

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
        .x6_out(x6),
        .start_out(start)
    );

    Computation_Unit Computation_Unit (
        .clk(clk),
        .reset(reset),
        .b({b, 16'd0}),
        .x_0(x1),
        .x_1(x2),
        .x_2(x3),
        .x_3(x4),
        .x_4(x5),
        .x_5(x6),
        .x_new(x)
    );

    //Handle cycle_count_r, initialize when in_en is high; otherwise, count the cycle number
    always @(*) begin
        if (in_en == 1'b1)
            cycle_count_w = 4'd0;
        else
            cycle_count_w = cycle_count_r + 1;
    end

    always @(posedge clk) begin
        cycle_count_r <= cycle_count_w;
    end

    //Handle run_count_r, initialize when in_en is high; otherwise, when cycle_count_r is 15, run_count_r + 1
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

    assign x_out     = x; //just output the x computed
    assign out_valid = (start && ((run_count_r == RUN && cycle_count_r >= 4'd1) || (run_count_r == RUN + 1 && cycle_count_r == 4'd0))) ? 1'b1 : 1'b0; //pulled up when run_count_r achieve RUN

endmodule

/*Register file, used for shiftedly outputing the needed x and b for computation unit*/
module register_file (
    clk_in,
    rst_in,
    en_in,
    b_in,
    x_in,
    b_out,
    x1_out,
    x2_out,
    x3_out,
    x4_out,
    x5_out,
    x6_out,
    start_out
);

    input           clk_in, rst_in, en_in;
    input  [16-1:0] b_in;
    input  [32-1:0] x_in;
    output [16-1:0] b_out;
    output [32-1:0] x1_out, x2_out, x3_out, x4_out, x5_out, x6_out;
    output          start_out;

    reg    [16-1:0] b_r[0:16-1];
    reg    [16-1:0] b_w[0:16-1];
    
    reg    [32-1:0] x_r[0:16-1];
    reg    [32-1:0] x_w[0:16-1];

    reg    [4-1:0] count_r;
    reg    [4-1:0] count_w;

    reg            start_r;
    reg            start_w;

    reg            delay_start_r;
    reg            delay_start_w;

    integer i;

    //Handle b_r, when en_in == 1'b1, read b_in and shift to lower index; otherwise, shift circularly
    always @(*) begin
        if (en_in == 1'b1) begin
            b_w[15] = b_in;
            for (i = 0; i < 16 - 1; i = i + 1) begin
                b_w[i] = b_r[i+1];
            end
        end
        else begin
            b_w[15] = b_r[0];
            for (i = 0; i < 16 - 1; i = i + 1) begin
                b_w[i] = b_r[i+1];
            end
        end
    end

    always @(posedge clk_in) begin
        for (i = 0; i < 16; i = i + 1) begin
            b_r[i] <= b_w[i];
        end
    end

    //Handle x_r, when reset is high, reset to initial values; else store their values until start_r is high, note that the delay_start_r is due to the pipeline of computational unit.
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            x_w[i] = x_r[i];
        end
        if (start_r == 1'b1) begin //shift but not store x_in
            x_w[15] = x_r[0];
            for (i = 0; i < 16 - 1; i = i + 1) begin
                x_w[i] = x_r[i+1];
            end
        end
        else if (delay_start_r == 1'b1) begin //shift and store x_in to x[14]
            x_w[15] = x_r[0];
            x_w[14] = x_in;
            for (i = 0; i < 16 - 2; i = i + 1) begin
                x_w[i] = x_r[i+1];
            end
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1) begin //Run initial_x_value_generator.py for random initial values
            x_r[0] = 32'd0;
            x_r[1] = 32'd0;
            x_r[2] = 32'd0;
            x_r[3] = 32'd0;
            x_r[4] = 32'd0;
            x_r[5] = 32'd0;
            x_r[6] = 32'd0;
            x_r[7] = 32'd0;
            x_r[8] = 32'd0;
            x_r[9] = 32'd0;
            x_r[10] = 32'd0;
            x_r[11] = 32'd0;
            x_r[12] = 32'd0;
            x_r[13] = 32'd0;
            x_r[14] = 32'd0;
            x_r[15] = 32'd0;
        end
        else begin
            for (i = 0; i < 16; i = i + 1) begin
                x_r[i] <= x_w[i];
            end
        end
    end

    //Handle count_r, start to count right after the moment en_in is pulled to high; before that, set to 0
    always @(*) begin
        count_w = count_r + 1;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (start_r == 1'b1 || en_in == 1'b1)
            count_r <= count_w;
        else
            count_r <= 4'd0;
    end

    //Handle start_r, if en_in is high, the counter start, and if the counter arrives at 15, set start_r to shift x_r
    always @(*) begin
        if (count_r == 4'd15)
            start_w = 1'b1;
        else
            start_w = start_r;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1)
            start_r <= 1'b0;
        else
            start_r <= start_w;
    end

    //Handle delay_start_r, delayed from start_r by one cycle because of the computational unit delay
    always @(*) begin
        delay_start_w = start_r;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1)
            delay_start_r <= 1'b0;
        else
            delay_start_r <= delay_start_w;
    end

    assign b_out     = b_r[0];                               //always output b_r[0] and shift from higher index
    assign x1_out    = (count_r == 4'd15) ? 32'd0 : x_r[1];  //see ppt P.4 for this implementation
    assign x2_out    = (count_r == 4'd0)  ? 32'd0 : x_r[15]; //see ppt P.4 for this implementation
    assign x3_out    = (count_r >= 4'd14) ? 32'd0 : x_r[2];  //see ppt P.4 for this implementation
    assign x4_out    = (count_r <= 4'd1)  ? 32'd0 : x_r[14]; //see ppt P.4 for this implementation
    assign x5_out    = (count_r >= 4'd13) ? 32'd0 : x_r[3];  //see ppt P.4 for this implementation
    assign x6_out    = (count_r <= 4'd2)  ? 32'd0 : x_r[13]; //see ppt P.4 for this implementation
    assign start_out = start_r;                              //To let GSIM know the out_valid can be pulled up

endmodule


/* ======== 說明 ========
以下的code是參考Exercise.pdf p.9 右下角的架構圖來完成的
不過我把他切成2個stage的pipeline，前後2個stage的critical path都差不多是連續4個32bit加法所要的時間
我自己測了幾個test pattern，答案是正確的(雖然不能百分百保證沒問題)，然後誤差也很小，看能不能達到rank A(不能就再改一下除法器)
 ================================*/

module Computation_Unit (clk, reset, b, x_0, x_1, x_2, x_3, x_4, x_5, x_new); // compute the result in 2 cycles 
    input                clk, reset;               // Compute : b + 13(x_0 + x_1) - 6(x_2 + x_3) + (x_4 + x_5)
    input signed  [31:0] b;                    
    input signed  [31:0] x_0, x_1, x_2, x_3, x_4, x_5;
    output signed [31:0] x_new;

    //================= Parameter Declaration ======================
    wire signed   [31:0] x_0_1, x_2_3, x_4_5, x_plus_b, x_sub_6, DFF_nxt;
    wire signed   [31:0] x_0_1_mul4, x_0_1_mul8, x_0_1_mul13, x_2_3_mul2, x_2_3_mul4, x_2_3_mul6;
    reg signed    [31:0] DFF;

    //===================== Combinational ==========================
    assign x_0_1 = x_0 + x_1;
    assign x_2_3 = x_2 + x_3;
    assign x_4_5 = x_4 + x_5;
    assign x_plus_b = x_4_5 + b;
    assign x_0_1_mul4 = {x_0_1[29:0], 2'b0};
    assign x_0_1_mul8 = {x_0_1[28:0], 3'b0};
    assign x_0_1_mul13 = x_0_1 + x_0_1_mul4 + x_0_1_mul8;
    assign x_2_3_mul2 = {x_2_3[30:0], 1'b0};
    assign x_2_3_mul4 = {x_2_3[29:0], 2'b0};
    assign x_2_3_mul6 = x_2_3_mul2 + x_2_3_mul4;
    assign x_sub_6 = x_plus_b - x_2_3_mul6;
    assign DFF_nxt = x_0_1_mul13 + x_sub_6;

    division_20 div0 (.in(DFF), .out(x_new));

    //======================= Sequential ===========================
    always @(posedge clk or posedge reset) begin
        if (reset) DFF <= 32'b0;
        else DFF <= DFF_nxt;
    end

endmodule

module division_20 (in, out);  // multiply by (2^-5 + 2^-6 + 2^-9 + 2^-10 + 2^-13 + 2^-14 
    input  [31:0] in;          //            + 2^-17 + 2^-18 + 2^-21 + 2^-22 + 2^-25 + 2^-26)
    output [31:0] out;
    wire [33:0] x_5, x_6, x_9, x_10, x_13, x_14, x_17, x_18, x_21, x_22, x_25, x_26;
    wire [33:0] x_5_6, x_9_10, x_13_14, x_17_18, x_21_22, x_25_26, x_5to10, x_13to18, x_21to26;
    assign x_5 = {{5{in[31]}}, in[31:3]};
    assign x_6 = {{6{in[31]}}, in[31:4]};
    assign x_9 = {{9{in[31]}}, in[31:7]};
    assign x_10 = {{10{in[31]}}, in[31:8]};
    assign x_13 = {{13{in[31]}}, in[31:11]};
    assign x_14 = {{14{in[31]}}, in[31:12]};
    assign x_17 = {{17{in[31]}}, in[31:15]};
    assign x_18 = {{18{in[31]}}, in[31:16]}; 
    assign x_21 = {{21{in[31]}}, in[31:19]};
    assign x_22 = {{22{in[31]}}, in[31:20]};
    assign x_25 = {{25{in[31]}}, in[31:23]};
    assign x_26 = {{26{in[31]}}, in[31:24]}; 
    assign x_5_6 = x_5 + x_6;
    assign x_9_10 = x_9 + x_10;
    assign x_13_14 = x_13 + x_14;
    assign x_17_18 = x_17 + x_18;
    assign x_21_22 = x_21 + x_22;
    assign x_25_26 = x_25 + x_26;
    assign x_5to10 = x_5_6 + x_9_10;
    assign x_13to18 = x_13_14 + x_17_18;
    assign x_21to26 = x_21_22 + x_25_26;
    assign out = x_5to10[33:2] + x_13to18[33:2] + x_21to26[33:2];
endmodule