`timescale 1ns / 1ps

module tb_debounce;

    parameter WIDTH = 4;
    parameter CNT_MAX = 20'd100;       // ? 改为100，约1μs @ 100MHz
    parameter CLK_PERIOD = 10;          // 100MHz = 10ns

    reg                 clk_100m;
    reg                 rst;
    reg  [WIDTH-1:0]    btn_raw;
    wire [WIDTH-1:0]    btn_deb;

    debounce #(
        .WIDTH(WIDTH),
        .CNT_MAX(CNT_MAX)               // ? 仿真用小值，综合时换回大值
    ) uut (
        .clk_100m(clk_100m),
        .rst(rst),
        .btn_raw(btn_raw),
        .btn_deb(btn_deb)
    );

    initial begin
        clk_100m = 0;
        forever #(CLK_PERIOD/2) clk_100m = ~clk_100m;
    end

    initial begin
        rst = 1;
        btn_raw = {WIDTH{1'b0}};

        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);

        // 测试1：正常按下
        $display("[%0t] Test1: 正常按下 btn[0]", $time);
        btn_raw[0] = 1;
        #(CLK_PERIOD * 200);              // ? 2μs 替代 10ms
        $display("[%0t] btn_deb = %b (期望 1)", $time, btn_deb);
        btn_raw[0] = 0;
        #(CLK_PERIOD * 200);
        $display("[%0t] btn_deb = %b (期望 0)", $time, btn_deb);

        // 测试2：按键抖动（应被过滤）
        $display("\n[%0t] Test2: 按键抖动", $time);
        btn_raw[1] = 1;
        #(CLK_PERIOD * 10); btn_raw[1] = 0;
        #(CLK_PERIOD * 10); btn_raw[1] = 1;
        #(CLK_PERIOD * 10); btn_raw[1] = 0;
        #(CLK_PERIOD * 10); btn_raw[1] = 1;
        #(CLK_PERIOD * 10); btn_raw[1] = 0;
        #(CLK_PERIOD * 200);               // 等消抖完成
        $display("[%0t] btn_deb[1] = %b (期望 0，抖动被过滤)", $time, btn_deb[1]);

        // 测试3：多按键同时按下
        $display("\n[%0t] Test3: 多按键同时按下", $time);
        btn_raw[2] = 1;
        btn_raw[3] = 1;
        #(CLK_PERIOD * 200);
        $display("[%0t] btn_deb = %b (期望 1100)", $time, btn_deb);
        btn_raw[2] = 0;
        #(CLK_PERIOD * 100);
        $display("[%0t] btn_deb = %b (期望 1000)", $time, btn_deb);
        btn_raw[3] = 0;
        #(CLK_PERIOD * 200);
        $display("[%0t] btn_deb = %b (期望 0000)", $time, btn_deb);

        // 测试4：消抖期间信号变化
        $display("\n[%0t] Test4: 消抖期间变化", $time);
        btn_raw[0] = 1;
        #(CLK_PERIOD * 50);                // 还没消抖完
        btn_raw[0] = 0;                    // 提前松开
        #(CLK_PERIOD * 100);
        $display("[%0t] btn_deb[0] = %b (期望 0，重新消抖)", $time, btn_deb[0]);

        #(CLK_PERIOD * 100);
        $display("\n[%0t] Simulation finished", $time);
        $finish;
    end

    initial begin
        $dumpfile("debounce.vcd");
        $dumpvars(0, tb_debounce);
    end

endmodule
