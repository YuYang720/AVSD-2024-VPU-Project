set_host_options -max_cores 16

check_routability

source ../scripts/route_app_options.tcl

set_app_options -name route.common.concurrent_redundant_via_mode -value reserve_space
set_app_options -name route.common.post_detail_route_redundant_via_insertion -value off

source /usr/cad/CBDK/Executable_Package/Collaterals/Tech/APR/N16ADFP_APR_ICC2/N16ADFP_APR_ICC2_11M_Antenna.10a.tcl

#uncomment
route_auto

source ../scripts/rdl_routing.tcl

check_routes
route_detail -incremental true -initial_drc_from_input true

save_block
save_block -as CHIP:before_add_redundant_vias


add_redundant_vias


check_routes
route_detail -incremental true -initial_drc_from_input true

#uncomment
route_opt

check_routes
route_detail -incremental true -initial_drc_from_input true
report_timing -significant_digits 4 > route_timing.log
report_timing -delay_type min -significant_digits 4 > route_timing_hold.log

save_block
save_block -as  CHIP:route.design
save_lib