`timescale 1ns / 1ps

module abc_text_display (
    input  logic       clk,
    input  logic       d_en,
    input  logic [9:0] x,
    input  logic [9:0] y,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue,
    output logic text_on
);

localparam VIDEO_X_START = 160;   // 영상 시작 x 좌표
localparam VIDEO_WIDTH    = 320;  // 영상 폭
localparam CHAR_WIDTH     = 8;
localparam CHAR_HEIGHT    = 16;

localparam TEXT_X_START = 148; // 영상 중심 정렬용
localparam TEXT_Y_START = 16;

    logic [2:0] bit_addr;      // x 내에서 문자 내 열 위치
    logic [3:0] row_addr;      // y 내에서 문자 내 행 위치
    logic [7:0] font_line;     // font_rom에서 가져온 비트 한 줄
    logic       pixel_on;

    logic [1:0] char_ind_enx;
    logic [7:0] char_cod_en;

    logic [10:0] rom_addr;

    assign text_on = pixel_on;

    // ROM 인스턴스
    font_rom u_font (
        .clk(clk),
        .addr(rom_addr),
        .data(font_line)
    );

    // 문자 인덱스 및 코드 결정
    always_comb begin
        char_cod_en = 8'h00;
        row_addr  = 4'd0;
        bit_addr  = 3'd0;
        pixel_on  = 1'b0;
        if (x >= TEXT_X_START && x < TEXT_X_START + 24 &&
            y >= TEXT_Y_START && y < TEXT_Y_START + CHAR_HEIGHT && d_en) begin
            char_ind_enx = (x - TEXT_X_START) / CHAR_WIDTH;

            case (char_ind_enx)
                0: char_cod_en = "a";  // 97
                1: char_cod_en = "b";  // 98
                2: char_cod_en = "c";  // 99
            endcase

            row_addr  = y - TEXT_Y_START;
            bit_addr = (x - TEXT_X_START) % CHAR_WIDTH;
            pixel_on  = font_line[bit_addr];

        end 
    end

    assign rom_addr = {char_cod_en, row_addr};

    always_comb begin
        if (pixel_on && d_en) begin
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

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end

endmodule

