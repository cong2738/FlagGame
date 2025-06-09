`timescale 1ns / 1ps

module PRNG (
    input clk,
    input rst,
    input ce,
    input seed_btn,
    output[31:0] rnd
);
    logic [31:0] bptCount, sys_count;
    ButtonPushTimeCounter u_ButtonPushTimeCounter (
        .clk      (clk),
        .reset    (rst),
        .i_btn    (seed_btn),
        .bptCount (bptCount),
        .seed_tick(seed_en)
    );
    sys_counter u_sys_counter (
        .clk  (clk),
        .en   (seed_en),
        .count(sys_count)
    );
    xorshift64 u_xorshift (
        .clk    (clk),
        .rst    (rst),
        .ce     (ce),
        .seed_en(seed_en),
        .seed   ({bptCount, sys_count}),
        .rnd    (rnd)
    );
endmodule
