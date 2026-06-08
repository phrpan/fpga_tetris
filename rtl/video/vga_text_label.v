`timescale 1ns / 1ps

//==============================================================
// vga_text_label.v
//
// 功能：
// 在 VGA 画面中绘制固定英文标签。
// 使用 5x7 点阵字体，每个字符宽 5 像素，高 7 像素，
// 字符之间留 1 像素间隔。
// SCALE 参数用于放大字符。
//
// LABEL_ID:
// 0: NEXT
// 1: SCORE
// 2: LEVEL
// 3: LINES
// 4: GAME OVER
// 5: PRESS C
// 6: FPGA TETRIS
//==============================================================

module vga_text_label #(
    parameter LABEL_ID   = 0,
    parameter CHAR_COUNT = 4,
    parameter X0         = 0,
    parameter Y0         = 0,
    parameter SCALE      = 2
)(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    output reg        text_on
);

    localparam CHAR_W = 5;
    localparam CHAR_H = 7;
    localparam STEP_W = 6;

    wire in_area;

    assign in_area =
        (pixel_x >= X0) &&
        (pixel_x <  X0 + CHAR_COUNT * STEP_W * SCALE) &&
        (pixel_y >= Y0) &&
        (pixel_y <  Y0 + CHAR_H * SCALE);

    wire [9:0] lx;
    wire [9:0] ly;

    assign lx = pixel_x - X0;
    assign ly = pixel_y - Y0;

    wire [5:0] char_idx;
    wire [2:0] font_col;
    wire [2:0] font_row;

    assign char_idx = lx / (STEP_W * SCALE);
    assign font_col = (lx % (STEP_W * SCALE)) / SCALE;
    assign font_row = ly / SCALE;

    reg [5:0] char_code;
    reg [4:0] row_bits;

    // ----------------------------------------------------------
    // 字符编码：
    // 0 = space
    // 1~26 = A~Z
    // ----------------------------------------------------------
    function [5:0] get_char;
        input [3:0] label_id;
        input [5:0] idx;
        begin
            get_char = 6'd0;

            case (label_id)

                // NEXT
                4'd0: begin
                    case (idx)
                        6'd0: get_char = 6'd14; // N
                        6'd1: get_char = 6'd5;  // E
                        6'd2: get_char = 6'd24; // X
                        6'd3: get_char = 6'd20; // T
                        default: get_char = 6'd0;
                    endcase
                end

                // SCORE
                4'd1: begin
                    case (idx)
                        6'd0: get_char = 6'd19; // S
                        6'd1: get_char = 6'd3;  // C
                        6'd2: get_char = 6'd15; // O
                        6'd3: get_char = 6'd18; // R
                        6'd4: get_char = 6'd5;  // E
                        default: get_char = 6'd0;
                    endcase
                end

                // LEVEL
                4'd2: begin
                    case (idx)
                        6'd0: get_char = 6'd12; // L
                        6'd1: get_char = 6'd5;  // E
                        6'd2: get_char = 6'd22; // V
                        6'd3: get_char = 6'd5;  // E
                        6'd4: get_char = 6'd12; // L
                        default: get_char = 6'd0;
                    endcase
                end

                // LINES
                4'd3: begin
                    case (idx)
                        6'd0: get_char = 6'd12; // L
                        6'd1: get_char = 6'd9;  // I
                        6'd2: get_char = 6'd14; // N
                        6'd3: get_char = 6'd5;  // E
                        6'd4: get_char = 6'd19; // S
                        default: get_char = 6'd0;
                    endcase
                end

                // GAME OVER
                4'd4: begin
                    case (idx)
                        6'd0: get_char = 6'd7;  // G
                        6'd1: get_char = 6'd1;  // A
                        6'd2: get_char = 6'd13; // M
                        6'd3: get_char = 6'd5;  // E
                        6'd4: get_char = 6'd0;  // space
                        6'd5: get_char = 6'd15; // O
                        6'd6: get_char = 6'd22; // V
                        6'd7: get_char = 6'd5;  // E
                        6'd8: get_char = 6'd18; // R
                        default: get_char = 6'd0;
                    endcase
                end

                // PRESS C
                4'd5: begin
                    case (idx)
                        6'd0: get_char = 6'd16; // P
                        6'd1: get_char = 6'd18; // R
                        6'd2: get_char = 6'd5;  // E
                        6'd3: get_char = 6'd19; // S
                        6'd4: get_char = 6'd19; // S
                        6'd5: get_char = 6'd0;  // space
                        6'd6: get_char = 6'd3;  // C
                        default: get_char = 6'd0;
                    endcase
                end

                // FPGA TETRIS
                4'd6: begin
                    case (idx)
                        6'd0:  get_char = 6'd6;  // F
                        6'd1:  get_char = 6'd16; // P
                        6'd2:  get_char = 6'd7;  // G
                        6'd3:  get_char = 6'd1;  // A
                        6'd4:  get_char = 6'd0;  // space
                        6'd5:  get_char = 6'd20; // T
                        6'd6:  get_char = 6'd5;  // E
                        6'd7:  get_char = 6'd20; // T
                        6'd8:  get_char = 6'd18; // R
                        6'd9:  get_char = 6'd9;  // I
                        6'd10: get_char = 6'd19; // S
                        default: get_char = 6'd0;
                    endcase
                end

                default: get_char = 6'd0;
            endcase
        end
    endfunction

    // ----------------------------------------------------------
    // 5x7 字体点阵
    // 每一行 5 bit，从左到右显示。
    // ----------------------------------------------------------
    function [4:0] font_row_bits;
        input [5:0] ch;
        input [2:0] row;
        begin
            font_row_bits = 5'b00000;

            case (ch)

                // space
                6'd0: begin
                    font_row_bits = 5'b00000;
                end

                // A
                6'd1: begin
                    case (row)
                        3'd0: font_row_bits = 5'b01110;
                        3'd1: font_row_bits = 5'b10001;
                        3'd2: font_row_bits = 5'b10001;
                        3'd3: font_row_bits = 5'b11111;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b10001;
                        3'd6: font_row_bits = 5'b10001;
                    endcase
                end

                // C
                6'd3: begin
                    case (row)
                        3'd0: font_row_bits = 5'b01111;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b10000;
                        3'd4: font_row_bits = 5'b10000;
                        3'd5: font_row_bits = 5'b10000;
                        3'd6: font_row_bits = 5'b01111;
                    endcase
                end

                // E
                6'd5: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11111;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b11110;
                        3'd4: font_row_bits = 5'b10000;
                        3'd5: font_row_bits = 5'b10000;
                        3'd6: font_row_bits = 5'b11111;
                    endcase
                end

                // F
                6'd6: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11111;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b11110;
                        3'd4: font_row_bits = 5'b10000;
                        3'd5: font_row_bits = 5'b10000;
                        3'd6: font_row_bits = 5'b10000;
                    endcase
                end

                // G
                6'd7: begin
                    case (row)
                        3'd0: font_row_bits = 5'b01111;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b10111;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b10001;
                        3'd6: font_row_bits = 5'b01111;
                    endcase
                end

                // I
                6'd9: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11111;
                        3'd1: font_row_bits = 5'b00100;
                        3'd2: font_row_bits = 5'b00100;
                        3'd3: font_row_bits = 5'b00100;
                        3'd4: font_row_bits = 5'b00100;
                        3'd5: font_row_bits = 5'b00100;
                        3'd6: font_row_bits = 5'b11111;
                    endcase
                end

                // L
                6'd12: begin
                    case (row)
                        3'd0: font_row_bits = 5'b10000;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b10000;
                        3'd4: font_row_bits = 5'b10000;
                        3'd5: font_row_bits = 5'b10000;
                        3'd6: font_row_bits = 5'b11111;
                    endcase
                end

                // M
                6'd13: begin
                    case (row)
                        3'd0: font_row_bits = 5'b10001;
                        3'd1: font_row_bits = 5'b11011;
                        3'd2: font_row_bits = 5'b10101;
                        3'd3: font_row_bits = 5'b10101;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b10001;
                        3'd6: font_row_bits = 5'b10001;
                    endcase
                end

                // N
                6'd14: begin
                    case (row)
                        3'd0: font_row_bits = 5'b10001;
                        3'd1: font_row_bits = 5'b11001;
                        3'd2: font_row_bits = 5'b10101;
                        3'd3: font_row_bits = 5'b10011;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b10001;
                        3'd6: font_row_bits = 5'b10001;
                    endcase
                end

                // O
                6'd15: begin
                    case (row)
                        3'd0: font_row_bits = 5'b01110;
                        3'd1: font_row_bits = 5'b10001;
                        3'd2: font_row_bits = 5'b10001;
                        3'd3: font_row_bits = 5'b10001;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b10001;
                        3'd6: font_row_bits = 5'b01110;
                    endcase
                end

                // P
                6'd16: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11110;
                        3'd1: font_row_bits = 5'b10001;
                        3'd2: font_row_bits = 5'b10001;
                        3'd3: font_row_bits = 5'b11110;
                        3'd4: font_row_bits = 5'b10000;
                        3'd5: font_row_bits = 5'b10000;
                        3'd6: font_row_bits = 5'b10000;
                    endcase
                end

                // R
                6'd18: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11110;
                        3'd1: font_row_bits = 5'b10001;
                        3'd2: font_row_bits = 5'b10001;
                        3'd3: font_row_bits = 5'b11110;
                        3'd4: font_row_bits = 5'b10100;
                        3'd5: font_row_bits = 5'b10010;
                        3'd6: font_row_bits = 5'b10001;
                    endcase
                end

                // S
                6'd19: begin
                    case (row)
                        3'd0: font_row_bits = 5'b01111;
                        3'd1: font_row_bits = 5'b10000;
                        3'd2: font_row_bits = 5'b10000;
                        3'd3: font_row_bits = 5'b01110;
                        3'd4: font_row_bits = 5'b00001;
                        3'd5: font_row_bits = 5'b00001;
                        3'd6: font_row_bits = 5'b11110;
                    endcase
                end

                // T
                6'd20: begin
                    case (row)
                        3'd0: font_row_bits = 5'b11111;
                        3'd1: font_row_bits = 5'b00100;
                        3'd2: font_row_bits = 5'b00100;
                        3'd3: font_row_bits = 5'b00100;
                        3'd4: font_row_bits = 5'b00100;
                        3'd5: font_row_bits = 5'b00100;
                        3'd6: font_row_bits = 5'b00100;
                    endcase
                end

                // V
                6'd22: begin
                    case (row)
                        3'd0: font_row_bits = 5'b10001;
                        3'd1: font_row_bits = 5'b10001;
                        3'd2: font_row_bits = 5'b10001;
                        3'd3: font_row_bits = 5'b10001;
                        3'd4: font_row_bits = 5'b10001;
                        3'd5: font_row_bits = 5'b01010;
                        3'd6: font_row_bits = 5'b00100;
                    endcase
                end

                // X
                6'd24: begin
                    case (row)
                        3'd0: font_row_bits = 5'b10001;
                        3'd1: font_row_bits = 5'b01010;
                        3'd2: font_row_bits = 5'b00100;
                        3'd3: font_row_bits = 5'b00100;
                        3'd4: font_row_bits = 5'b00100;
                        3'd5: font_row_bits = 5'b01010;
                        3'd6: font_row_bits = 5'b10001;
                    endcase
                end

                default: begin
                    font_row_bits = 5'b00000;
                end
            endcase
        end
    endfunction

    always @* begin
        char_code = get_char(LABEL_ID[3:0], char_idx);
        row_bits  = font_row_bits(char_code, font_row);

        if (in_area && (font_col < 3'd5))
            text_on = row_bits[4 - font_col];
        else
            text_on = 1'b0;
    end

endmodule