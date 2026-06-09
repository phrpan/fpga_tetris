`timescale 1ns / 1ps

module tb_display;

    reg        clk;
    reg        rst;
    reg [7:0]  score;
    reg [7:0]  level;
    wire [7:0] an;
    wire [6:0] ca_g;

    integer errors;
    integer cycle_idx;
    reg seen_score_ones;
    reg seen_score_tens;
    reg seen_label_s;
    reg seen_level_ones;
    reg seen_level_tens;
    reg seen_label_l;

    display #(
        .SCAN_DIV_TICKS(17'd3)
    ) uut (
        .clk_100m(clk),
        .rst(rst),
        .score(score),
        .level(level),
        .an(an),
        .ca_g(ca_g)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [6:0] seg_code;
        input [3:0] value;
        begin
            case (value)
                4'd0: seg_code = 7'b1000000;
                4'd1: seg_code = 7'b1111001;
                4'd2: seg_code = 7'b0100100;
                4'd3: seg_code = 7'b0110000;
                4'd4: seg_code = 7'b0011001;
                4'd5: seg_code = 7'b0010010;
                4'd6: seg_code = 7'b0000010;
                4'd7: seg_code = 7'b1111000;
                4'd8: seg_code = 7'b0000000;
                4'd9: seg_code = 7'b0010000;
                4'd10: seg_code = 7'b1000110;
                4'd11: seg_code = 7'b1010010;
                default: seg_code = 7'b1000000;
            endcase
        end
    endfunction

    task clear_seen;
        begin
            seen_score_ones = 1'b0;
            seen_score_tens = 1'b0;
            seen_label_s = 1'b0;
            seen_level_ones = 1'b0;
            seen_level_tens = 1'b0;
            seen_label_l = 1'b0;
        end
    endtask

    task sample_display;
        input [3:0] exp_score_ones;
        input [3:0] exp_score_tens;
        input [3:0] exp_level_ones;
        input [3:0] exp_level_tens;
        begin
            for (cycle_idx = 0; cycle_idx < 120; cycle_idx = cycle_idx + 1) begin
                @(posedge clk);
                #1;
                if ((an === 8'b11111110) && (ca_g === seg_code(exp_score_ones)))
                    seen_score_ones = 1'b1;
                if ((an === 8'b11111101) && (ca_g === seg_code(exp_score_tens)))
                    seen_score_tens = 1'b1;
                if ((an === 8'b11111011) && (ca_g === seg_code(4'd11)))
                    seen_label_s = 1'b1;
                if ((an === 8'b11101111) && (ca_g === seg_code(exp_level_ones)))
                    seen_level_ones = 1'b1;
                if ((an === 8'b11011111) && (ca_g === seg_code(exp_level_tens)))
                    seen_level_tens = 1'b1;
                if ((an === 8'b10111111) && (ca_g === seg_code(4'd10)))
                    seen_label_l = 1'b1;
            end
        end
    endtask

    task check_seen;
        input [8*64-1:0] label;
        begin
            if (!seen_score_ones) begin
                $display("FAIL: %0s did not show score ones", label);
                errors = errors + 1;
            end
            if (!seen_score_tens) begin
                $display("FAIL: %0s did not show score tens", label);
                errors = errors + 1;
            end
            if (!seen_label_s) begin
                $display("FAIL: %0s did not show S label", label);
                errors = errors + 1;
            end
            if (!seen_level_ones) begin
                $display("FAIL: %0s did not show level ones", label);
                errors = errors + 1;
            end
            if (!seen_level_tens) begin
                $display("FAIL: %0s did not show level tens", label);
                errors = errors + 1;
            end
            if (!seen_label_l) begin
                $display("FAIL: %0s did not show L label", label);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;
        score = 8'd42;
        level = 8'd87;
        clear_seen();

        repeat (4) @(posedge clk);
        #1;
        if (an !== 8'hFF) begin
            $display("FAIL: reset an expected 11111111 got %b", an);
            errors = errors + 1;
        end

        rst = 1'b0;
        repeat (4) @(posedge clk);

        clear_seen();
        sample_display(4'd2, 4'd4, 4'd7, 4'd8);
        check_seen("score42_level87");

        score = 8'd99;
        level = 8'd15;
        repeat (4) @(posedge clk);

        clear_seen();
        sample_display(4'd9, 4'd9, 4'd5, 4'd1);
        check_seen("score99_level15");

        if (errors == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
