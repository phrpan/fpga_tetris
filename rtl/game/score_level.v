`timescale 1ns / 1ps

module score_level (
    input  wire        clk_100m,
    input  wire        rst,
    input  wire        clear_event,
    input  wire [2:0]  clear_count,
    output reg  [15:0] score,
    output reg  [7:0]  lines,
    output reg  [3:0]  level
);

`include "../common/game_defs.vh"

function [15:0] score_delta;
    input [2:0] count;
    input [3:0] cur_level;
begin
    case (count)
        3'd1: score_delta = 16'd100 * cur_level;
        3'd2: score_delta = 16'd300 * cur_level;
        3'd3: score_delta = 16'd500 * cur_level;
        3'd4: score_delta = 16'd800 * cur_level;
        default: score_delta = 16'd0;
    endcase
end
endfunction

function [3:0] calc_level;
    input [7:0] line_count;
    integer next_level;
begin
    next_level = (line_count / 10) + 1;
    if (next_level > 15) begin
        calc_level = 4'd15;
    end else begin
        calc_level = next_level[3:0];
    end
end
endfunction

always @(posedge clk_100m) begin
    if (rst) begin
        score <= 16'd0;
        lines <= 8'd0;
        level <= 4'd1;
    end else if (clear_event && (clear_count >= 3'd1) && (clear_count <= 3'd4)) begin
        score <= score + score_delta(clear_count, level);
        lines <= lines + {5'd0, clear_count};
        level <= calc_level(lines + {5'd0, clear_count});
    end
end

endmodule
