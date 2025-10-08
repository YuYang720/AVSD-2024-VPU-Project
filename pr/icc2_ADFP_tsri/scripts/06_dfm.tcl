source ../scripts/create_stdcell_fillers_MVT.tcl

check_routes > dfm_drc.log
report_timing -significant_digits 4 > dfm_before_create_stdcell_fillers_timing.log
report_timing -delay_type min -significant_digits 4 > dfm_before_create_stdcell_fillers_timing_hold.log

save_block
save_block -as CHIP:dfm0.design


check_routes

source ../scripts/add_io_text_adfp.tcl


create_shape -layer TEXT4 -height 5 -origin {310 764} -shape_type text -text VDD 
create_shape -layer TEXT4 -height 5 -origin {310 760} -shape_type text -text VSS 
create_shape -layer TEXT5 -height 5 -origin {332 836} -shape_type text -text VDDPST 

check_routes

check_pg_drc
check_pg_connectivity
check_pg_missing_vias
check_lvs -max_errors 0

report_power > final_power.log
report_timing -significant_digits 4 > final_timing.log
report_timing -delay_type min -significant_digits 4 > final_timing_hold.log


save_block
save_block -as CHIP:dfm.design
save_lib