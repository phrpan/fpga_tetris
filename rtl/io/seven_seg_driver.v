// seven_seg_driver.v - 八位七段数码管静态显示驱动
// 支持：0-9 + L(10) + S(11)

`timescale 1ns / 1ps

module seven_seg_driver (
    input  wire        clk_100m,           // 时钟（仅用于打拍输出，可不接）
    input  wire        rst,           // 复位信号（高有效）
    input  wire [3:0]  digit_value,   // 要显示的内容：0~9, 10=L, 11=S
    input  wire [2:0]  digit_sel,     // 位选信号：选择哪一位亮（0=最右，7=最左）
    output reg  [7:0]  an,             // 位选输出（低有效：0=选中该位）
    output reg  [6:0]  ca_g            // 段选输出（低有效：0=亮，顺序 gfedcba）
);

    // ========================================
    // 七段编码表（低有效：0=亮，1=灭）
    // 编码顺序：g f e d c b a
    // ========================================
    localparam SEG_0 = 7'b1000000;  // 数字 0
    localparam SEG_1 = 7'b1111001;  // 数字 1
    localparam SEG_2 = 7'b0100100;  // 数字 2
    localparam SEG_3 = 7'b0110000;  // 数字 3
    localparam SEG_4 = 7'b0011001;  // 数字 4
    localparam SEG_5 = 7'b0010010;  // 数字 5
    localparam SEG_6 = 7'b0000010;  // 数字 6
    localparam SEG_7 = 7'b1111000;  // 数字 7
    localparam SEG_8 = 7'b0000000;  // 数字 8
    localparam SEG_9 = 7'b0010000;  // 数字 9
    localparam SEG_L = 7'b1000111;  // 字母 L（10）
    localparam SEG_S = 7'b0010010;  // 字母 S（11）

    // ========================================
    // 组合逻辑：根据 digit_value 查表得到段码
    // seg_code：当前要显示的内容对应的段选信号
    // 支持范围：0~9, 10(L), 11(S)，超出默认显示0
    // ========================================
    wire [6:0] seg_code;
    assign seg_code = 
        (digit_value == 4'd0)  ? SEG_0 :
        (digit_value == 4'd1)  ? SEG_1 :
        (digit_value == 4'd2)  ? SEG_2 :
        (digit_value == 4'd3)  ? SEG_3 :
        (digit_value == 4'd4)  ? SEG_4 :
        (digit_value == 4'd5)  ? SEG_5 :
        (digit_value == 4'd6)  ? SEG_6 :
        (digit_value == 4'd7)  ? SEG_7 :
        (digit_value == 4'd8)  ? SEG_8 :
        (digit_value == 4'd9)  ? SEG_9 :
        (digit_value == 4'd10) ? SEG_L :   // 10 -> L
        (digit_value == 4'd11) ? SEG_S :   // 11 -> S
                                 SEG_0;    // 超出范围默认显示0

    // ========================================
    // 位选解码：根据 digit_sel 生成 8位 an 信号
    // 作用：只有 digit_sel 指定的那一位为0（选中），其余为1（关闭）
    // ========================================
    wire [7:0] an_decoded;
    assign an_decoded = 8'b11111111 ^ (8'b00000001 << digit_sel);
    // 解释：1 << digit_sel 得到只有1位为1的数，与全1异或后，
    //       结果是只有 digit_sel 位为0（选中），其余为1（关闭）

    // ========================================
    // 输出寄存器：在时钟上升沿更新输出
    // 作用：将组合逻辑结果打一拍，避免毛刺
    // ========================================
    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            an  <= 8'hFF;   // 复位时全部位选关闭
            ca_g <= 7'h7F;  // 复位时全部段灭
        end else begin
            an  <= an_decoded;  // 输出位选：只亮 digit_sel 指定的位
            ca_g <= seg_code;   // 输出段选：显示 digit_value 对应的内容
        end
    end

endmodule
