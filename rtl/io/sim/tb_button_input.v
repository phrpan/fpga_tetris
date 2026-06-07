`timescale 1ns / 1ps

module tb_button_input;

    reg         clk_100m;
    reg         rst;
    reg         btnc, btnu, btnd, btnl, btnr;
    reg  [1:0]  sw;

    wire        btn_left_pulse;
    wire        btn_right_pulse;
    wire        btn_rotate_pulse;
    wire        btn_soft_drop_hold;
    wire        btn_hard_drop_pulse;
    wire        btn_start_pulse;
    wire        btn_pause_pulse;
    wire        btn_reset_pulse;

    // 实例化
    button_input uut (
        .clk_100m        (clk_100m),
        .rst             (rst),
        .btnc            (btnc),
        .btnu            (btnu),
        .btnd            (btnd),
        .btnl            (btnl),
        .btnr            (btnr),
        .sw              (sw),
        .btn_left_pulse  (btn_left_pulse),
        .btn_right_pulse (btn_right_pulse),
        .btn_rotate_pulse(btn_rotate_pulse),
        .btn_soft_drop_hold(btn_soft_drop_hold),
        .btn_hard_drop_pulse(btn_hard_drop_pulse),
        .btn_start_pulse (btn_start_pulse),
        .btn_pause_pulse (btn_pause_pulse),
        .btn_reset_pulse (btn_reset_pulse)
    );

    // 100MHz 时钟
    initial begin
        clk_100m = 0;
        forever #5 clk_100m = ~clk_100m;
    end

    // 测试向量
    initial begin
        rst = 1; btnc=0; btnu=0; btnd=0; btnl=0; btnr=0; sw=0;
        #100 rst = 0;

        // 测试左移（按下 11ms，确保超过消抖时间）
        #200 btnl = 1;
        #11_000_000 btnl = 0;  // ? 11ms
        #100;

        // 测试右移
        #200 btnr = 1;
        #11_000_000 btnr = 0;  // ? 11ms
        #100;

        // 测试旋转
        #200 btnu = 1;
        #11_000_000 btnu = 0;  // ? 11ms
        #100;

        // 测试软降（hold 电平，保持不松开）
        #200 btnd = 1;
        #11_000_000;           // ? 按住 11ms，不松开

        // 测试开始 + 硬降（快速双击，本身就是脉冲）
        #200 btnc = 1;
        #20 btnc = 0;
        #500 btnc = 1;
        #20 btnc = 0;

        // 测试暂停（长按）
        #200 sw[0] = 1;
        #11_000_000 sw[0] = 0;  // ? 11ms

        #1000 $finish;
    end

    // 波形监控
    initial begin
        $dumpfile("tb_button_input.vcd");
        $dumpvars(0, tb_button_input);
    end

endmodule
