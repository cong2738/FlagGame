
`timescale 1ns / 1ps

//==============================================================================
// Font ROM: 16-bit wide, depth = 2^12 = 4096 words
// - font_counter_new.mem: 숫자 전용 폰트, 0부터 5까지 16라인씩 저장 (@0000~@005F)
//==============================================================================
module font_rom_count #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 16,
    parameter MEM_FILE   = "font_counter_new.mem"
)(
    input  logic                     clk,
    input  logic [ADDR_WIDTH-1:0]    addr,
    output logic [DATA_WIDTH-1:0]    data
);
    localparam DEPTH = 1 << ADDR_WIDTH;
    (* rom_style = "block" *)
    logic [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(MEM_FILE, rom);
    end

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
endmodule


//==============================================================================
// COUNT_Text_display: 중앙에 0~5 숫자를 16×16 폰트로 표시
// - SCALE 배율 적용, 파이프라인 1단계
// - font_rom_count에서 읽어온 16비트 행 데이터 사용
//==============================================================================
module COUNT_Text_display #(
    parameter int SCALE        = 6,
    parameter int CHAR_WIDTH   = 16,
    parameter int CHAR_HEIGHT  = 16,
    parameter int CAM_WIDTH    = 640,
    parameter int CAM_HEIGHT   = 480
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        d_en,
    input  logic [31:0] game_count_i,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,

    output logic [ 3:0] o_red_cnt,
    output logic [ 3:0] o_green_cnt,
    output logic [ 3:0] o_blue_cnt,
    output logic        text_on_cnt
);

    // 중앙 정렬
    localparam int SCALED_W = CHAR_WIDTH  * SCALE;
    localparam int SCALED_H = CHAR_HEIGHT * SCALE;
    localparam int X_START  = (CAM_WIDTH  - SCALED_W) / 2;
    localparam int Y_START  = (CAM_HEIGHT - SCALED_H) / 2;

    // 파이프라인 신호
    logic [11:0] rom_addr_nxt, rom_addr_reg;
    logic [15:0] font_data, font_line_reg;
    logic [ 3:0] col_nxt, col_reg;
    logic        pixel_on;

    // 문자 인덱스 계산 (0='0' … 5='5')
    logic [7:0] char_idx;
    always_comb begin
        if      (game_count_i < 100_000_000) char_idx = 8'd1;
        else if (game_count_i < 200_000_000) char_idx = 8'd2;
        else if (game_count_i < 300_000_000) char_idx = 8'd3;
        else if (game_count_i < 400_000_000) char_idx = 8'd4;
        else if (game_count_i < 500_000_000) char_idx = 8'd5;
        else                                  char_idx = 8'd0;
    end

    // 좌표 및 문자 픽셀 위치 계산용
    logic [9:0]  dx, dy;
    logic [4:0]  col_tmp, row_tmp;

    // 조합블록: ROM 주소 및 컬럼 인덱스 계산
    always_comb begin
        rom_addr_nxt = {char_idx, 4'd0}; // 기본 첫 줄 주소
        col_nxt      = 4'd0;

        if (d_en &&
            x >= X_START && x < X_START + SCALED_W &&
            y >= Y_START && y < Y_START + SCALED_H) begin

            // 화면 내 상대 좌표
            dx = x - X_START;
            dy = y - Y_START;

            // 축소하여 문자 내 픽셀 좌표
            col_tmp = dx / SCALE;
            row_tmp = dy / SCALE;

            // 클리핑
            if (col_tmp >= CHAR_WIDTH)  col_tmp = CHAR_WIDTH  - 1;
            if (row_tmp >= CHAR_HEIGHT) row_tmp = CHAR_HEIGHT - 1;

            // ROM 블록 시작 주소 + 행 오프셋
            rom_addr_nxt = {char_idx, 4'd0} + row_tmp;
            col_nxt      = col_tmp[3:0];
        end
    end

    // Font ROM 인스턴스 및 파이프라인 플롭
    font_rom_count #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(16),
        .MEM_FILE   ("font_counter_new.mem")
    ) u_font (
        .clk (clk),
        .addr(rom_addr_reg),
        .data(font_data)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rom_addr_reg  <= 12'd0;
            font_line_reg <= 16'd0;
            col_reg       <= 4'd0;
        end else begin
            rom_addr_reg  <= rom_addr_nxt;
            font_line_reg <= font_data;
            col_reg       <= col_nxt;
        end
    end

    // 픽셀 활성화 (영역 및 폰트 데이터 함께 체크)
    always_comb begin
        pixel_on = 1'b0;
        if (d_en &&
            x >= X_START && x < X_START + SCALED_W &&
            y >= Y_START && y < Y_START + SCALED_H &&
            font_line_reg[CHAR_WIDTH-1-col_reg]) begin
            pixel_on = 1'b1;
        end
    end
    assign text_on_cnt = pixel_on;

    // 색상 할당 (보라색)
    always_comb begin
        if (text_on_cnt) begin
            o_red_cnt   = 4'h0;
            o_green_cnt = 4'h0;
            o_blue_cnt  = 4'h0;
        end else begin
            o_red_cnt   = 4'h0;
            o_green_cnt = 4'h0;
            o_blue_cnt  = 4'h0;
        end
    end
endmodule
