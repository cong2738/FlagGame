`timescale 1ns / 1ps

module color_find (
    input clk,
    input reset,
    input [9:0] x_pixel,
    input [9:0] y_pixel,
    input [3:0] R,
    input [3:0] G,
    input [3:0] B,
    output logic user_hand0,
    output logic user_hand1
);
    reg [31:0] target0_U_count;
    reg [31:0] target0_D_count;
    reg [31:0] target1_U_count;
    reg [31:0] target1_D_count;
    always_ff @(posedge clk, posedge reset) begin : COLOR_FIND
        if (reset) begin
            target0_U_count <= 0;
            target0_D_count <= 0;
            target1_U_count <= 0;
            target1_D_count <= 0;
        end else begin
            if (x_pixel == 320 && y_pixel == 240) begin
                user_hand1 <= (target1_D_count < target1_U_count);
                user_hand0 <= (target0_D_count < target0_U_count);
            end else if (x_pixel == 0 && y_pixel == 0) begin
                target0_U_count <= 0;
                target0_D_count <= 0;
                target1_U_count <= 0;
                target1_D_count <= 0;
            end else begin  //오른손
                if ((R < 5) && (G < 5) && (B > 10)) begin  //파랑
                    if (y_pixel < 120)  //반절 위면
                        target0_U_count <= target0_U_count + 1;
                    else target0_D_count <= target0_D_count + 1;
                end else if (R > 10 && G < 5 && B < 5) begin  //빨강
                    if (y_pixel < 120)  //반절 위면
                        target1_U_count <= target1_U_count + 1;
                    else target1_D_count <= target1_D_count + 1;
                end
            end
        end
    end
endmodule
