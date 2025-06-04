`timescale 1ns / 1ps

module ImageRom (
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [16:0] addr = 320 * y_pixel + x_pixel;
    logic [15:0]  data;  // RGB565 -> 16'brrrrr_gggggg_bbbbb

    always_comb begin : Display_Enable
        {red_port, green_port, blue_port} = {4'b0, 4'b0, 4'b0};
        if (DE && y_pixel <= 320 && x_pixel <= 240) begin
            //16'brrrr_r_gggg_gg_bbbb_b -> 12'brrrr_gggg_bbbb
            {red_port, green_port, blue_port} = {
                 data[15:12],  data[10:7],  data[4:1]
            };
        end
    end

    image_rom u_image_rom (
        .addr (addr),
        .data(data)
    );

endmodule

module image_rom (
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:320*240-1];
    initial begin
        $readmemh("Lenna.mem", rom);
    end
    assign  data = rom[addr];
endmodule
