`timescale 1ns / 1ps

module top_vga_color_test (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,

    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,

    output wire [15:0] LED
);

    wire rst = ~CPU_RESETN;

    reg [1:0] div_cnt;

    always @(posedge CLK100MHZ) begin
        if (rst)
            div_cnt <= 2'd0;
        else
            div_cnt <= div_cnt + 2'd1;
    end

    wire pix_clk = div_cnt[1];

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

    reg [11:0] rgb;

    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end else if (pixel_x < 10'd160) begin
            rgb = 12'hf00;   // red
        end else if (pixel_x < 10'd320) begin
            rgb = 12'h0f0;   // green
        end else if (pixel_x < 10'd480) begin
            rgb = 12'h00f;   // blue
        end else begin
            rgb = 12'hfff;   // white
        end
    end

    assign VGA_R = rgb[11:8];
    assign VGA_G = rgb[7:4];
    assign VGA_B = rgb[3:0];

    assign LED[0] = pix_clk;
    assign LED[1] = VGA_HS;
    assign LED[2] = VGA_VS;
    assign LED[15:3] = 13'd0;

endmodule