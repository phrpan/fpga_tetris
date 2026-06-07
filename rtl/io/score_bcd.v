// score_bcd.v - 16位二进制分数 → 5位 BCD 码（显示用）
// Day 1 版本：直接透传低8位，高位清零

`timescale 1ns / 1ps

module score_bcd (
    input  wire [15:0] score_bin,
    output reg  [3:0]  digit4,   // 万位
    output reg  [3:0]  digit3,   // 千位
    output reg  [3:0]  digit2,   // 百位
    output reg  [3:0]  digit1,   // 十位
    output reg  [3:0]  digit0    // 个位
);

    // 简易 Bin → BCD（仅支持 0~99999）
    integer i;
    reg [15:0] tmp;

    always @(*) begin
        tmp = score_bin;
        digit4 = 4'd0;
        for (i = 0; i < 5; i = i + 1) begin
            case (i)
                0: digit0 = tmp % 10;
                1: digit1 = (tmp / 10) % 10;
                2: digit2 = (tmp / 100) % 10;
                3: digit3 = (tmp / 1000) % 10;
                4: digit4 = (tmp / 10000) % 10;
            endcase
        end
    end

endmodule
