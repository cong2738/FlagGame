`timescale 1ns / 1ps

module top_hand_signal (
    input        clk,
    input        reset,
    input        game_start,
    // ov7670 signals
    input        ov7670_start,
    output       ov7670_scl,
    output       ov7670_sda,
    output       ov7670_xclk,    // == mclk
    input        ov7670_pclk,
    input        ov7670_href,
    input        ov7670_v_sync,
    input  [7:0] ov7670_data,
    // export 
    output       Hsync,
    output       Vsync,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output [3:0] fndCom,
    output [7:0] fndFont
);
    SCCB_core u_SCCB_core (
        .clk(clk),
        .reset(reset),
        .initial_start(ov7670_start),
        .sioc(ov7670_scl),
        .siod(ov7670_sda)
    );

    wire [3:0] ov7670_Red, ov7670_Green, ov7670_Blue;
    wire [9:0] x_pixel, y_pixel;
    OV7670_VGA_Display u_OV7670_VGA_Display (
        .clk          (clk),
        .reset        (reset),
        .ov7670_xclk  (ov7670_xclk),
        .ov7670_pclk  (ov7670_pclk),
        .ov7670_href  (ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data  (ov7670_data),
        .ov7670_Red   (ov7670_Red),
        .ov7670_Green (ov7670_Green),
        .ov7670_Blue  (ov7670_Blue),
        .ov7670_en    (ov7670_en),
        .vga_en       (vga_en),
        .Hsync        (Hsync),
        .Vsync        (Vsync),
        .x_pixel      (x_pixel),
        .y_pixel      (y_pixel)
    );

    wire [3:0] zone_id;
    AreaSel u_AreaSel (
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .zone_id(zone_id)
    );

    wire [3:0] blue_flag, red_flag;
    hand_signal u_hand_signal (
        .clk        (clk),
        .rst        (reset),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .zone_id    (zone_id),
        .pixel_COLOR({ov7670_Red, ov7670_Green, ov7670_Blue}),
        .blue_flag  (blue_flag),
        .red_flag   (red_flag)
    );

    fndController u_fndController (
        .clk    (clk),
        .reset  (reset),
        .fndData(red_flag * 10 + blue_flag),
        .fndDot (4'b1111),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );

    print_grid u_print_grid (
        .R        (ov7670_Red),
        .G        (ov7670_Green),
        .B        (ov7670_Blue),
        .x        (x_pixel),
        .y        (y_pixel),
        .blue_flag(blue_flag),
        .red_flag (red_flag),
        .o_R      (vgaRed),
        .o_G      (vgaGreen),
        .o_B      (vgaBlue)
    );

endmodule

module print_grid #(
    X_SIZE = 640,
    Y_SIZE = 480
) (
    input        [3:0] R,
    input        [3:0] G,
    input        [3:0] B,
    input        [9:0] x,
    input        [9:0] y,
    input        [3:0] blue_flag,
    input        [3:0] red_flag,
    input        [3:0] zone_id,
    output logic [3:0] o_R,
    output logic [3:0] o_G,
    output logic [3:0] o_B
);
    localparam X_UNIT = X_SIZE / 3, Y_UNIT = Y_SIZE / 3;
    always_comb begin : PRINT_LOGIC
        {o_R, o_G, o_B} = {R, G, B};
        case (x)
            X_UNIT * 1: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
            X_UNIT * 2: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
            X_UNIT * 3: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
        endcase
        case (y)
            Y_UNIT * 1: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
            Y_UNIT * 2: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
            Y_UNIT * 3: {o_R, o_G, o_B} = {4'hf, 4'h0, 4'h0};
        endcase
    end
endmodule

module AreaSel #(
    parameter IMG_WIDTH  = 640,
    parameter IMG_HEIGHT = 480
) (
    input      [ $clog2(IMG_WIDTH)-1:0] x_pixel,
    input      [$clog2(IMG_HEIGHT)-1:0] y_pixel,
    output reg [                   3:0] zone_id
);
    // 영역 경계 계산
    localparam X_UNIT = IMG_WIDTH / 3;
    localparam Y_UNIT = IMG_HEIGHT / 3;

    wire    X_AREA0 = x_pixel < (X_UNIT * 1),


            X_AREA1 = x_pixel < (X_UNIT * 2),


            X_AREA2 = x_pixel < (X_UNIT * 3),


            Y_AREA0 = y_pixel < (Y_UNIT * 1),


            Y_AREA1 = y_pixel < (Y_UNIT * 2),


            Y_AREA2 = y_pixel < (Y_UNIT * 3);

    // 영역 판별 (3x3 기준)
    always @(*) begin
        if (X_AREA0) begin
            if (Y_AREA0) zone_id = 4'd0;
            else if (Y_AREA1) zone_id = 4'd3;
            else if (Y_AREA2) zone_id = 4'd6;
        end else if (X_AREA1) begin
            if (Y_AREA0) zone_id = 4'd1;
            else if (Y_AREA1) zone_id = 4'd4;
            else if (Y_AREA2) zone_id = 4'd7;
        end else if (X_AREA2) begin
            if (Y_AREA0) zone_id = 4'd2;
            else if (Y_AREA1) zone_id = 4'd5;
            else if (Y_AREA2) zone_id = 4'd8;
        end
    end
endmodule

module hand_signal #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480,
    parameter IMG_WB = $clog2(IMG_WIDTH),
    parameter IMG_HB = $clog2(IMG_HEIGHT)
) (
    input                   clk,
    input                   rst,
    input      [IMG_WB-1:0] x_pixel,
    input      [IMG_HB-1:0] y_pixel,
    input      [       3:0] zone_id,
    input      [      11:0] pixel_COLOR,
    output reg [       3:0] blue_flag,
    output reg [       3:0] red_flag
);
    reg [3:0] max_zone_color1, max_zone_color2;

    integer i;

    // RGB 분리
    wire [3:0] R = pixel_COLOR[11:8];
    wire [3:0] G = pixel_COLOR[7:4];
    wire [3:0] B = pixel_COLOR[3:0];

    // 색 조건
    // wire is_color1 = (R < 10) && (G < 10) && (10 < B);  //blue 계열
    // wire is_color2 = (G < 10) && (B < 10) && (10 < R);  //red 계열
    rgb4_to_color_detect u_rgb4_to_color_detect (
        .R      (R),
        .G      (G),
        .B      (B),
        .is_red (is_color2),
        .is_blue(is_color1)
    );


    // 색별 영역 카운트 배열
    reg [31:0] zone_count_color1[0:8];
    reg [31:0] zone_count_color2[0:8];

    // 최대 카운트 영역 추적
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 9; i = i + 1) begin
                zone_count_color1[i] <= 0;
                zone_count_color2[i] <= 0;
            end
            max_zone_color1 <= 0;
            max_zone_color2 <= 0;
            blue_flag <= 0;
            red_flag <= 0;
        end else begin
            if (x_pixel == 0 && y_pixel == 0) begin
                for (i = 0; i < 9; i = i + 1) begin
                    zone_count_color1[i] <= 0;
                    zone_count_color2[i] <= 0;
                end
                max_zone_color1 <= 0;
                max_zone_color2 <= 0;
            end else if (x_pixel == IMG_WIDTH && y_pixel == IMG_HEIGHT) begin
                blue_flag <= max_zone_color1;
                red_flag  <= max_zone_color2;
            end else begin
                // color1인 영역 카운트
                if (is_color1) begin
                    zone_count_color1[zone_id] <= zone_count_color1[zone_id] + 1;
                    if (zone_count_color1[zone_id] + 1 >= zone_count_color1[max_zone_color1]) begin
                        max_zone_color1 <= zone_id;
                    end
                end

                // color2인 영역 카운트
                if (is_color2) begin
                    zone_count_color2[zone_id] <= zone_count_color2[zone_id] + 1;
                    if (zone_count_color2[zone_id] + 1 >= zone_count_color2[max_zone_color2]) begin
                        max_zone_color2 <= zone_id;
                    end
                end
            end
        end
    end
endmodule

