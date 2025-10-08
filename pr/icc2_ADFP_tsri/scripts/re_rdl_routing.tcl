create_routing_rule RDL -widths {AP 6}

set_routing_rule -rule RDL \
[get_nets -of_objects [get_pins -of_objects \
[get_cells -filter "ref_name == PAD80APB_LF_BU"]]]

route_rdl_flip_chip -layers AP

remove_routes -rdl
route_rdl_flip_chip -layers AP

#remove_routes -nets CLK -rdl
#route_rdl_flip_chip -layers AP -nets CLK
#check_routes

#optimize_rdl_routes -layer AP -reserve_power_resources true
