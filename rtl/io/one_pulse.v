// one_pulse.v - rising-edge detector with one-clock output pulse

`timescale 1ns / 1ps

module one_pulse #(
    parameter WIDTH = 1
)(
    input  wire             clk_100m,
    input  wire             rst,
    input  wire [WIDTH-1:0] sig_in,
    output reg  [WIDTH-1:0] pulse_out
);

    reg [WIDTH-1:0] sig_d;

    always @(posedge clk_100m) begin
        if (rst) begin
            sig_d <= {WIDTH{1'b0}};
            pulse_out <= {WIDTH{1'b0}};
        end else begin
            sig_d <= sig_in;
            pulse_out <= sig_in & ~sig_d;
        end
    end

endmodule
