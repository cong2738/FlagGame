`timescale 1ns / 1ps

module sound_card (
    input  wire clk,        // 1 MHz 클럭
    input  wire reset,
    input  wire game_over,
    input  wire game_on,
    output wire speaker
);

    wire [ 5:0] note;
    wire [15:0] half_period;
    wire [31:0] duration;
    wire play, tone_done;

    freq_lut lut (
        .note       (note),
        .half_period(half_period)
    );

    tone_player tone (
        .clk        (clk),
        .start      (play),
        .half_period(half_period),
        .duration   (duration),
        .speaker    (speaker),
        .done       (tone_done)
    );

    music_controller music (
        .clk      (clk),
        .reset    (reset),
        .game_over(game_over),
        .game_on  (game_on),
        .note     (note),
        .duration (duration),
        .play     (play),
        .tone_done(tone_done)
    );

endmodule

module music_controller (
    input wire clk,
    input wire reset,
    input wire game_over,
    input wire game_on,
    input wire beep_on,
    output reg [5:0] note,
    output reg [31:0] duration,
    output reg play,
    input wire tone_done
);
    localparam GAMEOVER = 0, PASS = 1, BEEP = 2;
    reg [3:0] state = 0;
    reg music_sel = 0;
    reg active = 0;

    reg [5:0] PASS_MUSIC[0:5] = '{12, 15, 19, 31, 31, 31};
    reg [31:0] PASS_MUSIC_DUR[0:5] = '{
        10_000_000,
        10_000_000,
        10_000_000,
        0,
        0,
        0
    };

    reg [5:0] BEEP_SOUND[0:5] = '{19, 31, 31, 31, 31, 31};
    reg [31:0] BEEP_DUR[0:5] = '{
        10_000_000,
        0,
        0,
        0,
        0,
        0
    };

    reg [5:0] GAMEOVER_MUSIC[0:5] = '{16, 14, 12, 11, 9, 7};
    reg [31:0] GAMEOVER_MUSIC_DUR[0:5] = '{
        20_000_000,
        20_000_000,
        20_000_000,
        20_000_000,
        20_000_000,
        30_000_000
    };

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= 0;
            music_sel <= 0;
            active    <= 0;
            play      <= 0;
        end else if (beep_on || game_on || game_over && !active) begin
            active    <= 1;
            case ({beep_on,game_on,game_over})
                001: music_sel = GAMEOVER;
                010: music_sel = PASS;
                100: music_sel = BEEP;
                default: music_sel = 0; 
            endcase
            music_sel <= game_over ? GAMEOVER : PASS;
            state     <= 0;
        end else if (active) begin
            if (!play && state < 6) begin
                play <= 1;
                case (music_sel)
                    GAMEOVER: begin
                        note     <= GAMEOVER_MUSIC[state];
                        duration <= GAMEOVER_MUSIC_DUR[state];
                    end
                    PASS: begin
                        note     <= PASS_MUSIC[state];
                        duration <= PASS_MUSIC_DUR[state];
                    end
                    BEEP: begin
                        note     <= BEEP_SOUND[state];
                        duration <= BEEP_DUR[state];
                    end
                endcase
            end else if (tone_done) begin
                play  <= 0;
                state <= state + 1;
                if (state == 5) active <= 0;
            end
        end
    end
endmodule

module tone_player (
    input  wire        clk,
    input  wire        start,
    input  wire [15:0] half_period,
    input  wire [31:0] duration,
    output reg         speaker,
    output reg         done
);
    integer tcnt = 0;
    integer dcnt = 0;

    always @(posedge clk) begin
        if (start && !done) begin
            if (dcnt >= duration) begin
                speaker <= 0;
                done    <= 1;
            end else begin
                if (tcnt >= half_period) begin
                    tcnt    <= 0;
                    speaker <= ~speaker;
                end else begin
                    tcnt <= tcnt + 1;
                end
                dcnt <= dcnt + 1;
            end
        end else begin
            tcnt    <= 0;
            dcnt    <= 0;
            speaker <= 0;
            done    <= 0;
        end
    end
endmodule


module freq_lut (
    input  wire [ 5:0] note,
    output reg  [15:0] half_period
);
    always @(*) begin
        case (note)
            5'd0:    half_period = 30578;  // C0
            5'd1:    half_period = 28867;  // C#0
            5'd2:    half_period = 27239;  // D0
            5'd3:    half_period = 25702;  // D#0
            5'd4:    half_period = 24271;  // E0
            5'd5:    half_period = 22909;  // F0
            5'd6:    half_period = 21615;  // F#0
            5'd7:    half_period = 20408;  // G0
            5'd8:    half_period = 19265;  // G#0
            5'd9:    half_period = 18182;  // A0
            5'd10:   half_period = 17158;  // A#0
            5'd11:   half_period = 16186;  // B0
            5'd12:   half_period = 15290;  // C1
            5'd13:   half_period = 14424;  // C#1
            5'd14:   half_period = 13615;  // D1
            5'd15:   half_period = 12857;  // D#1
            5'd16:   half_period = 12136;  // E1
            5'd17:   half_period = 11451;  // F1
            5'd18:   half_period = 10811;  // F#1
            5'd19:   half_period = 10204;  // G1
            5'd20:   half_period = 9629;  // G#1
            5'd21:   half_period = 9091;  // A1
            5'd22:   half_period = 8585;  // A#1
            5'd23:   half_period = 8098;  // B1
            default: half_period = 0;
        endcase
    end
endmodule
