`timescale 1ns / 1ps

module Flag_cmd (
    input logic clk,
    input logic reset,
    input logic [11:0] rnd,
    output logic [7:0] flag_cmd
);

    // 명령어 정의: 청기/백기 올려, 내려, 내리지마, 올리지마
    typedef enum logic [3:0] {
        BLUE_UP       = 4'b0001,  // 청기 올려
        BLUE_DOWN     = 4'b0010,  // 청기 내려
        BLUE_NO_DOWN  = 4'b0011,  // 청기 내리지마
        BLUE_NO_UP    = 4'b0100,  // 청기 올리지마
        WHITE_UP      = 4'b0101,  // 백기 올려
        WHITE_DOWN    = 4'b0110,  // 백기 내려
        WHITE_NO_DOWN = 4'b0111,  // 백기 내리지마
        WHITE_NO_UP   = 4'b1000,  // 백기 올리지마
        BOTH_UP       = 4'b1001,  // 청기, 백기 둘 다 올려
        BOTH_DOWN     = 4'b1010,  // 청기, 백기 둘 다 내려
        BOTH_NO_DOWN  = 4'b1011,  // 청기, 백기 둘 다 내리지마
        BOTH_NO_UP    = 4'b1100   // 청기, 백기 둘 다 올리지마
    } CMD;

    CMD blue_cmd, white_cmd, both_cmd;   // 형태는 유지하되, 모두 같은 ‘랜덤 CMD’ 값을 갖도록 할 예정
    CMD selected_cmd, prev_cmd;

    // -------------------------------------------------------------------
    // 1) rnd[11:0]를 12로 나눈 나머지(0~11)를 idx에 저장
    // 2) idx에 따라 CMD 값을 하나 뽑아서 rand_cmd에 할당
    // 3) blue_cmd, white_cmd, both_cmd 모두 rand_cmd와 동일하게 설정
    //    → 이렇게 하면 이후 순서 논리에서 “both_cmd, white_cmd, blue_cmd 우선순위”가
    //       모두 같은 값을 비교하게 되어, 특정 명령에 가중치가 실리는 현상이 사라짐
    // -------------------------------------------------------------------
    logic [3:0] idx;
    CMD rand_cmd;

    always_comb begin
        // 12로 나눈 나머지(idx)는 0부터 11까지의 값
        idx = rnd % 12;

        case (idx)
            0:  rand_cmd = BLUE_UP;
            1:  rand_cmd = BLUE_DOWN;
            2:  rand_cmd = BLUE_NO_DOWN;
            3:  rand_cmd = BLUE_NO_UP;
            4:  rand_cmd = WHITE_UP;
            5:  rand_cmd = WHITE_DOWN;
            6:  rand_cmd = WHITE_NO_DOWN;
            7:  rand_cmd = WHITE_NO_UP;
            8:  rand_cmd = BOTH_UP;
            9:  rand_cmd = BOTH_DOWN;
            10: rand_cmd = BOTH_NO_DOWN;
            11: rand_cmd = BOTH_NO_UP;
            default: rand_cmd = BLUE_UP; // 절대 default로 가면 안 되지만, 안전하게 하나 지정
        endcase

        // 기존 변수명(blue_cmd, white_cmd, both_cmd)을 그대로 두되,
        // 모두 같은 랜덤 명령(rand_cmd)을 가지도록 한다.
        blue_cmd  = rand_cmd;
        white_cmd = rand_cmd;
        both_cmd  = rand_cmd;
    end

    // -------------------------------------------------------------------
    // 순서 논리:
    // reset 시 prev_cmd와 flag_cmd를 0으로 초기화
    // 그 외 시점에는 항상 both_cmd(== rand_cmd)을 selected_cmd에 바로 할당
    // → prev_cmd는 단순히 과거 상태 기록용
    // → “특정 명령이 반복해서 나오면 유지” 같은 로직은 제거하여
    //    매 클럭마다 완전히 독립적이고 균등한 랜덤 명령이 출력됨
    // -------------------------------------------------------------------
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            prev_cmd   <= CMD'(4'b0000);
            selected_cmd <= CMD'(4'b0000);
            flag_cmd   <= 8'b0;
        end else begin
            // 매 사이클마다 both_cmd(==rand_cmd)를 selected_cmd로 무조건 덮어씀
            selected_cmd <= both_cmd;
            prev_cmd     <= selected_cmd;

            // 출력은 8비트로 확장: 상위 4비트를 0으로 채우고, 하위 4비수만 selected_cmd
            flag_cmd <= {4'h0, selected_cmd};
        end
    end

endmodule
