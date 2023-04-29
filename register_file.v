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
    x6_out
);

    input           clk_in, rst_in, en_in;
    input  [16-1:0] b_in;
    input  [32-1:0] x_in;
    output [16-1:0] b_out;
    output [32-1:0] x1_out, x2_out, x3_out, x4_out, x5_out, x6_out;

    reg    [16-1:0] b_r[0:16-1];
    reg    [16-1:0] b_w[0:16-1];
    
    reg    [32-1:0] x_r[0:16-1];
    reg    [32-1:0] x_w[0:16-1];

    reg    [4-1:0] count_r;
    reg    [4-1:0] count_w;

    reg            start_r;
    reg            start_w;

    integer i;

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

    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            x_w[i] = x_r[i];
        end
        if (start_r == 1'b1) begin
            x_w[15] = x_in;
            for (i = 0; i < 16 - 1; i = i + 1) begin
                x_w[i] = x_r[i+1];
            end
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1) begin
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

    always @(*) begin
        count_w = count_r + 1;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (start_r == 1'b1 || en_in == 1'b1)
            count_r <= count_w;
        else
            count_r <= 4'd0;
    end

    assign b_out  = b_r[0];
    assign x1_out = (count_r == 4'd15) ? 32'd0 : x_r[1];
    assign x2_out = (count_r == 4'd0)  ? 32'd0 : x_r[15];
    assign x3_out = (count_r >= 4'd14) ? 32'd0 : x_r[2];
    assign x4_out = (count_r <= 4'd1)  ? 32'd0 : x_r[14];
    assign x5_out = (count_r >= 4'd13) ? 32'd0 : x_r[3];
    assign x6_out = (count_r <= 4'd2)  ? 32'd0 : x_r[13];

    always @(*) begin
        if (count_r == 4'd15)
            start_w = 1'd1;
        else
            start_w = start_r;
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in == 1'b1)
            start_r <= 1'b0;
        else
            start_r <= start_w;
    end

endmodule
