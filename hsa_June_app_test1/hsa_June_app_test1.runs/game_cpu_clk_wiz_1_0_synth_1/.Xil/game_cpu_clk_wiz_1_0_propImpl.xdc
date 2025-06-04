set_property SRC_FILE_INFO {cfile:{c:/harman/_HARMAN Team Project/HarmanSA_June_TeamPJ/hsa_June_app_test1/hsa_June_app_test1.gen/sources_1/bd/game_cpu/ip/game_cpu_clk_wiz_1_0/game_cpu_clk_wiz_1_0.xdc} rfile:../../../hsa_June_app_test1.gen/sources_1/bd/game_cpu/ip/game_cpu_clk_wiz_1_0/game_cpu_clk_wiz_1_0.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.1
