`timescale 1ns / 1ps

module top (
    input  wire CLK100MHZ,
    input  wire CPU_RESETN,
    output wire LED
);

    reg [26:0] cnt;

    always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN)
            cnt <= 27'd0;
        else
            cnt <= cnt + 27'd1;
    end

    assign LED = cnt[26];

endmodule