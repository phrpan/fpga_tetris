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
    reg signed [4:0] saved_piece_x;
    reg signed [5:0] saved_piece_y;
    reg [1:0] saved_piece_rot;
    reg [15:0] saved_score;
    reg [7:0] saved_lines;
    reg [3:0] saved_level;
    reg [2:0] saved_piece_type;
    integer tb_row;
    integer tb_col;

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

    task clear_internal_board;
        begin
            for (tb_row = 0; tb_row < BOARD_ROWS; tb_row = tb_row + 1) begin
                for (tb_col = 0; tb_col < BOARD_COLS; tb_col = tb_col + 1) begin
                    dut.board[tb_row][tb_col] = CELL_EMPTY;
                end
            end
        end
    endtask

    task force_play_piece;
        input [2:0] piece_type_value;
        input [1:0] piece_rot_value;
        input signed [4:0] piece_x_value;
        input signed [5:0] piece_y_value;
        begin
            @(negedge clk_100m);
            clear_internal_board();
            dut.core_phase = 4'd3;
            dut.game_state = GS_PLAY;
            dut.cur_piece_type = piece_type_value;
            dut.cur_piece_rot = piece_rot_value;
            dut.cur_piece_x = piece_x_value;
            dut.cur_piece_y = piece_y_value;
            dut.candidate_x = piece_x_value;
            dut.candidate_y = piece_y_value;
            dut.candidate_rot = piece_rot_value;
            dut.candidate_action = 3'd0;
            dut.candidate_soft_drop = 1'b0;
            dut.soft_drop_wait_release = 1'b0;
            dut.check_idx = 2'd0;
            dut.check_collision = 1'b0;
            dut.lock_idx = 2'd0;
            dut.gravity_counter = 26'd0;
            @(posedge clk_100m);
        end
    endtask

    task force_game_over_context;
        begin
            @(negedge clk_100m);
            dut.board[0][4] = CELL_T;
            dut.board[19][0] = CELL_I;
            dut.score_level_inst.score = 16'd1234;
            dut.score_level_inst.lines = 8'd12;
            dut.score_level_inst.level = 4'd2;
            dut.core_phase = 4'd10;
            dut.game_state = GS_GAME_OVER;
            dut.cur_piece_type = PIECE_T;
            dut.cur_piece_rot = 2'd0;
            dut.cur_piece_x = 5'sd3;
            dut.cur_piece_y = 6'sd0;
            dut.candidate_soft_drop = 1'b0;
            dut.soft_drop_wait_release = 1'b0;
            @(posedge clk_100m);
        end
    endtask

    task force_play_gravity_context;
        input [3:0] forced_level;
        input [25:0] forced_counter;
        begin
            @(negedge clk_100m);
            dut.score_level_inst.level = forced_level;
            dut.core_phase = 4'd3;
            dut.game_state = GS_PLAY;
            dut.cur_piece_type = PIECE_T;
            dut.cur_piece_rot = 2'd0;
            dut.cur_piece_x = 5'sd3;
            dut.cur_piece_y = 6'sd0;
            dut.candidate_x = 5'sd3;
            dut.candidate_y = 6'sd0;
            dut.candidate_rot = 2'd0;
            dut.candidate_action = 3'd0;
            dut.candidate_soft_drop = 1'b0;
            dut.soft_drop_wait_release = 1'b0;
            dut.check_idx = 2'd0;
            dut.check_collision = 1'b0;
            dut.gravity_counter = forced_counter;
            @(posedge clk_100m);
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

        force_play_piece(PIECE_I, 2'd0, 5'sd3, 6'sd0);
        pulse_rotate();
        repeat (8) @(posedge clk_100m);
        if (cur_piece_x != 5'sd3 ||
            cur_piece_y != 6'sd0 ||
            cur_piece_rot != 2'd1) begin
            fail("valid rotate should update only rotation");
        end

        force_play_piece(PIECE_I, 2'd1, 5'sd7, 6'sd0);
        pulse_rotate();
        repeat (8) @(posedge clk_100m);
        if (cur_piece_x != 5'sd7 ||
            cur_piece_y != 6'sd0 ||
            cur_piece_rot != 2'd1) begin
            fail("failed rotate should keep x/y/rot unchanged");
        end

        btn_soft_drop_hold = 1'b1;
        repeat (80) @(posedge clk_100m);
        btn_soft_drop_hold = 1'b0;
        if (cur_piece_y == 6'sd0) begin
            fail("soft drop should advance the piece downward");
        end

        saved_piece_x = cur_piece_x;
        saved_piece_y = cur_piece_y;
        saved_piece_rot = cur_piece_rot;
        saved_piece_type = cur_piece_type;
        saved_score = score;
        saved_lines = lines;
        saved_level = level;

        pulse_start();
        repeat (2) @(posedge clk_100m);
        if (game_state != GS_PAUSE) begin
            fail("start pulse in GS_PLAY should enter GS_PAUSE");
        end

        pulse_left();
        pulse_right();
        pulse_rotate();
        btn_soft_drop_hold = 1'b1;
        repeat (32) @(posedge clk_100m);
        btn_soft_drop_hold = 1'b0;

        if (game_state != GS_PAUSE) begin
            fail("game_state should remain GS_PAUSE while paused");
        end
        if (cur_piece_x != saved_piece_x ||
            cur_piece_y != saved_piece_y ||
            cur_piece_rot != saved_piece_rot ||
            cur_piece_type != saved_piece_type) begin
            fail("pause should hold current piece type, position, and rotation");
        end
        if (score != saved_score || lines != saved_lines || level != saved_level) begin
            fail("pause should hold score/lines/level");
        end

        pulse_start();
        repeat (2) @(posedge clk_100m);
        if (game_state != GS_PLAY) begin
            fail("start pulse in GS_PAUSE should resume GS_PLAY");
        end

        force_play_piece(PIECE_T, 2'd0, 5'sd3, 6'sd18);
        btn_soft_drop_hold = 1'b1;
        @(negedge clk_100m);
        dut.gravity_counter = 26'd5;
        @(posedge clk_100m);
        repeat (900) @(posedge clk_100m);
        if (game_state != GS_PLAY) begin
            fail("soft-drop lock should eventually spawn back to GS_PLAY");
        end
        if (cur_piece_y != 6'sd0) begin
            fail("held soft drop should not immediately accelerate the next spawned piece");
        end

        repeat (32) @(posedge clk_100m);
        if (cur_piece_y != 6'sd0) begin
            fail("soft-drop release guard should hold until BTND is released");
        end

        btn_soft_drop_hold = 1'b0;
        repeat (4) @(posedge clk_100m);
        btn_soft_drop_hold = 1'b1;
        repeat (24) @(posedge clk_100m);
        btn_soft_drop_hold = 1'b0;
        if (cur_piece_y == 6'sd0) begin
            fail("soft drop should work again after BTND is released and pressed again");
        end

        board_query_row = cur_piece_y[4:0];
        board_query_col = cur_piece_x[3:0];
        repeat (2) @(posedge clk_100m);
        check_no_x();

        force_game_over_context();
        if (game_state != GS_GAME_OVER) begin
            fail("forced context should enter GS_GAME_OVER");
        end

        pulse_start();
        wait_for_play(260);

        if (score != 16'd0 || lines != 8'd0 || level != 4'd1) begin
            fail("restart should reset score/lines/level");
        end
        if (cur_piece_x != 5'sd3 || cur_piece_y != 6'sd0 || cur_piece_rot != 2'd0) begin
            fail("restart should reset current piece position and rotation");
        end
        if (cur_piece_type > PIECE_L || next_piece_type > PIECE_L) begin
            fail("restart should keep current and next pieces legal");
        end

        board_query_row = 5'd19;
        board_query_col = 4'd0;
        repeat (2) @(posedge clk_100m);
        if (board_cell_value != CELL_EMPTY) begin
            fail("restart should clear bottom-left board cell");
        end

        board_query_row = 5'd0;
        board_query_col = 4'd4;
        repeat (2) @(posedge clk_100m);
        if (board_cell_value != CELL_EMPTY) begin
            fail("restart should clear spawn-blocking board cell");
        end

        force_play_gravity_context(4'd1, 26'd45000000);
        repeat (8) @(posedge clk_100m);
        if (cur_piece_y != 6'sd0) begin
            fail("level 1 should not fall at the level 2 threshold");
        end

        force_play_gravity_context(4'd2, 26'd45000000);
        repeat (8) @(posedge clk_100m);
        if (cur_piece_y <= 6'sd0) begin
            fail("level 2 should fall at its shorter gravity threshold");
        end

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
