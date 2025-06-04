`timescale 1ns / 1ps
//top module

module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] sw_filter,
    // ov7670 signals
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // export signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic we;
    logic [16:0] wAddr;
    logic [15:0] wData;

    logic [16:0] rAddr;
    logic [15:0] rData;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic       DE;
    logic       w_rclk, rclk;
    logic [3:0] red_port_i;
    logic [3:0] green_port_i;
    logic [3:0] blue_port_i;

pixel_clk_gen U_Pix_Clk_gen2(
    .clk(clk),
    .reset(reset),
    .pclk(ov7670_xclk)    // pixel_clk
);

VGA_Controller U_VGAController(
    .clk(clk),
    .reset(reset),
    .rclk(w_rclk),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .DE(DE),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel)
);

    Frame_Buffer U_FRAME_BUFFER (
    .wclk(ov7670_pclk),
    .we(we),
    .wAddr(wAddr),
    .wData(wData),
    //read side
    .rclk(rclk),
    .oe(oe),
    .rAddr(rAddr),
    .rData(rData)
); 

QVGA_MemController U_QVGA_MemController(
    .clk(w_rclk),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .DE(DE),
    .rclk(rclk),
    .d_en(oe),
    .rAddr(rAddr),
    .rData(rData),
    .red_port(red_port_i),
    .green_port(green_port_i),
    .blue_port(blue_port_i)
    );

OV7670_MemController U_OV7670_Memcontroller(
    .pclk(ov7670_pclk),
    .reset(reset),
    .href(ov7670_href),
    .v_sync(ov7670_v_sync),
    .ov7670_data(ov7670_data),
    .we(we),
    .wAddr(wAddr),
    .wData(wData)
);

    Filter U_FILTER(
        .sw_filter(sw_filter),
        .red_port_i(red_port_i),
        .green_port_i(green_port_i),
        .blue_port_i(blue_port_i),
        .red_port_o(red_port),
        .green_port_o(green_port),
        .blue_port_o(blue_port),
        .clk(clk),
        .d_en(oe),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
        );




endmodule
