`timescale 1ns / 1ps

module top_hand_signal (
    input              clk,
    input              reset,
    input              game_start,
    // ov7670 signals
    input  logic       ov7670_start,
    output logic       ov7670_scl,
    output logic       ov7670_sda,
    output logic       ov7670_xclk,    // == mclk
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // export 
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);
    SCCB_core u_SCCB_core (
        .clk          (clk),
        .reset        (reset),
        .initial_start(ov7670_start),
        .sioc         (ov7670_scl),
        .siod         (ov7670_sda)
    );

    logic [3:0] ov7670_Red, ov7670_Green, ov7670_Blue;
    logic [9:0] x_pixel, y_pixel;
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

    logic [3:0] blue_flag, red_flag;
    hand_signal #(
        .IMG_WIDTH (320),
        .IMG_HEIGHT(240)
    ) u_hand_signal (
        .clk        (clk),
        .rst        (reset),
        .pixel_valid(ov7670_en),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
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
        .R  (ov7670_Red),
        .G  (ov7670_Green),
        .B  (ov7670_Blue),
        .x  (x_pixel),
        .y  (y_pixel),
        .o_R(vgaRed),
        .o_G(vgaGreen),
        .o_B(vgaBlue)
    );

endmodule

module print_grid #(
    X_SIZE = 320,
    Y_SIZE = 240
) (
    input [3:0] R,
    input [3:0] G,
    input [3:0] B,
    input [9:0] x,
    input [9:0] y,
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

module hand_signal #(
    parameter IMG_WIDTH  = 320,
    parameter IMG_HEIGHT = 240
) (
    input clk,
    input rst,

    input                               pixel_valid,
    input      [ $clog2(IMG_WIDTH)-1:0] x_pixel,
    input      [$clog2(IMG_HEIGHT)-1:0] y_pixel,
    input      [                  11:0] pixel_COLOR,
    output reg [                   3:0] blue_flag,
    output reg [                   3:0] red_flag
);
    reg [3:0] max_zone_color1, max_zone_color2;

    integer i;

    // RGB 추출
    wire [3:0] R = pixel_COLOR[11:8];
    wire [3:0] G = pixel_COLOR[7:4];
    wire [3:0] B = pixel_COLOR[3:0];

    // 색 조건
    wire is_color1 = (B > R) && (B > G);  //blue 계열
    wire is_color2 = (R > G) && (R > B);  //red 계열

    // 영역 경계 계산
    localparam W1 = IMG_WIDTH / 3;
    localparam W2 = (IMG_WIDTH * 2) / 3;
    localparam W3 = IMG_WIDTH;
    localparam H1 = IMG_HEIGHT / 3;
    localparam H2 = (IMG_HEIGHT * 2) / 3;
    localparam H3 = IMG_HEIGHT;

    // 영역 판별 (3x3 기준)
    reg [3:0] zone_id;
    always @(*) begin
        if (x_pixel < W1) begin
            if (y_pixel < H1) zone_id = 4'd0;
            else if (y_pixel < H2) zone_id = 4'd3;
            else if (y_pixel < H3) zone_id = 4'd6;
        end else if (x_pixel < W2) begin
            if (y_pixel < H1) zone_id = 4'd1;
            else if (y_pixel < H2) zone_id = 4'd4;
            else if (y_pixel < H3) zone_id = 4'd7;
        end else if (x_pixel < W3) begin
            if (y_pixel < H1) zone_id = 4'd2;
            else if (y_pixel < H2) zone_id = 4'd5;
            else if (y_pixel < H3) zone_id = 4'd8;
        end
    end
    // 색별 영역 카운트 배열
    reg [15:0] zone_count_color1[0:8];
    reg [15:0] zone_count_color2[0:8];

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
        end else if (pixel_valid) begin
            if (x_pixel == 320 && y_pixel == 240) begin
                for (i = 0; i < 9; i = i + 1) begin
                    zone_count_color1[i] <= 0;
                    zone_count_color2[i] <= 0;
                end
                max_zone_color1 <= 0;
                max_zone_color2 <= 0;
            end else if (x_pixel == 320 && y_pixel == 240) begin
                blue_flag <= max_zone_color1;
                red_flag  <= max_zone_color2;
            end else begin
                // color1인 영역 카운트
                if (is_color1) begin
                    zone_count_color1[zone_id] <= zone_count_color1[zone_id] + 1;
                    if (zone_count_color1[zone_id] + 1 > zone_count_color1[max_zone_color1]) begin
                        max_zone_color1 <= zone_id;
                    end
                end

                // color2인 영역 카운트
                if (is_color2) begin
                    zone_count_color2[zone_id] <= zone_count_color2[zone_id] + 1;
                    if (zone_count_color2[zone_id] + 1 > zone_count_color2[max_zone_color2]) begin
                        max_zone_color2 <= zone_id;
                    end
                end
            end
        end
    end
endmodule

