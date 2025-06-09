`timescale 1ns / 1ps

module CMD_text_display (
    input  logic        clk,
    input  logic        reset,
    input  logic        d_en,
    input  logic [ 3:0] commend,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic [ 3:0] o_red_cmd,
    output logic [ 3:0] o_green_cmd,
    output logic [ 3:0] o_blue_cmd,
    output logic text_on_cmd,
    //rom_data ports
    output logic [$clog2(8) + 7:0] rom_addr_cmd,
    input  logic [7:0] font_line_cmd 
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


    // 카메라 영상 크기 (320×240) 내부 좌표 기준
    localparam int CAM_WIDTH = 320;
    localparam int CAM_HEIGHT = 240;

    localparam int MAX_CHARS = 13;
    localparam int CHAR_WIDTH = 8;
    localparam int CHAR_HEIGHT = 8;

    // 카메라 내부 좌표계(0~319)에서 가로 중앙에 텍스트 블록을 정렬
    localparam int TEXT_X_START = (CAM_WIDTH - MAX_CHARS * CHAR_WIDTH) / 2;
    localparam int TEXT_Y_START = 16;
    localparam int TEXT_X_END = TEXT_X_START + MAX_CHARS * CHAR_WIDTH;
    localparam int TEXT_Y_END = TEXT_Y_START + CHAR_HEIGHT;

    localparam int ROW_addr_CMD_BITS = $clog2(CHAR_HEIGHT);
    localparam int SLOT_NUM_BITS = $clog2(MAX_CHARS);

    logic [  ROW_addr_CMD_BITS-1:0] row_addr_cmd;
    logic [  ROW_addr_CMD_BITS-1:0] bit_idx;
    logic                       pixel_on;

    logic [                7:0] char_rom_idx;
    // logic [ROW_addr_CMD_BITS + 7:0] rom_addr_cmd;
    logic [                7:0] codes        [0:MAX_CHARS-1]; // ROM 인덱스 배열 (13글자)
    int                         str_len; // 실제 그려야 할 슬롯 개수 (항상 13으로 고정)
    logic                       show_text;   // 문자열 활성화 여부

    // logic [2:0] count_five_sec, count_five_sec_next;

    assign text_on_cmd  = pixel_on && d_en;
    assign rom_addr_cmd = (char_rom_idx << ROW_addr_CMD_BITS) | row_addr_cmd;

    // font_rom u_font (
    //     .clk (clk),
    //     .addr_cmd(rom_addr_cmd),
    //     .data_cmd(font_line_cmd)
    // );



    always_comb begin : commend_text
        //기본값 : 공백
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
                str_len   = 13;
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
                str_len   = 13;
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
                str_len   = 13;
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
        row_addr_cmd     = '0;
        bit_idx      = '0;

        if (d_en && show_text) begin
            if ( x >= TEXT_X_START && x <  TEXT_X_END &&
                 y >= TEXT_Y_START && y <  TEXT_Y_END ) begin

                logic [SLOT_NUM_BITS-1:0] char_slot;
                char_slot = (x - TEXT_X_START) / CHAR_WIDTH;

                if (char_slot < str_len) begin
                    char_rom_idx = codes[char_slot];
                    row_addr_cmd = (y - TEXT_Y_START) & ((1 << ROW_addr_CMD_BITS) - 1);
                    bit_idx = (x - TEXT_X_START) % CHAR_WIDTH;
                    pixel_on = font_line_cmd[bit_idx];
                end else begin
                    // str_len 초과 슬롯: 공백 (pixel_on 그대로 0)
                end
            end
        end
    end

    always_comb begin
        if (pixel_on && d_en) begin
            o_red_cmd   = 4'hf;
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
    input  logic [10:0] addr_cnt,
    output logic [ 7:0] data_cmd,
    output logic [ 7:0] data_cnt
);

    (* rom_style = "block" *)
    logic [7:0] rom[0:1023];

    initial begin
        $readmemh("font_complete.mem", rom);
    end

    always_ff @(posedge clk) begin
        data_cmd <= rom[addr_cmd];
        data_cnt <= rom[addr_cnt];

    end

endmodule

