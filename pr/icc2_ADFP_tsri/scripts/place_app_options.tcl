# Congestion Driven Restructuring
#set_app_option -name place.coarse.cong_restruct -value on
#set_app_option -name place.coarse.cong_restruct_iterations -value 3
#set_app_option -name place.coarse.cong_restruct_effort -value high

# Advance Legalizer
#set_app_option -name place.legalize.enable_advanced_legalizer -value true
#set_app_option -name place.legalize.enable_advanced_prerouted_net_check -value true

# Logic restructuring 
#set_app_option -name opt.common.advanced_logic_restructuring_mode -value area_timing

# Auto density control
set_app_option -name place.coarse.enhanced_auto_density_control -value true
