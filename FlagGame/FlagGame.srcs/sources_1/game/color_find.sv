`timescale 1ns / 1ps

module color_find (
    input clk,
    input reset,
    input [9:0] x_pixel,
    input [9:0] y_pixel,
    input [3:0] R,
    input [3:0] G,
    input [3:0] B,
    output logic[1:0] USER
);
    reg [31:0] blue_flag_U_count;
    reg [31:0] blue_flag_D_count;
    reg [31:0] red_flag_U_count;
    reg [31:0] red_flag_D_count;
    reg        red_flag = (R > 10) && (G < 5) && (B < 5);
    reg        blue_flag = (R < 5) && (G < 5) && (B > 10);
    always_ff @(posedge clk, posedge reset) begin : COLOR_FIND
        if (reset) begin
            blue_flag_U_count <= 0;
            blue_flag_D_count <= 0;
            red_flag_U_count <= 0;
            red_flag_D_count <= 0;
        end else begin
            if (x_pixel == 320 && y_pixel == 240) begin
                USER[1] <= (red_flag_D_count < red_flag_U_count);
                USER[0] <= (blue_flag_D_count < blue_flag_U_count);
            end else if (x_pixel == 0 && y_pixel == 0) begin
                blue_flag_U_count <= 0;
                blue_flag_D_count <= 0;
                red_flag_U_count <= 0;
                red_flag_D_count <= 0;
            end else begin  
                if (blue_flag) begin  //파랑
                    if (y_pixel < 120)  //반절 위면
                        blue_flag_U_count <= blue_flag_U_count + 1;
                    else blue_flag_D_count <= blue_flag_D_count + 1;
                end else if (red_flag) begin  //빨강
                    if (y_pixel < 120)  //반절 위면
                        red_flag_U_count <= red_flag_U_count + 1;
                    else red_flag_D_count <= red_flag_D_count + 1;
                end
            end
        end
    end
endmodule
