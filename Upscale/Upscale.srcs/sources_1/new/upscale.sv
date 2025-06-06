`timescale 1ns / 1ps

module upscale (
    input  logic       clk,
    input  logic       rst_n,
    
    // 원본 RGB 입력 (4비트씩)
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 4비트 RGB444 출력 (업스케일된)
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o
);

    // 단순히 원본을 그대로 출력 (QVGA_MemController에서 업스케일 처리)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            pixel_r_o <= pixel_r_i;  // 원본 그대로
            pixel_g_o <= pixel_g_i;
            pixel_b_o <= pixel_b_i;
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
        end
    end

endmodule
