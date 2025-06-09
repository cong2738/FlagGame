`timescale 1ns / 1ps

module Gameover_effect (
    input logic [3:0] gameover,
    input logic [3:0] red_port_i,
    input logic [3:0] green_port_i,
    input logic [3:0] blue_port_i,
    output logic [3:0] red_port_o,
    output logic [3:0] green_port_o,
    output logic [3:0] blue_port_o
);

logic [11:0] color_port;

Grayscale_filter U_GRAY_FILTER(
    .red_port(red_port_i),
    .green_port(green_port_i),
    .blue_port(blue_port_i),
    .color_port(color_port)
    );

always_comb begin : grayscale
    if (gameover == 4'hf) begin //gameover
        red_port_o = color_port[11:8];
        green_port_o = color_port[7:4];
        blue_port_o = color_port[3:0];
    end
    else begin
        red_port_o = red_port_i;
        green_port_o = green_port_i;
        blue_port_o = blue_port_i;
    end
end
    
endmodule


module Grayscale_filter(
    input logic [3:0] red_port,
    input logic [3:0] green_port,
    input logic [3:0] blue_port,
    output logic [11:0] color_port
    );
    //256곱하기 (8bit으로 늘려줌)
    logic [7:0] r8, g8, b8;
    assign r8 = {red_port, 4'b0000};  
    assign g8 = {green_port, 4'b0000};
    assign b8 = {blue_port, 4'b0000};

    // 가중치 연산
    logic [15:0] gray_calc;
    logic [7:0] gray8;
    logic [3:0] gray4;

    assign gray_calc = (r8 * 8'd77) + (g8 * 8'd150) + (b8 * 8'd29);
    assign gray8 = gray_calc[15:8]; // 상위 바이트만 사용
    assign gray4 = gray8[7:4];
    assign color_port = {gray4, gray4, gray4};

endmodule
