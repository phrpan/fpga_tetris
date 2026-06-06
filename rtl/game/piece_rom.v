`timescale 1ns / 1ps

module piece_rom (
    input  wire [2:0] piece_type,
    input  wire [1:0] rotation,
    input  wire [1:0] block_idx,
    output reg  [1:0] dx,
    output reg  [1:0] dy
);

`include "../common/game_defs.vh"

always @* begin
    dx = 2'd0;
    dy = 2'd0;

    case (piece_type)
        PIECE_I: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd1; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd3; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd2; dy = 2'd0; end
                        2'd1: begin dx = 2'd2; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd2; end
                        2'd3: begin dx = 2'd2; dy = 2'd3; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd2; end
                        2'd1: begin dx = 2'd1; dy = 2'd2; end
                        2'd2: begin dx = 2'd2; dy = 2'd2; end
                        2'd3: begin dx = 2'd3; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd2; end
                        2'd3: begin dx = 2'd1; dy = 2'd3; end
                    endcase
                end
            endcase
        end

        PIECE_O: begin
            case (block_idx)
                2'd0: begin dx = 2'd1; dy = 2'd0; end
                2'd1: begin dx = 2'd2; dy = 2'd0; end
                2'd2: begin dx = 2'd1; dy = 2'd1; end
                2'd3: begin dx = 2'd2; dy = 2'd1; end
            endcase
        end

        PIECE_T: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd1; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
            endcase
        end

        PIECE_S: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd2; dy = 2'd0; end
                        2'd2: begin dx = 2'd0; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd2; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd1; end
                        2'd1: begin dx = 2'd2; dy = 2'd1; end
                        2'd2: begin dx = 2'd0; dy = 2'd2; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
            endcase
        end

        PIECE_Z: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd0; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd2; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd1; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd2; end
                        2'd3: begin dx = 2'd2; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd0; dy = 2'd2; end
                    endcase
                end
            endcase
        end

        PIECE_J: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd2; dy = 2'd0; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd1; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd0; dy = 2'd2; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
            endcase
        end

        PIECE_L: begin
            case (rotation)
                2'd0: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd2; dy = 2'd0; end
                        2'd1: begin dx = 2'd0; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd2; dy = 2'd1; end
                    endcase
                end
                2'd1: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd1; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd1; dy = 2'd2; end
                        2'd3: begin dx = 2'd2; dy = 2'd2; end
                    endcase
                end
                2'd2: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd1; end
                        2'd1: begin dx = 2'd1; dy = 2'd1; end
                        2'd2: begin dx = 2'd2; dy = 2'd1; end
                        2'd3: begin dx = 2'd0; dy = 2'd2; end
                    endcase
                end
                2'd3: begin
                    case (block_idx)
                        2'd0: begin dx = 2'd0; dy = 2'd0; end
                        2'd1: begin dx = 2'd1; dy = 2'd0; end
                        2'd2: begin dx = 2'd1; dy = 2'd1; end
                        2'd3: begin dx = 2'd1; dy = 2'd2; end
                    endcase
                end
            endcase
        end

        default: begin
            dx = 2'd0;
            dy = 2'd0;
        end
    endcase
end

endmodule
