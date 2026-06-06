`timescale 1ns / 1ps

module tb_random_lfsr;

`include "../rtl/common/game_defs.vh"

reg        clk_100m;
reg        rst;
reg        enable;
wire [2:0] piece_type;

integer error_count;
integer i;
reg [2:0] first_piece;
reg changed;

random_lfsr dut (
    .clk_100m(clk_100m),
    .rst(rst),
    .enable(enable),
    .piece_type(piece_type)
);

initial begin
    clk_100m = 1'b0;
end

always #5 clk_100m = ~clk_100m;

task check_piece_legal;
    input [8*40-1:0] name;
begin
    if ((piece_type < PIECE_I) || (piece_type > PIECE_L) ||
        (piece_type == PIECE_NONE)) begin
        $display("ERROR: %0s illegal piece_type=%0d", name, piece_type);
        error_count = error_count + 1;
    end
end
endtask

initial begin
    error_count = 0;
    changed = 1'b0;
    rst = 1'b1;
    enable = 1'b0;

    repeat (3) @(posedge clk_100m);
    rst = 1'b0;
    @(posedge clk_100m);
    #1;

    check_piece_legal("after reset");
    first_piece = piece_type;

    enable = 1'b1;
    for (i = 0; i < 64; i = i + 1) begin
        @(posedge clk_100m);
        #1;
        check_piece_legal("enabled sequence");
        if (piece_type != first_piece) begin
            changed = 1'b1;
        end
    end
    enable = 1'b0;

    if (!changed) begin
        $display("ERROR: piece_type did not change during enabled sequence");
        error_count = error_count + 1;
    end

    if (error_count == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL: %0d errors", error_count);
    end

    $finish;
end

endmodule
