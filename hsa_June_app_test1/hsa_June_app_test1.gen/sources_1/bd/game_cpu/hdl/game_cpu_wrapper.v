//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Wed Jun  4 10:01:14 2025
//Host        : korchamHoyoun24 running 64-bit major release  (build 9200)
//Command     : generate_target game_cpu_wrapper.bd
//Design      : game_cpu_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module game_cpu_wrapper
   (reset,
    sys_clock);
  input reset;
  input sys_clock;

  wire reset;
  wire sys_clock;

  game_cpu game_cpu_i
       (.reset(reset),
        .sys_clock(sys_clock));
endmodule
