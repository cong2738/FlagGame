`timescale 1ns / 1ps

module SCCB_core (
    input  logic clk,
    input  logic reset,
    input  logic initial_start,
    output logic sioc,
    inout  logic siod
);

    logic sccb_start;
    logic [7:0] reg_addr;
    logic [7:0] write_data;
    logic sccb_done;

    tick_gen U_tick_gen_ (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    btn_detector U_btn_detector (
        .clk(clk),
        .reset(reset),
        .btn(initial_start),
        .start_signal(controller_start)
    );

    SCCB_Controller U_SCCB_Controller (
        .clk(tick),
        .reset(reset),
        .initial_start(controller_start),
        .start(sccb_start),
        .reg_addr(reg_addr),
        .data(write_data),
        .done(sccb_done)
    );

    SCCB U_SCCB(
        .clk(tick),         
        .reset(reset),
        .start(sccb_start),       
        .indata({8'h42, reg_addr[7:0],write_data[7:0]}),      
        .scl(sioc),
        .sda(siod),
        .done(sccb_done)         
);

endmodule

module SCCB_Controller (
    input logic clk,
    input logic reset,
    input logic initial_start,

    output logic       start,
    output logic [7:0] reg_addr,
    output logic [7:0] data,
    input  logic       done
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        WAIT_DONE,
        WAIT
    } state_e;
    state_e state;

    logic [7:0] rom_addr;
    logic [15:0] rom_data;

    logic [6:0] wait_count;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            start      <= 1'b0;
            reg_addr   <= 0;
            data       <= 0;
            rom_addr   <= 0;
            wait_count <= 0;
        end else begin

            case (state)
                IDLE: begin
                    if (initial_start) begin
                        state <= START;
                    end
                end
                START: begin // rom에서 가져온 신호 전달달
                    state    <= WAIT_DONE;
                    start    <= 1'b1;
                    reg_addr <= rom_data[15:8];
                    data     <= rom_data[7:0];
                end
                WAIT_DONE: begin // done 신호 대기
                    start <= 1'b0;

                    if (done) begin
                        if (rom_addr == 80) begin
                            rom_addr <= 0;
                            state <= IDLE;
                        end else begin
                            rom_addr <= rom_addr + 1;
                            state    <= WAIT;
                        end
                    end
                end
                WAIT: begin // 몇 클럭정도 대기 후 다음 전송으로 이동동
                    if (wait_count == 100) begin
                        state    <= START;
                        wait_count <= 0;
                    end else begin
                        wait_count <= wait_count + 1;
                    end
                end
            endcase
        end
    end

    OV7670_config_rom U_OV7670_config_rom (
        .clk (clk),
        .addr(rom_addr),
        .dout(rom_data)
    );
endmodule

module SCCB (
    input  logic        clk,         // 400kHz tick input
    input  logic        reset,
    input  logic        start,       // 트랜잭션 시작
    input  logic [23:0] indata,      // {slave_addr[7:0], reg_addr[7:0], data[7:0]}
    output logic        scl,
    inout  logic        sda,
    output logic        done         // 완료 표시
);

    typedef enum logic [3:0] {
        IDLE,
        START,
        SETUP,
        SCL_HIGH,
        SCL_LOW,
        WAIT_ACK_SETUP,
        WAIT_ACK_SAMPLE,
        NEXT_BYTE,
        STOP1,
        STOP2,
        DONE
    } state_t;

    state_t state;
    logic [23:0] shifter;      // 전송할 3바이트 데이터
    logic [2:0] bit_cnt;       // 0~7 비트 전송 인덱스
    logic [1:0] byte_cnt;      // 0: slave_addr, 1: reg_addr, 2: data

    logic scl_reg;
    logic sda_reg;
    logic sda_oe;

    assign scl = scl_reg;
    assign sda = sda_oe ? 1'bz : sda_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            shifter  <= 24'b0;
            bit_cnt  <= 3'd7;
            byte_cnt <= 2'd0;
            scl_reg  <= 1;
            sda_reg  <= 1;
            sda_oe   <= 1;  
            done     <= 0;
        end else begin
            case (state)
                IDLE: begin
                    scl_reg  <= 1;
                    sda_reg  <= 1;
                    sda_oe   <= 1;
                    done     <= 0;
                    if (start) begin
                        shifter  <= indata;
                        bit_cnt  <= 3'd7;
                        byte_cnt <= 2'd0;
                        sda_reg  <= 0;   // SDA 하강 Start 1상태
                        sda_oe   <= 0;
                        state    <= START;
                    end
                end

                START: begin
                    scl_reg <= 0;        // SCL = LOW Start_2 state
                    state   <= SETUP;
                end

                SETUP: begin
                    // 정확한 MSB-first 방식으로 인덱싱
                    sda_reg <= shifter[23 - (byte_cnt * 8 + (7 - bit_cnt))]; // 8개의 bit로 하나씩
                    sda_oe  <= 0;
                    scl_reg <= 0;
                    state   <= SCL_HIGH;
                end

                SCL_HIGH: begin
                    scl_reg <= 1;        // 슬레이브 샘플링 타이밍 SCL이 HIGH일 때 scl값은 high
                    state   <= SCL_LOW;
                end

                SCL_LOW: begin
                    scl_reg <= 0;
                    if (bit_cnt == 0) begin
                        bit_cnt <= 3'd7;
                        sda_oe  <= 1;    // SDA 입력으로 전환
                        state   <= WAIT_ACK_SETUP;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        state   <= SETUP;  // 다음 비트 전송
                    end
                end

                WAIT_ACK_SETUP: begin
                    scl_reg <= 1;        // SCL High => slave로 ack 신호 전달달
                    state   <= WAIT_ACK_SAMPLE;
                end

                WAIT_ACK_SAMPLE: begin
                    // ACK == 0 (Low)
                    scl_reg <= 0;
                    sda_oe  <= 0;        // 다시 출력 모드로 전환
                    if (sda == 1'b0) begin
                        if (byte_cnt == 2) begin
                            state <= STOP1;
                        end else begin
                            byte_cnt <= byte_cnt + 1;
                            state    <= SETUP;
                        end
                    end else begin
                        // NACK: 즉시 STOP
                        state <= STOP1;
                    end
                end

                STOP1: begin
                    sda_reg <= 0;
                    sda_oe  <= 0;
                    scl_reg <= 1;
                    state   <= STOP2;
                end

                STOP2: begin
                    sda_reg <= 1;        // SDA ↑ while SCL ↑ → STOP 조건
                    state   <= DONE;
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end
endmodule

module OV7670_config_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] dout
);

 //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  //reset --> 처음 reset
            1: dout <= 16'hFF_F0;  //delay --> 약간의 딜레이
            2: dout <= 16'h12_14;  // COM7,     set RGB color output and set QVGA = (출력 포맷 RGB와 해상도 설정 QVGA)
            //COM7 카메라 선세의 핵심 제어 레지스터
            3: dout <= 16'h11_80;  // CLKRC     CLK활성화한다는 얘기
            4: dout <= 16'h0C_04;  // COM3,     default settings = (자동 PCLK 모드) 4번 bit
            5: dout <= 16'h3E_19;  // COM14,    no scaling, normal pclock (scaling X)
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656 
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range(RGB 풀)
            8: dout <= 16'h3a_04;  //TSLB       
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10: dout <= 16'h4F_B3;  //MTX1      -> RGB 색상조정 3x3 행렬을 통하여 색상변환       
            11: dout <= 16'h50_B3;  //MTX2      -> RGB 색상조정 3x3 행렬을 통하여 색상변환
            12: dout <= 16'h51_00;  //MTX3      -> RGB 색상조정 3x3 행렬을 통하여 색상변환
            13: dout <= 16'h52_3d;  //MTX4      -> RGB 색상조정 3x3 행렬을 통하여 색상변환
            14: dout <= 16'h53_A7;  //MTX5      -> RGB 색상조정 3x3 행렬을 통하여 색상변환
            15: dout <= 16'h54_E4;  //MTX6      -> RGB 색상조정 3x3 행렬을 통하여 색상변환
            16: dout <= 16'h58_9E;  //MTXS      매트릭스의 계수인데 모름 일단 쓰는 듯
            17: dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18: dout <= 16'h17_15;  //HSTART     start high 8 bits (가로 시작)
            19: dout <= 16'h18_03;  //HSTOP      stop high 8 bits //these kill the odd colored line (가로 종료)
            20: dout <= 16'h32_00;  //HREF       edge offset // (disenable 구간)
            21: dout <= 16'h19_03;  //VSTART     start high 8 bits (세로 시작)
            22: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits (세로 종료료)
            23: dout <= 16'h03_00;  // 00 //VREF       vsync edge offset (disenable 구간)
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25: dout <= 16'h1E_20; //MVFP       거울모드(on MVFP[5]=1 이면 거울, MVFP[4] =1이면 상하반전)
            26: dout <= 16'h33_0B;  //CHLF       //magic value from the internet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control (전체 게인 수동으로 조정)--> 즉 픽셀의 밝기를 조절할 수 있음
            29: dout <= 16'h74_00;  //REG74      
            30: dout <= 16'hB0_84;  //RSVD       (레지스터가 현재 사용X이며, 향후 확장 기능을 위해서 비워둔 자리)
            31: dout <= 16'hB1_0c;  //ABLC1      (자동 블랙 레벨 조정)
            32: dout <= 16'hB2_0e;  //RSVD       
            33: dout <= 16'hB3_80;  //THL_ST    (ABLD Target) - 블랙레벨 안정 타겟 하한값
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a; // 수평 및 수직 크롭/확장 -> 크롭(전체 영상 중 일부 영역만 선택해서 출력)    
            35: dout <= 16'h71_35; // 수평 및 수직 크롭/확장 -> 크롭(전체 영상 중 일부 영역만 선택해서 출력)
            36: dout <= 16'h72_11; // 수평 및 수직 크롭/확장 -> 크롭(전체 영상 중 일부 영역만 선택해서 출력)
            37: dout <= 16'h73_f1; // 수평 및 수직 크롭/확장 -> 크롭(전체 영상 중 일부 영역만 선택해서 출력)
            38: dout <= 16'ha2_02; // 수평 및 수직 크롭/확장 -> 크롭(전체 영상 중 일부 영역만 선택해서 출력)
            //gamma curve values
            39: dout <= 16'h7a_20; //세부 크롭 조정     
            40: dout <= 16'h7b_10; //세부 크롭 조정 
            41: dout <= 16'h7c_1e; //세부 크롭 조정 
            42: dout <= 16'h7d_35; //세부 크롭 조정 
            43: dout <= 16'h7e_5a; //세부 크롭 조정 
            44: dout <= 16'h7f_69; //세부 크롭 조정 
            45: dout <= 16'h80_76; //세부 크롭 조정 
            46: dout <= 16'h81_80; //세부 크롭 조정 
            47: dout <= 16'h82_88; //세부 크롭 조정 
            48: dout <= 16'h83_8f; //세부 크롭 조정 
            49: dout <= 16'h84_96; //세부 크롭 조정 
            50: dout <= 16'h85_a3; //세부 크롭 조정 
            51: dout <= 16'h86_af; //세부 크롭 조정 
            52: dout <= 16'h87_c4; //세부 크롭 조정 
            53: dout <= 16'h88_d7; //세부 크롭 조정 
            54: dout <= 16'h89_e8; //세부 크롭 조정    
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC(게인 레지스터)
            57: dout <= 16'h10_00;  //set ARCJ reg to 0(자동 노출 컨트롤)- AEC가 올바르게 작동하기 위한 기본값
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4 - 필터/평균 설정
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit 
            60: dout <= 16'ha5_05;  // 60hz 환경에서 자동노출 상한레벨 지정
            61: dout <= 16'hab_07;  // 60hz 환경에서 자동게인인 상한레벨 지정
            62: dout <= 16'h24_95;  //AGC upper limit => 자동 노리개 상한 기준 
            63: dout <= 16'h25_33;  //AGC lower limit => 자동 노리개 하한 기준
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2 => 밝기 분포
            67: dout <= 16'ha1_03;  //magic (내부 제어용)
            68: dout <= 16'ha6_d8;  //HAECC3 => 밝기중심 자동 조정 
            69: dout <= 16'ha7_d8;  //HAECC4 => 밝기중심 자동 조정
            70: dout <= 16'ha8_f0;  //HAECC5 => 밝기중심 자동 조정
            71: dout <= 16'ha9_90;  //HAECC6 => 밝기중심 자동 조정
            72: dout <= 16'haa_94;  //HAECC7 => 밝기중심 자동 조정
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC (재활성화)
            74: dout <= 16'h69_07;  // Fix Gain
            default: dout <= 16'hFF_FF; 
        endcase
    end
endmodule




module tick_gen (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    logic [7:0] count;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            tick  <= 1'b0;

        end else begin
            if (count == 250 - 1) begin //4Mhz
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
        end
    end
endmodule





module btn_detector (
    input  clk,
    input  reset,
    input  btn,
    output start_signal
);

    reg [$clog2(100_000)-1:0] counter;
    reg tick;
    reg [3:0] shift_reg;
    wire debounce;
    reg q_reg;


    reg [11:0] pulse_counter;
    reg start_reg;


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick <= 1'b0;
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                tick <= 1'b1;
            end else begin
                counter <= counter + 1;
                tick <= 1'b0;
            end
        end
    end

    // debouncer by shift register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 4'b0000;
        end else if (tick) begin
            shift_reg <= {btn, shift_reg[3:1]};
        end
    end
    assign debounce = &shift_reg;

    // edge detection flip-flop
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q_reg <= 1'b0;
        end else begin
            q_reg <= debounce;
        end
    end

    assign rising_edge = debounce & (~q_reg);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pulse_counter <= 0;
            start_reg <= 1'b0;
        end else begin
            if (rising_edge) begin
                pulse_counter <= 12'd249;
                start_reg <= 1'b1;
            end else if (pulse_counter > 0) begin
                pulse_counter <= pulse_counter - 1;
                start_reg <= 1'b1;
            end else begin
                start_reg <= 1'b0;
            end
        end
    end

    assign start_signal = start_reg;
endmodule