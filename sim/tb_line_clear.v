`timescale 1ns / 1ps

module tb_line_clear;

`include "../rtl/common/game_defs.vh"

reg  [799:0] board_flat_in;
wire [799:0] board_flat_out;
wire [19:0]  clear_line_mask;
wire [2:0]   clear_count;

integer error_count;
integer col;

line_clear dut (
    .board_flat_in(board_flat_in),
    .board_flat_out(board_flat_out),
    .clear_line_mask(clear_line_mask),
    .clear_count(clear_count)
);

task clear_board;
begin
    board_flat_in = 800'd0;
end
endtask

task set_cell;
    input integer row;
    input integer col;
    input [3:0] value;
    integer cell_index;
begin
    cell_index = row * BOARD_COLS + col;
    board_flat_in[cell_index*4 +: 4] = value;
end
endtask

task fill_row;
    input integer row;
    input [3:0] value;
    integer fill_col;
begin
    for (fill_col = 0; fill_col < BOARD_COLS; fill_col = fill_col + 1) begin
        set_cell(row, fill_col, value);
    end
end
endtask

task check_cell;
    input [799:0] board_value;
    input integer row;
    input integer col;
    input [3:0] expected;
    input [8*48-1:0] name;
    integer cell_index;
    reg [3:0] actual;
begin
    cell_index = row * BOARD_COLS + col;
    actual = board_value[cell_index*4 +: 4];
    if (actual !== expected) begin
        $display("ERROR: %0s row=%0d col=%0d expected=%0d got=%0d",
                 name, row, col, expected, actual);
        error_count = error_count + 1;
    end
end
endtask

task check_result;
    input [2:0] expected_count;
    input [19:0] expected_mask;
    input [8*48-1:0] name;
begin
    #1;
    if (clear_count !== expected_count) begin
        $display("ERROR: %0s expected clear_count=%0d got=%0d",
                 name, expected_count, clear_count);
        error_count = error_count + 1;
    end
    if (clear_line_mask !== expected_mask) begin
        $display("ERROR: %0s expected mask=%h got=%h",
                 name, expected_mask, clear_line_mask);
        error_count = error_count + 1;
    end
end
endtask

initial begin
    error_count = 0;

    clear_board;
    check_result(3'd0, 20'd0, "empty board");
    if (board_flat_out !== 800'd0) begin
        $display("ERROR: empty board output should remain empty");
        error_count = error_count + 1;
    end

    clear_board;
    fill_row(19, CELL_I);
    check_result(3'd1, 20'h80000, "bottom row full");
    if (board_flat_out !== 800'd0) begin
        $display("ERROR: single bottom clear output should be empty");
        error_count = error_count + 1;
    end

    clear_board;
    fill_row(18, CELL_T);
    fill_row(19, CELL_Z);
    check_result(3'd2, 20'hc0000, "bottom two rows full");
    if (board_flat_out !== 800'd0) begin
        $display("ERROR: double bottom clear output should be empty");
        error_count = error_count + 1;
    end

    clear_board;
    fill_row(10, CELL_J);
    set_cell(9, 3, CELL_L);
    set_cell(12, 4, CELL_S);
    check_result(3'd1, 20'h00400, "middle row full");
    check_cell(board_flat_out, 10, 3, CELL_L, "upper row moved down");
    check_cell(board_flat_out, 12, 4, CELL_S, "lower row stayed in place");
    check_cell(board_flat_out, 9, 3, CELL_EMPTY, "source row became empty");

    clear_board;
    for (col = 0; col < BOARD_COLS - 1; col = col + 1) begin
        set_cell(19, col, CELL_O);
    end
    check_result(3'd0, 20'd0, "non-full row");
    if (board_flat_out !== board_flat_in) begin
        $display("ERROR: non-full board should not change");
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
