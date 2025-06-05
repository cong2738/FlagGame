`timescale 1ns / 1ps

module upscaler_interpolation (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] final_data,
    output logic [11:0] up_scale_data
);

    // --------------------------------------------
    // 1) 두 줄(line) 버퍼: QVGA 한 줄당 320픽셀(0~319)을 저장
    // --------------------------------------------
    logic [11:0] line_buf_0 [0:319];  // QVGA 짝수 줄(즉 y_pixel/2의 LSB=0)에 해당
    logic [11:0] line_buf_1 [0:319];  // QVGA 홀수 줄(즉 y_pixel/2의 LSB=1)에 해당

    // --------------------------------------------
    // 2) VGA 좌표 → QVGA 좌표 변환
    //    - qx = floor(x_pixel / 2)  (0~319)
    //    - qy = floor(y_pixel / 2)  (0~239)
    //    - fx = x_pixel[0]          (짝/홀 판단용)
    //    - fy = y_pixel[0]          (짝/홀 판단용)
    // --------------------------------------------
    logic [8:0] qx;  // 0~319
    logic [7:0] qy;  // 0~239
    logic       fx;  // x_pixel[0]
    logic       fy;  // y_pixel[0]

    assign qx = x_pixel[9:1];   // >>1 = floor(x_pixel/2)
    assign qy = y_pixel[9:1];   // >>1 = floor(y_pixel/2)
    assign fx = x_pixel[0];
    assign fy = y_pixel[0];

    // --------------------------------------------
    // 2-1) “QVGA 영역인지” 판단
    //    - 0 ≤ x_pixel < 320  AND  0 ≤ y_pixel < 240 이면 QVGA 영역
    // --------------------------------------------
    logic is_qvga_region;
    assign is_qvga_region = (x_pixel < 320) && (y_pixel < 240);

    // --------------------------------------------
    // 3) 버퍼 쓰기(Write) 로직
    //    - 리셋 시 두 줄 버퍼 모두 0으로 초기화
    //    - 그 이후에는 아래 조건이 모두 참일 때만 QVGA 픽셀(final_data)을 쓰기
    //      • is_qvga_region == 1    (VGA 좌표가 0~319,0~239 안쪽)
    //      • fx == 0  AND  fy == 0   (짝수-짝수 좌표 → 실제 QVGA 픽셀 타이밍)
    //    - qy[0]이 0이면 line_buf_0[qx] ≤ final_data (“짝수 라인”), 
    //      qy[0]이 1이면 line_buf_1[qx] ≤ final_data (“홀수 라인”)
    // --------------------------------------------
    integer i;
    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            // 두 줄 버퍼를 모두 0으로 초기화
            for (i = 0; i < 320; i = i + 1) begin
                line_buf_0[i] <= 12'h000;
                line_buf_1[i] <= 12'h000;
            end
        end else begin
            // “QVGA 영역 & 짝수-짝수 순간”에만 버퍼 쓰기
            if (is_qvga_region && (fx == 1'b0) && (fy == 1'b0)) begin
                if (qy[0] == 1'b0) begin
                    // 짝수 QVGA 줄 → line_buf_0에 저장
                    line_buf_0[qx] <= final_data;
                end else begin
                    // 홀수 QVGA 줄 → line_buf_1에 저장
                    line_buf_1[qx] <= final_data;
                end
            end
        end
    end

    // --------------------------------------------
    // 4) 읽기(Read)용 픽셀 A, B, C, D
    //    - A = line_buf_0[qx]
    //    - B = line_buf_0[qx+1] (경계면일 때는 B = A)
    //    - C = line_buf_1[qx]
    //    - D = line_buf_1[qx+1] (경계면일 때는 D = C)
    // --------------------------------------------
    logic [11:0] A, B, C, D;
    always_comb begin
        A = line_buf_0[qx];
        B = (qx < 319) ? line_buf_0[qx + 1] : line_buf_0[qx];
        C = line_buf_1[qx];
        D = (qx < 319) ? line_buf_1[qx + 1] : line_buf_1[qx];
    end

    // --------------------------------------------
    // 5) 보간(Interpolation) 및 업스케일된 픽셀 계산
    //    - 네 가지 케이스 (fx, fy 조합)
    //      1) fx=0, fy=0 → 원본 픽셀 A 그대로
    //      2) fx=1, fy=0 → 수평 보간 → (A + B) / 2
    //      3) fx=0, fy=1 → 수직 보간 → (A + C) / 2
    //      4) fx=1, fy=1 → 2×2 평균 → (A + B + C + D) / 4
    //    - QVGA 영역이 아닐 때는 검은색(0) 출력
    // --------------------------------------------
    // 4비트 R,G,B 각각의 최대 합은 15+15+15+15=60이므로 6비트로 합산
    logic [5:0] r_sum, g_sum, b_sum;
    logic [3:0] r_out, g_out, b_out;

    always_comb begin
        if (!is_qvga_region) begin
            // QVGA 영역 바깥 → 검은색
            up_scale_data = 12'h000;
        end else begin
            // QVGA 영역 안(0≤x<320, 0≤y<240) → 네 이웃 픽셀 합계 계산
            r_sum = A[11:8] + B[11:8] + C[11:8] + D[11:8];
            g_sum = A[7:4]  + B[7:4]  + C[7:4]  + D[7:4];
            b_sum = A[3:0]  + B[3:0]  + C[3:0]  + D[3:0];

            if ((fx == 1'b0) && (fy == 1'b0)) begin
                // (짝수,짝수) → 원본 픽셀 A
                up_scale_data = A;
            end else if ((fx == 1'b1) && (fy == 1'b0)) begin
                // (홀수,짝수) → 수평 보간 (A + B) >> 1
                r_out = (A[11:8] + B[11:8]) >> 1;
                g_out = (A[7:4]  + B[7:4])  >> 1;
                b_out = (A[3:0]  + B[3:0])  >> 1;
                up_scale_data = {r_out, g_out, b_out};
            end else if ((fx == 1'b0) && (fy == 1'b1)) begin
                // (짝수,홀수) → 수직 보간 (A + C) >> 1
                r_out = (A[11:8] + C[11:8]) >> 1;
                g_out = (A[7:4]  + C[7:4])  >> 1;
                b_out = (A[3:0]  + C[3:0])  >> 1;
                up_scale_data = {r_out, g_out, b_out};
            end else begin
                // (홀수,홀수) → 2×2 평균 (A + B + C + D) >> 2
                r_out = r_sum[5:2];   // >> 2
                g_out = g_sum[5:2];
                b_out = b_sum[5:2];
                up_scale_data = {r_out, g_out, b_out};
            end
        end
    end

endmodule
