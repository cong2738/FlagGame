`timescale 1ns / 1ps

module FlagGame (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [ 3:0] RANDCMD,
    input  logic [ 1:0] USER,
    output logic [ 3:0] GAME,
    output logic        get,
    output logic [31:0] game_count,
    output logic [31:0] game_score
);
    // 명령어 정의: 청기/백기 올려, 내려, 내리지마(내림의 반대), 올리지마(올림의 반대)
    typedef enum logic [3:0] {
        BLUE_UP = 4'b0001,  // 청기 올려
        BLUE_DOWN = 4'b0010,  // 청기 내려
        BLUE_NODOWN = 4'b0011,  // 청기 내리지마 (내림의 반대=올림)
        BLUE_NOUP = 4'b0100,  // 청기 올리지마 (올림의 반대=내림)
        WHITE_UP = 4'b0101,  // 백기 올려
        WHITE_DOWN = 4'b0110,  // 백기 내려
        WHITE_NODOWN = 4'b0111,  // 백기 내리지마 (내림의 반대=올림)
        WHITE_NOUP = 4'b1000,  // 백기 올리지마 (올림의 반대=내림)
        BOTH_UP = 4'b1001,  // 청기, 백기 둘 다 올려
        BOTH_DOWN = 4'b1010,  // 청기, 백기 둘 다 내려
        BOTH_NODOWN      = 4'b1011, // 청기, 백기 둘 다 내리지마 (내림의 반대=둘 다 올림)
        BOTH_NOUP      = 4'b1100 // 청기, 백기 둘 다 올리지마 (올림의 반대=둘 다 내림)
    } CMD_E;

    typedef enum logic [3:0] {
        GAME_START = 4'h0,
        CMD_SAVE,
        GAME_ON,
        GAME_JUDGE,
        GAME_OVER  = 4'hf
    } GAME_STATE_E;

    GAME_STATE_E game_state, game_next;
    logic [3:0] temp_CMD, temp_CMD_next;
    logic timeover, pass;

    assign GAME = temp_CMD;

    always_ff @(posedge clk, posedge reset) begin : GAME_STATE_LOGIC
        if (reset) begin
            game_state <= GAME_START;
            temp_CMD   <= GAME_START;
        end else begin
            game_state <= game_next;
            temp_CMD   <= temp_CMD_next;
        end
    end

    always_ff @(posedge clk, posedge reset) begin : GAME_COUNTER
        if (reset) begin
            game_count <= 0;
        end else begin
            if (game_state == GAME_START) game_count <= 0;
            else if (game_count == 500_000_000) begin
                game_count <= 0;
                timeover   <= 1;
            end else begin
                game_count <= game_count + 1;
                timeover   <= 0;
            end
        end
    end

    always_ff @(posedge pass, posedge reset) begin : SCORE_COUNTER
        if (reset) begin
            game_score <= 0;
        end else begin
            game_score <= game_score + 1;
        end
    end

    always_comb begin : GAME_NEXT_LOGIC
        game_next     = game_state;
        temp_CMD_next = temp_CMD;
        get           = 0;
        pass          = 0;
        case (game_state)
            GAME_START: begin
                temp_CMD_next = GAME_START;
                if (start) begin
                    get = 1;
                    game_next = CMD_SAVE;
                end
            end
            CMD_SAVE: begin
                temp_CMD_next = RANDCMD;  // letching CMD
                game_next     = GAME_ON;
            end
            GAME_ON: begin
                if (timeover) begin
                    game_next = GAME_JUDGE;
                    get       = 1;
                end
            end
            GAME_JUDGE: begin
                case (temp_CMD)
                    BLUE_UP, BLUE_NODOWN: begin
                        if (USER != 2'b10) begin
                            game_next = GAME_OVER;
                        end else begin
                            pass = 1;
                            game_next = CMD_SAVE;
                        end
                    end
                    BOTH_UP, BOTH_NODOWN: begin
                        if (USER != 2'b11) begin
                            game_next = GAME_OVER;
                        end else begin
                            pass = 1;
                            game_next = CMD_SAVE;
                        end
                    end
                    WHITE_UP, WHITE_NODOWN: begin
                        if (USER != 2'b01) begin
                            game_next = GAME_OVER;
                        end else begin
                            pass = 1;
                            game_next = CMD_SAVE;
                        end
                    end
                    BLUE_DOWN, BLUE_NOUP, BOTH_DOWN, BOTH_NOUP, WHITE_DOWN, WHITE_NOUP: begin
                        if (USER != 2'b00) begin
                            game_next = GAME_OVER;
                        end else begin
                            pass = 1;
                            game_next = CMD_SAVE;
                        end
                    end
                    default: begin
                        game_next = GAME_OVER;
                    end
                endcase
            end
            GAME_OVER: begin
                temp_CMD_next = GAME_OVER;
                if (start) begin
                    get = 1;
                    game_next = GAME_START;
                end
            end
        endcase
    end
endmodule
