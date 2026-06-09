`timescale 1ns / 1ps

module tb_seven_seg_driver;

    reg        clk;
    reg        rst;
    reg [3:0]  digit_value;
    reg [2:0]  digit_sel;
    wire [7:0] an;
    wire [6:0] ca_g;

    integer errors;
    integer i;
    integer sel_idx;

    seven_seg_driver uut (
        .clk_100m(clk),
        .rst(rst),
        .digit_value(digit_value),
        .digit_sel(digit_sel),
        .an(an),
        .ca_g(ca_g)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [6:0] expected_seg;
        input [3:0] value;
        begin
            case (value)
                4'd0: expected_seg = 7'b1000000;
                4'd1: expected_seg = 7'b1111001;
                4'd2: expected_seg = 7'b0100100;
                4'd3: expected_seg = 7'b0110000;
                4'd4: expected_seg = 7'b0011001;
                4'd5: expected_seg = 7'b0010010;
                4'd6: expected_seg = 7'b0000010;
                4'd7: expected_seg = 7'b1111000;
                4'd8: expected_seg = 7'b0000000;
                4'd9: expected_seg = 7'b0010000;
                4'd10: expected_seg = 7'b1000110;
                4'd11: expected_seg = 7'b1010010;
                default: expected_seg = 7'b1000000;
            endcase
        end
    endfunction

    function [7:0] expected_an;
        input [2:0] value;
        begin
            expected_an = 8'hFF ^ (8'b00000001 << value);
        end
    endfunction

    task check_output;
        input [3:0] value;
        input [2:0] sel;
        begin
            digit_value = value;
            digit_sel = sel;
            @(posedge clk);
            #1;
            if (ca_g !== expected_seg(value)) begin
                $display("FAIL: digit %0d segment expected %b got %b", value, expected_seg(value), ca_g);
                errors = errors + 1;
            end
            if (an !== expected_an(sel)) begin
                $display("FAIL: select %0d an expected %b got %b", sel, expected_an(sel), an);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;
        digit_value = 4'd0;
        digit_sel = 3'd0;
        repeat (3) @(posedge clk);
        #1;

        if (an !== 8'hFF) begin
            $display("FAIL: reset an expected 11111111 got %b", an);
            errors = errors + 1;
        end
        if (ca_g !== 7'h7F) begin
            $display("FAIL: reset ca_g expected 1111111 got %b", ca_g);
            errors = errors + 1;
        end

        rst = 1'b0;
        @(posedge clk);

        for (i = 0; i < 10; i = i + 1) begin
            check_output(i[3:0], 3'd0);
        end

        check_output(4'd10, 3'd0);
        check_output(4'd11, 3'd0);
        check_output(4'd12, 3'd0);

        for (sel_idx = 0; sel_idx < 8; sel_idx = sel_idx + 1) begin
            check_output(4'd5, sel_idx[2:0]);
        end

        if (errors == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
