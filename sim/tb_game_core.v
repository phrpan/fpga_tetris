`timescale 1ns / 1ps

module tb_game_core;

`include "../rtl/common/game_defs.vh"

reg               clk_100m;
reg               rst;
reg               btn_left_pulse;
reg               btn_right_pulse;
reg               btn_rotate_pulse;
reg               btn_soft_drop_hold;
reg               btn_start_pulse;
reg [4:0]         board_query_row;
reg [3:0]         board_query_col;

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

integer error_count;
integer wait_count;
reg signed [4:0] saved_x;
reg signed [5:0] saved_y;
reg [1:0] saved_rot;

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
end

always #5 clk_100m = ~clk_100m;

task pulse_start;
begin
    @(negedge clk_100m);
    btn_start_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_start_pulse = 1'b0;
end
endtask

task pulse_left;
begin
    @(negedge clk_100m);
    btn_left_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_left_pulse = 1'b0;
end
endtask

task pulse_right;
begin
    @(negedge clk_100m);
    btn_right_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_right_pulse = 1'b0;
end
endtask

task pulse_rotate;
begin
    @(negedge clk_100m);
    btn_rotate_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_rotate_pulse = 1'b0;
end
endtask

task check_no_x;
    input [8*48-1:0] name;
begin
    if ((^game_state === 1'bx) || (^cur_piece_type === 1'bx) ||
        (^cur_piece_rot === 1'bx) || (^cur_piece_x === 1'bx) ||
        (^cur_piece_y === 1'bx) || (^next_piece_type === 1'bx) ||
        (^score === 1'bx) || (^lines === 1'bx) || (^level === 1'bx) ||
        (^board_cell_value === 1'bx)) begin
        $display("ERROR: %0s observed unknown value", name);
        error_count = error_count + 1;
    end
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
    board_query_row = 5'd0;
    board_query_col = 4'd0;

    repeat (4) @(posedge clk_100m);
    rst = 1'b0;
    @(posedge clk_100m);
    #1;

    if (game_state !== GS_TITLE) begin
        $display("ERROR: reset expected GS_TITLE, got %0d", game_state);
        error_count = error_count + 1;
    end
    check_no_x("after reset");

    pulse_start;

    wait_count = 0;
    while ((game_state != GS_PLAY) && (wait_count < 16)) begin
        @(posedge clk_100m);
        #1;
        wait_count = wait_count + 1;
    end

    if (game_state !== GS_PLAY) begin
        $display("ERROR: start did not reach GS_PLAY, state=%0d", game_state);
        error_count = error_count + 1;
    end

    if ((cur_piece_type < PIECE_I) || (cur_piece_type > PIECE_L)) begin
        $display("ERROR: illegal current piece type %0d", cur_piece_type);
        error_count = error_count + 1;
    end

    saved_x = cur_piece_x;
    pulse_left;
    if (cur_piece_x > saved_x) begin
        $display("ERROR: left pulse moved in wrong direction x=%0d saved=%0d",
                 cur_piece_x, saved_x);
        error_count = error_count + 1;
    end

    saved_x = cur_piece_x;
    pulse_right;
    if (cur_piece_x < saved_x) begin
        $display("ERROR: right pulse moved in wrong direction x=%0d saved=%0d",
                 cur_piece_x, saved_x);
        error_count = error_count + 1;
    end

    saved_rot = cur_piece_rot;
    pulse_rotate;
    if (cur_piece_rot == saved_rot) begin
        $display("ERROR: rotate pulse did not change rotation");
        error_count = error_count + 1;
    end

    saved_y = cur_piece_y;
    btn_soft_drop_hold = 1'b1;
    repeat (12) begin
        @(posedge clk_100m);
        #1;
        check_no_x("soft drop run");
    end
    btn_soft_drop_hold = 1'b0;

    if (cur_piece_y <= saved_y) begin
        $display("ERROR: soft drop did not move piece down y=%0d saved=%0d",
                 cur_piece_y, saved_y);
        error_count = error_count + 1;
    end

    board_query_row = cur_piece_y[4:0];
    board_query_col = cur_piece_x[3:0];
    #1;
    check_no_x("board query");

    repeat (64) begin
        @(posedge clk_100m);
        #1;
        check_no_x("state machine run");
    end

    if (error_count == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL: %0d errors", error_count);
    end

    $finish;
end

endmodule
