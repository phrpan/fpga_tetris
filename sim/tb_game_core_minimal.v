`timescale 1ns / 1ps

module tb_game_core_minimal;

`include "../rtl/common/game_defs.vh"

reg               clk_100m;
reg               rst;
reg               btn_left_pulse;
reg               btn_right_pulse;
reg               btn_rotate_pulse;
reg               btn_start_pulse;

wire [2:0]        cur_piece_type;
wire [1:0]        cur_piece_rot;
wire signed [4:0] cur_piece_x;
wire signed [5:0] cur_piece_y;
wire [2:0]        game_state;

integer error_count;

game_core_minimal dut (
    .clk_100m(clk_100m),
    .rst(rst),
    .btn_left_pulse(btn_left_pulse),
    .btn_right_pulse(btn_right_pulse),
    .btn_rotate_pulse(btn_rotate_pulse),
    .btn_start_pulse(btn_start_pulse),
    .cur_piece_type(cur_piece_type),
    .cur_piece_rot(cur_piece_rot),
    .cur_piece_x(cur_piece_x),
    .cur_piece_y(cur_piece_y),
    .game_state(game_state)
);

initial begin
    clk_100m = 1'b0;
end

always #5 clk_100m = ~clk_100m;

initial begin
    error_count = 0;
    rst = 1'b1;
    btn_left_pulse = 1'b0;
    btn_right_pulse = 1'b0;
    btn_rotate_pulse = 1'b0;
    btn_start_pulse = 1'b0;

    repeat (3) @(posedge clk_100m);
    rst = 1'b0;
    @(posedge clk_100m);
    #1;

    if (game_state !== GS_TITLE) begin
        $display("ERROR: reset game_state expected GS_TITLE, got %0d", game_state);
        error_count = error_count + 1;
    end
    if (cur_piece_type !== PIECE_T) begin
        $display("ERROR: reset piece expected PIECE_T, got %0d", cur_piece_type);
        error_count = error_count + 1;
    end
    if ((cur_piece_x !== 5'sd3) || (cur_piece_y !== 6'sd0)) begin
        $display("ERROR: reset position expected x=3 y=0, got x=%0d y=%0d",
                 cur_piece_x, cur_piece_y);
        error_count = error_count + 1;
    end

    @(negedge clk_100m);
    btn_start_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_start_pulse = 1'b0;

    if (game_state !== GS_PLAY) begin
        $display("ERROR: start pulse expected GS_PLAY, got %0d", game_state);
        error_count = error_count + 1;
    end

    @(negedge clk_100m);
    btn_left_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_left_pulse = 1'b0;

    if (cur_piece_x !== 5'sd2) begin
        $display("ERROR: left pulse expected x=2, got x=%0d", cur_piece_x);
        error_count = error_count + 1;
    end

    @(negedge clk_100m);
    btn_right_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_right_pulse = 1'b0;

    if (cur_piece_x !== 5'sd3) begin
        $display("ERROR: right pulse expected x=3, got x=%0d", cur_piece_x);
        error_count = error_count + 1;
    end

    @(negedge clk_100m);
    btn_rotate_pulse = 1'b1;
    @(posedge clk_100m);
    #1;
    btn_rotate_pulse = 1'b0;

    if (cur_piece_rot !== 2'd1) begin
        $display("ERROR: rotate pulse expected rot=1, got rot=%0d", cur_piece_rot);
        error_count = error_count + 1;
    end

    if (error_count == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL: %0d errors", error_count);
    end

    $finish;
end

endmodule
