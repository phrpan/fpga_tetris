`timescale 1ns / 1ps

module bin16_to_bcd (
    input  wire [15:0] bin,
    output reg  [19:0] bcd
);

    integer i;

    always @* begin
        bcd = 20'd0;

        for (i = 15; i >= 0; i = i - 1) begin
            if (bcd[3:0] >= 4'd5)
                bcd[3:0] = bcd[3:0] + 4'd3;

            if (bcd[7:4] >= 4'd5)
                bcd[7:4] = bcd[7:4] + 4'd3;

            if (bcd[11:8] >= 4'd5)
                bcd[11:8] = bcd[11:8] + 4'd3;

            if (bcd[15:12] >= 4'd5)
                bcd[15:12] = bcd[15:12] + 4'd3;

            if (bcd[19:16] >= 4'd5)
                bcd[19:16] = bcd[19:16] + 4'd3;

            bcd = {bcd[18:0], bin[i]};
        end
    end

endmodule