`timescale 1ns / 1ps

module top_FlagGame (
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
    //export
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);
    logic [3:0] GAME;
    logic [3:0] Red;
    logic [3:0] Green;
    logic [3:0] Blue;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;

    SCCB_core u_OV7670_SCCB_core (
        .clk          (clk),
        .reset        (reset),
        .initial_start(ov7670_start),
        .sioc         (ov7670_scl),
        .siod         (ov7670_sda)
    );

    logic [3:0] ov7670_Red, ov7670_Green, ov7670_Blue;
    OV7670_VGA_Display u_OV7670_VGA_Display (
        .clk          (clk),
        .reset        (reset),
        .ov7670_xclk  (ov7670_xclk),
        .ov7670_pclk  (ov7670_pclk),
        .ov7670_href  (ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data  (ov7670_data),
        .DE           (d_en),
        .Hsync        (Hsync),
        .Vsync        (Vsync),
        .ov7670_Red   (ov7670_Red),
        .ov7670_Green (ov7670_Green),
        .ov7670_Blue  (ov7670_Blue),
        .x_pixel      (x_pixel),
        .y_pixel      (y_pixel)
    );

    abc_text_display u_abc_text_display (
        .clk    (clk),
        .d_en   (d_en),
        .sw_cmd (GAME),
        .x      (x_pixel),
        .y      (y_pixel),
        .i_red  (ov7670_Red),
        .i_green(ov7670_Green),
        .i_blue (ov7670_Blue),
        .o_red  (Red),
        .o_green(Green),
        .o_blue (Blue)
    );

    game u_game (
        .clk    (clk),
        .reset  (reset),
        .start  (game_start),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .color  ({ov7670_Red, ov7670_Green, ov7670_Blue}),
        .GAME   (GAME)
    );

    assign {vgaRed, vgaGreen, vgaBlue} = {Red, Green, Blue};
endmodule

module game (
    input clk,
    input reset,
    input start,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [11:0] color,
    output logic [3:0] GAME
);
    logic         seed_en;
    logic [127:0] seed;
    logic [ 31:0] rnd;
    logic [  1:0] USER;
    logic [  3:0] flag_cmd;
    xorshift128 u_xorshift128 (
        .clk    (clk),
        .rst    (reset),
        .ce     (get),
        .seed_en(seed_en),
        .seed   (seed),
        .rnd    (rnd)
    );

    Flag_cmd u_Flag_cmd (
        .clk     (clk),
        .reset   (reset),
        .rnd     (rnd),
        .flag_cmd(flag_cmd)
    );

    color_find u_color_find (
        .clk       (clk),
        .reset     (reset),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .R         (color[3:0]),
        .G         (color[7:4]),
        .B         (color[11:8]),
        .user_hand0(USER[0]),
        .user_hand1(USER[1])
    );

    FlagGame u_FlagGame (
        .clk    (clk),
        .reset  (reset),
        .start  (start),
        .RANDCMD(flag_cmd),
        .USER   (USER),
        .GAME   (GAME),
        .get    (get)
    );

endmodule
