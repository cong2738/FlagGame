`timescale 1ns / 1ps

module abc_text_display (
    input  logic       clk,
    input  logic       d_en,
    input  logic [9:0] x,
    input  logic [9:0] y,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue,
    output logic       text_on
);

    localparam CHAR_WIDTH    = 8;
    localparam CHAR_HEIGHT   = 16;
    localparam TEXT_X_START  = 148;
    localparam TEXT_Y_START  = 16;

    logic [3:0]   row_addr;
    logic [2:0]   bit_idx;
    logic [7:0]   font_line;
    logic         pixel_on;

    logic [7:0]   char_rom_idx;
    logic [10:0]  rom_addr;

    assign text_on = pixel_on && d_en;
    assign rom_addr = { char_rom_idx, row_addr };

    font_rom u_font (
        .clk  (clk),
        .addr (rom_addr),
        .data (font_line)
    );

    always_comb begin
        pixel_on     = 1'b0;
        char_rom_idx = 8'h00;
        row_addr     = 4'd0;
        bit_idx      = 3'd0;

        if ( d_en &&
             x >= TEXT_X_START &&
             x <  (TEXT_X_START + 4 * CHAR_WIDTH) &&
             y >= TEXT_Y_START &&
             y <  (TEXT_Y_START + CHAR_HEIGHT) ) begin

            logic [1:0] char_slot;
            char_slot = (x - TEXT_X_START) / CHAR_WIDTH;

            case (char_slot)
                2'd0: char_rom_idx = 8'd111;
                2'd1: char_rom_idx = 8'd96;
                2'd2: char_rom_idx = 8'd114;
                2'd3: char_rom_idx = 8'd114;
                default: char_rom_idx = 8'h00;
            endcase

            row_addr = y - TEXT_Y_START;
            bit_idx  = (x - TEXT_X_START) % CHAR_WIDTH;
            pixel_on = font_line[bit_idx];
        end
        else begin
            pixel_on = 1'b0;
        end
    end

    always_comb begin
        if ( pixel_on && d_en ) begin
            red   = 4'hF;
            green = 4'h0;
            blue  = 4'h0;
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

endmodule


module font_rom (
    input  logic        clk,
    input  logic [10:0] addr,  // {char_cod_en[7:0], row[3:0]} = 8 + 4 = 12 → 총 2048줄
    output logic [7:0]  data
);

    (* rom_style = "block" *)  // 또는 "distributed"를 명시해도 됨
    logic [7:0] rom [0:2047];  // 128문자 x 16줄 = 2048줄

    initial begin
        $readmemh("charactor_file.mem", rom);  // 외부 폰트 파일 로딩
    end

    always_ff @(posedge clk ) begin
        data <= rom[addr];
    end

endmodule

