// led_blink.v - LED闪烁模块（时序逻辑）
// failed=1时，16位LED以1秒为周期（亮0.5s+灭0.5s）闪烁3秒后停止

`timescale 1ns / 1ps

module beep (
    input  wire         clk_100m,          // 100MHz时钟
    input  wire         rst,               // 复位（高有效）
    input  wire         failed,            // 失败信号（高电平触发）
    output reg          beep
);

    // ========================================
    // 常量定义（固定值，不可修改）
    // ========================================
    localparam integer TIME_CYCLES  = 300_000_000;  // 3秒
    localparam integer PERIOD_CYCLES = 100_000_000;  // 1秒（一个周期）
    localparam integer HALF_CYCLES  =  50_000_000;  // 0.5秒（半周期）

    // ========================================
    // 计数器位宽
    // ========================================
    localparam integer TIME_W  = 29;  // log2(300M) ≈ 29
    localparam integer PERIOD_W = 27;  // log2(100M) ≈ 27

    // ========================================
    // 计数器定义
    // ========================================
    reg [TIME_W-1:0]   time_cnt;      // 总时间计数器（0~300M）
    reg [PERIOD_W-1:0] period_cnt;    // 周期计数器（0~100M）

    // ========================================
    // 时序逻辑：控制LED闪烁
    // ========================================
    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            beep       <= 1'b0;
            time_cnt   <= {TIME_W{1'b0}};
            period_cnt <= {PERIOD_W{1'b0}};
        end else if (failed) begin
            if (time_cnt < TIME_CYCLES) begin
                // 更新周期计数器
                if (period_cnt >= PERIOD_CYCLES - 1)
                    period_cnt <= {PERIOD_W{1'b0}};
                else
                    period_cnt <= period_cnt + 1;

                // beep控制
                if (period_cnt < HALF_CYCLES) begin
                    beep<= 1'b1;
                end else begin
                    beep<= 1'b1;
                end
                // 更新总时间计数器
                time_cnt <= time_cnt + 1;
            end else begin
                // 3秒到，停止蜂鸣
                beep       <= 1'b0;
                time_cnt   <= {TIME_W{1'b0}};
                period_cnt <= {PERIOD_W{1'b0}};
            end
        end else begin
            // 正常状态：不响，计数器清零
            beep       <= 1'b0;
            time_cnt   <= {TIME_W{1'b0}};
            period_cnt <= {PERIOD_W{1'b0}};
        end
    end

endmodule
