`timescale 1ns / 1ps
/* 버튼 입력시간을 재서 시드로 이용할거임 */
module ButtonPushTimeCounter (
    input clk,
    input reset,
    input i_btn,
    output reg [31:0] bptCount,
    output seed_tick
);
    reg [7:0] q_reg, q_next;
    wire btn_debounce;

    // 1khz clk, state
    reg [$clog2(100_000)-1:0] counter;
    reg r_1khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz  <= 0;
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                r_1khz  <= 1'b1;
            end else begin  // 1khz 1tick.
                counter <= counter + 1;
                r_1khz  <= 1'b0;
            end
        end
    end

    // state logic, shift register 
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // next logic
    always @(i_btn, r_1khz) begin  // event i_btn, r_1khz
        // q_reg 현재의 상위 7비트를 다음 하위 7비트에 넣고,
        // 최상에는 i_btn을 넣어라
        q_next = {i_btn, q_reg[7:1]};  // 8shift 의 동작 설명.
    end

    // 8 input AND gate
    assign btn_debounce = &q_reg;

    // edge _ detector
    reg d0, d1;
    always_ff @(posedge clk) begin : edge_detect
        d0 <= btn_debounce;
        d1 <= d0;
    end
    reg r_edge = d0 & ~d1, f_edge = ~d0 & d1;

    reg [31:0] temp_count;
    always_ff @(clk) begin : bptCounter
        if (f_edge) begin
            bptCount <= temp_count;
        end else if (btn_debounce) begin
            temp_count <= temp_count + 1;
        end
    end

    assign seed_tick = f_edge;
endmodule


module ButtonPushTimeCounter_TestCircuit (
    input clk,
    input rst,
    input btn,
    output [7:0] fnd_font,
    output [3:0] fnd_comm
);
    logic [31:0] bptCount;
    ButtonPushTimeCounter u_ButtonPushTimeCounter (
        .clk     (clk),
        .reset   (rst),
        .i_btn   (btn),
        .bptCount(bptCount),
        .seed_tick()
    );
    fnd_controller u_fnd_controller (
        .clk     (clk),
        .reset   (rst),
        .bcd32   (bptCount),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );
endmodule
