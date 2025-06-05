`timescale 1ns / 1ps

module grayscale_conv (
    input  logic [ 3:0] red_port_g,
    input  logic [ 3:0] green_port_g,
    input  logic [ 3:0] blue_port_g,
    output logic [11:0] grey_port
);

    logic [ 3:0] grey;
    logic [15:0] mul_77;
    logic [15:0] mul_150;
    logic [15:0] mul_29;
    logic [15:0] sum;

    assign mul_77 = red_port_g * 77;
    assign mul_150 = green_port_g * 150;
    assign mul_29 = blue_port_g * 29;

    assign sum = mul_77 + mul_150 + mul_29;

    assign grey = (sum * 15) / 3840;

    assign grey_port = {grey, grey, grey};
endmodule
