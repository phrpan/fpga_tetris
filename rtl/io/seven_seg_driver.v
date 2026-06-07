// seven_seg_driver.v - 八位七段数码管动态扫描驱动
// Day 1 版本：显示固定测试数字 "00000001"

`timescale 1ns / 1ps

module seven_seg_driver (
    input  wire        clk_100m,
    input  wire        rst,
    input  wire [3:0]  digit_value,   // 要显示的数字 0~9
    output reg  [7:0]  an,             // 位选（低有效）
    output reg  [6:0]  ca_g            // 段选（低有效：0=亮）
);

    // 七段编码（低有效：0=亮，1=灭）
    //  gfedcba
    localparam SEG_0 = 7'b1000000;
    localparam SEG_1 = 7'b1111001;
    localparam SEG_2 = 7'b0100100;
    localparam SEG_3 = 7'b0110000;
    localparam SEG_4 = 7'b0011001;
    localparam SEG_5 = 7'b0010010;
    localparam SEG_6 = 7'b0000010;
    localparam SEG_7 = 7'b1111000;
    localparam SEG_8 = 7'b0000000;
    localparam SEG_9 = 7'b0010000;

    reg [15:0] scan_cnt;
    reg [2:0]  digit_sel;

    // 扫描计数器：约 1kHz 刷新
    always @(posedge clk_100m) begin
        if (rst) begin
            scan_cnt <= 16'd0;
        end else begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    always @(posedge clk_100m) begin
        if (rst) begin
            digit_sel <= 3'd0;
        end else if (scan_cnt[15]) begin  // 约 32768 / 100MHz ≈ 327μs 每位
            digit_sel <= digit_sel + 1'b1;
        end
    end

    // 位选 + 段选
    always @(posedge clk_100m) begin
        if (rst) begin
            an  <= 8'hFF;
            ca_g <= 7'h7F;
        end else begin
            an <= 8'hFF;  // 全部关
            ca_g <= 7'h7F;

            case (digit_sel)
                3'd0: begin an <= 8'hFE; ca_g <= SEG_0; end  // 最右位显示 digit_value
                3'd1: begin an <= 8'hFD; ca_g <= SEG_0; end
                3'd2: begin an <= 8'hFB; ca_g <= SEG_0; end
                3'd3: begin an <= 8'hF7; ca_g <= SEG_0; end
                3'd4: begin an <= 8'hEF; ca_g <= SEG_0; end
                3'd5: begin an <= 8'hDF; ca_g <= SEG_0; end
                3'd6: begin an <= 8'hBF; ca_g <= SEG_0; end
                3'd7: begin an <= 8'h7F; ca_g <= SEG_0; end
                default: begin an <= 8'hFF; ca_g <= 7'h7F; end
            endcase
        end
    end

endmodule
