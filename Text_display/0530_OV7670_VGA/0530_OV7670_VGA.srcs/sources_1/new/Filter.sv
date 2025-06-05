`timescale 1ns / 1ps

module Filter(
    input logic clk,
    input logic d_en,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    //input switch
    input logic [3:0] sw_filter,
    input  logic [3:0] sw_cmd,
    //input rgb port
    input logic [3:0] red_port_i,
    input logic [3:0] green_port_i,
    input logic [3:0] blue_port_i,
    //output rgb port
    output logic [3:0] red_port_o,
    output logic [3:0] green_port_o,
    output logic [3:0] blue_port_o,
    input logic        sw_passfail
    );

    logic [11:0] color_port_gray;
    logic [3:0] red_port_text, green_port_text,blue_port_text;
    logic text_on;

Grayscale_filter U_GRAY_FILTER(
    .red_port(red_port_i),
    .green_port(red_port_i),
    .blue_port(red_port_i),
    .color_port(color_port_gray)
    );

    abc_text_display U_TEXT_DISPLAY(
    .clk(clk),
    .d_en(d_en),
    .sw_cmd(sw_cmd),
    .x(x_pixel),
    .y(y_pixel),
    .red(red_port_text),
    .green(green_port_text),
    .blue(blue_port_text),
    .text_on(text_on)
    //.sw_passfail(sw_passfail)
);

    always_comb begin : sw_filter_logic
        red_port_o   = red_port_i; 
        green_port_o = green_port_i;
        blue_port_o  = blue_port_i;
        if (d_en && text_on) begin //text 영역
            red_port_o   = red_port_text;
            green_port_o = green_port_text;
            blue_port_o  = blue_port_text;
        end else begin
            case (sw_filter)
                4'b0001: begin //gray filter
                    red_port_o   = color_port_gray[11:8];
                    green_port_o = color_port_gray[7:4];
                    blue_port_o  = color_port_gray[3:0];
                end
                4'b0010: begin //red filter
                    red_port_o   = red_port_i; 
                    green_port_o = 4'h0;
                    blue_port_o  = 4'h0;
                end 
                4'b0100: begin //green filter
                    red_port_o   = 4'h0;
                    green_port_o = green_port_i;
                    blue_port_o  = 4'h0;
                end 
                4'b1000: begin //blue filter
                    red_port_o   = 4'h0;
                    green_port_o = 4'h0;
                    blue_port_o  = blue_port_i;
                end  
            endcase
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
    assign gray_calc = (r8 * 8'd77) + (g8 * 8'd150) + (b8 * 8'd29);

    // >>8로 나눔 (256으로 나누기), 결과는 8비트
    logic [7:0] gray8;
    assign gray8 = gray_calc[15:8]; // 상위 바이트만 사용

    // 상위 비트만 사용하고 나머지 버리기
    logic [3:0] gray4;
    assign gray4 = gray8[7:4];

    // 최종 출력: R=G=B=gray4
    assign color_port = {gray4, gray4, gray4};

endmodule