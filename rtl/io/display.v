`timescale 1ns / 1ps

module display #(
    parameter SCAN_DIV_TICKS = 17'd100000
)(
    input  wire        clk_100m,
    input  wire        rst,
    input  wire [7:0]  score,
    input  wire [7:0]  level,
    output wire [7:0]  an,
    output wire [6:0]  ca_g
);
    reg [3:0] score_huns;
    reg [3:0] score_tens;
    reg [3:0] score_ones;
    reg [3:0] level_tens;
    reg [3:0] level_ones;

    reg [16:0] scan_div_cnt;
    reg [2:0]  scan_cnt;
    reg [2:0]  sel;
    reg [3:0]  seg_val;
    

    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            score_tens <= 4'd0;
            score_ones <= 4'd0;
            level_tens <= 4'd0;
            level_ones <= 4'd0;
        end else begin
            score_ones <= score % 10;
            score_tens <= (score / 10) % 10;
            level_ones <= level % 10;
            level_tens <= (level / 10) % 10;
        end
    end

    always @(posedge clk_100m or posedge rst) begin
        if (rst) begin
            scan_div_cnt <= 17'd0;
            scan_cnt     <= 3'd0;
            sel          <= 3'd0;
            seg_val      <= 4'd0;
        end else begin
            if (scan_div_cnt >= (SCAN_DIV_TICKS - 1'b1)) begin
                scan_div_cnt <= 17'd0;

                if (scan_cnt == 3'd5)
                    scan_cnt <= 3'd0;
                else
                    scan_cnt <= scan_cnt + 1'b1;
                case (scan_cnt)
                    3'd0: begin sel <= 3'd0; seg_val <= score_ones; end
                    3'd1: begin sel <= 3'd1; seg_val <= score_tens; end
                    3'd2: begin sel <= 3'd2; seg_val <= score_huns; end
                    3'd3: begin sel <= 3'd4; seg_val <= level_ones; end
                    3'd4: begin sel <= 3'd5; seg_val <= level_tens; end
//                    3'd5: begin sel <= 3'd6; seg_val <= 4'd10; end
                    default: begin sel <= 3'd0; seg_val <= score_ones; end
                endcase
            end else begin
                scan_div_cnt <= scan_div_cnt + 1'b1;
            end
        end
    end

    seven_seg_driver u_seg (
        .clk_100m(clk_100m),
        .rst(rst),
        .digit_value(seg_val),
        .digit_sel(sel),
        .an(an),
        .ca_g(ca_g)
    );

endmodule
