`timescale 1ns / 1ps

module Text_score #(
    parameter max_score_bit = $clog2(9999) - 1
) (
    input logic clk,
    input logic d_en,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic [max_score_bit:0] score,  // 0 ~ 9999 까지 4자릿수 표현현
    output logic [3:0] text_red,
    output logic [3:0] text_green,
    output logic [3:0] text_blue,
    output logic score_on
);

    localparam int CHAR_WIDTH = 16;
    localparam int CHAR_HEIGHT = 16;
    localparam int MAX_DIGITS = 4;
    localparam int TEXT_WIDTH = CHAR_WIDTH * MAX_DIGITS;  // 16 * 10 = 160
    localparam int TEXT_HEIGHT = CHAR_HEIGHT;  // 16

    localparam int CAM_WIDTH = 320;
    localparam int CAM_HEIGHT = 240;

    localparam int TEXT_X_START = CAM_WIDTH - TEXT_WIDTH;  // 320 - 160 = 160
    localparam int TEXT_Y_START = CAM_HEIGHT - TEXT_HEIGHT;  // 240 -  16 = 224
    localparam int TEXT_X_END = TEXT_X_START + TEXT_WIDTH;  // 160 + 160 = 320
    localparam int TEXT_Y_END = TEXT_Y_START + TEXT_HEIGHT;  // 224 +  16 = 240

    localparam int SLOT_BITS = $clog2(MAX_DIGITS);  // ceil(log2(10)) = 4
    localparam int ROW_BITS = $clog2(CHAR_HEIGHT);  // log2(16) = 4
    localparam int ROM_IDX_BITS = 8;  // 문자 인덱스 8비트

    // =====================================================
    // 폰트 ROM 인터페이스용 신호
    // =====================================================
    logic [10:0] rom_addr;  // [7:0] char_idx, [3:0] row_addr
    logic [15:0] font_line;        // ROM에서 읽어오는 16비트 한 행 데이터
    logic [3:0] row_addr;  // 글자 세로 위치(0~15)
    logic [3:0] bit_idx;  // 글자 가로 위치(0~15)

    logic pixel_on;                // ROM 비트맵 상에서 현재 픽셀이 켜져 있는가
    logic [7:0] char_idx;  // ROM 인덱스(문자 코드 + 숫자)
    logic [ROM_IDX_BITS-1:0] char_code[0:MAX_DIGITS-1];

    logic [3:0] thousands, hundreds, tens, ones;

    // combinational 할당(모듈 레벨)
    assign thousands = (score / 1000) % 10;
    assign hundreds  = (score / 100) % 10;
    assign tens      = (score / 10) % 10;
    assign ones      = score % 10;

    // =====================================================
    // "SCORE:XYZ" 문자열의 각 슬롯에 올릴 문자 코드 결정
    // =====================================================
    always_comb begin
        char_code[0] = 8'h60 + thousands;
        char_code[1] = 8'h60 + hundreds;
        char_code[2] = 8'h60 + tens;
        char_code[3] = 8'h60 + ones;
    end

    // =====================================================
    // 현재 픽셀이 텍스트 영역 안에 있는지, 그리고 픽셀 단위로 폰트 비트맵 판정
    // =====================================================
    always_comb begin
        score_on = 1'b0;  // enable 신호 0
        pixel_on = 1'b0;  // pixel 켜지는 신호 0
        char_idx = '0;  // 문자 + 숫자 0
        bit_idx  = '0;  // 숫자 세로 위치
        row_addr = '0;  // 숫자 가로 위치
        rom_addr = '0;  // rom 주소소

        if (d_en &&
            x >= TEXT_X_START && x < TEXT_X_END &&
            y >= TEXT_Y_START && y < TEXT_Y_END) begin

            // (x, y)가 텍스트 렌더링 영역 안에 들어올 때
            logic [SLOT_BITS-1:0] char_slot;
            char_slot = (x - TEXT_X_START) / CHAR_WIDTH;
            // x축이 어느 글자 슬롯(0~9)에 해당하는지 계산

            char_idx  = char_code[char_slot];
            bit_idx   = (x - TEXT_X_START) % CHAR_WIDTH;
            row_addr  = (y - TEXT_Y_START) % CHAR_HEIGHT;

            rom_addr  = {char_idx, row_addr};
            // ROM 주소 = {8비트 char_idx, 4비트 row_addr} = 11비트

            // ROM에서 이미 읽어온 font_line의 (15 - bit_idx) 위치가 1이면 픽셀 켜짐
            pixel_on  = font_line[15-bit_idx];
            score_on  = pixel_on;
        end
    end

    // =====================================================
    // 텍스트 색상 결정 (노란색)
    // =====================================================
    always_comb begin
        if (score_on) begin
            text_red   = 4'hf;  // 1111
            text_green = 4'hf;  // 1111
            text_blue  = 4'h0;  // 0000
        end else begin
            text_red = 4'h0;
            text_green = 4'h0;
            text_blue  = 4'h0;  // 실제로는 o_rgb = i_rgb가 되므로 의미 없음
        end
    end

    // =====================================================
    // 실제 폰트 ROM 인스턴스
    // =====================================================
    logic [15:0] font_line_temp;
    Score_rom u_font (
        .clk (clk),
        .addr(rom_addr),
        .data(font_line_temp)
    );
    assign font_line = font_line_temp;

endmodule


// =========================================================
// 16×16 Font ROM 모듈
// =========================================================
module Score_rom (
    input  logic        clk,
    input  logic [10:0] addr,  // [7:0] char_idx, [3:0] row_addr
    output logic [15:0] data
);
    (* rom_style = "block" *)
    logic [15:0] rom[0:2047];  // 128문자 × 16행 = 2048 워드

    initial begin
        $readmemh("font_score_16by16.mem", rom);
    end

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
endmodule
