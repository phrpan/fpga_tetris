`timescale 1ns / 1ps

module tb_debounce;
    parameter WIDTH = 2;
    parameter CNT_MAX = 20'd3;

    reg clk_100m;
    reg rst;
    reg [WIDTH-1:0] btn_raw;
    wire [WIDTH-1:0] btn_deb;
    integer error_count;

    debounce #(
        .WIDTH(WIDTH),
        .CNT_MAX(CNT_MAX)
    ) uut (
        .clk_100m(clk_100m),
        .rst(rst),
        .btn_raw(btn_raw),
        .btn_deb(btn_deb)
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

    task wait_ticks;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                tick();
            end
        end
    endtask

    initial begin
        error_count = 0;
        rst = 1'b1;
        btn_raw = 2'b00;
        wait_ticks(3);
        if (btn_deb !== 2'b00) fail("reset should clear debounced output");

        rst = 1'b0;
        wait_ticks(2);

        btn_raw[0] = 1'b1;
        wait_ticks(1);
        btn_raw[0] = 1'b0;
        wait_ticks(1);
        btn_raw[0] = 1'b1;
        wait_ticks(1);
        btn_raw[0] = 1'b0;
        wait_ticks(8);
        if (btn_deb[0] !== 1'b0) fail("short bouncing input should be filtered");

        btn_raw[0] = 1'b1;
        wait_ticks(8);
        if (btn_deb[0] !== 1'b1) fail("stable press should debounce high");
        btn_raw[0] = 1'b0;
        wait_ticks(8);
        if (btn_deb[0] !== 1'b0) fail("stable release should debounce low");

        btn_raw = 2'b11;
        wait_ticks(8);
        if (btn_deb !== 2'b11) fail("multiple stable inputs should debounce high");

        rst = 1'b1;
        wait_ticks(2);
        if (btn_deb !== 2'b00) fail("reset should clear debounced output while raw is high");
        rst = 1'b0;
        btn_raw = 2'b00;
        wait_ticks(8);
        if (btn_deb !== 2'b00) fail("released inputs should remain low after reset");

        if (error_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", error_count);
        end
        $finish;
    end
endmodule
