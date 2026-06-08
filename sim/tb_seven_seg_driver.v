// seven_seg_driver_tb.v - 七段数码管驱动模块仿真测试

`timescale 1ns / 1ps

module tb_seven_seg_driver;

    // ========================================
    // 测试信号定义
    // ========================================
    reg         clk;
    reg         rst;
    reg  [3:0]  digit_value;   // 0~9, 10=L, 11=S
    reg  [2:0]  digit_sel;     // 0~7
    wire [7:0]  an;
    wire [6:0]  ca_g;

    // ========================================
    // 实例化被测模块
    // ========================================
    seven_seg_driver uut (
        .clk(clk),
        .rst(rst),
        .digit_value(digit_value),
        .digit_sel(digit_sel),
        .an(an),
        .ca_g(ca_g)
    );

    // ========================================
    // 时钟生成：100MHz，周期10ns
    // ========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ========================================
    // 波形文件
    // ========================================
    initial begin
        $dumpfile("seven_seg_driver.vcd");
        $dumpvars(0, seven_seg_driver_tb);
    end

    // ========================================
    // 刺激信号
    // ========================================
    initial begin
        // 复位
        rst = 1;
        digit_value = 4'd0;
        digit_sel = 3'd0;
        #30;

        // 释放复位
        rst = 0;
        #10;

        // 数字 0~9 遍历
        for (integer i = 0; i < 10; i = i + 1) begin
            digit_value = i;
            digit_sel = 3'd0;
            #40;
        end

        // 字母 L(10) 和 S(11)
        digit_value = 4'd10;
        digit_sel = 3'd0;
        #40;

        digit_value = 4'd11;
        digit_sel = 3'd0;
        #40;

        // 位选 0~7 遍历（显示数字5）
        digit_value = 4'd5;
        for (integer sel = 0; sel < 8; sel = sel + 1) begin
            digit_sel = sel;
            #40;
        end

        // 超出范围 12~15
        for (integer i = 12; i < 16; i = i + 1) begin
            digit_value = i;
            digit_sel = 3'd0;
            #40;
        end

        // 动态切换
        digit_value = 4'd1;  digit_sel = 3'd0; #40;
        digit_value = 4'd2;  digit_sel = 3'd1; #40;
        digit_value = 4'd3;  digit_sel = 3'd2; #40;
        digit_value = 4'd10; digit_sel = 3'd3; #40;
        digit_value = 4'd11; digit_sel = 3'd4; #40;

        #100;
        $finish;
    end

endmodule