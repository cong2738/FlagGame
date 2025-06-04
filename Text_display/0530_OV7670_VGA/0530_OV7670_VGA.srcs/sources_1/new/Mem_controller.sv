`timescale 1ns / 1ps

// module OV7670_Mem_controller (
//     input logic       PCLK,
//     input logic       clk,
//     input logic       reset,
//     input logic       HREF,
//     input logic       v_sync,
//     input logic [7:0] data
// );

// typedef enum [3:0] { 
//     IDLE,
//     DATA
// } state_e;

// state_e state, state_next;

// assign pclk_rising = ()


// always_ff @( posedge clk , posedge reset ) begin 
//     if (reset) begin
//         state <= IDLE;
//     end
//     else begin
//         state <= state_next;
//     end
// end
// always_comb begin
//     state_next = state; 
//     case (state)
//         IDLE: begin
            
//         end 
//         DATA1: begin
//             if (pclk_rising) begin
                
//             end
//         end 
//         DATA2: begin
            
//         end 
//         WAIT: begin
            
//         end 
        
//     endcase
// end
// endmodule


module OV7670_MemController (
    input logic       pclk,
    input logic       reset,
    input logic       href,
    input logic       v_sync,
    input logic [7:0] ov7670_data,
    output logic       we,
    output logic [16:0]  wAddr,
    output logic [15:0] wData
);

    logic [9:0] h_counter; // 320 * 2 (640 pixel)
    logic [7:0] v_counter; //240 line
    logic [15:0] pix_data;

    assign wAddr = v_counter * 320 + h_counter[9:1]; //remove lower bit, hcounter/2
    assign wData = pix_data;


    always_ff @( posedge pclk, posedge reset ) begin : h_sequence
        if (reset) begin
            pix_data <= 0;
            h_counter <= 0;
            we <= 1'b0;
        end
        else begin
            if (href == 1'b0) begin
                h_counter <= 0;
                we <= 1'b0;
            end
            else begin
                h_counter <= h_counter + 1;
                if (h_counter[0] == 1'b0) begin // even data
                    pix_data[15:8] <= ov7670_data; //save upper 8bit 
                    we <= 1'b0;
                end
                else begin //odd data
                    pix_data[7:0] <= ov7670_data;
                    we <= 1'b1;
                end
            end
        end
    end

    always_ff @( posedge pclk, posedge reset ) begin : v_sequance
        if (reset) begin
            v_counter <= 0;
        end
        else begin
            if (v_sync) begin
                v_counter <= 0;
            end
            else begin
                if (h_counter == 640 - 1) begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end


endmodule
