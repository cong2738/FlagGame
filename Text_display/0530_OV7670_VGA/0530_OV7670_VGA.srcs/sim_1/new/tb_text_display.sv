

module tb_text_display();

    logic       clk;
    logic       d_en;
    logic [9:0] x;
    logic [9:0] y;


    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;
    logic text_on;


abc_text_display DUT(.*);

always #5 clk = ~clk;

int yy;
int xx;
initial begin
    clk = 1; d_en = 1;
    // 문자열이 보이는 구역만 스캔
    for (int yy = 16; yy < 32; yy++) begin
        for (int xx = 308; xx < 332; xx++) begin
            x = xx;
            y = yy;
            #10;
            if (text_on) begin
                $display("x=%0d, y=%0d, R=%h, G=%h, B=%h", x, y, red, green, blue);
            end
        end
    end
    $finish;

end

endmodule
