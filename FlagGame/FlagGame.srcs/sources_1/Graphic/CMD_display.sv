`timescale 1ns / 1ps


module CMD_text_display #(
    parameter int SCALE        = 2,               // 확대 배율 2배
    parameter int CAM_WIDTH    = 640,
    parameter int CAM_HEIGHT   = 480,
    parameter int MAX_CHARS    = 13,
    parameter int CHAR_WIDTH   = 8,
    parameter int CHAR_HEIGHT  = 8
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        d_en,
    input  logic [ 3:0] commend,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic [ 3:0] o_red_cmd,
    output logic [ 3:0] o_green_cmd,
    output logic [ 3:0] o_blue_cmd,
    output logic        text_on_cmd,
    output logic [$clog2(CHAR_HEIGHT) + 7:0] rom_addr_cmd,
    input  logic [ 7:0] font_line_cmd
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
        GAME_OVER = 4'b1111
    } commend_e;

    
    typedef enum bit [2:0] { 
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    } sec_e;

    sec_e state, state_next;


       // 스케일 적용된 문자 블록 크기, 화면 중앙 정렬
    localparam int BLOCK_W    = MAX_CHARS * CHAR_WIDTH * SCALE;
    localparam int BLOCK_H    = CHAR_HEIGHT * SCALE;
    localparam int TEXT_X0    = (CAM_WIDTH  - BLOCK_W) / 2;
    localparam int TEXT_Y0    = 16;  // Y 위치 고정(start at 16)
    localparam int TEXT_X1    = TEXT_X0 + BLOCK_W;
    localparam int TEXT_Y1    = TEXT_Y0 + BLOCK_H;

    // 문장 표시 여부와 ROM 코드 배열
    logic show_text;
    logic [7:0] codes [0:MAX_CHARS-1];

    // scaled 상대 좌표, 원본 ROM 좌표
    logic [9:0] dx, dy;
    logic [3:0] char_slot;
    logic [2:0] row_addr, col_addr;
    logic pixel_on;
    logic [7:0] char_rom_idx;
                // 슬롯 내부 상대 좌표
    logic [9:0] sx = dx % (CHAR_WIDTH * SCALE);
    logic [9:0] sy = dy;

    // text_on 및 ROM 주소
    assign text_on_cmd = pixel_on && d_en;
    assign rom_addr_cmd = (char_rom_idx << $clog2(CHAR_HEIGHT)) | row_addr;


    always_comb begin : commend_text
        //기본값 : 공백
        for (int i = 0; i < MAX_CHARS; i++) begin
            codes[i] = 8'd100;  // backtick(`) 폰트 인덱스 = 63
        end
 
        show_text = 1'b0;

        // 2) commend_e에 따라  과 codes[] 배열에 ROM 인덱스 할당
        //    모든 경우  을 13으로 고정하여 앞뒤 공백까지 전부 그리도록 함
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

            end

            RED_UP: begin
                show_text = 1'b1;
                // "RED_UP" → 6글자 + 왼쪽 2칸 공백, 오른쪽 5칸 공백
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='U', [7]='P', [8..12]=공백
                codes[0]  = 8'd100;  // 공백
                codes[1]  = 8'd100;  // 공백
                codes[2]  = 8'd100;  // 공백
                codes[3]  = 8'd17;  // 'R'
                codes[4]  = 8'd4;  // 'E'
                codes[5]  = 8'd3;  // 'D'
                codes[6]  = 8'd63;  // '_'
                codes[7]  = 8'd20;  // 'U'
                codes[8]  = 8'd15;  // 'P'
                codes[9]  = 8'd100;
                codes[10] = 8'd100;
                codes[11] = 8'd100;
                codes[12] = 8'd100;
          
            end

            RED_DOWN: begin
                show_text = 1'b1;
                // "RED_DOWN" → 8글자 + 왼쪽 2칸 공백, 오른쪽 3칸 공백
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='D', [7]='O', [8]='W', [9]='N', [10..12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd100;
                codes[2]  = 8'd17;  // 'R'
                codes[3]  = 8'd4;  // 'E'
                codes[4]  = 8'd3;  // 'D'
                codes[5]  = 8'd63;  // '_'
                codes[6]  = 8'd3;  // 'D'
                codes[7]  = 8'd14;  // 'O'
                codes[8]  = 8'd22;  // 'W'
                codes[9]  = 8'd13;  // 'N'
                codes[10] = 8'd100;
                codes[11] = 8'd100;
                codes[12] = 8'd100;
          
            end

            RED_NO_DOWN: begin
                show_text = 1'b1;
                // "RED_NO_DOWN" → 11글자 + 좌우 1칸씩 공백
                //   [0]=공백, [1]='R', [2]='E', [3]='D', [4]='_', [5]='N', [6]='O', [7]='_', [8]='D', [9]='O', [10]='W', [11]='N', [12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd17;  // 'R'
                codes[2]  = 8'd4;  // 'E'
                codes[3]  = 8'd3;  // 'D'
                codes[4]  = 8'd63;  // '_'
                codes[5]  = 8'd13;  // 'N'
                codes[6]  = 8'd14;  // 'O'
                codes[7]  = 8'd63;  // '_'
                codes[8]  = 8'd3;  // 'D'
                codes[9]  = 8'd14;  // 'O'
                codes[10] = 8'd22;  // 'W'
                codes[11] = 8'd13;  // 'N'
                codes[12] = 8'd100;
            end

            RED_NO_UP: begin
                show_text = 1'b1;
                // "RED_NO_UP" → 9글자 + 좌우 공백 2칸씩
                //   [0..1]=공백, [2]='R', [3]='E', [4]='D', [5]='_', [6]='N', [7]='O', [8]='_', [9]='U', [10]='P', [11..12]=공백
                codes[0]  = 8'd100;
                codes[1]  = 8'd100;
                codes[2]  = 8'd17;  // 'R'
                codes[3]  = 8'd4;  // 'E'
                codes[4]  = 8'd3;  // 'D'
                codes[5]  = 8'd63;  // '_'
                codes[6]  = 8'd13;  // 'N'
                codes[7]  = 8'd14;  // 'O'
                codes[8]  = 8'd63;  // '_'
                codes[9]  = 8'd20;  // 'U'
                codes[10] = 8'd15;  // 'P'
                codes[11] = 8'd100;
                codes[12] = 8'd100;
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
            end

            default: begin
                // default일 때 show_text=0 → 공백 상태
                show_text = 1'b0;
            end
        endcase

        pixel_on     = 1'b0;
        char_rom_idx = 8'd0;
        row_addr     = '0;
        col_addr     = '0;
        dx           = '0;
        dy           = '0;

        if (d_en && show_text &&
            x >= TEXT_X0 && x < TEXT_X1 &&
            y >= TEXT_Y0 && y < TEXT_Y1) begin

            // 확대된 블록 내 상대 좌표
            dx = x - TEXT_X0;
            dy = y - TEXT_Y0;

            // 어느 문자 슬롯인지
            char_slot = dx / (CHAR_WIDTH * SCALE);
            char_rom_idx = codes[char_slot];

            // 원본 ROM 좌표 복원
            col_addr = sx / SCALE;     // 0..7
            row_addr = sy / SCALE;     // 0..7

            // 비트 선택 (MSB=좌측)
            pixel_on = font_line_cmd[col_addr];
        end
    end

    // 3) 색상 출력
    always_comb begin
        if (pixel_on) begin
            o_red_cmd   = 4'hF;
            o_green_cmd = 4'h0;
            o_blue_cmd  = 4'h0;
        end else begin
            o_red_cmd   = 4'h0;
            o_green_cmd = 4'h0;
            o_blue_cmd  = 4'h0;
        end
    end

endmodule



module font_rom (
    input  logic        clk,
    input  logic [10:0] addr_cmd,
    // input  logic [10:0] addr_cnt,
    output logic [ 7:0] data_cmd
    // output logic [ 7:0] data_cnt
);

    (* rom_style = "block" *)
    logic [7:0] rom1[0:1023];
    // logic [7:0] rom2[0:1023];


    initial begin
        $readmemh("font_complete.mem", rom1);
        // $readmemh("font_counter_new.mem", rom2);
    end

    always_ff @(posedge clk) begin
        data_cmd <= rom1[addr_cmd];
        // data_cnt <= rom2[addr_cnt];

    end

endmodule

