`timescale 1ns / 1ps

module tb_game_core;
    `include "../rtl/common/game_defs.vh"

    reg clk_100m;
    reg rst;
    reg btn_left_pulse;
    reg btn_right_pulse;
    reg btn_rotate_pulse;
    reg btn_soft_drop_hold;
    reg btn_start_pulse;
    reg [4:0] board_query_row;
    reg [3:0] board_query_col;

    wire [3:0] board_cell_value;
    wire [2:0] cur_piece_type;
    wire [1:0] cur_piece_rot;
    wire signed [4:0] cur_piece_x;
    wire signed [5:0] cur_piece_y;
    wire [2:0] next_piece_type;
    wire [15:0] score;
    wire [7:0] lines;
    wire [3:0] level;
    wire [2:0] game_state;

    integer error_count;

    game_core dut (
        .clk_100m(clk_100m),
        .rst(rst),
        .btn_left_pulse(btn_left_pulse),
        .btn_right_pulse(btn_right_pulse),
        .btn_rotate_pulse(btn_rotate_pulse),
        .btn_soft_drop_hold(btn_soft_drop_hold),
        .btn_start_pulse(btn_start_pulse),
        .board_query_row(board_query_row),
        .board_query_col(board_query_col),
        .board_cell_value(board_cell_value),
        .cur_piece_type(cur_piece_type),
        .cur_piece_rot(cur_piece_rot),
        .cur_piece_x(cur_piece_x),
        .cur_piece_y(cur_piece_y),
        .next_piece_type(next_piece_type),
        .score(score),
        .lines(lines),
        .level(level),
        .game_state(game_state)
    );

    initial begin
        clk_100m = 1'b0;
        forever #5 clk_100m = ~clk_100m;
    end

    task fail;
        input [255:0] message;
        begin
            $display("FAIL: %0s", message);
            error_count = error_count + 1;
        end
    endtask

    task pulse_start;
        begin
            @(posedge clk_100m);
            btn_start_pulse <= 1'b1;
            @(posedge clk_100m);
            btn_start_pulse <= 1'b0;
        end
    endtask

    task pulse_left;
        begin
            @(posedge clk_100m);
            btn_left_pulse <= 1'b1;
            @(posedge clk_100m);
            btn_left_pulse <= 1'b0;
        end
    endtask

    task pulse_right;
        begin
            @(posedge clk_100m);
            btn_right_pulse <= 1'b1;
            @(posedge clk_100m);
            btn_right_pulse <= 1'b0;
        end
    endtask

    task pulse_rotate;
        begin
            @(posedge clk_100m);
            btn_rotate_pulse <= 1'b1;
            @(posedge clk_100m);
            btn_rotate_pulse <= 1'b0;
        end
    endtask

    task wait_for_play;
        input integer max_cycles;
        integer i;
        reg found;
        begin
            found = 1'b0;
            for (i = 0; i < max_cycles; i = i + 1) begin
                @(posedge clk_100m);
                if (game_state == GS_PLAY) begin
                    found = 1'b1;
                    i = max_cycles;
                end
            end

            if (!found) begin
                fail("game_state did not reach GS_PLAY");
            end
        end
    endtask

    task check_no_x;
        begin
            if ((^game_state) === 1'bx) fail("game_state contains X");
            if ((^cur_piece_type) === 1'bx) fail("cur_piece_type contains X");
            if ((^cur_piece_rot) === 1'bx) fail("cur_piece_rot contains X");
            if ((^cur_piece_x) === 1'bx) fail("cur_piece_x contains X");
            if ((^cur_piece_y) === 1'bx) fail("cur_piece_y contains X");
            if ((^next_piece_type) === 1'bx) fail("next_piece_type contains X");
            if ((^board_cell_value) === 1'bx) fail("board_cell_value contains X");
            if ((^score) === 1'bx) fail("score contains X");
            if ((^lines) === 1'bx) fail("lines contains X");
            if ((^level) === 1'bx) fail("level contains X");
        end
    endtask

    initial begin
        error_count = 0;
        rst = 1'b1;
        btn_left_pulse = 1'b0;
        btn_right_pulse = 1'b0;
        btn_rotate_pulse = 1'b0;
        btn_soft_drop_hold = 1'b0;
        btn_start_pulse = 1'b0;
        board_query_row = 5'd19;
        board_query_col = 4'd0;

        repeat (5) @(posedge clk_100m);
        rst = 1'b0;
        repeat (2) @(posedge clk_100m);

        if (game_state != GS_TITLE) begin
            fail("reset should enter GS_TITLE");
        end
        if (score != 16'd0 || lines != 8'd0 || level != 4'd1) begin
            fail("score/lines/level reset values are incorrect");
        end

        pulse_start();
        wait_for_play(32);

        if (cur_piece_type > PIECE_L) begin
            fail("cur_piece_type should stay in 0..6");
        end
        if (next_piece_type > PIECE_L) begin
            fail("next_piece_type should stay in 0..6");
        end

        if (cur_piece_x != 5'sd3 || cur_piece_y != 6'sd0) begin
            fail("spawn position should be x=3 y=0");
        end

        pulse_left();
        repeat (8) @(posedge clk_100m);
        if (cur_piece_x != 5'sd2) begin
            fail("left pulse should move piece from x=3 to x=2");
        end

        pulse_right();
        repeat (8) @(posedge clk_100m);
        if (cur_piece_x != 5'sd3) begin
            fail("right pulse should move piece from x=2 to x=3");
        end

        pulse_rotate();
        repeat (8) @(posedge clk_100m);
        if (cur_piece_rot != 2'd1) begin
            fail("rotate pulse should increment rotation");
        end

        btn_soft_drop_hold = 1'b1;
        repeat (80) @(posedge clk_100m);
        btn_soft_drop_hold = 1'b0;
        if (cur_piece_y == 6'sd0) begin
            fail("soft drop should advance the piece downward");
        end

        board_query_row = cur_piece_y[4:0];
        board_query_col = cur_piece_x[3:0];
        repeat (2) @(posedge clk_100m);
        check_no_x();

        repeat (128) begin
            @(posedge clk_100m);
            check_no_x();
        end

        if (error_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", error_count);
        end

        $finish;
    end
endmodule
