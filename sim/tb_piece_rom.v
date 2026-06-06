`timescale 1ns / 1ps

module tb_piece_rom;

reg  [2:0] piece_type;
reg  [1:0] rotation;
reg  [1:0] block_idx;
wire [1:0] dx;
wire [1:0] dy;

integer p;
integer r;
integer b;
integer error_count;

piece_rom dut (
    .piece_type(piece_type),
    .rotation(rotation),
    .block_idx(block_idx),
    .dx(dx),
    .dy(dy)
);

initial begin
    error_count = 0;

    for (p = 0; p < 7; p = p + 1) begin
        for (r = 0; r < 4; r = r + 1) begin
            for (b = 0; b < 4; b = b + 1) begin
                piece_type = p[2:0];
                rotation   = r[1:0];
                block_idx  = b[1:0];
                #1;

                $display("piece=%0d rot=%0d block=%0d dx=%0d dy=%0d",
                         piece_type, rotation, block_idx, dx, dy);

                if ((^dx === 1'bx) || (^dy === 1'bx) ||
                    (dx > 2'd3) || (dy > 2'd3)) begin
                    $display("ERROR: coordinate out of range or unknown");
                    error_count = error_count + 1;
                end
            end
        end
    end

    piece_type = 3'd7;
    rotation   = 2'd0;
    block_idx  = 2'd0;
    #1;

    $display("illegal piece test: piece=%0d rot=%0d block=%0d dx=%0d dy=%0d",
             piece_type, rotation, block_idx, dx, dy);

    if ((dx !== 2'd0) || (dy !== 2'd0)) begin
        $display("ERROR: illegal piece_type should return dx=0 dy=0");
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
