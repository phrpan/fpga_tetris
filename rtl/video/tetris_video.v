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

    wire in_board_area;

    assign in_board_area =
        (pixel_x >= BOARD_X0) &&
        (pixel_x <  BOARD_X0 + BOARD_COLS * CELL_SIZE) &&
        (pixel_y >= BOARD_Y0) &&
        (pixel_y <  BOARD_Y0 + BOARD_ROWS * CELL_SIZE);

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

    reg [3:0] active_cell;
    reg [11:0] active_color;
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
        case (active_cell)
            CELL_I:     active_color = 12'h0ff;
            CELL_O:     active_color = 12'hff0;
            CELL_T:     active_color = 12'hf0f;
            CELL_S:     active_color = 12'h0f0;
            CELL_Z:     active_color = 12'hf00;
            CELL_J:     active_color = 12'h00f;
            CELL_L:     active_color = 12'hfa0;
            default:    active_color = 12'hfff;
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

    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end else if (game_state == GS_TITLE) begin
            if (in_board_area)
                rgb = 12'h113;
            else
                rgb = 12'h024;
        end else if (game_state == GS_GAME_OVER) begin
            if (in_board_area)
                rgb = 12'h411;
            else
                rgb = 12'h200;
        end else if (show_active_piece) begin
            rgb = active_color;
        end else if (in_board_area && (board_cell_value != CELL_EMPTY)) begin
            rgb = board_color;
        end else if (grid_line) begin
            rgb = 12'h666;
        end else if (in_board_area) begin
            rgb = 12'h111;
        end else begin
            rgb = 12'h000;
        end
    end

    assign VGA_R = rgb[11:8];
    assign VGA_G = rgb[7:4];
    assign VGA_B = rgb[3:0];

endmodule
