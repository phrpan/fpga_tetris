`timescale 1ns / 1ps

module collision_check (
    input  wire signed [4:0] test_x,
    input  wire signed [5:0] test_y,
    input  wire [2:0]        piece_type,
    input  wire [1:0]        rotation,

    output reg  [4:0]        q_row0,
    output reg  [3:0]        q_col0,
    input  wire [3:0]        q_cell0,

    output reg  [4:0]        q_row1,
    output reg  [3:0]        q_col1,
    input  wire [3:0]        q_cell1,

    output reg  [4:0]        q_row2,
    output reg  [3:0]        q_col2,
    input  wire [3:0]        q_cell2,

    output reg  [4:0]        q_row3,
    output reg  [3:0]        q_col3,
    input  wire [3:0]        q_cell3,

    output reg               collision
);

`include "../common/game_defs.vh"

wire [1:0] dx0;
wire [1:0] dy0;
wire [1:0] dx1;
wire [1:0] dy1;
wire [1:0] dx2;
wire [1:0] dy2;
wire [1:0] dx3;
wire [1:0] dy3;

wire signed [5:0] block_x0;
wire signed [5:0] block_x1;
wire signed [5:0] block_x2;
wire signed [5:0] block_x3;
wire signed [6:0] block_y0;
wire signed [6:0] block_y1;
wire signed [6:0] block_y2;
wire signed [6:0] block_y3;

piece_rom piece_block0 (
    .piece_type(piece_type),
    .rotation(rotation),
    .block_idx(2'd0),
    .dx(dx0),
    .dy(dy0)
);

piece_rom piece_block1 (
    .piece_type(piece_type),
    .rotation(rotation),
    .block_idx(2'd1),
    .dx(dx1),
    .dy(dy1)
);

piece_rom piece_block2 (
    .piece_type(piece_type),
    .rotation(rotation),
    .block_idx(2'd2),
    .dx(dx2),
    .dy(dy2)
);

piece_rom piece_block3 (
    .piece_type(piece_type),
    .rotation(rotation),
    .block_idx(2'd3),
    .dx(dx3),
    .dy(dy3)
);

assign block_x0 = {test_x[4], test_x} + {4'd0, dx0};
assign block_x1 = {test_x[4], test_x} + {4'd0, dx1};
assign block_x2 = {test_x[4], test_x} + {4'd0, dx2};
assign block_x3 = {test_x[4], test_x} + {4'd0, dx3};

assign block_y0 = {test_y[5], test_y} + {5'd0, dy0};
assign block_y1 = {test_y[5], test_y} + {5'd0, dy1};
assign block_y2 = {test_y[5], test_y} + {5'd0, dy2};
assign block_y3 = {test_y[5], test_y} + {5'd0, dy3};

always @* begin
    q_row0 = 5'd0;
    q_col0 = 4'd0;
    q_row1 = 5'd0;
    q_col1 = 4'd0;
    q_row2 = 5'd0;
    q_col2 = 4'd0;
    q_row3 = 5'd0;
    q_col3 = 4'd0;

    collision = 1'b0;

    if (block_y0 >= 0) begin
        if ((block_x0 >= 0) && (block_x0 < BOARD_COLS) && (block_y0 < BOARD_ROWS)) begin
            q_row0 = block_y0[4:0];
            q_col0 = block_x0[3:0];
        end
        if ((block_x0 < 0) || (block_x0 >= BOARD_COLS) || (block_y0 >= BOARD_ROWS) ||
            (((block_x0 >= 0) && (block_x0 < BOARD_COLS) && (block_y0 < BOARD_ROWS)) &&
             (q_cell0 != CELL_EMPTY))) begin
            collision = 1'b1;
        end
    end

    if (block_y1 >= 0) begin
        if ((block_x1 >= 0) && (block_x1 < BOARD_COLS) && (block_y1 < BOARD_ROWS)) begin
            q_row1 = block_y1[4:0];
            q_col1 = block_x1[3:0];
        end
        if ((block_x1 < 0) || (block_x1 >= BOARD_COLS) || (block_y1 >= BOARD_ROWS) ||
            (((block_x1 >= 0) && (block_x1 < BOARD_COLS) && (block_y1 < BOARD_ROWS)) &&
             (q_cell1 != CELL_EMPTY))) begin
            collision = 1'b1;
        end
    end

    if (block_y2 >= 0) begin
        if ((block_x2 >= 0) && (block_x2 < BOARD_COLS) && (block_y2 < BOARD_ROWS)) begin
            q_row2 = block_y2[4:0];
            q_col2 = block_x2[3:0];
        end
        if ((block_x2 < 0) || (block_x2 >= BOARD_COLS) || (block_y2 >= BOARD_ROWS) ||
            (((block_x2 >= 0) && (block_x2 < BOARD_COLS) && (block_y2 < BOARD_ROWS)) &&
             (q_cell2 != CELL_EMPTY))) begin
            collision = 1'b1;
        end
    end

    if (block_y3 >= 0) begin
        if ((block_x3 >= 0) && (block_x3 < BOARD_COLS) && (block_y3 < BOARD_ROWS)) begin
            q_row3 = block_y3[4:0];
            q_col3 = block_x3[3:0];
        end
        if ((block_x3 < 0) || (block_x3 >= BOARD_COLS) || (block_y3 >= BOARD_ROWS) ||
            (((block_x3 >= 0) && (block_x3 < BOARD_COLS) && (block_y3 < BOARD_ROWS)) &&
             (q_cell3 != CELL_EMPTY))) begin
            collision = 1'b1;
        end
    end
end

endmodule
