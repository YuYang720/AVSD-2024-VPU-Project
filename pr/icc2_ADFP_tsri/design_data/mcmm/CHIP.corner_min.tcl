set_parasitic_parameters -early_spec rcbest -late_spec rcbest
set_temperature -40
set_process_number 1
set_voltage 0.88 -object_list VDD
#set_voltage 3.6 -object_list [get_lib_cells P*]
set_operating_conditions -library io_best
set_timing_derate -late 1.05 -cell_delay -net_delay


