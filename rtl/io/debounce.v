// debounce.v - 板载按键消抖模块（修复版）
// 消抖时间约 10ms @ 100MHz
// 按下为高电平（1），未按下为低电平（0）

`timescale 1ns / 1ps

module debounce #(
    parameter WIDTH = 1,
    parameter CNT_MAX = 20'd999_999  // 10ms @ 100MHz
)(
    input  wire                clk_100m,
    input  wire                rst,
    input  wire [WIDTH-1:0]    btn_raw,
    output reg  [WIDTH-1:0]    btn_deb
);

    reg [19:0] cnt [0:WIDTH-1];
    reg [WIDTH-1:0] btn_sync_0, btn_sync_1;
    integer i;

    always @(posedge clk_100m) begin
        if (rst) begin
            btn_sync_0 <= {WIDTH{1'b0}};   // ? 改为0（未按下）
            btn_sync_1 <= {WIDTH{1'b0}};
            btn_deb    <= {WIDTH{1'b0}};
            for (i = 0; i < WIDTH; i = i + 1) cnt[i] <= 20'd0;
        end else begin
            btn_sync_0 <= btn_raw;
            btn_sync_1 <= btn_sync_0;

            for (i = 0; i < WIDTH; i = i + 1) begin
                if (btn_sync_1[i] == btn_deb[i]) begin
                    cnt[i] <= 20'd0;
                end else begin
                    if (cnt[i] < CNT_MAX) begin
                        cnt[i] <= cnt[i] + 1'b1;
                    end else begin
                        btn_deb[i] <= btn_sync_1[i];
                        cnt[i] <= 20'd0;
                    end
                end
            end
        end
    end

endmodule
