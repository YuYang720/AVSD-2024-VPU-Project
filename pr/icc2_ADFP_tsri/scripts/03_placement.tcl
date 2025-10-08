set_host_options -max_cores 8

report_congestion -rerun_global_router
save_block

set_app_options -name time.delay_calculation_style -value zero_interconnect
report_timing > before_place_opt_with_zrt_timing.log
set_app_options -name time.delay_calculation_style -value auto


report_power

source ../scripts/add_tie.tcl
set_app_options -name place.coarse.continue_on_missing_scandef -value true


set_app_option -name place.legalize.enable_advanced_legalizer -value false
set_app_option -name place.legalize.enable_advanced_prerouted_net_check -value false

#uncomment
place_opt

refine_placement
legalize_placement

report_congestion -rerun_global_router

report_timing > place_timing.log
report_power
connect_pg_net

save_block
save_block -as  CHIP:placement.design
save_lib