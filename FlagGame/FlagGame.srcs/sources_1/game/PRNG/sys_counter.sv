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

module sys_counter_test (
    input clk,
    input rst,
    input btn,
    output [7:0] fnd_font,
    output [3:0] fnd_comm
);
    reg [31:0] count;
    btn_debounce u_btn_debounce(
        .clk   (clk   ),
        .reset (rst ),
        .i_btn (btn ),
        .o_btn (en )
    );
    sys_counter u_sys_counter(
        .clk   (clk   ),
        .en    (en    ),
        .count (count )
    );
    fnd_controller u_fnd_controller(
        .clk      (clk      ),
        .reset    (rst    ),
        .bcd32    (count    ),
        .fnd_font (fnd_font ),
        .fnd_comm (fnd_comm )
    );
    
endmodule