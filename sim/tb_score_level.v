`timescale 1ns / 1ps

module tb_score_level;

`include "../rtl/common/game_defs.vh"

reg         clk_100m;
reg         rst;
reg         clear_event;
reg  [2:0]  clear_count;
wire [15:0] score;
wire [7:0]  lines;
wire [3:0]  level;

integer error_count;

score_level dut (
    .clk_100m(clk_100m),
    .rst(rst),
    .clear_event(clear_event),
    .clear_count(clear_count),
    .score(score),
    .lines(lines),
    .level(level)
);

initial begin
    clk_100m = 1'b0;
end

always #5 clk_100m = ~clk_100m;

task pulse_clear;
    input [2:0] count;
begin
    @(negedge clk_100m);
    clear_count = count;
    clear_event = 1'b1;
    @(posedge clk_100m);
    #1;
    clear_event = 1'b0;
    clear_count = 3'd0;
end
endtask

task check_state;
    input [15:0] expected_score;
    input [7:0]  expected_lines;
    input [3:0]  expected_level;
    input [8*48-1:0] name;
begin
    if (score !== expected_score) begin
        $display("ERROR: %0s expected score=%0d got=%0d",
                 name, expected_score, score);
        error_count = error_count + 1;
    end
    if (lines !== expected_lines) begin
        $display("ERROR: %0s expected lines=%0d got=%0d",
                 name, expected_lines, lines);
        error_count = error_count + 1;
    end
    if (level !== expected_level) begin
        $display("ERROR: %0s expected level=%0d got=%0d",
                 name, expected_level, level);
        error_count = error_count + 1;
    end
end
endtask

initial begin
    error_count = 0;
    rst = 1'b1;
    clear_event = 1'b0;
    clear_count = 3'd0;

    repeat (3) @(posedge clk_100m);
    rst = 1'b0;
    @(posedge clk_100m);
    #1;
    check_state(16'd0, 8'd0, 4'd1, "after reset");

    pulse_clear(3'd1);
    check_state(16'd100, 8'd1, 4'd1, "clear one line");

    pulse_clear(3'd4);
    check_state(16'd900, 8'd5, 4'd1, "clear four lines");

    pulse_clear(3'd4);
    check_state(16'd1700, 8'd9, 4'd1, "clear four lines again");

    pulse_clear(3'd1);
    check_state(16'd1800, 8'd10, 4'd2, "reach level two");

    @(negedge clk_100m);
    clear_count = 3'd4;
    clear_event = 1'b0;
    @(posedge clk_100m);
    #1;
    clear_count = 3'd0;
    check_state(16'd1800, 8'd10, 4'd2, "clear_event zero");

    @(negedge clk_100m);
    clear_count = 3'd0;
    clear_event = 1'b1;
    @(posedge clk_100m);
    #1;
    clear_event = 1'b0;
    check_state(16'd1800, 8'd10, 4'd2, "clear_count zero");

    if (error_count == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL: %0d errors", error_count);
    end

    $finish;
end

endmodule
