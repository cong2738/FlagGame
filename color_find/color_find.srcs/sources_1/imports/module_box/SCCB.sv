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

    SCCB U_SCCB (
        .clk(tick),
        .reset(reset),
        .sccb_start(sccb_start),
        .reg_addr(reg_addr),
        .write_data(write_data),
        .sccb_done(sccb_done),
        .sioc(sioc),
        .siod(siod)
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
    input  logic       clk,
    input  logic       reset,
    input  logic       sccb_start,
    input  logic [7:0] reg_addr,
    input  logic [7:0] write_data,
    output logic       sccb_done,
    output logic       sioc,
    inout  logic       siod
);
    localparam OV7670_ADDR_WRITE = 8'h42; // register의 Wrtie 0x42
    localparam OV7670_ADDR_READ = 8'h43; // read 0x43

    typedef enum logic [1:0] {
        SCCB_IDLE, 
        SCCB_READ, // write 모드드
        SCCB_WRITE
    } sccb_state_e;

    typedef enum logic [1:0] {
        PHASE_IP_ADDR, //슬레이브 주소 전송
        PHASE_REG_ADDR, // register의 주소 
        PHASE_DATA // 그때 들어갈 데이터터
    } phase_state_e;

    typedef enum logic [2:0] {
        PROTO_IDLE, 
        PROTO_START, // start 생성
        PROTO_DATA, // 데이터 8bit 전송
        PROTO_ACK, // ack 신호 처리
        PROTO_STOP 
    } protocol_state_e;



    sccb_state_e sccb_state;
    phase_state_e phase_state;
    protocol_state_e protocol_state;

    logic [1:0] count;
    logic stop_flag;
    logic [2:0] data_index;
    logic [7:0] temp_reg_addr;
    logic [7:0] temp_write_data;
    logic [7:0] temp_read_data;


    logic siod_mode; // inout 모드 조절
    logic siod_out_data; // out data
    logic sioc_out;

    logic sioc_reg;

    assign siod = siod_mode ? 1'bz : siod_out_data;
    assign sioc = sccb_state == SCCB_IDLE ? 1'b1 : sioc_reg;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sccb_state      <= SCCB_IDLE;
            phase_state     <= PHASE_IP_ADDR;
            protocol_state  <= PROTO_IDLE;
            count           <= 0;
            stop_flag       <= 1'b0;
            data_index      <= 7;
            temp_reg_addr   <= 0;
            temp_write_data <= 0;
            temp_read_data  <= 0;
            siod_mode       <= 1'b0;
            siod_out_data   <= 1'b1;
            sioc_out        <= 1'b1;
            sccb_done       <= 1'b0;
        end else begin
            case (sccb_state)
                SCCB_IDLE: begin
                    sccb_done <= 1'b0;
                    if (sccb_start) begin
                        temp_reg_addr <= reg_addr;
                        temp_write_data <= write_data;
                        sccb_state <= SCCB_WRITE;
                    end
                end


                SCCB_WRITE: begin
                    case (phase_state)
                        PHASE_IP_ADDR: begin
                            case (protocol_state)
                                PROTO_IDLE: begin
                                    siod_mode <= 1'b0;
                                    siod_out_data <= 1'b1;
                                    protocol_state <= PROTO_START;
                                end
                                PROTO_START: begin
                                    if (count == 3) begin
                                        protocol_state <= PROTO_DATA;
                                        count <= 0;
                                        siod_out_data <= OV7670_ADDR_WRITE[data_index];
                                    end else begin
                                        count <= count + 1;
                                        siod_out_data <= 1'b0;
                                    end
                                end
                                PROTO_DATA: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        data_index <= data_index - 1;
                                        siod_out_data <= OV7670_ADDR_WRITE[data_index-1];
                                        if (data_index == 0) begin
                                            protocol_state <= PROTO_ACK;
                                            siod_mode <= 1'b1;
                                            data_index <= 3'd7;
                                            siod_out_data <= 1'b1;
                                        end
                                    end else begin
                                        count <= count + 1;
                                    end

                                end
                                PROTO_ACK: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        siod_mode <= 1'b0;
                                        siod_out_data <= temp_reg_addr[data_index];
                                        phase_state <= PHASE_REG_ADDR;
                                        protocol_state <= PROTO_DATA;
                                    end else begin
                                        count <= count + 1;
                                    end
                                end
                            endcase
                        end


                        PHASE_REG_ADDR: begin
                            case (protocol_state)
                                PROTO_DATA: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        data_index <= data_index - 1;
                                        siod_out_data <= temp_reg_addr[data_index-1];
                                        if (data_index == 0) begin
                                            protocol_state <= PROTO_ACK;
                                            siod_mode <= 1'b1;
                                            data_index <= 3'd7;
                                            siod_out_data <= 1'b1;
                                        end
                                    end else begin
                                        count <= count + 1;
                                    end
                                end
                                PROTO_ACK: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        siod_out_data <= temp_write_data[data_index];
                                        siod_mode <= 1'b0;
                                        phase_state <= PHASE_DATA;
                                        protocol_state <= PROTO_DATA;
                                    end else begin
                                        count <= count + 1;
                                    end
                                end
                            endcase
                        end

                        PHASE_DATA: begin
                            case (protocol_state)
                                PROTO_DATA: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        data_index <= data_index - 1;
                                        siod_out_data <= temp_write_data[data_index-1];
                                        if (data_index == 0) begin
                                            protocol_state <= PROTO_ACK;
                                            siod_mode <= 1'b1;
                                            data_index <= 3'd7;
                                            siod_out_data <= 1'b1;
                                        end

                                    end else begin
                                        count <= count + 1;
                                    end

                                end
                                PROTO_ACK: begin
                                    if (count == 3) begin
                                        count <= 0;
                                        siod_mode <= 1'b0;
                                        siod_out_data <= 1'b0;
                                        protocol_state <= PROTO_STOP;
                                    end else begin
                                        count <= count + 1;
                                    end
                                end
                                PROTO_STOP: begin

                                    if (count == 3) begin
                                        siod_out_data <= 1'b1;
                                        count <= 0;
                                        stop_flag <= 1'b1;
                                        if (stop_flag) begin
                                            stop_flag <= 1'b0;
                                            count <= 0;
                                            sccb_done <= 1'b1;
                                            sccb_state <= SCCB_IDLE;
                                            phase_state <= PHASE_IP_ADDR;
                                            protocol_state <= PROTO_IDLE;
                                        end
                                    end else begin
                                        count <= count + 1;
                                    end
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sioc_reg <= 1'b1;
        end else begin
            if (count == 0) begin
                sioc_reg <= 1'b1;
            end else if (count == 2) begin
                if (phase_state == PHASE_DATA && protocol_state == PROTO_STOP);
                else sioc_reg <= 1'b0;
            end
        end
    end
endmodule




module OV7670_config_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] dout
);
    //  always_ff @(posedge clk) begin
    //     case (addr)
    //         0: dout <= 16'h12_80;
    //         1: dout <= 16'hff_f0;
    //         2: dout <= 16'h3a_04;
    //         3: dout <= 16'h13_e7;
    //         4: dout <= 16'h6f_9f;
    //         5: dout <= 16'hb0_84;
    //         6: dout <= 16'hff_f0;
    //         7: dout <= 16'h12_11;
    //         8: dout <= 16'h0c_04;
    //         9: dout <= 16'h3e_19;
    //         10: dout <= 16'h70_3a;
    //         11: dout <= 16'h71_35;.
    //         12: dout <= 16'h72_11;
    //         13: dout <= 16'h73_f1;
    //         14: dout <= 16'ha2_02;
    //         15: dout <= 16'h17_15;  //HSTART     start high 8 bits
    //         16: dout <= 16'h18_03; //HSTOP      stop high 8 bits 
    //         17: dout <= 16'h32_80;  //HREF       edge offset
    //         18: dout <= 16'h19_03;  //VSTART     start high 8 bits
    //         19: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
    //         20: dout <= 16'h03_00;  //VREF       vsync edge offset
    //         // 21: dout <= 16'h12_10;
    //         // 22: dout <= 16'h40_10;
    //         21: dout <= 16'h12_14;
    //         22: dout <= 16'h40_d0;
    //         default: dout <= 16'hFF_FF;  //mark end of ROM
    //     endcase

    // end
    
    //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  //reset 
            1: dout <= 16'hFF_F0;  //delay
            2: dout <= 16'h12_14;  // COM7,     set RGB color output
            3: dout <= 16'h11_80;  // CLKRC     internal PLL matches input clock
            4: dout <= 16'h0C_00;  // COM3,     default settings
            5: dout <= 16'h3E_00;  // COM14,    no scaling, normal pclock
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656     
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range
            8:
            dout <= 16'h3a_04; //TSLB       set correct output data sequence (magic)
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10:
            dout <= 16'h4F_B3; //MTX1       all of these are magical matrix coefficients
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17:
            dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18:
            dout <= 16'h17_14; //HSTART   14 -> 15  start high 8 bits 이거만 바꾸면 멈춤 + 초록, 마젠타
            19:
            dout <= 16'h18_02; //HSTOP    02 -> 03  stop high 8 bits //these kill the odd colored line
            20: dout <= 16'h32_91;  //HREF     80 -> 91  edge offset
            21: dout <= 16'h19_03;  //VSTART     start high 8 bits
            22: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
            23:
            dout <= 16'h03_00; //VREF     0a -> 00  vsync edge offset 전체적 밝기, 명암비 상승
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25:
            dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
            26: dout <= 16'h33_8f;  //CHLF       //magic value ft:nternet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control
            29: dout <= 16'h74_00;  //REG74      Digital gain control
            30:
            dout <= 16'hB0_84; //RSVD       magic value ft:nternet *required* for good color
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD       more magic internet values
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_f0;
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
            57: dout <= 16'h10_60;  //set ARCJ reg to 0
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
            73: dout <= 16'h6f_9f;
            74: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            ////////////////////////////////////////////
            75: dout <= 16'h55_10;  // bright
            76: dout <= 16'h13_40;  //AWB off
            77: dout <= 16'h6A_7f;  // 초 90
            78: dout <= 16'h01_b0;  // 빨 b0
            79: dout <= 16'h02_c0;  // 파 a0

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
