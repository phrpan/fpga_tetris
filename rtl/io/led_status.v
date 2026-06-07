// led_status.v - 根据游戏状态驱动板载 LED
// Day 1 版本：仅显示 GS_TITLE / GS_PLAY / GS_GAME_OVER

`timescale 1ns / 1ps

module led_status (
    input  wire        clk_100m,
    input  wire        rst,
    input  wire [2:0]  game_state,   // 来自 game_core
    output reg  [15:0] led           // 板载 16 个 LED
);

    // LED 分配：
    // LED15 = 游戏进行中 (GS_PLAY)
    // LED14 = 标题页 (GS_TITLE)
    // LED13 = Game Over (GS_GAME_OVER)
    // 其余 LED 暂不使用

    localparam LED_TITLE      = 16'h4000;  // LED14
    localparam LED_PLAYING    = 16'h8000;  // LED15
    localparam LED_GAME_OVER  = 16'h2000;  // LED13

    always @(posedge clk_100m) begin
        if (rst) begin
            led <= 16'h0000;
        end else begin
            case (game_state)
                3'd0:  led <= LED_TITLE;       // GS_TITLE
                3'd2:  led <= LED_PLAYING;     // GS_PLAY
                3'd6:  led <= LED_GAME_OVER;   // GS_GAME_OVER
                default: led <= 16'h0000;
            endcase
        end
    end

endmodule
