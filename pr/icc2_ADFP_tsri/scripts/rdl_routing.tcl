create_routing_rule RDL -widths {AP 6}

set_routing_rule -rule RDL \
[get_nets -of_objects [get_pins -of_objects \
[get_cells -filter "ref_name == PAD80APB_LF_BU"]]]

#connect_pg_net -net VDDPST [get_pins */VDDPST]

#mapping core_power / io_power to Bump
#place_io

route_rdl_flip_chip -layers AP

#set_attribute -object [get_nets CLK] -name physical_status -value lock
#set_attribute -object [get_shapes -of [get_nets CLK]et_attri -name physical_status -value lock -object [get_shapes -of [get_nets CLK]] -name physical_status -value lock


remove_routes -rdl
route_rdl_flip_chip -layers AP

#remove_routes -nets CLK -rdl
#route_rdl_flip_chip -layers AP -nets CLK
#check_routes

#optimize_rdl_routes -layer AP -reserve_power_resources true
