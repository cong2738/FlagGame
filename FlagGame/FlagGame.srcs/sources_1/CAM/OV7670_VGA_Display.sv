`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals
    output logic       ov7670_xclk,    // == mclk
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // ov7670 export signals
    output logic [3:0] ov7670_Red,
    output logic [3:0] ov7670_Green,
    output logic [3:0] ov7670_Blue,
    output logic       ov7670_en,
    // vga export signals
    output logic       vga_en,
    output logic       Hsync,
    output logic       Vsync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel
);

    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [16:0] rAddr;
    logic [15:0] rData;

    logic        w_rclk;
    logic        rclk;


    VGA_Controller U_VGAController (
        .clk    (clk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (Hsync),
        .v_sync (Vsync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frame_buffer U_Frame_Buffer (
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    QVGA_MemController U_QVGA_MemController (
        .clk       (w_rclk),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .DE        (DE),
        .rclk      (rclk),
        .d_en      (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .red_port  (ov7670_Red),
        .green_port(ov7670_Green),
        .blue_port (ov7670_Blue)
    );
endmodule
