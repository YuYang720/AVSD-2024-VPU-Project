set_parasitic_parameters -early_spec rcworst -late_spec rcworst
set_temperature 125
set_process_number 1
set_voltage 0.72 -object_list VDD
#set_voltage 3.0 -object_list [get_lib_cells P*]
#set_operating_conditions -library io_worst
set_timing_derate -early 0.95 -cell_delay -net_delay


