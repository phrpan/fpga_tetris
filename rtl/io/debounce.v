// debounce.v - active-high button debouncer

`timescale 1ns / 1ps

module debounce #(
    parameter WIDTH = 1,
    parameter CNT_MAX = 20'd999_999
)(
    input  wire             clk_100m,
    input  wire             rst,
    input  wire [WIDTH-1:0] btn_raw,
    output reg  [WIDTH-1:0] btn_deb
);

    reg [19:0] cnt [0:WIDTH-1];
    reg [WIDTH-1:0] btn_sync_0;
    reg [WIDTH-1:0] btn_sync_1;
    integer i;

    always @(posedge clk_100m) begin
        if (rst) begin
            btn_sync_0 <= {WIDTH{1'b0}};
            btn_sync_1 <= {WIDTH{1'b0}};
            btn_deb <= {WIDTH{1'b0}};
            for (i = 0; i < WIDTH; i = i + 1) begin
                cnt[i] <= 20'd0;
            end
        end else begin
            btn_sync_0 <= btn_raw;
            btn_sync_1 <= btn_sync_0;

            for (i = 0; i < WIDTH; i = i + 1) begin
                if (btn_sync_1[i] == btn_deb[i]) begin
                    cnt[i] <= 20'd0;
                end else if (cnt[i] < CNT_MAX) begin
                    cnt[i] <= cnt[i] + 1'b1;
                end else begin
                    btn_deb[i] <= btn_sync_1[i];
                    cnt[i] <= 20'd0;
                end
            end
        end
    end

endmodule
