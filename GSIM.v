`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
input   clk ;
input   reset ;
input   in_en;
output  out_valid;
input   [15:0]  b_in;
output  [31:0]  x_out;

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