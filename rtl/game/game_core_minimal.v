`timescale 1ns / 1ps

module game_core_minimal (
    input  wire              clk_100m,
    input  wire              rst,

    input  wire              btn_left_pulse,
    input  wire              btn_right_pulse,
    input  wire              btn_rotate_pulse,
    input  wire              btn_start_pulse,

    output reg  [2:0]        cur_piece_type,
    output reg  [1:0]        cur_piece_rot,
    output reg signed [4:0]  cur_piece_x,
    output reg signed [5:0]  cur_piece_y,
    output reg  [2:0]        game_state
);

`include "../common/game_defs.vh"

always @(posedge clk_100m) begin
    if (rst) begin
        cur_piece_type <= PIECE_T;
        cur_piece_rot  <= 2'd0;
        cur_piece_x    <= 5'sd3;
        cur_piece_y    <= 6'sd0;
        game_state     <= GS_TITLE;
    end else begin
        case (game_state)
            GS_TITLE: begin
                if (btn_start_pulse) begin
                    game_state <= GS_PLAY;
                end
            end

            GS_PLAY: begin
                if (btn_left_pulse && (cur_piece_x > 5'sd0)) begin
                    cur_piece_x <= cur_piece_x - 5'sd1;
                end else if (btn_right_pulse && (cur_piece_x < 5'sd6)) begin
                    cur_piece_x <= cur_piece_x + 5'sd1;
                end

                if (btn_rotate_pulse) begin
                    cur_piece_rot <= cur_piece_rot + 2'd1;
                end
            end

            default: begin
                game_state <= GS_TITLE;
            end
        endcase
    end
end

endmodule
