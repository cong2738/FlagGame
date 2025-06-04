`timescale 1ns / 1ps

module color_finder (
    input bit clk,
    input bit reset,
    input logic [11:0] color,
    input logic [9:0] addr,
    output logic [9:0] o_x,
    output logic [9:0] o_y
);
    reg [11:0] color0 = 12'hfff;
    reg [11:0] color1 = 12'hfff;
    reg [9:0] color0_loc;
    reg [9:0] color1_loc;
    always_ff @(posedge clk, posedge reset) begin : COLOR_FIND
        if(color == color0) color0_loc = addr;
    end
endmodule
