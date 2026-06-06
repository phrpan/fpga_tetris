`timescale 1ns / 1ps

module game_core (
    input  wire              clk_100m,
    input  wire              rst,

    input  wire              btn_left_pulse,
    input  wire              btn_right_pulse,
    input  wire              btn_rotate_pulse,
    input  wire              btn_soft_drop_hold,
    input  wire              btn_start_pulse,

    input  wire [4:0]        board_query_row,
    input  wire [3:0]        board_query_col,
    output reg  [3:0]        board_cell_value,

    output reg  [2:0]        cur_piece_type,
    output reg  [1:0]        cur_piece_rot,
    output reg signed [4:0]  cur_piece_x,
    output reg signed [5:0]  cur_piece_y,

    output reg  [2:0]        next_piece_type,
    output wire [15:0]       score,
    output wire [7:0]        lines,
    output wire [3:0]        level,
    output reg  [2:0]        game_state
);

`include "../common/game_defs.vh"

localparam NORMAL_FALL_TICKS = 26'd5000000;
localparam SOFT_FALL_TICKS   = 26'd5;

reg [3:0] board [0:19][0:9];
reg [25:0] gravity_counter;

integer row;
integer col;
integer cell_index;

wire random_enable;
wire [2:0] random_piece_type;

wire [799:0] board_flat_in;
wire [799:0] board_flat_out;
wire [19:0] clear_line_mask;
wire [2:0] clear_count;

wire score_clear_event;

wire [1:0] lock_dx0;
wire [1:0] lock_dy0;
wire [1:0] lock_dx1;
wire [1:0] lock_dy1;
wire [1:0] lock_dx2;
wire [1:0] lock_dy2;
wire [1:0] lock_dx3;
wire [1:0] lock_dy3;

wire signed [5:0] lock_x0;
wire signed [5:0] lock_x1;
wire signed [5:0] lock_x2;
wire signed [5:0] lock_x3;
wire signed [6:0] lock_y0;
wire signed [6:0] lock_y1;
wire signed [6:0] lock_y2;
wire signed [6:0] lock_y3;

wire spawn_collision;
wire left_collision;
wire right_collision;
wire rotate_collision;
wire down_collision;

wire [4:0] spawn_q_row0;
wire [3:0] spawn_q_col0;
wire [4:0] spawn_q_row1;
wire [3:0] spawn_q_col1;
wire [4:0] spawn_q_row2;
wire [3:0] spawn_q_col2;
wire [4:0] spawn_q_row3;
wire [3:0] spawn_q_col3;

wire [4:0] left_q_row0;
wire [3:0] left_q_col0;
wire [4:0] left_q_row1;
wire [3:0] left_q_col1;
wire [4:0] left_q_row2;
wire [3:0] left_q_col2;
wire [4:0] left_q_row3;
wire [3:0] left_q_col3;

wire [4:0] right_q_row0;
wire [3:0] right_q_col0;
wire [4:0] right_q_row1;
wire [3:0] right_q_col1;
wire [4:0] right_q_row2;
wire [3:0] right_q_col2;
wire [4:0] right_q_row3;
wire [3:0] right_q_col3;

wire [4:0] rotate_q_row0;
wire [3:0] rotate_q_col0;
wire [4:0] rotate_q_row1;
wire [3:0] rotate_q_col1;
wire [4:0] rotate_q_row2;
wire [3:0] rotate_q_col2;
wire [4:0] rotate_q_row3;
wire [3:0] rotate_q_col3;

wire [4:0] down_q_row0;
wire [3:0] down_q_col0;
wire [4:0] down_q_row1;
wire [3:0] down_q_col1;
wire [4:0] down_q_row2;
wire [3:0] down_q_col2;
wire [4:0] down_q_row3;
wire [3:0] down_q_col3;

function [3:0] piece_to_cell;
    input [2:0] piece;
begin
    case (piece)
        PIECE_I: piece_to_cell = CELL_I;
        PIECE_O: piece_to_cell = CELL_O;
        PIECE_T: piece_to_cell = CELL_T;
        PIECE_S: piece_to_cell = CELL_S;
        PIECE_Z: piece_to_cell = CELL_Z;
        PIECE_J: piece_to_cell = CELL_J;
        PIECE_L: piece_to_cell = CELL_L;
        default: piece_to_cell = CELL_EMPTY;
    endcase
end
endfunction

function [3:0] board_at;
    input [4:0] query_row;
    input [3:0] query_col;
begin
    if ((query_row < BOARD_ROWS) && (query_col < BOARD_COLS)) begin
        board_at = board[query_row][query_col];
    end else begin
        board_at = CELL_EMPTY;
    end
end
endfunction

assign random_enable = (game_state == GS_SPAWN);
assign score_clear_event = (game_state == GS_CLEAR) && (clear_count != 3'd0);

random_lfsr random_piece_gen (
    .clk_100m(clk_100m),
    .rst(rst),
    .enable(random_enable),
    .piece_type(random_piece_type)
);

score_level score_level_inst (
    .clk_100m(clk_100m),
    .rst(rst),
    .clear_event(score_clear_event),
    .clear_count(clear_count),
    .score(score),
    .lines(lines),
    .level(level)
);

line_clear line_clear_inst (
    .board_flat_in(board_flat_in),
    .board_flat_out(board_flat_out),
    .clear_line_mask(clear_line_mask),
    .clear_count(clear_count)
);

piece_rom lock_piece_block0 (
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .block_idx(2'd0),
    .dx(lock_dx0),
    .dy(lock_dy0)
);

piece_rom lock_piece_block1 (
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .block_idx(2'd1),
    .dx(lock_dx1),
    .dy(lock_dy1)
);

piece_rom lock_piece_block2 (
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .block_idx(2'd2),
    .dx(lock_dx2),
    .dy(lock_dy2)
);

piece_rom lock_piece_block3 (
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .block_idx(2'd3),
    .dx(lock_dx3),
    .dy(lock_dy3)
);

assign lock_x0 = {cur_piece_x[4], cur_piece_x} + {4'd0, lock_dx0};
assign lock_x1 = {cur_piece_x[4], cur_piece_x} + {4'd0, lock_dx1};
assign lock_x2 = {cur_piece_x[4], cur_piece_x} + {4'd0, lock_dx2};
assign lock_x3 = {cur_piece_x[4], cur_piece_x} + {4'd0, lock_dx3};
assign lock_y0 = {cur_piece_y[5], cur_piece_y} + {5'd0, lock_dy0};
assign lock_y1 = {cur_piece_y[5], cur_piece_y} + {5'd0, lock_dy1};
assign lock_y2 = {cur_piece_y[5], cur_piece_y} + {5'd0, lock_dy2};
assign lock_y3 = {cur_piece_y[5], cur_piece_y} + {5'd0, lock_dy3};

collision_check spawn_check (
    .test_x(5'sd3),
    .test_y(6'sd0),
    .piece_type(next_piece_type),
    .rotation(2'd0),
    .q_row0(spawn_q_row0),
    .q_col0(spawn_q_col0),
    .q_cell0(board_at(spawn_q_row0, spawn_q_col0)),
    .q_row1(spawn_q_row1),
    .q_col1(spawn_q_col1),
    .q_cell1(board_at(spawn_q_row1, spawn_q_col1)),
    .q_row2(spawn_q_row2),
    .q_col2(spawn_q_col2),
    .q_cell2(board_at(spawn_q_row2, spawn_q_col2)),
    .q_row3(spawn_q_row3),
    .q_col3(spawn_q_col3),
    .q_cell3(board_at(spawn_q_row3, spawn_q_col3)),
    .collision(spawn_collision)
);

collision_check left_check (
    .test_x(cur_piece_x - 5'sd1),
    .test_y(cur_piece_y),
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .q_row0(left_q_row0),
    .q_col0(left_q_col0),
    .q_cell0(board_at(left_q_row0, left_q_col0)),
    .q_row1(left_q_row1),
    .q_col1(left_q_col1),
    .q_cell1(board_at(left_q_row1, left_q_col1)),
    .q_row2(left_q_row2),
    .q_col2(left_q_col2),
    .q_cell2(board_at(left_q_row2, left_q_col2)),
    .q_row3(left_q_row3),
    .q_col3(left_q_col3),
    .q_cell3(board_at(left_q_row3, left_q_col3)),
    .collision(left_collision)
);

collision_check right_check (
    .test_x(cur_piece_x + 5'sd1),
    .test_y(cur_piece_y),
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .q_row0(right_q_row0),
    .q_col0(right_q_col0),
    .q_cell0(board_at(right_q_row0, right_q_col0)),
    .q_row1(right_q_row1),
    .q_col1(right_q_col1),
    .q_cell1(board_at(right_q_row1, right_q_col1)),
    .q_row2(right_q_row2),
    .q_col2(right_q_col2),
    .q_cell2(board_at(right_q_row2, right_q_col2)),
    .q_row3(right_q_row3),
    .q_col3(right_q_col3),
    .q_cell3(board_at(right_q_row3, right_q_col3)),
    .collision(right_collision)
);

collision_check rotate_check (
    .test_x(cur_piece_x),
    .test_y(cur_piece_y),
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot + 2'd1),
    .q_row0(rotate_q_row0),
    .q_col0(rotate_q_col0),
    .q_cell0(board_at(rotate_q_row0, rotate_q_col0)),
    .q_row1(rotate_q_row1),
    .q_col1(rotate_q_col1),
    .q_cell1(board_at(rotate_q_row1, rotate_q_col1)),
    .q_row2(rotate_q_row2),
    .q_col2(rotate_q_col2),
    .q_cell2(board_at(rotate_q_row2, rotate_q_col2)),
    .q_row3(rotate_q_row3),
    .q_col3(rotate_q_col3),
    .q_cell3(board_at(rotate_q_row3, rotate_q_col3)),
    .collision(rotate_collision)
);

collision_check down_check (
    .test_x(cur_piece_x),
    .test_y(cur_piece_y + 6'sd1),
    .piece_type(cur_piece_type),
    .rotation(cur_piece_rot),
    .q_row0(down_q_row0),
    .q_col0(down_q_col0),
    .q_cell0(board_at(down_q_row0, down_q_col0)),
    .q_row1(down_q_row1),
    .q_col1(down_q_col1),
    .q_cell1(board_at(down_q_row1, down_q_col1)),
    .q_row2(down_q_row2),
    .q_col2(down_q_col2),
    .q_cell2(board_at(down_q_row2, down_q_col2)),
    .q_row3(down_q_row3),
    .q_col3(down_q_col3),
    .q_cell3(board_at(down_q_row3, down_q_col3)),
    .collision(down_collision)
);

genvar flat_row;
genvar flat_col;
generate
    for (flat_row = 0; flat_row < BOARD_ROWS; flat_row = flat_row + 1) begin : gen_flat_row
        for (flat_col = 0; flat_col < BOARD_COLS; flat_col = flat_col + 1) begin : gen_flat_col
            assign board_flat_in[((flat_row * BOARD_COLS + flat_col) * 4) +: 4] =
                board[flat_row][flat_col];
        end
    end
endgenerate

always @* begin
    if ((board_query_row < BOARD_ROWS) && (board_query_col < BOARD_COLS)) begin
        board_cell_value = board[board_query_row][board_query_col];
    end else begin
        board_cell_value = CELL_EMPTY;
    end
end

always @(posedge clk_100m) begin
    if (rst) begin
        for (row = 0; row < BOARD_ROWS; row = row + 1) begin
            for (col = 0; col < BOARD_COLS; col = col + 1) begin
                board[row][col] <= CELL_EMPTY;
            end
        end

        game_state <= GS_TITLE;
        cur_piece_type <= PIECE_T;
        next_piece_type <= PIECE_T;
        cur_piece_x <= 5'sd3;
        cur_piece_y <= 6'sd0;
        cur_piece_rot <= 2'd0;
        gravity_counter <= 26'd0;
    end else begin
        case (game_state)
            GS_TITLE: begin
                gravity_counter <= 26'd0;
                if (btn_start_pulse) begin
                    for (row = 0; row < BOARD_ROWS; row = row + 1) begin
                        for (col = 0; col < BOARD_COLS; col = col + 1) begin
                            board[row][col] <= CELL_EMPTY;
                        end
                    end
                    game_state <= GS_SPAWN;
                end
            end

            GS_SPAWN: begin
                cur_piece_type <= next_piece_type;
                next_piece_type <= random_piece_type;
                cur_piece_x <= 5'sd3;
                cur_piece_y <= 6'sd0;
                cur_piece_rot <= 2'd0;
                gravity_counter <= 26'd0;

                if (spawn_collision) begin
                    game_state <= GS_GAME_OVER;
                end else begin
                    game_state <= GS_PLAY;
                end
            end

            GS_PLAY: begin
                if (btn_left_pulse && !left_collision) begin
                    cur_piece_x <= cur_piece_x - 5'sd1;
                end else if (btn_right_pulse && !right_collision) begin
                    cur_piece_x <= cur_piece_x + 5'sd1;
                end

                if (btn_rotate_pulse && !rotate_collision) begin
                    cur_piece_rot <= cur_piece_rot + 2'd1;
                end

                if (gravity_counter >= (btn_soft_drop_hold ? SOFT_FALL_TICKS : NORMAL_FALL_TICKS)) begin
                    gravity_counter <= 26'd0;
                    if (!down_collision) begin
                        cur_piece_y <= cur_piece_y + 6'sd1;
                    end else begin
                        game_state <= GS_LOCK;
                    end
                end else begin
                    gravity_counter <= gravity_counter + 26'd1;
                end
            end

            GS_LOCK: begin
                if ((lock_y0 >= 0) && (lock_y0 < BOARD_ROWS) &&
                    (lock_x0 >= 0) && (lock_x0 < BOARD_COLS)) begin
                    board[lock_y0[4:0]][lock_x0[3:0]] <= piece_to_cell(cur_piece_type);
                end
                if ((lock_y1 >= 0) && (lock_y1 < BOARD_ROWS) &&
                    (lock_x1 >= 0) && (lock_x1 < BOARD_COLS)) begin
                    board[lock_y1[4:0]][lock_x1[3:0]] <= piece_to_cell(cur_piece_type);
                end
                if ((lock_y2 >= 0) && (lock_y2 < BOARD_ROWS) &&
                    (lock_x2 >= 0) && (lock_x2 < BOARD_COLS)) begin
                    board[lock_y2[4:0]][lock_x2[3:0]] <= piece_to_cell(cur_piece_type);
                end
                if ((lock_y3 >= 0) && (lock_y3 < BOARD_ROWS) &&
                    (lock_x3 >= 0) && (lock_x3 < BOARD_COLS)) begin
                    board[lock_y3[4:0]][lock_x3[3:0]] <= piece_to_cell(cur_piece_type);
                end
                game_state <= GS_CLEAR;
            end

            GS_CLEAR: begin
                for (row = 0; row < BOARD_ROWS; row = row + 1) begin
                    for (col = 0; col < BOARD_COLS; col = col + 1) begin
                        cell_index = row * BOARD_COLS + col;
                        board[row][col] <= board_flat_out[cell_index*4 +: 4];
                    end
                end
                game_state <= GS_SPAWN;
            end

            GS_GAME_OVER: begin
                gravity_counter <= 26'd0;
                if (btn_start_pulse) begin
                    for (row = 0; row < BOARD_ROWS; row = row + 1) begin
                        for (col = 0; col < BOARD_COLS; col = col + 1) begin
                            board[row][col] <= CELL_EMPTY;
                        end
                    end
                    game_state <= GS_SPAWN;
                end
            end

            default: begin
                game_state <= GS_TITLE;
            end
        endcase
    end
end

endmodule
