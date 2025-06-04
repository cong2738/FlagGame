`timescale 1ns / 1ps

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
    input  logic       sw_mode,
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
        .clk       (clk),
        .reset     (reset),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .R         (vgaRed),
        .G         (vgaGreen),
        .B         (vgaBlue),
        .user_hand0(user_hand0),
        .user_hand1(user_hand1)
    );

    logic [31:0] center_color;
    always_ff @(posedge clk) begin : CC_Sel
        center_color <= ((x_pixel==160) && (y_pixel==120)) ? {vgaRed, vgaGreen, vgaBlue} : center_color;
    end
    fnd_controller u_fnd_controller (
        .clk     (clk),
        .reset   (reset),
        .bcd32   (sw_mode ? user_hand1 : user_hand0),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

endmodule
