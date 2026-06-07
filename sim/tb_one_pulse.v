`timescale 1ns / 1ps

module tb_one_pulse;
    reg clk_100m;
    reg rst;
    reg [2:0] sig_in;
    wire [2:0] pulse_out;
    integer error_count;

    one_pulse #(
        .WIDTH(3)
    ) uut (
        .clk_100m(clk_100m),
        .rst(rst),
        .sig_in(sig_in),
        .pulse_out(pulse_out)
    );

    initial begin
        clk_100m = 1'b0;
        forever #5 clk_100m = ~clk_100m;
    end

    task fail;
        input [255:0] message;
        begin
            $display("FAIL: %0s", message);
            error_count = error_count + 1;
        end
    endtask

    task tick;
        begin
            @(posedge clk_100m);
            #1;
        end
    endtask

    task expect_pulse;
        input [2:0] expected;
        input [255:0] message;
        begin
            tick();
            if (pulse_out !== expected) begin
                fail(message);
            end
        end
    endtask

    initial begin
        error_count = 0;
        rst = 1'b1;
        sig_in = 3'b000;
        tick();
        tick();
        if (pulse_out !== 3'b000) fail("reset should clear pulse_out");

        rst = 1'b0;
        tick();

        sig_in = 3'b001;
        expect_pulse(3'b001, "bit0 rising edge should pulse once");
        expect_pulse(3'b000, "held bit0 should not pulse again");
        sig_in = 3'b000;
        expect_pulse(3'b000, "falling edge should not pulse");

        sig_in = 3'b110;
        expect_pulse(3'b110, "multiple rising edges should pulse together");
        expect_pulse(3'b000, "held multiple bits should not pulse again");
        sig_in = 3'b010;
        expect_pulse(3'b000, "held bit after partial release should not repulse");
        sig_in = 3'b000;
        expect_pulse(3'b000, "release should not pulse");

        sig_in = 3'b100;
        expect_pulse(3'b100, "new rising edge after release should pulse");
        sig_in = 3'b000;
        expect_pulse(3'b000, "final release should not pulse");

        if (error_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", error_count);
        end
        $finish;
    end
endmodule
