`timescale 1ns / 1ps

module vga_digit7seg #(
    parameter X0 = 0,
    parameter Y0 = 0,
    parameter W  = 18,
    parameter H  = 30,
    parameter S  = 3
)(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [3:0] digit,
    output reg        digit_on
);

    localparam MID = H / 2;

    wire in_digit;

    assign in_digit =
        (pixel_x >= X0) &&
        (pixel_x <  X0 + W) &&
        (pixel_y >= Y0) &&
        (pixel_y <  Y0 + H);

    wire [9:0] lx;
    wire [9:0] ly;

    assign lx = pixel_x - X0;
    assign ly = pixel_y - Y0;

    wire seg_a;
    wire seg_b;
    wire seg_c;
    wire seg_d;
    wire seg_e;
    wire seg_f;
    wire seg_g;

    assign seg_a = in_digit &&
                   (ly < S) &&
                   (lx >= S) &&
                   (lx < W - S);

    assign seg_b = in_digit &&
                   (lx >= W - S) &&
                   (ly >= S) &&
                   (ly < MID);

    assign seg_c = in_digit &&
                   (lx >= W - S) &&
                   (ly >= MID) &&
                   (ly < H - S);

    assign seg_d = in_digit &&
                   (ly >= H - S) &&
                   (lx >= S) &&
                   (lx < W - S);

    assign seg_e = in_digit &&
                   (lx < S) &&
                   (ly >= MID) &&
                   (ly < H - S);

    assign seg_f = in_digit &&
                   (lx < S) &&
                   (ly >= S) &&
                   (ly < MID);

    assign seg_g = in_digit &&
                   (ly >= MID - (S / 2)) &&
                   (ly <  MID + (S / 2) + 1) &&
                   (lx >= S) &&
                   (lx < W - S);

    reg [6:0] seg_mask;

    always @* begin
        case (digit)
            4'd0: seg_mask = 7'b1111110;
            4'd1: seg_mask = 7'b0110000;
            4'd2: seg_mask = 7'b1101101;
            4'd3: seg_mask = 7'b1111001;
            4'd4: seg_mask = 7'b0110011;
            4'd5: seg_mask = 7'b1011011;
            4'd6: seg_mask = 7'b1011111;
            4'd7: seg_mask = 7'b1110000;
            4'd8: seg_mask = 7'b1111111;
            4'd9: seg_mask = 7'b1111011;
            default: seg_mask = 7'b0000000;
        endcase
    end

    always @* begin
        digit_on =
            (seg_mask[6] && seg_a) ||
            (seg_mask[5] && seg_b) ||
            (seg_mask[4] && seg_c) ||
            (seg_mask[3] && seg_d) ||
            (seg_mask[2] && seg_e) ||
            (seg_mask[1] && seg_f) ||
            (seg_mask[0] && seg_g);
    end

endmodule