`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);

    input   clk ;
    input   reset ;
    input   in_en;
    output  out_valid;
    input   [15:0]  b_in;
    output reg [31:0]  x_out;

    parameter RUN = 100; //after this run number, the out_valid will be pulled up

    wire [32-1:0] x;
    wire [32-1:0] x1, x2, x3, x4, x5, x6;
    wire [16-1:0] b;
    reg  [4-1:0]  cycle_count_r;
    reg  [4-1:0]  cycle_count_w;
    reg  [9-1:0]  run_count_r;
    reg  [9-1:0]  run_count_w;
    wire          start;
    reg  [32-1:0] x_stored_r[1:16];
    reg  [32-1:0] x_stored_w[1:16];

    integer       i;

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
            run_count_w = 8'd0;
        else if (cycle_count_r == 4'd15)
            run_count_w = run_count_r + 1;
        else
            run_count_w = run_count_r;
    end

    always @(posedge clk) begin
        run_count_r <= run_count_w;
    end

    // assign x_out     = x; //just output the x computed
    always @(*) begin
        for (i = 1; i < 16+1; i = i + 1) begin
            x_stored_w[i] = x_stored_r[i];
        end
        if (start && ((run_count_r == RUN && cycle_count_r >= 4'd3) || (run_count_r == RUN + 1 && cycle_count_r <= 4'd2))) begin
            x_stored_w[16] = x;
            for (i = 1; i < 16; i = i + 1) begin
                x_stored_w[i] = x_stored_r[i+1];
            end
        end
    end

    always @(posedge clk) begin
        for (i = 1; i < 16+1; i = i + 1) begin
            x_stored_r[i] <= x_stored_w[i];
        end
    end

    always @(*) begin
        case (cycle_count_r)//1 5 9 13 2 6 10 14 3 7 11 15 4 8 12 16
            4'd3:
                x_out =  x_stored_r[1];
            4'd4:
                x_out =  x_stored_r[5];
            4'd5:
                x_out =  x_stored_r[9];
            4'd6:
                x_out =  x_stored_r[13];
            4'd7:
                x_out =  x_stored_r[2];
            4'd8:
                x_out =  x_stored_r[6];
            4'd9:
                x_out =  x_stored_r[10];
            4'd10:
                x_out =  x_stored_r[14];
            4'd11:
                x_out =  x_stored_r[3];
            4'd12:
                x_out =  x_stored_r[7];
            4'd13:
                x_out =  x_stored_r[11];
            4'd14:
                x_out =  x_stored_r[15];
            4'd15:
                x_out =  x_stored_r[4];
            4'd0:
                x_out =  x_stored_r[8];
            4'd1:
                x_out =  x_stored_r[12];
            4'd2:
                x_out =  x_stored_r[16];
        endcase
    end

    assign out_valid = (start && ((run_count_r == RUN+1 && cycle_count_r >= 4'd3) || (run_count_r == RUN + 2 && cycle_count_r <= 4'd2))) ? 1'b1 : 1'b0; //pulled up when run_count_r achieve RUN

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

    input               clk_in, rst_in, en_in;
    input      [16-1:0] b_in;
    input      [32-1:0] x_in;
    output     [16-1:0] b_out;
    output     [32-1:0] x1_out, x2_out, x3_out, x4_out, x5_out, x6_out;
    output              start_out;

    reg        [16-1:0] b_r[1:16];
    reg        [16-1:0] b_w[1:16];
    
    reg        [32-1:0] x_r[1:16]; //1 5 9 13 2 6 10 14 3 7 11 15 4 8 12 16
    reg        [32-1:0] x_w[1:16];

    reg        [4-1:0]  count_r;
    reg        [4-1:0]  count_w;

    reg                 start_r;
    reg                 start_w;

    reg                 delay_start_r;
    reg                 delay_start_w;

    reg                 compute_delay_start_r;
    reg                 compute_delay_start_w;

    integer             i;

    //Handle b_r, when en_in == 1'b1, read b_in and shift to lower index; otherwise, shift circularly
    always @(*) begin
        if (en_in == 1'b1) begin
            b_w[16] = b_in;
            for (i = 1; i < 16; i = i + 1) begin
                b_w[i] = b_r[i+1];
            end
        end
        else if (start_r == 1'b1 && delay_start_r == 1'b0) begin //b_r stored in this order 1 5 9 13 2 6 10 14 3 7 11 15 4 8 12 16
            b_w[1] = b_r[5];
            b_w[2] = b_r[9];
            b_w[3] = b_r[13];
            b_w[4] = b_r[2];
            b_w[5] = b_r[6];
            b_w[6] = b_r[10];
            b_w[7] = b_r[14];
            b_w[8] = b_r[3];
            b_w[9] = b_r[7];
            b_w[10] = b_r[11];
            b_w[11] = b_r[15];
            b_w[12] = b_r[4];
            b_w[13] = b_r[8];
            b_w[14] = b_r[12];
            b_w[15] = b_r[16];
            b_w[16] = b_r[1];
        end
        else begin
            b_w[16] = b_r[1];
            for (i = 1; i < 16; i = i + 1) begin
                b_w[i] = b_r[i+1];
            end
        end
    end

    always @(posedge clk_in) begin
        for (i = 1; i < 16+1; i = i + 1) begin
            b_r[i] <= b_w[i];
        end
    end

    //Handle x_r, when reset is high, reset to initial values; else store their values until start_r is high, note that the delay_start_r is due to the pipeline of computational unit.
    always @(*) begin
        if (compute_delay_start_r == 1'b1) begin //shift and store x_in to x[14]
            x_w[16] = x_r[1];
            for (i = 1; i < 16; i = i + 1) begin
                x_w[i] = x_r[i+1];
            end
            x_w[13] = x_in;
        end
        else if (start_r == 1'b1) begin //shift but not store x_in
            x_w[16] = x_r[1];
            for (i = 1; i < 16; i = i + 1) begin
                x_w[i] = x_r[i+1];
            end
        end
        else begin
            for (i = 1; i < 16+1; i = i + 1) begin
                x_w[i] = x_r[i];
            end
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1) begin //Run initial_x_value_generator.py for random initial values
            x_r[1] <= 32'd0;
            x_r[2] <= 32'd0;
            x_r[3] <= 32'd0;
            x_r[4] <= 32'd0;
            x_r[5] <= 32'd0;
            x_r[6] <= 32'd0;
            x_r[7] <= 32'd0;
            x_r[8] <= 32'd0;
            x_r[9] <= 32'd0;
            x_r[10] <= 32'd0;
            x_r[11] <= 32'd0;
            x_r[12] <= 32'd0;
            x_r[13] <= 32'd0;
            x_r[14] <= 32'd0;
            x_r[15] <= 32'd0;
            x_r[16] <= 32'd0;
        end
        else begin
            for (i = 1; i < 16+1; i = i + 1) begin
                x_r[i] <= x_w[i];
            end
        end
    end

    //Handle count_r, start to count right after the moment en_in is pulled to high; before that, set to 0
    always @(*) begin
        count_w = count_r + 1;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1)
            count_r <= 4'd0;
        else if (start_r == 1'b1 || en_in == 1'b1)
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

    //Handle compute_delay_start_r to know when we start write the value back
    always @(*) begin
        if (start_r == 1'b1 && count_r == 4'd2) begin
            compute_delay_start_w = start_r;
        end
        else begin
            compute_delay_start_w = compute_delay_start_r;
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1)
            compute_delay_start_r <= 1'b0;
        else
            compute_delay_start_r <= compute_delay_start_w;
    end

    assign b_out     = b_r[1];                               //always output b_r[1] and shift from higher index
    assign x1_out    = (count_r < 4'd12) ? x_r[5] :
                       (count_r < 4'd15) ? x_r[6] : 32'd0;
    assign x2_out    = (count_r > 4'd3) ? x_r[13] :
                       (count_r > 4'd0) ? x_r[12] : 32'd0;
    assign x3_out    = (count_r < 4'd8) ? x_r[9] :
                       (count_r != 4'd11 && count_r != 4'd15) ? x_r[10] : 32'd0;
    assign x4_out    = (count_r > 4'd7) ? x_r[9] :
                       (count_r != 4'd0 && count_r != 4'd4) ? x_r[8] : 32'd0;
    assign x5_out    = (count_r < 4'd4) ? x_r[13] :
                       (count_r != 4'd7 && count_r != 4'd11 && count_r != 4'd15) ? x_r[14] : 32'd0;
    assign x6_out    = (count_r > 4'd11) ? x_r[5] :
                       (count_r != 4'd8 && count_r != 4'd4 && count_r != 4'd0) ? x_r[4] : 32'd0;
    assign start_out = start_r;                              //To let GSIM know the out_valid can be pulled up

endmodule


/* ======== 說明 ========
以下的code是參考Exercise.pdf p.9 右下角的架構圖來完成的
不過我把他切成2個stage的pipeline，前後2個stage的critical path都差不多是連續4個32bit加法所要的時間
我自己測了幾個test pattern，答案是正確的(雖然不能百分百保證沒問題)，然後誤差也很小，看能不能達到rank A(不能就再改一下除法器)
 ================================*/

module Computation_Unit (clk, b, x_0, x_1, x_2, x_3, x_4, x_5, x_new); // compute the result in 2 cycles 
    input                clk;               // Compute : b + 13(x_0 + x_1) - 6(x_2 + x_3) + (x_4 + x_5)
    input signed  [31:0] b;                    
    input signed  [31:0] x_0, x_1, x_2, x_3, x_4, x_5;
    output signed [31:0] x_new;

    reg signed  [31:0] b_r;                    
    reg signed  [31:0] x_0_r, x_1_r, x_2_r, x_3_r, x_4_r, x_5_r;
    reg signed  [31:0] b_r_r;                    
    reg signed  [31:0] x_0_r_r, x_1_r_r, x_2_r_r, x_3_r_r, x_4_r_r, x_5_r_r;

    always @(posedge clk) begin
        b_r <= b;
        x_0_r <= x_0;
        x_1_r <= x_1;
        x_2_r <= x_2;
        x_3_r <= x_3;
        x_4_r <= x_4;
        x_5_r <= x_5;
        b_r_r <= b_r;
        x_0_r_r <= x_0_r;
        x_1_r_r <= x_1_r;
        x_2_r_r <= x_2_r;
        x_3_r_r <= x_3_r;
        x_4_r_r <= x_4_r;
        x_5_r_r <= x_5_r;
    end

    //================= Parameter Declaration ======================
    wire signed   [32:0] x_0_1, x_2_3, x_4_5, x_plus_b;
    wire signed   [33:0] x_2_3_mul2;
    wire signed   [34:0] x_0_1_mul4, x_2_3_mul4, x_2_3_mul6;
    wire signed   [35:0] x_0_1_mul8, x_0_1_mul13, x_sub_6;
    wire signed   [36:0] DFF_nxt;
    reg signed    [36:0] DFF;

    //===================== Combinational ==========================
    assign x_0_1 = x_0_r_r + x_1_r_r;
    assign x_2_3 = x_2_r_r + x_3_r_r;
    assign x_4_5 = x_4_r_r + x_5_r_r;
    assign x_plus_b = x_4_5 + b_r_r;
    assign x_0_1_mul4 = {x_0_1, 2'b0};
    assign x_0_1_mul8 = {x_0_1, 3'b0};
    assign x_0_1_mul13 = x_0_1 + x_0_1_mul4 + x_0_1_mul8;
    assign x_2_3_mul2 = {x_2_3, 1'b0};
    assign x_2_3_mul4 = {x_2_3, 2'b0};
    assign x_2_3_mul6 = x_2_3_mul2 + x_2_3_mul4;
    assign x_sub_6 = x_plus_b - x_2_3_mul6;
    assign DFF_nxt = x_0_1_mul13 + x_sub_6;

    division_20 div0 (.in(DFF), .out(x_new));

    //======================= Sequential ===========================
    always @(posedge clk) begin
        DFF <= DFF_nxt;
    end

endmodule

module division_20 (in, out);  // multiply by (2^-5 + 2^-6 + 2^-9 + 2^-10 + 2^-13 + 2^-14 + 2^-17 + 2^-18 
    input  signed [36:0] in;   //            + 2^-21 + 2^-22 + 2^-25 + 2^-26 + 2^-29 + 2^-30 + 2^-33 + 2^-34)
    output signed [31:0] out;

    wire signed [36:0] x_5, x_6, x_9, x_10, x_13, x_14, x_17, x_18, x_21, x_22, x_25, x_26, x_29, x_30, x_33, x_34;
    wire signed [36:0] x_5_6, x_9_10, x_13_14, x_17_18, x_21_22, x_25_26, x_29_30, x_33_34;
    wire signed [36:0] x_5to10, x_13to18, x_21to26, x_29to34, x_5to18, x_21to34, x_total;

    assign x_5 = in;
    assign x_6 = in >>> 1;
    assign x_9 = in >>> 4;
    assign x_10 = in >>> 5;
    assign x_13 = in >>> 8;
    assign x_14 = in >>> 9;
    assign x_17 = in >>> 12;
    assign x_18 = in >>> 13; 
    assign x_21 = in >>> 16;
    assign x_22 = in >>> 17;
    assign x_25 = in >>> 20;
    assign x_26 = in >>> 21;
    assign x_29 = in >>> 24;
    assign x_30 = in >>> 25;
    assign x_33 = in >>> 28;
    assign x_34 = in >>> 29;

    assign x_5_6 = x_5 + x_6;
    assign x_9_10 = x_9 + x_10;
    assign x_13_14 = x_13 + x_14;
    assign x_17_18 = x_17 + x_18;
    assign x_21_22 = x_21 + x_22;
    assign x_25_26 = x_25 + x_26;
    assign x_29_30 = x_29 + x_30;
    assign x_33_34 = x_33 + x_34;

    assign x_5to10 = x_5_6 + x_9_10;
    assign x_13to18 = x_13_14 + x_17_18;
    assign x_21to26 = x_21_22 + x_25_26;
    assign x_29to34 = x_29_30 + x_33_34;

    assign x_5to18 = x_5to10 + x_13to18;
    assign x_21to34 = x_21to26 + x_29to34;

    assign x_total = x_5to18 + x_21to34;
    assign out = x_total[36:5] + x_total[4];
endmodule
