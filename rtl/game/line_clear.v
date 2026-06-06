`timescale 1ns / 1ps

module line_clear (
    input  wire [799:0] board_flat_in,
    output reg  [799:0] board_flat_out,
    output reg  [19:0]  clear_line_mask,
    output reg  [2:0]   clear_count
);

`include "../common/game_defs.vh"

integer row;
integer col;
integer write_row;
integer src_cell_index;
integer dst_cell_index;
reg row_full;

always @* begin
    board_flat_out = 800'd0;
    clear_line_mask = 20'd0;
    clear_count = 3'd0;
    write_row = BOARD_ROWS - 1;

    for (row = BOARD_ROWS - 1; row >= 0; row = row - 1) begin
        row_full = 1'b1;

        for (col = 0; col < BOARD_COLS; col = col + 1) begin
            src_cell_index = row * BOARD_COLS + col;
            if (board_flat_in[src_cell_index*4 +: 4] == CELL_EMPTY) begin
                row_full = 1'b0;
            end
        end

        if (row_full) begin
            clear_line_mask[row] = 1'b1;
            clear_count = clear_count + 3'd1;
        end else begin
            for (col = 0; col < BOARD_COLS; col = col + 1) begin
                src_cell_index = row * BOARD_COLS + col;
                dst_cell_index = write_row * BOARD_COLS + col;
                board_flat_out[dst_cell_index*4 +: 4] =
                    board_flat_in[src_cell_index*4 +: 4];
            end
            write_row = write_row - 1;
        end
    end
end

endmodule
