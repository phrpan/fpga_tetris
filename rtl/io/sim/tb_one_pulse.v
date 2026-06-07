`timescale 1ns / 1ps

module tb_one_pulse_debug;

    reg clk;
    reg rst;
    reg [4:0] sig_in;
    wire [4:0] pulse_out;

    // 实例化 one_pulse，假设你的模块长这样：
    // module one_pulse(input clk, input rst, input [4:0] sig_in, output reg [4:0] pulse_out);
    one_pulse  #(.WIDTH(5)) uut (
        .clk_100m(clk),
        .rst(rst),
        .sig_in(sig_in),
        .pulse_out(pulse_out)
    );

    // 时钟生成 100MHz = 10ns 周期
    initial clk = 0;
    always #5 clk = ~clk;

    // 复位
    initial begin
        rst = 1;
        sig_in = 5'b00000;
        #20 rst = 0;
    end

    // ========== 关键测试序列 ==========
    initial begin
        $display("==========================================");
        $display("  Test 1: 单bit上升沿 - bit0 0->1");
        $display("==========================================");
        #30 sig_in[0] = 1'b1;  // 只拉高 bit0
        #20 sig_in[0] = 1'b0;
        #50;

        $display("==========================================");
        $display("  Test 2: 多bit同时上升沿");
        $display("==========================================");
        #30 sig_in = 5'b11111;  // 全部拉高
        #20 sig_in = 5'b00000;
        #50;

        $display("==========================================");
        $display("  Test 3: 逐bit上升沿 - 模拟真实按键");
        $display("==========================================");
        #30 sig_in = 5'b00001;  // BTNL
        #20 sig_in = 5'b00000;
        #30 sig_in = 5'b00010;  // BTNR
        #20 sig_in = 5'b00000;
        #30 sig_in = 5'b00100;  // BTND
        #20 sig_in = 5'b00000;
        #30 sig_in = 5'b01000;  // BTNU
        #20 sig_in = 5'b00000;
        #30 sig_in = 5'b10000;  // BTNC
        #20 sig_in = 5'b00000;
        #50;

        $display("==========================================");
        $display("  Test 4: 按住不放 - 应该只出一次脉冲");
        $display("==========================================");
        #30 sig_in = 5'b00001;  // 按住 BTNL
        #500 sig_in = 5'b00001;  // 保持 500ns（50个时钟）
        #20 sig_in = 5'b00000;  // 松开
        #100;

        $display("==========================================");
        $display("  Test 5: 快速连按 - 每个时钟都按");
        $display("==========================================");
        #30 sig_in = 5'b00001;
        #10 sig_in = 5'b00000;
        #10 sig_in = 5'b00001;
        #10 sig_in = 5'b00000;
        #10 sig_in = 5'b00001;
        #10 sig_in = 5'b00000;
        #50;

        $display("==========================================");
        $display("  Simulation Finished");
        $display("==========================================");
        $finish;
    end

    // 实时监控
    always @(posedge clk) begin
        $display("[%0t] rst=%b sig_in=%b pulse_out=%b", 
                 $time, rst, sig_in, pulse_out);
    end

    // 波形 dump
    initial begin
        $dumpfile("tb_one_pulse_debug.vcd");
        $dumpvars(0, tb_one_pulse_debug);
    end

endmodule
