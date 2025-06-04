`timescale 1ns / 1ps

module fnd_controller #(
    parameter COUNT_100HZ = 1_000_000 //시뮬레이션 출력을 빠르게 나오게 하기 위한 탑 모듈 기준 타이머에 동기화 된 파라미터
) (
    input clk,
    input reset,
    input [31:0] bcd32,
    output [7:0] fnd_font,
    output [3:0] fnd_comm
);
    wire w_tick;
    wire [2:0] w_seg_sel;
    wire [7:0] segData;

    clk_divider #(
        .FCOUNT(10_000)
    ) U_Clk_Divider (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_tick)
    );

    counter_4 U_Counter_4 (
        .clk  (w_tick),
        .reset(reset),
        .o_sel(w_seg_sel)
    );

    segPlacer U_segPlacer (
        .seg_sel(w_seg_sel),
        .bcd32(bcd32),
        .segData(segData),
        .seg_comm(fnd_comm)
    );

    bcdtoseg U_bcdtoseg (
        .bcd(segData),
        .seg(fnd_font)
    );

endmodule

module clk_divider #(
    parameter FCOUNT = 100_000  // 이름을 상수화하여 사용.
) (
    input  clk,
    input  reset,
    output o_clk
);
    // $clog2 : 수를 나타내는데 필요한 비트수 계산
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin  // 
            r_counter <= 0;  // 리셋상태
            r_clk <= 1'b0;
        end else begin
            // clock divide 계산, 100Mhz -> 200hz
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;  // r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;  // r_clk : 0으로 유지.;
            end
        end
    end

endmodule

module counter_4 (
    input        clk,
    input        reset,
    output [1:0] o_sel
);
    reg [1:0] r_counter;
    assign o_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end

endmodule

module segPlacer (
    input [1:0] seg_sel,
    input [31:0] bcd32,
    output reg [7:0] segData,
    output reg [3:0] seg_comm
);

    // 2x4 decoder
    always @(seg_sel) begin
        seg_comm = 4'b1111;
        case (seg_sel)
            0: begin
                segData  = bcd32[7:0];
                seg_comm = 4'b1110;
            end
            1: begin
                segData  = bcd32[15:7];
                seg_comm = 4'b1101;
            end
            2: begin
                segData  = bcd32[23:15];
                seg_comm = 4'b1011;
            end
            3: begin
                segData  = bcd32[31:23];
                seg_comm = 4'b0111;
            end
        endcase
    end
endmodule

module bcdtoseg (
    input [3:0] bcd,  // [3:0] sum 값 
    output reg [7:0] seg
);
    // always 구문 출력으로 reg type을 가져야 한다.
    always @(bcd) begin
        case (bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hF9;
            4'h2: seg = 8'hA4;
            4'h3: seg = 8'hB0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'hA: seg = 8'h88 + 8'b10000000;
            4'hB: seg = 8'h83 + 8'b10000000;
            4'hC: seg = 8'hc6 + 8'b10000000;
            4'hD: seg = 8'ha1 + 8'b10000000;
            4'hE: seg = 8'h86 + 8'b10000000;
            4'hF: seg = 8'h8E + 8'b10000000;
            default: seg = 8'hff;
        endcase
    end
endmodule
