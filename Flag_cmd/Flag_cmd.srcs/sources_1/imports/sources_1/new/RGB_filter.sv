`timescale 1ns / 1ps

module RGB_filter (
    input  logic [3:0] rgb_grey_mode_sw,
    input  logic [3:0] red_port,
    input  logic [3:0] green_port,
    input  logic [3:0] blue_port,
    output logic [3:0] red_filter,
    output logic [3:0] green_filter,
    output logic [3:0] blue_filter
);

    logic [11:0] grey_port;

    grayscale_conv U_grey_filter (
        .red_port_g(red_port),
        .green_port_g(green_port),
        .blue_port_g(blue_port),
        .grey_port(grey_port)
    );
    
    localparam BASIC = 4'b0000, RED = 4'b1000, GREEN = 4'b0100, BLUE = 4'b0010, GREY = 4'b0001;

    always_comb begin
        red_filter   = red_port;
        green_filter = green_port;
        blue_filter  = blue_port;
        case (rgb_grey_mode_sw)
            RED: begin
                red_filter   = red_port;
                green_filter = 0;
                blue_filter  = 0;
            end
            GREEN: begin
                red_filter   = 0;
                green_filter = green_port;
                blue_filter  = 0;
            end
            BLUE: begin
                red_filter   = 0;
                green_filter = 0;
                blue_filter  = blue_port;
            end
            GREY: begin
                red_filter   = grey_port[11:8];
                green_filter = grey_port[7:4];
                blue_filter  = grey_port[3:0];
            end
        endcase
    end
endmodule

// module mux_2x1 (
//     input  logic        sw_grey,
//     input  logic [11:0] rgb_port,
//     input  logic [11:0] grey_port,
//     output logic [11:0] y
// );
//     always_comb begin
//         case (sw_grey)
//             0: y = rgb_port;
//             1: y = grey_port;
//             default: y = 12'b0;
//         endcase
//     end
// endmodule

