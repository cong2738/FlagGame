

`timescale 1ns / 1ps

module COUNT_Text_display (
    input  logic        clk,
    input  logic        reset,
    input  logic        d_en,
    input  logic [31:0] game_count_i,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic [ 3:0] o_red_cnt,
    output logic [ 3:0] o_green_cnt,
    output logic [ 3:0] o_blue_cnt,
    output logic        text_on_cnt,

    // rom interface
    output logic [10:0] rom_addr_cnt,
    input  logic [ 7:0] font_line_cnt
);

    typedef enum bit [2:0] {
        ONE   = 3'd0,
        TWO   = 3'd1,
        THREE = 3'd2,
        FOUR  = 3'd3,
        FIVE  = 3'd4
    } sec_e;

    localparam int CAM_WIDTH = 320;
    localparam int CAM_HEIGHT = 240;
    localparam int CHAR_WIDTH = 8;
    localparam int CHAR_HEIGHT = 8;
    localparam int TEXT_X_START = 3;
    localparam int TEXT_Y_START = 220;

    logic [2:0] row_addr, bit_idx;
    logic [31:0] char_rom_idx;
    logic       pixel_on;

    assign text_on_cnt = pixel_on && d_en;

    // 상태 계산 및 문자 선택
    always_comb begin
        char_rom_idx = 8'd100;  // 공백
        case (game_count_i / 100_000_000)
            0: char_rom_idx = 31'd27;  // '1'
            1: char_rom_idx = 31'd28;  // '2'
            2: char_rom_idx = 31'd29;  // '3'
            3: char_rom_idx = 31'd30;  // '4'
            4: char_rom_idx = 31'd31;  // '5'
            6: char_rom_idx = 31'h108;  // '6'
            7: char_rom_idx = 31'h110;  // '7'
            8: char_rom_idx = 31'h118;  // '8'
            9: char_rom_idx = 31'h120;  // '9'
        endcase
    end

    // 픽셀 위치 계산
    always_comb begin
        pixel_on = 1'b0;
        row_addr = 3'd0;
        bit_idx  = 3'd0;

        if (d_en && x >= TEXT_X_START && x < (TEXT_X_START + CHAR_WIDTH) && y >= TEXT_Y_START && y < (TEXT_Y_START + CHAR_HEIGHT)) begin
            row_addr = y - TEXT_Y_START;
            bit_idx  = x - TEXT_X_START;
            // pixel_on = font_line_cnt[CHAR_WIDTH - 1 - bit_idx];
            pixel_on = font_line_cnt[bit_idx];
        end
    end

    // ROM 주소 구성
    assign rom_addr_cnt = {char_rom_idx, row_addr};  // 11비트 = 8+3

    // 색상 출력
    always_comb begin
        if (pixel_on) begin
            o_red_cnt   = 4'hF;
            o_green_cnt = 4'h0;
            o_blue_cnt  = 4'hf;
        end else begin
            o_red_cnt   = 4'h0;
            o_green_cnt = 4'h0;
            o_blue_cnt  = 4'h0;
        end
    end

endmodule
