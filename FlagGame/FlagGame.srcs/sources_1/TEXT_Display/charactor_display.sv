`timescale 1ns / 1ps

module abc_text_display (
    input  logic       clk,
    input  logic       d_en,
    input  logic [3:0] sw_cmd,
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [3:0] i_red,
    input  logic [3:0] i_green,
    input  logic [3:0] i_blue,
    output logic [3:0] o_red,
    output logic [3:0] o_green,
    output logic [3:0] o_blue
);
    logic       text_on;
    logic [3:0] text_red, text_green, text_blue;

    assign o_red   = (text_on) ? text_red : i_red;
    assign o_green = (text_on) ? text_green : i_green;
    assign o_blue  = (text_on) ? text_blue : i_blue;
    typedef enum logic [3:0] {
        GAME_START,
        BLUE_UP,
        BLUE_DOWN,
        BLUE_NO_DOWN,
        BLUE_NO_UP,
        RED_UP,
        RED_DOWN,
        RED_NO_DOWN,
        RED_NO_UP,
        BOTH_UP,
        BOTH_DOWN,
        BOTH_NO_DOWN,
        BOTH_NO_UP,
        GAME_OVER
    } commend_e;

    logic [3:0] commend;
    sel_char u_sel (
        .sw     (sw_cmd),
        .commend(commend)
    );

    // 카메라 영상 크기 (320×240) 내부 좌표를 기준으로 삼음
    localparam int CAM_WIDTH = 320;
    localparam int CAM_HEIGHT = 240;

    // 가장 긴 문자열 "RED_NO_DOWN" = 13글자이므로 MAX_CHARS = 13
    localparam int MAX_CHARS = 13;
    localparam int CHAR_WIDTH = 8;
    localparam int CHAR_HEIGHT = 8;

    // 카메라 내부 좌표계(0~319)에서 가로 중앙에 텍스트 블록을 정렬
    localparam int TEXT_X_START = (CAM_WIDTH - MAX_CHARS * CHAR_WIDTH) / 2;
    localparam int TEXT_Y_START = 16;
    localparam int TEXT_X_END = TEXT_X_START + MAX_CHARS * CHAR_WIDTH;
    localparam int TEXT_Y_END = TEXT_Y_START + CHAR_HEIGHT;

    localparam int ROW_ADDR_BITS = $clog2(CHAR_HEIGHT);
    localparam int SLOT_NUM_BITS = $clog2(MAX_CHARS);

    logic [  ROW_ADDR_BITS-1:0] row_addr;
    logic [  ROW_ADDR_BITS-1:0] bit_idx;
    logic [                7:0] font_line;
    logic                       pixel_on;

    logic [                7:0] char_rom_idx;
    logic [ROW_ADDR_BITS + 7:0] rom_addr;

    // ROM 인덱스 배열 (13글자)
    logic [                7:0] codes        [0:MAX_CHARS-1];
    // 실제 그려야 할 슬롯 개수 (항상 13으로 고정)
    int                         str_len;
    // 이 문자열을 그릴 것인가 여부
    logic                       show_text;

    assign text_on  = pixel_on && d_en;
    assign rom_addr = (char_rom_idx << ROW_ADDR_BITS) | row_addr;

    font_rom u_font (
        .clk (clk),
        .addr(rom_addr),
        .data(font_line)
    );

    always_comb begin
        // 1) 기본값: codes[i] = 63(backtick) → 공백용
        //    str_len = 0, show_text = 0 → 화면에 아무것도 그리지 않음
        for (int i = 0; i < MAX_CHARS; i++) begin
            codes[i] = 8'd100;  // backtick(`) 폰트 인덱스 = 63
        end
        str_len   = 0;
        show_text = 1'b0;

        // 2) commend_e에 따라 str_len과 codes[] 배열에 ROM 인덱스 할당
        //    모든 경우 str_len을 13으로 고정하여 앞뒤 공백까지 전부 그리도록 함
        case (commend)
            GAME_START: begin
                show_text = 1'b1;
                // "GAME_START" → 10글자 + 왼쪽 1칸 공백, 오른쪽 2칸 공백
                //   [0] = 공백, [1]='G', [2]='A', [3]='M', [4]='E', [5]='_', [6]='S', [7]='T', [8]='A', [9]='R', [10]='T', [11..12] = 공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd6;  // 'G'
                codes[2]  = 8'd0;  // 'A'
                codes[3]  = 8'd12;  // 'M'
                codes[4]  = 8'd4;  // 'E'
                codes[5]  = 8'd63;  // '_'
                codes[6]  = 8'd18;  // 'S'
                codes[7]  = 8'd19;  // 'T'
                codes[8]  = 8'd0;  // 'A'
                codes[9]  = 8'd17;  // 'R'
                codes[10] = 8'd19;  // 'T'
                codes[11] = 8'd57;  // ?
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BLUE_UP: begin
                show_text = 1'b1;
                // "BLUE_UP" → 7글자 + 왼쪽 3칸 공백, 오른쪽 3칸 공백
                //   [0..2]=공백, [3]='B', [4]='L', [5]='U', [6]='E', [7]='_', [8]='U', [9]='P', [10..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd100;  // 공백
                codes[3]  = 8'd1;  // 'B'
                codes[4]  = 8'd11;  // 'L'
                codes[5]  = 8'd20;  // 'U'
                codes[6]  = 8'd4;  // 'E'
                codes[7]  = 8'd63;  // '_'
                codes[8]  = 8'd20;  // 'U'
                codes[9]  = 8'd15;  // 'P'
                codes[10] = 8'd100;  // 공백
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BLUE_DOWN: begin
                show_text = 1'b1;
                // "BLUE_DOWN" → 9글자 + 왼쪽 2칸 공백, 오른쪽 2칸 공백
                //   [0..1]=공백, [2]='B', [3]='L', [4]='U', [5]='E', [6]='_', [7]='D', [8]='O', [9]='W', [10]='N', [11..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd1;  // 'B'
                codes[3]  = 8'd11;  // 'L'
                codes[4]  = 8'd20;  // 'U'
                codes[5]  = 8'd4;  // 'E'
                codes[6]  = 8'd63;  // '_'
                codes[7]  = 8'd3;  // 'D'
                codes[8]  = 8'd14;  // 'O'
                codes[9]  = 8'd22;  // 'W'
                codes[10] = 8'd13;  // 'N'
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BLUE_NO_DOWN: begin
                show_text = 1'b1;
                // "BLUE_NO_DOWN" → 12글자 + 왼쪽 0칸 공백, 오른쪽 1칸 공백
                //   [0]='B', [1]='L', [2]='U', [3]='E', [4]='_', [5]='N', [6]='O', [7]='_', [8]='D', [9]='O', [10]='W', [11]='N', [12]=공백
                codes[0]  = 8'd1;  // 'B'
                codes[1]  = 8'd11;  // 'L'
                codes[2]  = 8'd20;  // 'U'
                codes[3]  = 8'd4;  // 'E'
                codes[4]  = 8'd63;  // '_'
                codes[5]  = 8'd13;  // 'N'
                codes[6]  = 8'd14;  // 'O'
                codes[7]  = 8'd63;  // '_'
                codes[8]  = 8'd3;  // 'D'
                codes[9]  = 8'd14;  // 'O'
                codes[10] = 8'd22;  // 'W'
                codes[11] = 8'd13;  // 'N'
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BLUE_NO_UP: begin
                show_text = 1'b1;
                // "BLUE_NO_UP" → 10글자 + 왼쪽 1칸 공백, 오른쪽 2칸 공백
                //   [0]=공백, [1]='B', [2]='L', [3]='U', [4]='E', [5]='_', [6]='N', [7]='O', [8]='_', [9]='U', [10]='P', [11..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd1;  // 'B'
                codes[2]  = 8'd11;  // 'L'
                codes[3]  = 8'd20;  // 'U'
                codes[4]  = 8'd4;  // 'E'
                codes[5]  = 8'd63;  // '_'
                codes[6]  = 8'd13;  // 'N'
                codes[7]  = 8'd14;  // 'O'
                codes[8]  = 8'd63;  // '_'
                codes[9]  = 8'd20;  // 'U'
                codes[10] = 8'd15;  // 'P'
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            RED_UP: begin
                show_text = 1'b1;
                // "RED_UP" → 6글자 + 왼쪽 2칸 공백, 오른쪽 5칸 공백
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='U', [7]='P', [8..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd100;  // 공백
                codes[3]  = 8'd17;   // 'R'
                codes[4]  = 8'd4;    // 'E'
                codes[5]  = 8'd3;    // 'D'
                codes[6]  = 8'd63;   // '_'
                codes[7]  = 8'd20;   // 'U'
                codes[8]  = 8'd15;   // 'P'
                codes[9]  = 8'd100;
                codes[10] = 8'd100;
                codes[11] = 8'd100;
                codes[12] = 8'd100;
                str_len   = 13;
            end

            RED_DOWN: begin
                show_text = 1'b1;
                // "RED_DOWN" → 8글자 + 왼쪽 2칸 공백, 오른쪽 3칸 공백
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='D', [7]='O', [8]='W', [9]='N', [10..12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd100;
                codes[2]  = 8'd17;   // 'R'
                codes[3]  = 8'd4;    // 'E'
                codes[4]  = 8'd3;    // 'D'
                codes[5]  = 8'd63;   // '_'
                codes[6]  = 8'd3;    // 'D'
                codes[7]  = 8'd14;   // 'O'
                codes[8]  = 8'd22;   // 'W'
                codes[9]  = 8'd13;   // 'N'
                codes[10] = 8'd100;
                codes[11] = 8'd100;
                codes[12] = 8'd100;
                str_len   = 13;
            end

            RED_NO_DOWN: begin
                show_text = 1'b1;
                // "RED_NO_DOWN" → 11글자 + 좌우 1칸씩 공백
                //   [0]=공백, [1]='R', [2]='E', [3]='D', [4]='_', [5]='N', [6]='O', [7]='_', [8]='D', [9]='O', [10]='W', [11]='N', [12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd17;   // 'R'
                codes[2]  = 8'd4;    // 'E'
                codes[3]  = 8'd3;    // 'D'
                codes[4]  = 8'd63;   // '_'
                codes[5]  = 8'd13;   // 'N'
                codes[6]  = 8'd14;   // 'O'
                codes[7]  = 8'd63;   // '_'
                codes[8]  = 8'd3;    // 'D'
                codes[9]  = 8'd14;   // 'O'
                codes[10] = 8'd22;   // 'W'
                codes[11] = 8'd13;   // 'N'
                codes[12] = 8'd100;
                str_len   = 13;
            end

            RED_NO_UP: begin
                show_text = 1'b1;
                // "RED_NO_UP" → 9글자 + 좌우 공백 2칸씩
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='N', [7]='O', [8]='_', [9]='U', [10]='P', [11..12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd100;
                codes[2]  = 8'd17;   // 'R'
                codes[3]  = 8'd4;    // 'E'
                codes[4]  = 8'd3;    // 'D'
                codes[5]  = 8'd63;   // '_'
                codes[6]  = 8'd13;   // 'N'
                codes[7]  = 8'd14;   // 'O'
                codes[8]  = 8'd63;   // '_'
                codes[9]  = 8'd20;   // 'U'
                codes[10] = 8'd15;   // 'P'
                codes[11] = 8'd100;
                codes[12] = 8'd100;
                str_len   = 13;
            end


            BOTH_UP: begin
                show_text = 1'b1;
                // "BOTH_UP" → 7글자 + 왼쪽 3칸 공백, 오른쪽 3칸 공백
                //   [0..2]=공백, [3]='B', [4]='O', [5]='T', [6]='H', [7]='_', [8]='U', [9]='P', [10..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd100;  // 공백
                codes[3]  = 8'd1;  // 'B'
                codes[4]  = 8'd14;  // 'O'
                codes[5]  = 8'd19;  // 'T'
                codes[6]  = 8'd7;  // 'H'
                codes[7]  = 8'd63;  // '_'
                codes[8]  = 8'd20;  // 'U'
                codes[9]  = 8'd15;  // 'P'
                codes[10] = 8'd100;  // 공백
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BOTH_DOWN: begin
                show_text = 1'b1;
                // "BOTH_DOWN" → 9글자 + 왼쪽 2칸 공백, 오른쪽 2칸 공백
                //   [0..1]=공백, [2]='B', [3]='O', [4]='T', [5]='H', [6]='_', [7]='D', [8]='O', [9]='W', [10]='N', [11..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd1;  // 'B'
                codes[3]  = 8'd14;  // 'O'
                codes[4]  = 8'd19;  // 'T'
                codes[5]  = 8'd7;  // 'H'
                codes[6]  = 8'd63;  // '_'
                codes[7]  = 8'd3;  // 'D'
                codes[8]  = 8'd14;  // 'O'
                codes[9]  = 8'd22;  // 'W'
                codes[10] = 8'd13;  // 'N'
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BOTH_NO_DOWN: begin
                show_text = 1'b1;
                // "BOTH_NO_DOWN" → 12글자 + 왼쪽 0칸 공백, 오른쪽 1칸 공백
                //   [0]='B', [1]='O', [2]='T', [3]='H', [4]='_', [5]='N', [6]='O', [7]='_', [8]='D', [9]='O', [10]='W', [11]='N', [12]=공백
                codes[0]  = 8'd1;  // 'B'
                codes[1]  = 8'd14;  // 'O'
                codes[2]  = 8'd19;  // 'T'
                codes[3]  = 8'd7;  // 'H'
                codes[4]  = 8'd63;  // '_'
                codes[5]  = 8'd13;  // 'N'
                codes[6]  = 8'd14;  // 'O'
                codes[7]  = 8'd63;  // '_'
                codes[8]  = 8'd3;  // 'D'
                codes[9]  = 8'd14;  // 'O'
                codes[10] = 8'd22;  // 'W'
                codes[11] = 8'd13;  // 'N'
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            BOTH_NO_UP: begin
                show_text = 1'b1;
                // "BOTH_NO_UP" → 11글자 + 왼쪽 1칸 공백, 오른쪽 1칸 공백
                //   [0]=공백, [1]='B', [2]='O', [3]='T', [4]='H', [5]='_', [6]='N', [7]='O', [8]='_', [9]='U', [10]='P', [11]=공백, [12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd1;  // 'B'
                codes[2]  = 8'd14;  // 'O'
                codes[3]  = 8'd19;  // 'T'
                codes[4]  = 8'd7;  // 'H'
                codes[5]  = 8'd63;  // '_'
                codes[6]  = 8'd13;  // 'N'
                codes[7]  = 8'd14;  // 'O'
                codes[8]  = 8'd63;  // '_'
                codes[9]  = 8'd20;  // 'U'
                codes[10] = 8'd15;  // 'P'
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            GAME_OVER: begin
                show_text = 1'b1;
                // "GAME_OVER" → 9글자 + 왼쪽 2칸 공백, 오른쪽 2칸 공백
                //   [0..1]=공백, [2]='G', [3]='A', [4]='M', [5]='E', [6]='_', [7]='O', [8]='V', [9]='E', [10]='R', [11..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd6;  // 'G'
                codes[3]  = 8'd0;  // 'A'
                codes[4]  = 8'd12;  // 'M'
                codes[5]  = 8'd4;  // 'E'
                codes[6]  = 8'd63;  // '_'
                codes[7]  = 8'd14;  // 'O'
                codes[8]  = 8'd21;  // 'V'
                codes[9]  = 8'd4;  // 'E'
                codes[10] = 8'd17;  // 'R'
                codes[11] = 8'd100;  // 공백
                codes[12] = 8'd100;  // 공백
                str_len   = 13;
            end

            default: begin
                // default일 때 show_text=0 → 공백 상태
                show_text = 1'b0;
                str_len   = 0;
            end
        endcase

        // 3) 픽셀 계산: show_text=0이면 전부 Off,
        //    char_slot < str_len 인 경우에만 문자 그리기
        pixel_on     = 1'b0;
        char_rom_idx = 8'h00;
        row_addr     = '0;
        bit_idx      = '0;

        if (d_en && show_text) begin
            if ( x >= TEXT_X_START && x <  TEXT_X_END &&
                 y >= TEXT_Y_START && y <  TEXT_Y_END ) begin

                logic [SLOT_NUM_BITS-1:0] char_slot;
                char_slot = (x - TEXT_X_START) / CHAR_WIDTH;

                if (char_slot < str_len) begin
                    char_rom_idx = codes[char_slot];
                    row_addr = (y - TEXT_Y_START) & ((1 << ROW_ADDR_BITS) - 1);
                    bit_idx = (x - TEXT_X_START) % CHAR_WIDTH;
                    pixel_on = font_line[bit_idx];
                end else begin
                    // str_len 초과 슬롯: 공백 (pixel_on 그대로 0)
                end
            end
        end
    end

    always_comb begin
        if (pixel_on && d_en) begin
            text_red   = 4'hf;
            text_green = 4'h0;
            text_blue  = 4'h0;
        end else begin
            text_red   = 4'h0;
            text_green = 4'h0;
            text_blue  = 4'h0;
        end
    end

endmodule


module sel_char (
    input  logic [3:0] sw,
    output logic [3:0] commend
);

    typedef enum logic [3:0] {
        GAME_START,
        BLUE_UP,
        BLUE_DOWN,
        BLUE_NO_DOWN,
        BLUE_NO_UP,
        RED_UP,
        RED_DOWN,
        RED_NO_DOWN,
        RED_NO_UP,
        BOTH_UP,
        BOTH_DOWN,
        BOTH_NO_DOWN,
        BOTH_NO_UP,
        GAME_OVER
    } commend_e;

    always_comb begin
        case (sw)
            4'b0000: commend = GAME_START;
            4'b0001: commend = BLUE_UP;
            4'b0010: commend = BLUE_DOWN;
            4'b0011: commend = BLUE_NO_DOWN;
            4'b0100: commend = BLUE_NO_UP;
            4'b0101: commend = RED_UP;
            4'b0110: commend = RED_DOWN;
            4'b0111: commend = RED_NO_DOWN;
            4'b1000: commend = RED_NO_UP;
            4'b1001: commend = BOTH_UP;
            4'b1010: commend = BOTH_DOWN;
            4'b1011: commend = BOTH_NO_DOWN;
            4'b1100: commend = BOTH_NO_UP;
            4'b1111: commend = GAME_OVER;
            default: commend = RED_NO_DOWN;
            // default일 때 show_text=0이므로 화면에는 아무 것도 그려지지 않습니다.
        endcase
    end

endmodule


module font_rom (
    input  logic        clk,
    input  logic [10:0] addr,
    output logic [ 7:0] data
);

    (* rom_style = "block" *)
    logic [7:0] rom[0:1023];

    initial begin
        $readmemh("font_complete.mem", rom);
    end

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end

endmodule
