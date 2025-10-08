set_host_options -max_cores 8

report_clocks
report_clocks -skew
report_clocks -groups
report_clock_qor

report_ports [get_ports cpu_clk]
check_design -checks pre_clock_tree_stage

source -echo ../scripts/cts_setup.tcl

report_timing -significant_digits 4 > pre_cts_timing.log

reset_timing_derate

get_scenario  -filter active&&hold
report_scenarios

source ../scripts/cts_app_options.tcl

remove_ideal_network -all
#uncomment
clock_opt

synthesize_clock_trees -postroute

report_timing -significant_digits 4 > cts_timing.log
report_timing -delay_type min -significant_digits 4 > cts_timing_hold.log
report_clock_timing -type skew

connect_pg_net

save_block
save_block -as  CHIP:cts.design
save_lib
reset_timing_derate