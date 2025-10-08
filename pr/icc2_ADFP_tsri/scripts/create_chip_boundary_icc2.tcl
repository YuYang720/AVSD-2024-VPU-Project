remove_shapes [get_shapes -filter {@layer_name == CUSTOM_CB}]
set left_out   [get_attr [get_designs CHIP] boundary_bounding_box.ll_x]
set bottom_out [get_attr [get_designs CHIP] boundary_bounding_box.ll_y]
set right_out  [get_attr [get_designs CHIP] boundary_bounding_box.ur_x]
set top_out    [get_attr [get_designs CHIP] boundary_bounding_box.ur_y]
set bottom_out_snap [expr round(($bottom_out-0.048)/0.096)*0.096]
set top_out_snap [expr round(($top_out+0.048)/0.096)*0.096]
puts "die_boundary: $left_out $bottom_out_snap $right_out $top_out_snap"
if { ![llength [get_layers CUSTOM_CB]] } {
    create_layer -name CUSTOM_CB -number 100
}
create_shape -shape_type rect -boundary [list [list $left_out $bottom_out_snap] [list $right_out $top_out_snap]]  -layer CUSTOM_CB
puts "\n\n To stream out chip_boundary, add below line in stream layer map\n all 100:0:* 108:250 \n\n"

#gui_set_setting -window [gui_get_current_window -types Layout] -setting hatchRoutedLayer_CUSTOM_CB -value NoBrush

