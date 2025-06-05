`timescale 1ns / 1ps
module OV7670_MemController (
    input  logic        pclk,
    input  logic        reset,
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] ov7670_data,
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);
    logic [ 9:0] h_counter;  // 320 * 2 = 640
    logic [ 7:0] v_counter;  // 240 lines
    logic [15:0] pix_data;

    assign wAddr = v_counter * 320 + h_counter[9:1];
    assign wData = pix_data;


    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            pix_data <= 0;
            h_counter <= 0;
            we <= 1'b0;
        end else begin
            if (href == 1'b0) begin
                h_counter <= 0;
                we <= 1'b0;
            end else begin
                h_counter <= h_counter + 1;
                if (h_counter[0] == 1'b0) begin  // even data
                    pix_data[15:8] <= ov7670_data;
                    we <= 1'b0;
                end else begin
                    pix_data[7:0] <= ov7670_data;
                    we            <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : v_sequance
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (v_sync) begin
                v_counter <= 0;
            end else begin
                if (h_counter == 640 - 1) begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
endmodule
