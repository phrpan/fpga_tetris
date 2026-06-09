`timescale 1ns / 1ps

module tb_vga_timing;

    // ------------------------------------------------------------
    // VGA timing parameters, same as DUT
    // ------------------------------------------------------------
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    // 25MHz pixel clock: period = 40ns
    localparam CLK_PERIOD = 40;

    reg        pix_clk;
    reg        rst;

    wire       hsync;
    wire       vsync;
    wire       video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    integer errors;
    integer i;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    vga_timing uut (
        .pix_clk  (pix_clk),
        .rst      (rst),
        .hsync    (hsync),
        .vsync    (vsync),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------
    initial begin
        pix_clk = 1'b0;
        forever #(CLK_PERIOD / 2) pix_clk = ~pix_clk;
    end

    // ------------------------------------------------------------
    // Helper task: check current timing signals
    // ------------------------------------------------------------
    task check_current_pixel;
        reg expected_hsync;
        reg expected_vsync;
        reg expected_video_on;
        begin
            expected_hsync = ~((pixel_x >= H_DISPLAY + H_FRONT) &&
                               (pixel_x <  H_DISPLAY + H_FRONT + H_SYNC));

            expected_vsync = ~((pixel_y >= V_DISPLAY + V_FRONT) &&
                               (pixel_y <  V_DISPLAY + V_FRONT + V_SYNC));

            expected_video_on = (pixel_x < H_DISPLAY) &&
                                (pixel_y < V_DISPLAY);

            if (hsync !== expected_hsync) begin
                $display("[%0t] ERROR: hsync mismatch. x=%0d y=%0d hsync=%b expected=%b",
                         $time, pixel_x, pixel_y, hsync, expected_hsync);
                errors = errors + 1;
            end

            if (vsync !== expected_vsync) begin
                $display("[%0t] ERROR: vsync mismatch. x=%0d y=%0d vsync=%b expected=%b",
                         $time, pixel_x, pixel_y, vsync, expected_vsync);
                errors = errors + 1;
            end

            if (video_on !== expected_video_on) begin
                $display("[%0t] ERROR: video_on mismatch. x=%0d y=%0d video_on=%b expected=%b",
                         $time, pixel_x, pixel_y, video_on, expected_video_on);
                errors = errors + 1;
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------
    initial begin
        errors = 0;

        $display("========================================");
        $display("Start tb_vga_timing");
        $display("========================================");

        // reset
        rst = 1'b1;
        repeat (5) @(posedge pix_clk);
        rst = 1'b0;
        @(posedge pix_clk);

        // Check reset result
        if (pixel_x !== 10'd0 || pixel_y !== 10'd0) begin
            $display("[%0t] ERROR: reset failed. pixel_x=%0d pixel_y=%0d",
                     $time, pixel_x, pixel_y);
            errors = errors + 1;
        end else begin
            $display("[%0t] Reset check passed.", $time);
        end

        // Run one full VGA frame and check every pixel
        for (i = 0; i < H_TOTAL * V_TOTAL; i = i + 1) begin
            @(posedge pix_clk);
            #1;
            check_current_pixel();
        end

        // After one full frame, counters should wrap around
        if (pixel_x !== 10'd0 || pixel_y !== 10'd0) begin
            $display("[%0t] ERROR: frame wrap failed. pixel_x=%0d pixel_y=%0d",
                     $time, pixel_x, pixel_y);
            errors = errors + 1;
        end else begin
            $display("[%0t] Frame wrap check passed.", $time);
        end

        // Run a few more lines for waveform observation
        repeat (H_TOTAL * 5) begin
            @(posedge pix_clk);
            #1;
            check_current_pixel();
        end

        if (errors == 0) begin
            $display("========================================");
            $display("tb_vga_timing PASSED.");
            $display("No errors found.");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("tb_vga_timing FAILED.");
            $display("Total errors = %0d", errors);
            $display("========================================");
        end

        $stop;
    end

endmodule