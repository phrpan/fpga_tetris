// tb_display.v - display模块仿真测试文件

`timescale 1ns / 1ps

module tb_display;

    // ========================================
    // 测试信号声明
    // ========================================
    reg         clk;
    reg         rst;
    reg  [7:0]  score;
    reg  [7:0]  level;
    wire [7:0]  an;
    wire [6:0]  ca_g;

    // ========================================
    // 实例化被测模块
    // ========================================
    display uut (
        .clk_100m(clk),
        .rst(rst),
        .score(score),
        .level(level),
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
    // 测试激励
    // ========================================
    initial begin
        rst = 1;
        score = 8'd0;
        level = 8'd0;

        #20;
        rst = 0;
        #20;

        // 测试1：分数显示
        #100;
        score = 8'd42;
        level = 8'd0;
        repeat(8) @(posedge clk);

        // 测试2：等级显示
        #100;
        score = 8'd0;
        level = 8'd87;
        repeat(8) @(posedge clk);

        // 测试3：同时显示
        #100;
        score = 8'd42;
        level = 8'd87;
        repeat(12) @(posedge clk);

        // 测试4：边界值
        #100;
        score = 8'd99;
        level = 8'd99;
        repeat(8) @(posedge clk);

        // 测试5：动态变化
        #100;
        score = 8'd15;
        level = 8'd50;
        repeat(8) @(posedge clk);
        
        score = 8'd78;
        level = 8'd23;
        repeat(8) @(posedge clk);

        #200;
        $finish;
    end

    // ========================================
    // 波形 dump
    // ========================================
    initial begin
        $dumpfile("tb_display.vcd");
        $dumpvars(0, tb_display);
    end

endmodule
