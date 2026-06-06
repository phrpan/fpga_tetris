`timescale 1ns / 1ps

module tb_collision_check;

`include "../rtl/common/game_defs.vh"

reg signed [4:0] test_x;
reg signed [5:0] test_y;
reg [2:0]        piece_type;
reg [1:0]        rotation;

wire [4:0]       q_row0;
wire [3:0]       q_col0;
reg  [3:0]       q_cell0;
wire [4:0]       q_row1;
wire [3:0]       q_col1;
reg  [3:0]       q_cell1;
wire [4:0]       q_row2;
wire [3:0]       q_col2;
reg  [3:0]       q_cell2;
wire [4:0]       q_row3;
wire [3:0]       q_col3;
reg  [3:0]       q_cell3;
wire             collision;

integer error_count;

collision_check dut (
    .test_x(test_x),
    .test_y(test_y),
    .piece_type(piece_type),
    .rotation(rotation),
    .q_row0(q_row0),
    .q_col0(q_col0),
    .q_cell0(q_cell0),
    .q_row1(q_row1),
    .q_col1(q_col1),
    .q_cell1(q_cell1),
    .q_row2(q_row2),
    .q_col2(q_col2),
    .q_cell2(q_cell2),
    .q_row3(q_row3),
    .q_col3(q_col3),
    .q_cell3(q_cell3),
    .collision(collision)
);

task clear_cells;
begin
    q_cell0 = CELL_EMPTY;
    q_cell1 = CELL_EMPTY;
    q_cell2 = CELL_EMPTY;
    q_cell3 = CELL_EMPTY;
end
endtask

task check_collision;
    input expected;
    input [8*48-1:0] name;
begin
    #1;
    if (collision !== expected) begin
        $display("ERROR: %0s expected collision=%0d got %0d",
                 name, expected, collision);
        error_count = error_count + 1;
    end else begin
        $display("OK: %0s collision=%0d", name, collision);
    end
end
endtask

initial begin
    error_count = 0;

    piece_type = PIECE_T;
    rotation = 2'd0;
    test_x = 5'sd3;
    test_y = 6'sd0;
    clear_cells;
    check_collision(1'b0, "empty board T at x=3 y=0");

    test_x = -5'sd1;
    test_y = 6'sd0;
    clear_cells;
    check_collision(1'b1, "left boundary x=-1");

    test_x = 5'sd8;
    test_y = 6'sd0;
    clear_cells;
    check_collision(1'b1, "right boundary x=8");

    test_x = 5'sd3;
    test_y = 6'sd19;
    clear_cells;
    check_collision(1'b1, "bottom boundary y=19");

    test_x = 5'sd3;
    test_y = 6'sd0;
    clear_cells;
    q_cell0 = CELL_T;
    check_collision(1'b1, "occupied board cell");

    test_x = 5'sd3;
    test_y = -6'sd1;
    clear_cells;
    check_collision(1'b0, "partial spawn above board y=-1");

    if (error_count == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL: %0d errors", error_count);
    end

    $finish;
end

endmodule
