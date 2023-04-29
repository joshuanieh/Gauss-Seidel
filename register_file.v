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
        else 
        if (delay_start_r == 1'b1) begin //shift and store x_in to x[14]
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
        delay_start_w = delay_start_r;
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
