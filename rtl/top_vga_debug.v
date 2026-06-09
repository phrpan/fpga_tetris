`timescale 1ns / 1ps

module top_vga_debug (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,

    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTND,
    input  wire        BTNL,
    input  wire        BTNR,

    output wire [15:0] LED,
    output wire [7:0]  an,
    output wire [6:0]  ca_g,
    output wire        beep,

    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS
);

    wire clk_100m = CLK100MHZ;
    wire rst = ~CPU_RESETN;

    reg [1:0] pix_div;

    always @(posedge clk_100m) begin
        if (rst)
            pix_div <= 2'd0;
        else
            pix_div <= pix_div + 2'd1;
    end

    wire pix_clk = pix_div[1];

    wire btn_start_pulse;
    wire btn_left_pulse;
    wire btn_right_pulse;
    wire btn_rotate_pulse;
    wire btn_soft_drop_hold;

    button_input button_input_inst (
        .clk_100m           (clk_100m),
        .rst                (rst),
        .btnc               (BTNC),
        .btnu               (BTNU),
        .btnd               (BTND),
        .btnl               (BTNL),
        .btnr               (BTNR),
        .btn_start_pulse    (btn_start_pulse),
        .btn_left_pulse     (btn_left_pulse),
        .btn_right_pulse    (btn_right_pulse),
        .btn_rotate_pulse   (btn_rotate_pulse),
        .btn_soft_drop_hold (btn_soft_drop_hold)
    );

    wire [4:0]        board_query_row;
    wire [3:0]        board_query_col;
    wire [3:0]        board_cell_value;

    wire [2:0]        cur_piece_type;
    wire [1:0]        cur_piece_rot;
    wire signed [4:0] cur_piece_x;
    wire signed [5:0] cur_piece_y;

    wire [2:0]        next_piece_type;
    wire [15:0]       score;
    wire [7:0]        lines;
    wire [3:0]        level;
    wire [2:0]        game_state;
    wire [15:0]       led_status_value;
    wire [15:0]       led_blink_value;
    wire              game_over;

    assign game_over = (game_state == 3'd6);
    assign LED = game_over ? led_blink_value : led_status_value;

    game_core core_inst (
        .clk_100m           (clk_100m),
        .rst                (rst),

        .btn_left_pulse     (btn_left_pulse),
        .btn_right_pulse    (btn_right_pulse),
        .btn_rotate_pulse   (btn_rotate_pulse),
        .btn_soft_drop_hold (btn_soft_drop_hold),
        .btn_start_pulse    (btn_start_pulse),

        .board_query_row    (board_query_row),
        .board_query_col    (board_query_col),
        .board_cell_value   (board_cell_value),

        .cur_piece_type     (cur_piece_type),
        .cur_piece_rot      (cur_piece_rot),
        .cur_piece_x        (cur_piece_x),
        .cur_piece_y        (cur_piece_y),

        .next_piece_type    (next_piece_type),
        .score              (score),
        .lines              (lines),
        .level              (level),
        .game_state         (game_state)
    );

    tetris_video video_inst (
        .pix_clk            (pix_clk),
        .rst                (rst),

        .board_query_row    (board_query_row),
        .board_query_col    (board_query_col),
        .board_cell_value   (board_cell_value),

        .cur_piece_type     (cur_piece_type),
        .cur_piece_rot      (cur_piece_rot),
        .cur_piece_x        (cur_piece_x),
        .cur_piece_y        (cur_piece_y),

        .next_piece_type    (next_piece_type),
        .score              (score),
        .lines              (lines),
        .level              (level),
        .game_state         (game_state),

        .VGA_HS             (VGA_HS),
        .VGA_VS             (VGA_VS),
        .VGA_R              (VGA_R),
        .VGA_G              (VGA_G),
        .VGA_B              (VGA_B)
    );

    display display_inst (
        .clk_100m (clk_100m),
        .rst      (rst),
        .score    (score[7:0]),
        .level    ({4'd0, level}),
        .an       (an),
        .ca_g     (ca_g)
    );

    led_status led_status_inst (
        .clk_100m   (clk_100m),
        .rst        (rst),
        .game_state (game_state),
        .led        (led_status_value)
    );

    led_blink led_blink_inst (
        .clk_100m (clk_100m),
        .rst      (rst),
        .failed   (game_over),
        .led      (led_blink_value)
    );
    
    
    beep beep_inst (
        .clk_100m (clk_100m),
        .rst      (rst),
        .failed   (game_over),
        .beep     (beep)
    );

endmodule
