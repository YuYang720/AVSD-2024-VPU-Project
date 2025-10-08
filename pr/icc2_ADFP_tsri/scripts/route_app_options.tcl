set_app_options -name route.global.timing_driven    -value true
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.timing_driven     -value true
set_app_options -name route.track.crosstalk_driven  -value true
set_app_options -name route.detail.timing_driven    -value true
set_app_options -name route.detail.force_max_number_iterations -value false
set_app_options -name time.si_enable_analysis       -value true

## Secondary PG Routin
#set_app_options -name route.common.number_of_secondary_pg_pin_connections -value 2
#set_app_options -name route.common.separate_tie_off_from_secondary_pg     -value true
#if {[get_routing_rules -quiet VDDwide] != ""} {remove_routing_rules VDDwide }
#create_routing_rule VDDwide -widths {M1 0.1 M2 0.1 M3 0.1} -taper_distance 0.4
#set_routing_rule -rule VDDwide -min_routing_layer M2 -min_layer_mode allow_pin_connection -max_routing_layer M3 [get_nets VDD]
#route_group -nets {VDD}

set_app_options -name ccd.post_route_buffer_removal -value true
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false
set_app_options -name route_opt.flow.enable_ccd -value false

## Fix soft rule violation
set_app_options -name route.common.post_detail_route_fix_soft_violations -value true
set_app_options -name route.common.post_group_route_fix_soft_violations -value true
set_app_options -name route.common.post_incremental_detail_route_fix_soft_violations -value true
set_app_options -name route.common.post_eco_route_fix_soft_violations -value true

