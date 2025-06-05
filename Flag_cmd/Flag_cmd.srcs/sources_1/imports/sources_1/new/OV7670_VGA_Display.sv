`timescale 1ns / 1ps

module OV7670_VGA_Display (
    input logic clk,
    input logic reset,
    
    input logic initial_btn,
    input  logic [3:0] rgb_grey_mode_sw,
    input  logic       ov7670_pclk,
    output logic       ov7670_xclk,
    input  logic       ov7670_href,
    input  logic       ov7670_sync,
    input  logic [7:0] ov7670_data,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_filter,
    output logic [3:0] green_filter,
    output logic [3:0] blue_filter,

    output logic sioc,
    output logic siod
);

    logic pclk;

    logic                   w_rclk;
    logic                   rclk;
    logic                   oe;
    //OV7670
    logic                   we;
    logic [           16:0] wAddr;
    logic [           15:0] wData;
    //QVGA
    logic                   DE;
    logic [           16:0] rAddr;
    logic [           15:0] rData;
    //VGA_Ctrl
    logic [$clog2(640)-1:0] x_pixel;
    logic [$clog2(640)-1:0] y_pixel;
    logic [            3:0] red_port;
    logic [            3:0] green_port;
    logic [            3:0] blue_port;

    // upscale
    logic [11:0] upscale_data;

    pixel_clk_gen U_OV7670_clk_gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    OV7670_MemController U_ov7670_ctrl (
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    VGA_Controller U_VGA_ctrl (
        .*,
        .rclk(w_rclk)
    );

    frame_buffer U_frame_buffer (
        .wclk(ov7670_pclk),
        .rclk(rclk),
        .oe  (oe),
        .*
    );

    QVGA_MemController U_QVGA_ctrl (
        .*,
        .clk (w_rclk),
        .rclk(rclk),
        .d_en(oe),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

    // upscale U_upscale(
    //     .clk(pclk),
    //     .reset(reset),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .input_data({red_port, green_port, blue_port}),
    //     .input_valid(1'b1),
    //     .upscale_data(upscale_data)
    // );

    upscaler_interpolation U_upscale_inter(
        .clk_25MHz(pclk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .final_data({red_port, green_port, blue_port}),
        .up_scale_data(upscale_data)
);

    RGB_filter U_RGB_filter (.*,
        .red_port(upscale_data[11:8]),
        .green_port(upscale_data[7:4]),
        .blue_port(upscale_data[3:0]),
        .red_filter(red_filter),
        .green_filter(green_filter),
        .blue_filter(blue_filter)
    );



    // assign {red_filter, green_filter, blue_filter} = sw_upscale ? {upscale_data[11:8],upscale_data[7:4], upscale_data[3:0]} : {red_filter_RGB, green_filter_RGB, blue_filter_RGB};

    SCCB_core U_SCCB(
        .clk(clk),
        .reset(reset),
        .initial_start(initial_btn),
        .sioc(sioc),
        .siod(siod)
);

//    SCCB U_SCCB(
//         .clk(clk),
//         .reset(reset),
//         .startSig(initial_btn),
//         .SCL(sioc),
//         .SDA(siod)
// );
endmodule
