// tb_led_blink.v - led_blink模块仿真测试文件

`timescale 1ns / 1ps

module tb_led_blink;

    // ========================================
    // 测试信号声明
    // ========================================
    reg         clk_100m;
    reg         rst;
    reg         failed;
    wire [15:0] led;
    wire        beep;

    // ========================================
    // 实例化被测模块
    // ========================================
    led_blink uut (
        .clk_100m(clk_100m),
        .rst(rst),
        .failed(failed),
        .led(led),
        .beep(beep)
    );

    // ========================================
    // 时钟生成：100MHz，周期10ns
    // ========================================
    initial begin
        clk_100m = 0;
        forever #1 clk_100m = ~clk_100m;
    end

    // ========================================
    // 测试激励
    // ========================================
    initial begin
        // 初始化
        rst = 1;
        failed = 0;
        
        #20;
        rst = 0;
        #20;

        // 测试1：failed=1，闪烁3秒
        #100;
        failed = 1;
        
        // 等待3秒（300M周期）
        repeat(300_000_000) @(posedge clk_100m);  // 缩小100万倍：300周期=3μs
        
        #100;
        failed = 0;
        
        // 等待观察复位
        repeat(10) @(posedge clk_100m);

        // 测试2：再次触发
        #100;
        failed = 1;
        repeat(300_000_000) @(posedge clk_100m);
        
        #100;
        failed = 0;
        repeat(10) @(posedge clk_100m);

        // 结束仿真
        #200;
        $finish;
    end

    // ========================================
    // 波形dump
    // ========================================
    initial begin
        $dumpfile("tb_led_blink.vcd");
        $dumpvars(0, tb_led_blink);
    end

endmodule
