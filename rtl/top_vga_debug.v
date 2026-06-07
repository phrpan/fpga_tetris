`timescale 1ns / 1ps

module top_vga_debug (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,

    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTND,
    input  wire        BTNL,
    input  wire        BTNR,

    output wire [15:0] LED,

    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS
);

    wire clk_100m = CLK100MHZ;
    wire rst = ~CPU_RESETN;

    reg [1:0] pix_div;

    always @(posedge clk_100m) begin
        if (rst)
            pix_div <= 2'd0;
        else
            pix_div <= pix_div + 2'd1;
    end

    wire pix_clk = pix_div[1];

    reg [23:0] start_cnt;
    reg btn_start_pulse_auto;

    always @(posedge clk_100m) begin
        if (rst) begin
            start_cnt <= 24'd0;
            btn_start_pulse_auto <= 1'b0;
        end else begin
            if (start_cnt < 24'd1000)
                start_cnt <= start_cnt + 1'b1;

            btn_start_pulse_auto <= (start_cnt == 24'd500);
        end
    end

    reg btnl_d;
    reg btnr_d;
    reg btnu_d;
    reg btnc_d;

    always @(posedge clk_100m) begin
        if (rst) begin
            btnl_d <= 1'b0;
            btnr_d <= 1'b0;
            btnu_d <= 1'b0;
            btnc_d <= 1'b0;
        end else begin
            btnl_d <= BTNL;
            btnr_d <= BTNR;
            btnu_d <= BTNU;
            btnc_d <= BTNC;
        end
    end

    wire btn_left_pulse     = BTNL & ~btnl_d;
    wire btn_right_pulse    = BTNR & ~btnr_d;
    wire btn_rotate_pulse   = BTNU & ~btnu_d;
    wire btn_soft_drop_hold = BTND;
    wire btn_start_pulse    = btn_start_pulse_auto | (BTNC & ~btnc_d);

    wire [4:0]        board_query_row;
    wire [3:0]        board_query_col;
    wire [3:0]        board_cell_value;

    wire [2:0]        cur_piece_type;
    wire [1:0]        cur_piece_rot;
    wire signed [4:0] cur_piece_x;
    wire signed [5:0] cur_piece_y;

    wire [2:0]        next_piece_type;
    wire [15:0]       score;
    wire [7:0]        lines;
    wire [3:0]        level;
    wire [2:0]        game_state;

    game_core core_inst (
        .clk_100m           (clk_100m),
        .rst                (rst),

        .btn_left_pulse     (btn_left_pulse),
        .btn_right_pulse    (btn_right_pulse),
        .btn_rotate_pulse   (btn_rotate_pulse),
        .btn_soft_drop_hold (btn_soft_drop_hold),
        .btn_start_pulse    (btn_start_pulse),

        .board_query_row    (board_query_row),
        .board_query_col    (board_query_col),
        .board_cell_value   (board_cell_value),

        .cur_piece_type     (cur_piece_type),
        .cur_piece_rot      (cur_piece_rot),
        .cur_piece_x        (cur_piece_x),
        .cur_piece_y        (cur_piece_y),

        .next_piece_type    (next_piece_type),
        .score              (score),
        .lines              (lines),
        .level              (level),
        .game_state         (game_state)
    );

    tetris_video video_inst (
        .pix_clk            (pix_clk),
        .rst                (rst),

        .board_query_row    (board_query_row),
        .board_query_col    (board_query_col),
        .board_cell_value   (board_cell_value),

        .cur_piece_type     (cur_piece_type),
        .cur_piece_rot      (cur_piece_rot),
        .cur_piece_x        (cur_piece_x),
        .cur_piece_y        (cur_piece_y),

        .next_piece_type    (next_piece_type),
        .score              (score),
        .lines              (lines),
        .level              (level),
        .game_state         (game_state),

        .VGA_HS             (VGA_HS),
        .VGA_VS             (VGA_VS),
        .VGA_R              (VGA_R),
        .VGA_G              (VGA_G),
        .VGA_B              (VGA_B)
    );

    assign LED[2:0]   = game_state;
    assign LED[5:3]   = cur_piece_type;
    assign LED[9:6]   = cur_piece_x[3:0];
    assign LED[15:10] = cur_piece_y[5:0];

endmodule