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
    reg blue_flag, red_flag;

    rgb4_to_color_detect u_rgb_to_color_detect (
        .R      (R),
        .G      (G),
        .B      (B),
        .is_red (red_flag),
        .is_blue(blue_flag)
    );

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
                    if (y_pixel < DISPLAY_H >> 1)  //반절 위면
                        blue_flag_U_count <= blue_flag_U_count + 1;
                    else blue_flag_D_count <= blue_flag_D_count + 1;
                end else if (red_flag) begin  //빨강
                    if (y_pixel < DISPLAY_H >> 1)  //반절 위면
                        red_flag_U_count <= red_flag_U_count + 1;
                    else red_flag_D_count <= red_flag_D_count + 1;
                end
            end
        end
    end
endmodule

module rgb4_to_color_detect (
    input  [3:0] R,
    input  [3:0] G,
    input  [3:0] B,
    output       is_red,
    output       is_blue
);

    // RGB 확장 (0~255 범위로 확장)
    wire [7:0] R8 = (R * 255) / 15;
    wire [7:0] G8 = (G * 255) / 15;
    wire [7:0] B8 = (B * 255) / 15;

    // 최대, 최소, 델타
    wire [7:0] Cmax = (R8 > G8) ? ((R8 > B8) ? R8 : B8) : ((G8 > B8) ? G8 : B8);
    wire [7:0] Cmin = (R8 < G8) ? ((R8 < B8) ? R8 : B8) : ((G8 < B8) ? G8 : B8);
    wire [7:0] delta = Cmax - Cmin;

    // V, S 계산
    wire [7:0] V = Cmax;
    wire [15:0] S = (Cmax == 0) ? 0 : (delta * 255) / Cmax;

    // H 계산
    reg [15:0] H_raw;
    always @(*) begin
        if (delta == 0) begin
            H_raw = 0;
        end else if (Cmax == R8) begin
            H_raw = (60 * (G8 - B8)) / delta;
            if (H_raw < 0) H_raw = H_raw + 360;
        end else if (Cmax == G8) begin
            H_raw = (60 * (B8 - R8)) / delta + 120;
        end else begin
            H_raw = (60 * (R8 - G8)) / delta + 240;
        end
    end

    // H 정규화 (0~360)
    wire [8:0] H = H_raw % 360;

    // 빨강/파랑 색상 판별
    assign is_red  = (S > 50 && V > 50) && (H <= 15 || H >= 345);
    assign is_blue = (S > 50 && V > 50) && (H >= 210 && H <= 270);

endmodule
