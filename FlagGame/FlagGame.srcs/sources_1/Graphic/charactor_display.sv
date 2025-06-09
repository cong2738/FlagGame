`timescale 1ns / 1ps

module Text_display (
    input  logic        clk,
    input  logic        reset,
    input  logic        d_en,
    input  logic [31:0] game_count_i,
    input  logic [31:0] game_score,
    input  logic [ 3:0] commend,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    input  logic [ 3:0] i_red,
    input  logic [ 3:0] i_green,
    input  logic [ 3:0] i_blue,
    output logic [ 3:0] o_red,
    output logic [ 3:0] o_green,
    output logic [ 3:0] o_blue
);
    logic [3:0] o_red_cmd;
    logic [3:0] o_green_cmd;
    logic [3:0] o_blue_cmd;

    logic [3:0] o_red_cnt;
    logic [3:0] o_green_cnt;
    logic [3:0] o_blue_cnt;

    logic text_on_cmd;
    logic text_on_cnt;

    logic [$clog2(8)+ 7:0] rom_addr_cmd;
    logic [7:0] font_line_cmd;
    logic [10:0] rom_addr_cnt;
    logic [7:0] font_line_cnt;

    CMD_text_display U_CMD_text_display (.*);
    COUNT_Text_display U_CNT_DISPLAY (.*);
    font_rom U_FONT_ROM (
        .clk(clk),
        .addr_cmd(rom_addr_cmd),
        .addr_cnt(rom_addr_cnt),
        .data_cmd(font_line_cmd),
        .data_cnt(font_line_cnt)
    );

    logic [3:0] o_red_score;
    logic [3:0] o_green_score;
    logic [3:0] o_blue_score;
    Text_score u_Text_score (
        .clk       (clk),
        .d_en      (d_en),
        .x         (x),
        .y         (y),
        .score     (game_score),
        .text_red  (o_red_score),
        .text_green(o_green_score),
        .text_blue (o_blue_score),
        .score_on  (score_on)
    );

    localparam TEXT_SEL = 3'b001, TIME_SEL = 3'b010, SCORE_SEL = 3'b100;
    logic [11:0] o_c;
    assign {o_red, o_green, o_blue} = o_c;
    logic [2:0] sel = {score_on, text_on_cnt, text_on_cmd};
    always_comb begin : col_sel
        if (x < 320 && y == 120) begin  // vertical_mid_guide_line
            o_c = 12'h0f0;  // green color
        end else
            case (sel)
                TEXT_SEL:  o_c = {o_red_cmd, o_green_cmd, o_blue_cmd};
                TIME_SEL:  o_c = {o_red_cnt, o_green_cnt, o_blue_cnt};
                SCORE_SEL: o_c = {o_red_score, o_green_score, o_blue_score};
                default:   o_c = {i_red, i_green, i_blue};
            endcase
    end
endmodule

