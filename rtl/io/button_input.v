// button_input.v - 板载按键/开关 → 统一游戏动作接口
// Day 1 版本：支持左移、右移、旋转、开始/硬降、暂停

`timescale 1ns / 1ps

module button_input (
    input  wire        clk_100m,
    input  wire        rst,          // 高有效

    // 板载按键（高有效：按下=1）
    input  wire        btnc,         // 开始 / 硬降（由状态区分）
    input  wire        btnu,         // 旋转
    input  wire        btnd,         // 软降
    input  wire        btnl,         // 左移
    input  wire        btnr,         // 右移

    // 板载开关（高有效：ON=1）
    input  wire [1:0]  sw,           // SW0=暂停, SW1=Hold（Day1暂不用）

    // ===== 游戏动作输出 =====
    output reg         btn_left_pulse,
    output reg         btn_right_pulse,
    output reg         btn_rotate_pulse,
    output reg         btn_soft_drop_hold,
    output reg         btn_hard_drop_pulse,
    output reg         btn_start_pulse,
    output reg         btn_pause_pulse,
    output reg         btn_reset_pulse
);

    // ===== 内部消抖信号 =====
    wire btnc_db, btnu_db, btnd_db, btnl_db, btnr_db;
    wire sw0_db, sw1_db;

    // ===== 消抖实例 =====
    debounce #(.WIDTH(5)) u_deb_btn (
        .clk_100m (clk_100m),
        .rst      (rst),
        .btn_raw  ({btnr, btnl, btnd, btnu, btnc}),
        .btn_deb  ({btnr_db, btnl_db, btnd_db, btnu_db, btnc_db})
    );

    debounce #(.WIDTH(2)) u_deb_sw (
        .clk_100m (clk_100m),
        .rst      (rst),
        .btn_raw  (sw),
        .btn_deb  ({sw1_db, sw0_db})
    );

    // ===== 边沿检测 =====
    wire btnc_p, btnu_p, btnd_p, btnl_p, btnr_p;
    wire sw0_p, sw1_p;

    one_pulse #(.WIDTH(5)) u_pulse_btn (
        .clk_100m (clk_100m),
        .rst      (rst),
        .sig_in   ({btnr_db, btnl_db, btnd_db, btnu_db, btnc_db}),
        .pulse_out({btnr_p, btnl_p, btnd_p, btnu_p, btnc_p})
    );

    one_pulse #(.WIDTH(2)) u_pulse_sw (
        .clk_100m (clk_100m),
        .rst      (rst),
        .sig_in   ({sw1_db, sw0_db}),
        .pulse_out({sw1_p, sw0_p})
    );

    // ===== 动作输出逻辑 =====
    always @(posedge clk_100m) begin
        if (rst) begin
            btn_left_pulse      <= 1'b0;
            btn_right_pulse     <= 1'b0;
            btn_rotate_pulse    <= 1'b0;
            btn_soft_drop_hold  <= 1'b0;
            btn_hard_drop_pulse <= 1'b0;
            btn_start_pulse     <= 1'b0;
            btn_pause_pulse     <= 1'b0;
            btn_reset_pulse     <= 1'b0;
        end else begin
            // 左移 — BTNL
            btn_left_pulse <= btnl_p;

            // 右移 — BTNR
            btn_right_pulse <= btnr_p;

            // 旋转 — BTNU
            btn_rotate_pulse <= btnu_p;

            // 软降（按住电平）— BTND
            btn_soft_drop_hold <= btnd_db;

            // 硬降 — BTNC（在游戏核心中由状态区分是开始还是硬降）
            btn_hard_drop_pulse <= btnc_p;

            // 开始 — BTNC 上升沿（在游戏核心中由 GS_TITLE 状态过滤）
            btn_start_pulse <= btnc_p;

            // 暂停 — SW0
            btn_pause_pulse <= sw0_p;

            // 复位 — 全局复位信号在顶层转换
            btn_reset_pulse <= 1'b0;  // Day1 不用 CPU_RESETN 作为游戏复位
        end
    end

endmodule
