// button_input.v - board buttons to game_core action signals

`timescale 1ns / 1ps

module button_input #(
    parameter DEBOUNCE_TICKS = 20'd999_999
)(
    input  wire clk_100m,
    input  wire rst,

    input  wire btnc,
    input  wire btnu,
    input  wire btnd,
    input  wire btnl,
    input  wire btnr,

    output wire btn_start_pulse,
    output wire btn_left_pulse,
    output wire btn_right_pulse,
    output wire btn_rotate_pulse,
    output wire btn_soft_drop_hold
);

    wire btnc_db;
    wire btnu_db;
    wire btnd_db;
    wire btnl_db;
    wire btnr_db;

    wire btnc_pulse;
    wire btnu_pulse;
    wire btnl_pulse;
    wire btnr_pulse;

    debounce #(
        .WIDTH(5),
        .CNT_MAX(DEBOUNCE_TICKS)
    ) u_debounce_buttons (
        .clk_100m(clk_100m),
        .rst(rst),
        .btn_raw({btnr, btnl, btnd, btnu, btnc}),
        .btn_deb({btnr_db, btnl_db, btnd_db, btnu_db, btnc_db})
    );

    one_pulse #(
        .WIDTH(4)
    ) u_one_pulse_actions (
        .clk_100m(clk_100m),
        .rst(rst),
        .sig_in({btnr_db, btnl_db, btnu_db, btnc_db}),
        .pulse_out({btnr_pulse, btnl_pulse, btnu_pulse, btnc_pulse})
    );

    assign btn_start_pulse = btnc_pulse;
    assign btn_left_pulse = btnl_pulse;
    assign btn_right_pulse = btnr_pulse;
    assign btn_rotate_pulse = btnu_pulse;
    assign btn_soft_drop_hold = btnd_db;

endmodule
