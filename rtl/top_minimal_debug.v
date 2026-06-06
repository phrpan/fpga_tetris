`timescale 1ns / 1ps

module top_minimal_debug (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTND,
    input  wire        BTNL,
    input  wire        BTNR,
    output wire [15:0] LED
);

wire clk_100m;
wire rst;

reg btnc_meta;
reg btnc_sync;
reg btnc_sync_d;
reg btnu_meta;
reg btnu_sync;
reg btnu_sync_d;
reg btnl_meta;
reg btnl_sync;
reg btnl_sync_d;
reg btnr_meta;
reg btnr_sync;
reg btnr_sync_d;
reg btnd_meta;
reg btnd_sync;

wire btn_start_pulse;
wire btn_left_pulse;
wire btn_right_pulse;
wire btn_rotate_pulse;
wire btn_soft_drop_hold;

wire [3:0] board_cell_value;
wire [2:0] cur_piece_type;
wire [1:0] cur_piece_rot;
wire signed [4:0] cur_piece_x;
wire signed [5:0] cur_piece_y;
wire [2:0] next_piece_type;
wire [15:0] score;
wire [7:0] lines;
wire [3:0] level;
wire [2:0] game_state;

assign clk_100m = CLK100MHZ;
assign rst = ~CPU_RESETN;

always @(posedge clk_100m) begin
    if (rst) begin
        btnc_meta <= 1'b0;
        btnc_sync <= 1'b0;
        btnc_sync_d <= 1'b0;
        btnu_meta <= 1'b0;
        btnu_sync <= 1'b0;
        btnu_sync_d <= 1'b0;
        btnl_meta <= 1'b0;
        btnl_sync <= 1'b0;
        btnl_sync_d <= 1'b0;
        btnr_meta <= 1'b0;
        btnr_sync <= 1'b0;
        btnr_sync_d <= 1'b0;
        btnd_meta <= 1'b0;
        btnd_sync <= 1'b0;
    end else begin
        btnc_meta <= BTNC;
        btnc_sync <= btnc_meta;
        btnc_sync_d <= btnc_sync;

        btnu_meta <= BTNU;
        btnu_sync <= btnu_meta;
        btnu_sync_d <= btnu_sync;

        btnl_meta <= BTNL;
        btnl_sync <= btnl_meta;
        btnl_sync_d <= btnl_sync;

        btnr_meta <= BTNR;
        btnr_sync <= btnr_meta;
        btnr_sync_d <= btnr_sync;

        btnd_meta <= BTND;
        btnd_sync <= btnd_meta;
    end
end

assign btn_start_pulse = btnc_sync & ~btnc_sync_d;
assign btn_rotate_pulse = btnu_sync & ~btnu_sync_d;
assign btn_left_pulse = btnl_sync & ~btnl_sync_d;
assign btn_right_pulse = btnr_sync & ~btnr_sync_d;
assign btn_soft_drop_hold = btnd_sync;

game_core game_core_inst (
    .clk_100m(clk_100m),
    .rst(rst),
    .btn_left_pulse(btn_left_pulse),
    .btn_right_pulse(btn_right_pulse),
    .btn_rotate_pulse(btn_rotate_pulse),
    .btn_soft_drop_hold(btn_soft_drop_hold),
    .btn_start_pulse(btn_start_pulse),
    .board_query_row(5'd19),
    .board_query_col(4'd0),
    .board_cell_value(board_cell_value),
    .cur_piece_type(cur_piece_type),
    .cur_piece_rot(cur_piece_rot),
    .cur_piece_x(cur_piece_x),
    .cur_piece_y(cur_piece_y),
    .next_piece_type(next_piece_type),
    .score(score),
    .lines(lines),
    .level(level),
    .game_state(game_state)
);

assign LED[2:0]   = game_state;
assign LED[4:3]   = cur_piece_rot;
assign LED[9:5]   = cur_piece_x[4:0];
assign LED[13:10] = level;
assign LED[15:14] = board_cell_value[1:0];

endmodule
