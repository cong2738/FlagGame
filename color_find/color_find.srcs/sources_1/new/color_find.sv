`timescale 1ns / 1ps

module color_find (
    input clk,
    input reset,
    input [9:0] x_pixel,
    input [9:0] y_pixel,
    input [11:0] pixel_color,
    output logic [9:0] user_x0,
    output logic [9:0] user_y0,
    output logic [9:0] user_x1,
    output logic [9:0] user_y1
);
    reg target0 = 12'hff;
    reg target1 = 12'hff;
    always_ff @(posedge clk, posedge reset) begin : COLOR_FIND
        if (reset) begin
            user_x0 <= 0;
            user_y0 <= 0;
            user_x1 <= 0;
            user_y1 <= 0;
        end else begin
            if (pixel_color == target0) begin
                user_x0 <= x_pixel;
                user_y0 <= y_pixel;
            end
            if (pixel_color == target1) begin
                user_x1 <= x_pixel;
                user_y1 <= y_pixel;
            end
        end
    end
endmodule
