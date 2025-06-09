`timescale 1ns / 1ps

module color_find #(
    DISPLAY_W = 640,
    DISPLAY_H = 480
) (
    input clk,
    input reset,
    input [9:0] x_pixel,
    input [9:0] y_pixel,
    input [3:0] R,
    input [3:0] G,
    input [3:0] B,
    output logic [1:0] USER
);
    reg [31:0] blue_flag_U_count;
    reg [31:0] blue_flag_D_count;
    reg [31:0] red_flag_U_count;
    reg [31:0] red_flag_D_count;
    reg        blue_flag = (R < 10) && (G < 10) && (R < B) && (G < B);
    reg        red_flag = (G < 10) && (B < 10) && (G < R) && (B < R);
    always_ff @(posedge clk, posedge reset) begin : COLOR_FIND
        if (reset) begin
            blue_flag_U_count <= 0;
            blue_flag_D_count <= 0;
            red_flag_U_count  <= 0;
            red_flag_D_count  <= 0;
        end else begin
            if (x_pixel == DISPLAY_W && y_pixel == DISPLAY_H) begin
                USER[1] <= (red_flag_D_count < red_flag_U_count);
                USER[0] <= (blue_flag_D_count < blue_flag_U_count);
            end else if (x_pixel == 0 && y_pixel == 0) begin
                blue_flag_U_count <= 0;
                blue_flag_D_count <= 0;
                red_flag_U_count  <= 0;
                red_flag_D_count  <= 0;
            end else begin
                if (blue_flag) begin  //파랑
                    if (y_pixel < DISPLAY_H/2)  //반절 위면
                        blue_flag_U_count <= blue_flag_U_count + 1;
                    else blue_flag_D_count <= blue_flag_D_count + 1;
                end else if (red_flag) begin  //빨강
                    if (y_pixel < DISPLAY_H/2)  //반절 위면
                        red_flag_U_count <= red_flag_U_count + 1;
                    else red_flag_D_count <= red_flag_D_count + 1;
                end
            end
        end
    end
endmodule
