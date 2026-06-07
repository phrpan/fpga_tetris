`timescale 1ns / 1ps

module tb_button_input;
    reg clk_100m;
    reg rst;
    reg btnc;
    reg btnu;
    reg btnd;
    reg btnl;
    reg btnr;

    wire btn_start_pulse;
    wire btn_left_pulse;
    wire btn_right_pulse;
    wire btn_rotate_pulse;
    wire btn_soft_drop_hold;

    integer error_count;
    integer start_count;
    integer left_count;
    integer right_count;
    integer rotate_count;

    button_input #(
        .DEBOUNCE_TICKS(20'd3)
    ) uut (
        .clk_100m(clk_100m),
        .rst(rst),
        .btnc(btnc),
        .btnu(btnu),
        .btnd(btnd),
        .btnl(btnl),
        .btnr(btnr),
        .btn_start_pulse(btn_start_pulse),
        .btn_left_pulse(btn_left_pulse),
        .btn_right_pulse(btn_right_pulse),
        .btn_rotate_pulse(btn_rotate_pulse),
        .btn_soft_drop_hold(btn_soft_drop_hold)
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

    task clear_counts;
        begin
            start_count = 0;
            left_count = 0;
            right_count = 0;
            rotate_count = 0;
        end
    endtask

    task sample_counts;
        begin
            if (btn_start_pulse) start_count = start_count + 1;
            if (btn_left_pulse) left_count = left_count + 1;
            if (btn_right_pulse) right_count = right_count + 1;
            if (btn_rotate_pulse) rotate_count = rotate_count + 1;
        end
    endtask

    task sample_for;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                tick();
                sample_counts();
            end
        end
    endtask

    initial begin
        error_count = 0;
        clear_counts();
        rst = 1'b1;
        btnc = 1'b0;
        btnu = 1'b0;
        btnd = 1'b0;
        btnl = 1'b0;
        btnr = 1'b0;

        wait_ticks(3);
        if (btn_start_pulse || btn_left_pulse || btn_right_pulse ||
            btn_rotate_pulse || btn_soft_drop_hold) begin
            fail("reset should clear all button outputs");
        end

        rst = 1'b0;
        wait_ticks(2);

        clear_counts();
        btnl = 1'b1;
        sample_for(12);
        if (left_count != 1) fail("left press should produce exactly one pulse");
        sample_for(5);
        if (left_count != 1) fail("held left should not repeat without release");
        btnl = 1'b0;
        sample_for(10);
        if (left_count != 1) fail("left release should not produce a pulse");

        clear_counts();
        btnr = 1'b1;
        sample_for(12);
        if (right_count != 1) fail("right press should produce exactly one pulse");
        btnr = 1'b0;
        sample_for(10);
        if (right_count != 1) fail("right release should not produce a pulse");

        clear_counts();
        btnu = 1'b1;
        sample_for(12);
        if (rotate_count != 1) fail("rotate press should produce exactly one pulse");
        btnu = 1'b0;
        sample_for(10);
        if (rotate_count != 1) fail("rotate release should not produce a pulse");

        clear_counts();
        btnc = 1'b1;
        sample_for(12);
        if (start_count != 1) fail("start press should produce exactly one pulse");
        btnc = 1'b0;
        sample_for(10);
        if (start_count != 1) fail("start release should not produce a pulse");

        clear_counts();
        btnl = 1'b1;
        sample_for(1);
        btnl = 1'b0;
        sample_for(1);
        btnl = 1'b1;
        sample_for(1);
        btnl = 1'b0;
        sample_for(10);
        if (left_count != 0) fail("short left bounce should be filtered");

        btnd = 1'b1;
        wait_ticks(12);
        if (btn_soft_drop_hold !== 1'b1) fail("soft drop should become high while held");
        wait_ticks(5);
        if (btn_soft_drop_hold !== 1'b1) fail("soft drop should stay high while held");
        btnd = 1'b0;
        wait_ticks(12);
        if (btn_soft_drop_hold !== 1'b0) fail("soft drop should return low after release");

        rst = 1'b1;
        wait_ticks(2);
        if (btn_start_pulse || btn_left_pulse || btn_right_pulse ||
            btn_rotate_pulse || btn_soft_drop_hold) begin
            fail("reset should clear outputs after activity");
        end

        if (error_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", error_count);
        end
        $finish;
    end
endmodule
