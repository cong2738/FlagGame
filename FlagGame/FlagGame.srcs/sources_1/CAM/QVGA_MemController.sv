`timescale 1ns / 1ps

module QVGA_MemController (
    // VGA Controller side
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE, // n/c
    // frame buffer side
    output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);

    logic display_en;
    logic [8:0] qvga_x; // max 319
    logic [7:0] qvga_y; // max 239

    assign rclk = clk;

    // Downscale VGA pixel to QVGA pixel
    assign qvga_x = x_pixel[9:1]; // equivalent to x_pixel >> 1
    assign qvga_y = y_pixel[9:1]; // equivalent to y_pixel >> 1

    // Only enable if within 640x480
    assign display_en = (x_pixel < 640) && (y_pixel < 480);
    assign d_en = display_en;

    // QVGA framebuffer address
    assign rAddr = display_en ? (qvga_y * 320 + qvga_x) : 17'd0;

    // Color extraction from 16-bit packed RGB: R[15:12], G[10:7], B[4:1]
    assign {red_port, green_port, blue_port} = display_en ? {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;

endmodule