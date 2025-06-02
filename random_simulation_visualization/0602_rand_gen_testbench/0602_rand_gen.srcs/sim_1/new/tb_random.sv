`timescale 1ns / 1ps


module tb_random();


    logic         clk;
    logic         rst;
    logic         ce;
    logic         seed_en;
    logic [127:0] seed;     // 128비트 시드 입력 (x, y, z, w 순서)
    logic [ 31:0] rnd;       // 난수 출력

xorshift128 DUT(
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .seed_en(seed_en),
    .seed(seed),     // 128비트 시드 입력 (x, y, z, w 순서)
    .rnd(rnd)       // 난수 출력
);

always #5 clk = ~clk;
logic [31:0] rnd_array [0:9999];  // 1000개 난수 저장
logic [31:0] prev_rnd;
integer  i;
initial begin
    clk = 0; rst = 1; 
    seed = 128'h1234_5678_ABCD_EF01_DEAD_BEEF_CAFE_BABE; // 예시 시드
    #10 clk = 1; rst = 0; seed_en = 0; ce = 1;
    #20 ce = 1;

     prev_rnd = 32'hDEADBEEF; // dummy 초기값
    i = 0;

    // 수집 시작
    forever begin
        @(posedge clk);
        if (rnd !== prev_rnd) begin
            rnd_array[i] = rnd;
            $display("rnd[%0d] = %h", i, rnd);
            prev_rnd = rnd;
            i++;
            if (i == 10000) begin
                $writememh("C:/FPGA/0602_rand_gen/rnd_output.txt", rnd_array);
                $$display("10000_data over");
            end
        end
    end
    #500 seed_en = 1;
    $finish;
end

endmodule
