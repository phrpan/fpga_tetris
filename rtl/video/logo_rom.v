`timescale 1ns / 1ps

// 128x128 12-bit RGB logo ROM
// Address = y * 128 + x, x/y range 0..127
module logo_rom (
    input  wire        pix_clk,
    input  wire [13:0] addr,
    output reg  [11:0] rgb
);

    reg [11:0] rom [0:16383];

    initial begin
        $readmemh("logo_128x128.mem", rom);
    end

    always @(posedge pix_clk) begin
        rgb <= rom[addr];
    end

endmodule
