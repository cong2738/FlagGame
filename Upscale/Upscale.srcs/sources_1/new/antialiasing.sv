`timescale 1ns / 1ps

module antialiasing(
    input  logic       clk,
    input  logic       reset,
    
    // RGB 입력
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 필터된 RGB 출력
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o
);

    // 이전 픽셀들 저장 (수평 방향)
    logic [3:0] prev_r[0:3];  // 4픽셀 히스토리
    logic [3:0] prev_g[0:3];
    logic [3:0] prev_b[0:3];
    
    // 픽셀 히스토리 시프트
    always_ff @(posedge clk) begin
        if (de_i) begin
            prev_r[3] <= prev_r[2];
            prev_r[2] <= prev_r[1];
            prev_r[1] <= prev_r[0];
            prev_r[0] <= pixel_r_i;
            
            prev_g[3] <= prev_g[2];
            prev_g[2] <= prev_g[1];
            prev_g[1] <= prev_g[0];
            prev_g[0] <= pixel_g_i;
            
            prev_b[3] <= prev_b[2];
            prev_b[2] <= prev_b[1];
            prev_b[1] <= prev_b[0];
            prev_b[0] <= pixel_b_i;
        end
    end
    
    // 계단 검출: 4픽셀이 모두 같으면 계단 (4x4 블록의 특징)
    logic is_step_r, is_step_g, is_step_b;
    always_comb begin
        is_step_r = (pixel_r_i == prev_r[0]) && (prev_r[0] == prev_r[1]) && 
                    (prev_r[1] == prev_r[2]) && (prev_r[2] == prev_r[3]);
        is_step_g = (pixel_g_i == prev_g[0]) && (prev_g[0] == prev_g[1]) && 
                    (prev_g[1] == prev_g[2]) && (prev_g[2] == prev_g[3]);
        is_step_b = (pixel_b_i == prev_b[0]) && (prev_b[0] == prev_b[1]) && 
                    (prev_b[1] == prev_b[2]) && (prev_b[2] == prev_b[3]);
    end
    
    // 계단 끝 검출: 4픽셀 같다가 갑자기 바뀜
    logic step_end_r, step_end_g, step_end_b;
    always_comb begin
        step_end_r = is_step_r && (pixel_r_i != prev_r[0]);
        step_end_g = is_step_g && (pixel_g_i != prev_g[0]);
        step_end_b = is_step_b && (pixel_b_i != prev_b[0]);
    end
    
    // 계단현상 완화 필터
    logic [3:0] smooth_r, smooth_g, smooth_b;
    
    always_comb begin
        // R 채널 처리
        if (step_end_r && de_i) begin
            // 계단 끝에서 중간값 생성 (이전 + 현재) / 2
            smooth_r = (prev_r[0] + pixel_r_i) >> 1;
        end else if (is_step_r && de_i) begin
            // 계단 중간에서 약간의 노이즈 추가 (자연스럽게)
            case (prev_r[0][1:0])  // 하위 2비트로 패턴 생성
                2'b00: smooth_r = prev_r[0];
                2'b01: smooth_r = (prev_r[0] > 0) ? prev_r[0] - 1 : prev_r[0];
                2'b10: smooth_r = (prev_r[0] < 15) ? prev_r[0] + 1 : prev_r[0];
                2'b11: smooth_r = prev_r[0];
            endcase
        end else begin
            smooth_r = pixel_r_i;  // 원본 유지
        end
        
        // G 채널 처리
        if (step_end_g && de_i) begin
            smooth_g = (prev_g[0] + pixel_g_i) >> 1;
        end else if (is_step_g && de_i) begin
            case (prev_g[0][1:0])
                2'b00: smooth_g = prev_g[0];
                2'b01: smooth_g = (prev_g[0] > 0) ? prev_g[0] - 1 : prev_g[0];
                2'b10: smooth_g = (prev_g[0] < 15) ? prev_g[0] + 1 : prev_g[0];
                2'b11: smooth_g = prev_g[0];
            endcase
        end else begin
            smooth_g = pixel_g_i;
        end
        
        // B 채널 처리
        if (step_end_b && de_i) begin
            smooth_b = (prev_b[0] + pixel_b_i) >> 1;
        end else if (is_step_b && de_i) begin
            case (prev_b[0][1:0])
                2'b00: smooth_b = prev_b[0];
                2'b01: smooth_b = (prev_b[0] > 0) ? prev_b[0] - 1 : prev_b[0];
                2'b10: smooth_b = (prev_b[0] < 15) ? prev_b[0] + 1 : prev_b[0];
                2'b11: smooth_b = prev_b[0];
            endcase
        end else begin
            smooth_b = pixel_b_i;
        end
    end

    // 출력
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            
            pixel_r_o <= smooth_r;
            pixel_g_o <= smooth_g;
            pixel_b_o <= smooth_b;
        end
    end

endmodule