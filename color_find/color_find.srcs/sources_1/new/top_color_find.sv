`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/04 14:13:45
// Design Name: 
// Module Name: top_color_find
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_color_find (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals
    input  logic       initial_start,
    output logic       ov7670_xclk,    // == mclk
    input  logic       ov7670_pclk,
    output logic       ov7670_SCLK,
    output logic       ov7670_SDA,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // export signals
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic       sw_mode,
    output logic [7:0] fnd_font,
    output logic [3:0] fnd_comm
);
    SCCB_core u_OV7670_Init (
        .clk          (clk),
        .reset        (reset),
        .initial_start(initial_start),
        .sioc         (ov7670_SCLK),
        .siod         (ov7670_SDA)
    );

    logic [9:0] x_pixel, y_pixel;
    OV7670_VGA_Display u_OV7670_VGA_Display (
        .clk          (clk),
        .reset        (reset),
        .ov7670_xclk  (ov7670_xclk),
        .ov7670_pclk  (ov7670_pclk),
        .ov7670_href  (ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data  (ov7670_data),
        .Hsync        (Hsync),
        .Vsync        (Vsync),
        .vgaRed       (vgaRed),
        .vgaGreen     (vgaGreen),
        .vgaBlue      (vgaBlue),
        .x_pixel      (x_pixel),
        .y_pixel      (y_pixel)
    );

    logic [9:0] user_x0, user_y0, user_x1, user_y1;
    color_find u_color_find (
        .clk        (clk),
        .reset      (reset),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .pixel_color({vgaRed, vgaGreen, vgaBlue}),
        .user_x0    (user_x0),
        .user_y0    (user_y0),
        .user_x1    (user_x1),
        .user_y1    (user_y1)
    );

    logic[11:0] center_color;
    assign center_color = (x_pixel==180&&y_pixel==120) ? {vgaRed, vgaGreen, vgaBlue} : 0;
    logic[0:32] bcd32;
    assign bcd32 = sw_mode ? user_x0 : user_x0;

    fnd_controller u_fnd_controller (
        .clk     (clk),
        .reset   (reset),
        .bcd32   (12'hf2),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );


endmodule
