`timescale 1ns / 1ps

module random_lfsr (
    input  wire       clk_100m,
    input  wire       rst,
    input  wire       enable,
    output reg  [2:0] piece_type
);

`include "../common/game_defs.vh"

reg [7:0] lfsr;
wire feedback;
wire [7:0] lfsr_next;

assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
assign lfsr_next = {lfsr[6:0], feedback};

function [2:0] map_piece;
    input [7:0] value;
begin
    case (value[2:0])
        3'd0: map_piece = PIECE_I;
        3'd1: map_piece = PIECE_O;
        3'd2: map_piece = PIECE_T;
        3'd3: map_piece = PIECE_S;
        3'd4: map_piece = PIECE_Z;
        3'd5: map_piece = PIECE_J;
        3'd6: map_piece = PIECE_L;
        default: begin
            case (value[5:3])
                3'd0: map_piece = PIECE_I;
                3'd1: map_piece = PIECE_O;
                3'd2: map_piece = PIECE_T;
                3'd3: map_piece = PIECE_S;
                3'd4: map_piece = PIECE_Z;
                3'd5: map_piece = PIECE_J;
                default: map_piece = PIECE_L;
            endcase
        end
    endcase
end
endfunction

always @(posedge clk_100m) begin
    if (rst) begin
        lfsr <= 8'hA5;
        piece_type <= map_piece(8'hA5);
    end else if (enable) begin
        lfsr <= lfsr_next;
        piece_type <= map_piece(lfsr_next);
    end
end

endmodule
