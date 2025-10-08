set_app_options -name opt.dft.clock_aware_scan_reorder -value true
set_app_options -name time.remove_clock_reconvergence_pessimism -value true

#Turn off CCD
#set_app_options -name clock_opt.flow.enable_ccd -value false
#set_app_options -name cts.compile.enable_local_skew -value true
#set_app_options -name cts.optimize.enable_local_skew -value true

#Turn on CCD
set_app_options -name clock_opt.flow.enable_ccd -value true
set_app_options -name cts.compile.enable_local_skew -value true
set_app_options -name cts.optimize.enable_local_skew -value true

#Enhance Hold time fixing
set_app_options -name clock_opt.hold_effort -value high
#set_app_options -name ccd.hold_control_effort -value high
