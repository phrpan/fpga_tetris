// score_bcd.v - 16位二进制分数 → 2位 BCD 码（时序逻辑版）
// 输入：0~99，输出：十位 + 个位（0-9时十位自动补0）

`timescale 1ns / 1ps

module score_bcd (
    input  wire        clk_100m,          // 时钟（与七段驱动同步）
    input  wire        rst,          // 复位（高有效）
    input  wire [15:0] score_bin,    // 输入：0~99
    output reg  [3:0]  digit1,       // 十位（BCD）
    output reg  [3:0]  digit0        // 个位（BCD）
);

    // 时序逻辑：在时钟上升沿更新输出
    // 优点：避免毛刺，与七段驱动模块时钟域一致
    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            digit1 <= 4'd0;
            digit0 <= 4'd0;
        end else begin
            digit0 <= score_bin % 10;          // 个位
            digit1 <= (score_bin / 10) % 10;   // 十位（0-9时自动为0）
        end
    end

endmodule
