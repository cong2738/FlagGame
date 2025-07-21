`timescale 1ns / 1ps

module sys_counter (
    input clk,
    input en,
    output reg [31:0] count
);
    logic [31:0] temp;
    always_ff @(posedge clk) begin : COUNTER
        if (en) begin
            count <= temp;
        end else temp++;
    end
endmodule