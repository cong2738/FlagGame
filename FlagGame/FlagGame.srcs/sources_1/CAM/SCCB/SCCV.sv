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
                WAIT_DONE: begin // done 신호 대기기
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
            0: dout <= 16'h12_80;  //reset
            1: dout <= 16'hFF_F0;  //delay
            2: dout <= 16'h12_14;  // COM7,     set RGB color output and set QVGA
            3: dout <= 16'h11_80;  // CLKRC     internal PLL matches input clock
            4: dout <= 16'h0C_04;  // COM3,     default settings
            5: dout <= 16'h3E_19;  // COM14,    no scaling, normal pclock
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range
            8: dout <= 16'h3a_04;  //TSLB       
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10: dout <= 16'h4F_B3;  //MTX1       
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17: dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18: dout <= 16'h17_15;  //HSTART     start high 8 bits 
            19: dout <= 16'h18_03; //HSTOP      stop high 8 bits //these kill the odd colored line
            20: dout <= 16'h32_00;  //91  //HREF       edge offset
            21: dout <= 16'h19_03;  //VSTART     start high 8 bits
            22: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
            23: dout <= 16'h03_00;  // 00 //VREF       vsync edge offset
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25:
            dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
            26: dout <= 16'h33_0B;  //CHLF       //magic value from the internet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control
            29: dout <= 16'h74_00;  //REG74      Digital gain control
            30:
            dout <= 16'hB0_84; //RSVD       magic value from the internet *required* for good color
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD       more magic internet values
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_f1;
            38: dout <= 16'ha2_02;
            //gamma curve values
            39: dout <= 16'h7a_20;
            40: dout <= 16'h7b_10;
            41: dout <= 16'h7c_1e;
            42: dout <= 16'h7d_35;
            43: dout <= 16'h7e_5a;
            44: dout <= 16'h7f_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8f;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_a3;
            51: dout <= 16'h86_af;
            52: dout <= 16'h87_c4;
            53: dout <= 16'h88_d7;
            54: dout <= 16'h89_e8;
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC
            57: dout <= 16'h10_00;  //set ARCJ reg to 0
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit
            60: dout <= 16'ha5_05;  // BD50MAX
            61: dout <= 16'hab_07;  //DB60MAX
            62: dout <= 16'h24_95;  //AGC upper limit
            63: dout <= 16'h25_33;  //AGC lower limit
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2
            67: dout <= 16'ha1_03;  //magic
            68: dout <= 16'ha6_d8;  //HAECC3
            69: dout <= 16'ha7_d8;  //HAECC4
            70: dout <= 16'ha8_f0;  //HAECC5
            71: dout <= 16'ha9_90;  //HAECC6
            72: dout <= 16'haa_94;  //HAECC7
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            74: dout <= 16'h69_07;
            default: dout <= 16'hFF_FF;  //mark end of ROM
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
            if (count == 250 - 1) begin
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
