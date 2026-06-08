// top_module.v - 顶层模块：同时显示分数和等级
// 位0-2：分数（个位、十位、L）
// 位4-6：等级（个位、十位、S）

`timescale 1ns / 1ps

module display (
    input  wire        clk_100m,           // 系统时钟 100MHz
    input  wire        rst,           // 复位（高有效）
    input  wire [7:0]  score,         // 分数值 0~99
    input  wire [7:0]  level,         // 等级值 0~99
    output wire [7:0]  an,            // 位选输出
    output wire [6:0]  ca_g           // 段选输出
);

    // ========================================
    // BCD转换（时序逻辑）
    // ========================================
    reg [3:0] score_tens, score_ones;
    reg [3:0] level_tens, level_ones;

    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            score_tens  <= 4'd0;
            score_ones  <= 4'd0;
            level_tens  <= 4'd0;
            level_ones  <= 4'd0;
        end else begin
            score_ones <= score % 10;
            score_tens <= (score / 10) % 10;
            level_ones <= level % 10;
            level_tens <= (level / 10) % 10;
        end
    end

    // ========================================
    // 动态扫描控制（时序逻辑）
    // 扫描顺序：分数个位→分数十位→L→等级个位→等级十位→S
    // ========================================
    reg [2:0] scan_cnt;   // 扫描计数器：0→1→2→3→4→5→0...
    reg [2:0] sel;        // 当前位选
    reg [3:0] seg_val;    // 当前段码

    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            scan_cnt <= 3'd0;
            sel      <= 3'd0;
            seg_val  <= 4'd0;
        end else begin
            scan_cnt <= scan_cnt + 1;
            if (scan_cnt == 3'd5)
                scan_cnt <= 3'd0;

            case (scan_cnt)
                3'd0: begin sel <= 3'd0; seg_val <= score_ones; end     // 分数个位（AN0）
                3'd1: begin sel <= 3'd1; seg_val <= score_tens; end     // 分数十位（AN1）
                3'd2: begin sel <= 3'd2; seg_val <= 4'd11;    end      // S（AN2）
                3'd3: begin sel <= 3'd4; seg_val <= level_ones; end     // 等级个位（AN4）
                3'd4: begin sel <= 3'd5; seg_val <= level_tens; end     // 等级十位（AN5）
                3'd5: begin sel <= 3'd6; seg_val <= 4'd10;    end      // L（AN6）
                default: begin sel <= 3'd0; seg_val <= score_ones; end
            endcase
        end
    end

    // ========================================
    // 调用七段数码管驱动模块（封装）
    // ========================================
    seven_seg_driver u_seg (
        .clk_100m(clk_100m),
        .rst(rst),
        .digit_value(seg_val),
        .digit_sel(sel),
        .an(an),
        .ca_g(ca_g)
    );

endmodule
