`timescale 1ns / 1ps

module xorshift128 (
    input              clk,
    input              rst,
    input              ce,
    input              seed_en,
    input      [127:0] seed,     // 128비트 시드 입력 (x, y, z, w 순서)
    output reg [ 31:0] rnd       // 난수 출력
);

    reg [31:0] x, y, z, w;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 기본 시드
            x <= 32'h12345678;
            y <= 32'h87654321;
            z <= 32'hABCDEF01;
            w <= 32'h10FEDCBA;
        end else if (seed_en) begin
            // 외부 시드 설정
            x <= seed[127:96];
            y <= seed[95:64];
            z <= seed[63:32];
            w <= seed[31:0];
        end else if (ce) begin
            // XORSHIFT128 알고리즘
            reg [31:0] t;
            t = x ^ (x << 11);
            x   <= y;
            y   <= z;
            z   <= w;
            w   <= w ^ (w >> 19) ^ (t ^ (t >> 8));
            rnd <= w;
        end
    end

endmodule

module xorshift64 (
    input              clk,
    input              rst,
    input              ce,
    input              seed_en,
    input      [63:0]  seed,     // 64비트 시드 입력
    output reg [31:0]  rnd       // 난수 출력
);

    reg [31:0] x, y, z, w;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 기본 시드
            x <= 32'h12345678;
            y <= 32'h87654321;
            z <= 32'hABCDEF01;
            w <= 32'h10FEDCBA;
        end else if (seed_en) begin
            // 64비트 시드를 4개 상태로 분해
            x <= seed[63:48] ^ seed[31:16]; // 간단한 spread 방식
            y <= seed[47:32] ^ seed[15:0];
            z <= seed[31:16] ^ seed[63:48];
            w <= seed[15:0]  ^ seed[47:32];
        end else if (ce) begin
            // XORSHIFT128 알고리즘
            reg [31:0] t;
            t = x ^ (x << 11);
            x   <= y;
            y   <= z;
            z   <= w;
            w   <= w ^ (w >> 19) ^ (t ^ (t >> 8));
            rnd <= w;
        end
    end

endmodule
