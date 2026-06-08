`timescale 1ns / 1ps

module tetris_video (
    input  wire              pix_clk,
    input  wire              rst,

    output wire [4:0]        board_query_row,
    output wire [3:0]        board_query_col,
    input  wire [3:0]        board_cell_value,

    input  wire [2:0]        cur_piece_type,
    input  wire [1:0]        cur_piece_rot,
    input  wire signed [4:0] cur_piece_x,
    input  wire signed [5:0] cur_piece_y,

    input  wire [2:0]        next_piece_type,
    input  wire [15:0]       score,
    input  wire [7:0]        lines,
    input  wire [3:0]        level,
    input  wire [2:0]        game_state,

    output wire              VGA_HS,
    output wire              VGA_VS,
    output wire [3:0]        VGA_R,
    output wire [3:0]        VGA_G,
    output wire [3:0]        VGA_B
);

`include "../common/game_defs.vh"

    localparam CELL_SIZE = 20;
    localparam BOARD_X0  = 220;
    localparam BOARD_Y0  = 40;

    localparam BOARD_W = BOARD_COLS * CELL_SIZE;
    localparam BOARD_H = BOARD_ROWS * CELL_SIZE;

    // Simple UI layout
    localparam TITLE_X0 = 0;
    localparam TITLE_Y0 = 0;
    localparam TITLE_X1 = 640;
    localparam TITLE_Y1 = 36;

    localparam NEXT_X0 = 40;
    localparam NEXT_Y0 = 80;
    localparam NEXT_W  = 130;
    localparam NEXT_H  = 130;

    localparam INFO_X0 = 455;
    localparam INFO_Y0 = 80;
    localparam INFO_W  = 145;
    localparam INFO_H  = 230;

    localparam HELP_X0 = 40;
    localparam HELP_Y0 = 455;
    localparam HELP_W  = 560;
    localparam HELP_H  = 18;

    localparam GAMEOVER_X0 = 170;
    localparam GAMEOVER_Y0 = 170;
    localparam GAMEOVER_W  = 300;
    localparam GAMEOVER_H  = 130;

    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    vga_timing timing_inst (
        .pix_clk  (pix_clk),
        .rst      (rst),
        .hsync    (VGA_HS),
        .vsync    (VGA_VS),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    // ------------------------------------------------------------
    // Board area
    // ------------------------------------------------------------
    wire in_board_area;

    assign in_board_area =
        (pixel_x >= BOARD_X0) &&
        (pixel_x <  BOARD_X0 + BOARD_W) &&
        (pixel_y >= BOARD_Y0) &&
        (pixel_y <  BOARD_Y0 + BOARD_H);

    wire [9:0] board_local_x;
    wire [9:0] board_local_y;

    assign board_local_x = pixel_x - BOARD_X0;
    assign board_local_y = pixel_y - BOARD_Y0;

    assign board_query_col = in_board_area ? (board_local_x / CELL_SIZE) : 4'd0;
    assign board_query_row = in_board_area ? (board_local_y / CELL_SIZE) : 5'd0;

    wire [3:0] cur_col;
    wire [4:0] cur_row;

    assign cur_col = board_query_col;
    assign cur_row = board_query_row;

    wire grid_line;

    assign grid_line =
        in_board_area &&
        (
            (board_local_x % CELL_SIZE == 0) ||
            (board_local_y % CELL_SIZE == 0) ||
            (board_local_x % CELL_SIZE == CELL_SIZE - 1) ||
            (board_local_y % CELL_SIZE == CELL_SIZE - 1)
        );

    wire board_border;

    assign board_border =
        (
            (pixel_x >= BOARD_X0 - 3) &&
            (pixel_x <  BOARD_X0 + BOARD_W + 3) &&
            (pixel_y >= BOARD_Y0 - 3) &&
            (pixel_y <  BOARD_Y0 + BOARD_H + 3)
        ) &&
        !in_board_area;

    // ------------------------------------------------------------
    // UI regions
    // ------------------------------------------------------------
    wire in_title_bar;
    wire in_next_box;
    wire in_info_box;
    wire in_help_bar;
    wire in_gameover_panel;

    assign in_title_bar =
        (pixel_x >= TITLE_X0) &&
        (pixel_x <  TITLE_X1) &&
        (pixel_y >= TITLE_Y0) &&
        (pixel_y <  TITLE_Y1);

    assign in_next_box =
        (pixel_x >= NEXT_X0) &&
        (pixel_x <  NEXT_X0 + NEXT_W) &&
        (pixel_y >= NEXT_Y0) &&
        (pixel_y <  NEXT_Y0 + NEXT_H);

    assign in_info_box =
        (pixel_x >= INFO_X0) &&
        (pixel_x <  INFO_X0 + INFO_W) &&
        (pixel_y >= INFO_Y0) &&
        (pixel_y <  INFO_Y0 + INFO_H);

    assign in_help_bar =
        (pixel_x >= HELP_X0) &&
        (pixel_x <  HELP_X0 + HELP_W) &&
        (pixel_y >= HELP_Y0) &&
        (pixel_y <  HELP_Y0 + HELP_H);

    assign in_gameover_panel =
        (pixel_x >= GAMEOVER_X0) &&
        (pixel_x <  GAMEOVER_X0 + GAMEOVER_W) &&
        (pixel_y >= GAMEOVER_Y0) &&
        (pixel_y <  GAMEOVER_Y0 + GAMEOVER_H);

    wire next_box_border;
    wire info_box_border;
    wire help_bar_border;
    wire gameover_border;

    assign next_box_border =
        in_next_box &&
        (
            (pixel_x == NEXT_X0) ||
            (pixel_x == NEXT_X0 + NEXT_W - 1) ||
            (pixel_y == NEXT_Y0) ||
            (pixel_y == NEXT_Y0 + NEXT_H - 1)
        );

    assign info_box_border =
        in_info_box &&
        (
            (pixel_x == INFO_X0) ||
            (pixel_x == INFO_X0 + INFO_W - 1) ||
            (pixel_y == INFO_Y0) ||
            (pixel_y == INFO_Y0 + INFO_H - 1)
        );

    assign help_bar_border =
        in_help_bar &&
        (
            (pixel_x == HELP_X0) ||
            (pixel_x == HELP_X0 + HELP_W - 1) ||
            (pixel_y == HELP_Y0) ||
            (pixel_y == HELP_Y0 + HELP_H - 1)
        );

    assign gameover_border =
        in_gameover_panel &&
        (
            (pixel_x == GAMEOVER_X0) ||
            (pixel_x == GAMEOVER_X0 + GAMEOVER_W - 1) ||
            (pixel_y == GAMEOVER_Y0) ||
            (pixel_y == GAMEOVER_Y0 + GAMEOVER_H - 1)
        );

    // right info box separators: score / level / lines regions
    wire info_sep_line;

    assign info_sep_line =
        in_info_box &&
        (
            (pixel_y == INFO_Y0 + 70) ||
            (pixel_y == INFO_Y0 + 140)
        );

   
    // ------------------------------------------------------------
    // Current active piece
    // ------------------------------------------------------------
    wire [1:0] dx0;
    wire [1:0] dy0;
    wire [1:0] dx1;
    wire [1:0] dy1;
    wire [1:0] dx2;
    wire [1:0] dy2;
    wire [1:0] dx3;
    wire [1:0] dy3;

    piece_rom piece0 (
        .piece_type (cur_piece_type),
        .rotation   (cur_piece_rot),
        .block_idx  (2'd0),
        .dx         (dx0),
        .dy         (dy0)
    );

    piece_rom piece1 (
        .piece_type (cur_piece_type),
        .rotation   (cur_piece_rot),
        .block_idx  (2'd1),
        .dx         (dx1),
        .dy         (dy1)
    );

    piece_rom piece2 (
        .piece_type (cur_piece_type),
        .rotation   (cur_piece_rot),
        .block_idx  (2'd2),
        .dx         (dx2),
        .dy         (dy2)
    );

    piece_rom piece3 (
        .piece_type (cur_piece_type),
        .rotation   (cur_piece_rot),
        .block_idx  (2'd3),
        .dx         (dx3),
        .dy         (dy3)
    );

    wire signed [5:0] active_x0;
    wire signed [5:0] active_x1;
    wire signed [5:0] active_x2;
    wire signed [5:0] active_x3;

    wire signed [6:0] active_y0;
    wire signed [6:0] active_y1;
    wire signed [6:0] active_y2;
    wire signed [6:0] active_y3;

    assign active_x0 = cur_piece_x + {4'b0000, dx0};
    assign active_x1 = cur_piece_x + {4'b0000, dx1};
    assign active_x2 = cur_piece_x + {4'b0000, dx2};
    assign active_x3 = cur_piece_x + {4'b0000, dx3};

    assign active_y0 = cur_piece_y + {5'b00000, dy0};
    assign active_y1 = cur_piece_y + {5'b00000, dy1};
    assign active_y2 = cur_piece_y + {5'b00000, dy2};
    assign active_y3 = cur_piece_y + {5'b00000, dy3};

    wire pixel_is_active_piece;

    assign pixel_is_active_piece =
        in_board_area &&
        (
            ((active_x0 == cur_col) && (active_y0 == cur_row)) ||
            ((active_x1 == cur_col) && (active_y1 == cur_row)) ||
            ((active_x2 == cur_col) && (active_y2 == cur_row)) ||
            ((active_x3 == cur_col) && (active_y3 == cur_row))
        );

    wire show_active_piece;

    assign show_active_piece =
        pixel_is_active_piece &&
        (
            (game_state == GS_SPAWN) ||
            (game_state == GS_PLAY)  ||
            (game_state == GS_PAUSE) ||
            (game_state == GS_LOCK)
        );

    // ------------------------------------------------------------
    // Next piece preview, simple version
    // ------------------------------------------------------------
    localparam NEXT_CELL = 16;
    localparam NEXT_PX0  = 72;
    localparam NEXT_PY0  = 118;

    wire [1:0] ndx0;
    wire [1:0] ndy0;
    wire [1:0] ndx1;
    wire [1:0] ndy1;
    wire [1:0] ndx2;
    wire [1:0] ndy2;
    wire [1:0] ndx3;
    wire [1:0] ndy3;

    piece_rom next0 (
        .piece_type (next_piece_type),
        .rotation   (2'd0),
        .block_idx  (2'd0),
        .dx         (ndx0),
        .dy         (ndy0)
    );

    piece_rom next1 (
        .piece_type (next_piece_type),
        .rotation   (2'd0),
        .block_idx  (2'd1),
        .dx         (ndx1),
        .dy         (ndy1)
    );

    piece_rom next2 (
        .piece_type (next_piece_type),
        .rotation   (2'd0),
        .block_idx  (2'd2),
        .dx         (ndx2),
        .dy         (ndy2)
    );

    piece_rom next3 (
        .piece_type (next_piece_type),
        .rotation   (2'd0),
        .block_idx  (2'd3),
        .dx         (ndx3),
        .dy         (ndy3)
    );

    wire next0_on;
    wire next1_on;
    wire next2_on;
    wire next3_on;

    assign next0_on =
        (pixel_x >= NEXT_PX0 + ndx0 * NEXT_CELL) &&
        (pixel_x <  NEXT_PX0 + (ndx0 + 1'b1) * NEXT_CELL) &&
        (pixel_y >= NEXT_PY0 + ndy0 * NEXT_CELL) &&
        (pixel_y <  NEXT_PY0 + (ndy0 + 1'b1) * NEXT_CELL);

    assign next1_on =
        (pixel_x >= NEXT_PX0 + ndx1 * NEXT_CELL) &&
        (pixel_x <  NEXT_PX0 + (ndx1 + 1'b1) * NEXT_CELL) &&
        (pixel_y >= NEXT_PY0 + ndy1 * NEXT_CELL) &&
        (pixel_y <  NEXT_PY0 + (ndy1 + 1'b1) * NEXT_CELL);

    assign next2_on =
        (pixel_x >= NEXT_PX0 + ndx2 * NEXT_CELL) &&
        (pixel_x <  NEXT_PX0 + (ndx2 + 1'b1) * NEXT_CELL) &&
        (pixel_y >= NEXT_PY0 + ndy2 * NEXT_CELL) &&
        (pixel_y <  NEXT_PY0 + (ndy2 + 1'b1) * NEXT_CELL);

    assign next3_on =
        (pixel_x >= NEXT_PX0 + ndx3 * NEXT_CELL) &&
        (pixel_x <  NEXT_PX0 + (ndx3 + 1'b1) * NEXT_CELL) &&
        (pixel_y >= NEXT_PY0 + ndy3 * NEXT_CELL) &&
        (pixel_y <  NEXT_PY0 + (ndy3 + 1'b1) * NEXT_CELL);

    wire pixel_is_next_piece;
    assign pixel_is_next_piece = next0_on || next1_on || next2_on || next3_on;


    // ------------------------------------------------------------
    // Decimal number display for SCORE / LEVEL / LINES
    // ------------------------------------------------------------

    wire [19:0] score_bcd;
    wire [19:0] lines_bcd;
    wire [19:0] level_bcd;

    bin16_to_bcd score_bcd_inst (
        .bin(score),
        .bcd(score_bcd)
    );

    bin16_to_bcd lines_bcd_inst (
        .bin({8'd0, lines}),
        .bcd(lines_bcd)
    );

    bin16_to_bcd level_bcd_inst (
        .bin({12'd0, level}),
        .bcd(level_bcd)
    );

    wire score_d0_on;
    wire score_d1_on;
    wire score_d2_on;
    wire score_d3_on;
    wire score_d4_on;

    wire level_d0_on;
    wire level_d1_on;

    wire lines_d0_on;
    wire lines_d1_on;
    wire lines_d2_on;

    vga_digit7seg #(.X0(INFO_X0 + 15),  .Y0(INFO_Y0 + 25)) score_digit0 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(score_bcd[19:16]),
        .digit_on(score_d0_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 38),  .Y0(INFO_Y0 + 25)) score_digit1 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(score_bcd[15:12]),
        .digit_on(score_d1_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 61),  .Y0(INFO_Y0 + 25)) score_digit2 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(score_bcd[11:8]),
        .digit_on(score_d2_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 84),  .Y0(INFO_Y0 + 25)) score_digit3 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(score_bcd[7:4]),
        .digit_on(score_d3_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 107), .Y0(INFO_Y0 + 25)) score_digit4 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(score_bcd[3:0]),
        .digit_on(score_d4_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 45), .Y0(INFO_Y0 + 95)) level_digit0 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(level_bcd[7:4]),
        .digit_on(level_d0_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 70), .Y0(INFO_Y0 + 95)) level_digit1 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(level_bcd[3:0]),
        .digit_on(level_d1_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 35), .Y0(INFO_Y0 + 165)) lines_digit0 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(lines_bcd[11:8]),
        .digit_on(lines_d0_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 60), .Y0(INFO_Y0 + 165)) lines_digit1 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(lines_bcd[7:4]),
        .digit_on(lines_d1_on)
    );

    vga_digit7seg #(.X0(INFO_X0 + 85), .Y0(INFO_Y0 + 165)) lines_digit2 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .digit(lines_bcd[3:0]),
        .digit_on(lines_d2_on)
    );

    wire score_digits_on;
    wire level_digits_on;
    wire lines_digits_on;

    assign score_digits_on =
        score_d0_on || score_d1_on || score_d2_on ||
        score_d3_on || score_d4_on;

    assign level_digits_on =
        level_d0_on || level_d1_on;

    assign lines_digits_on =
        lines_d0_on || lines_d1_on || lines_d2_on;
    

        // ------------------------------------------------------------
    // Text labels
    // ------------------------------------------------------------

    wire title_label_on;
    wire next_label_on;
    wire score_label_on;
    wire level_label_on;
    wire lines_label_on;
    wire gameover_label_on;
    wire press_c_label_on;

    // Top title: FPGA TETRIS
    vga_text_label #(
        .LABEL_ID(6),
        .CHAR_COUNT(11),
        .X0(246),
        .Y0(10),
        .SCALE(2)
    ) label_title (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(title_label_on)
    );

    // NEXT label
    vga_text_label #(
        .LABEL_ID(0),
        .CHAR_COUNT(4),
        .X0(NEXT_X0 + 43),
        .Y0(NEXT_Y0 + 12),
        .SCALE(2)
    ) label_next (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(next_label_on)
    );

    // SCORE label
    vga_text_label #(
        .LABEL_ID(1),
        .CHAR_COUNT(5),
        .X0(INFO_X0 + 42),
        .Y0(INFO_Y0 + 8),
        .SCALE(2)
    ) label_score (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(score_label_on)
    );

    // LEVEL label
    vga_text_label #(
        .LABEL_ID(2),
        .CHAR_COUNT(5),
        .X0(INFO_X0 + 42),
        .Y0(INFO_Y0 + 78),
        .SCALE(2)
    ) label_level (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(level_label_on)
    );

    // LINES label
    vga_text_label #(
        .LABEL_ID(3),
        .CHAR_COUNT(5),
        .X0(INFO_X0 + 42),
        .Y0(INFO_Y0 + 148),
        .SCALE(2)
    ) label_lines (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(lines_label_on)
    );

    // GAME OVER text
    vga_text_label #(
        .LABEL_ID(4),
        .CHAR_COUNT(9),
        .X0(238),
        .Y0(205),
        .SCALE(3)
    ) label_gameover (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(gameover_label_on)
    );

    // PRESS C text
    vga_text_label #(
        .LABEL_ID(5),
        .CHAR_COUNT(7),
        .X0(250),
        .Y0(240),
        .SCALE(2)
    ) label_press_c (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .text_on(press_c_label_on)
    );
    // ------------------------------------------------------------
    // Color mapping
    // ------------------------------------------------------------
    reg [3:0] active_cell;
    reg [3:0] next_cell;
    reg [11:0] active_color;
    reg [11:0] next_color;
    reg [11:0] board_color;
    reg [11:0] rgb;

    always @* begin
        case (cur_piece_type)
            PIECE_I: active_cell = CELL_I;
            PIECE_O: active_cell = CELL_O;
            PIECE_T: active_cell = CELL_T;
            PIECE_S: active_cell = CELL_S;
            PIECE_Z: active_cell = CELL_Z;
            PIECE_J: active_cell = CELL_J;
            PIECE_L: active_cell = CELL_L;
            default: active_cell = CELL_EMPTY;
        endcase
    end

    always @* begin
        case (next_piece_type)
            PIECE_I: next_cell = CELL_I;
            PIECE_O: next_cell = CELL_O;
            PIECE_T: next_cell = CELL_T;
            PIECE_S: next_cell = CELL_S;
            PIECE_Z: next_cell = CELL_Z;
            PIECE_J: next_cell = CELL_J;
            PIECE_L: next_cell = CELL_L;
            default: next_cell = CELL_EMPTY;
        endcase
    end

    always @* begin
        case (active_cell)
            CELL_I:  active_color = 12'h0ff;
            CELL_O:  active_color = 12'hff0;
            CELL_T:  active_color = 12'hf0f;
            CELL_S:  active_color = 12'h0f0;
            CELL_Z:  active_color = 12'hf00;
            CELL_J:  active_color = 12'h00f;
            CELL_L:  active_color = 12'hfa0;
            default: active_color = 12'hfff;
        endcase
    end

    always @* begin
        case (next_cell)
            CELL_I:  next_color = 12'h0ff;
            CELL_O:  next_color = 12'hff0;
            CELL_T:  next_color = 12'hf0f;
            CELL_S:  next_color = 12'h0f0;
            CELL_Z:  next_color = 12'hf00;
            CELL_J:  next_color = 12'h00f;
            CELL_L:  next_color = 12'hfa0;
            default: next_color = 12'hfff;
        endcase
    end

    always @* begin
        case (board_cell_value)
            CELL_I:     board_color = 12'h0ff;
            CELL_O:     board_color = 12'hff0;
            CELL_T:     board_color = 12'hf0f;
            CELL_S:     board_color = 12'h0f0;
            CELL_Z:     board_color = 12'hf00;
            CELL_J:     board_color = 12'h00f;
            CELL_L:     board_color = 12'hfa0;
            CELL_GHOST: board_color = 12'h555;
            default:    board_color = 12'h111;
        endcase
    end

    // ------------------------------------------------------------
    // Final pixel priority
    // ------------------------------------------------------------
    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end

          // Game Over overlay
        else if ((game_state == GS_GAME_OVER) && gameover_label_on) begin
            rgb = 12'hfff;
        end else if ((game_state == GS_GAME_OVER) && press_c_label_on) begin
            rgb = 12'hff0;
        end else if ((game_state == GS_GAME_OVER) && gameover_border) begin
            rgb = 12'hf00;
        end else if ((game_state == GS_GAME_OVER) && in_gameover_panel) begin
            rgb = 12'h300;
        end

        // Title state background
        else if (game_state == GS_TITLE) begin
            if (in_title_bar)
                rgb = 12'h06f;
            else if (next_box_border || info_box_border || help_bar_border || board_border)
                rgb = 12'h0ff;
            else if (in_board_area)
                rgb = 12'h112;
            else if (in_next_box || in_info_box || in_help_bar)
                rgb = 12'h013;
            else
                rgb = 12'h001;
        end

        // Active game screen
        else if (show_active_piece) begin
            rgb = active_color;
        end else if (in_board_area && (board_cell_value != CELL_EMPTY)) begin
            rgb = board_color;
        end else if (pixel_is_next_piece) begin
            rgb = next_color;
         end else if (title_label_on) begin
            rgb = 12'hfff;
        end else if (next_label_on) begin
            rgb = 12'h0ff;
        end else if (score_label_on) begin
            rgb = 12'h0f0;
        end else if (level_label_on) begin
            rgb = 12'hff0;
        end else if (lines_label_on) begin
            rgb = 12'h0ff;
         end else if (score_digits_on) begin
            rgb = 12'h0f0;
        end else if (level_digits_on) begin
            rgb = 12'hff0;
        end else if (lines_digits_on) begin
            rgb = 12'h0ff;
        end else if (score_digits_on) begin
            rgb = 12'h0f0;
        end else if (level_digits_on) begin
            rgb = 12'hff0;
        end else if (lines_digits_on) begin
            rgb = 12'h0ff;
        end else if (board_border) begin
            rgb = 12'hfff;
        end else if (next_box_border) begin
            rgb = 12'h0ff;
        end else if (info_box_border || info_sep_line) begin
            rgb = 12'hff0;
        end else if (help_bar_border) begin
            rgb = 12'h888;
        end else if (grid_line) begin
            rgb = 12'h555;
        end else if (in_board_area) begin
            rgb = 12'h111;
        end else if (in_title_bar) begin
            rgb = 12'h024;
        end else if (in_next_box) begin
            rgb = 12'h012;
        end else if (in_info_box) begin
            rgb = 12'h210;
        end else if (in_help_bar) begin
            rgb = 12'h111;
        end else begin
            rgb = 12'h000;
        end
    end

    assign VGA_R = rgb[11:8];
    assign VGA_G = rgb[7:4];
    assign VGA_B = rgb[3:0];

endmodule
