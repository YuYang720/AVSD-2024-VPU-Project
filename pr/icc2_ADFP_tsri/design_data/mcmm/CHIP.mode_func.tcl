
set sdc_version 1.2
#set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA
current_design CHIP
create_clock [get_ports {CLK}] -name CLK1 -period 10 -waveform {0 5} 
set_case_analysis 0 [get_ports {TEST_MODE}]
set_case_analysis 0 [get_ports {SCAN_EN}]
set_clock_uncertainty  -setup 0.5  [get_clocks {CLK1}]
set_clock_uncertainty  -hold 0.02  [get_clocks {CLK1}]

set_input_delay     3 -clock CLK1 [remove_from_collection [all_inputs] [get_ports CLK]]
set_output_delay    3 -clock CLK1 [all_outputs]

set_drive 0.1 [all_inputs]
set_load -pin_load 20 [all_outputs]


set_ideal_network [get_ports {CLK}]
set_clock_latency 2 [get_clocks {CLK1}]

