set_host_options -max_cores 8
source -echo -continue_on_error ../scripts/01_design_setup.tcl
source -echo -continue_on_error ../scripts/02_design_planning.tcl
source -echo -continue_on_error ../scripts/03_placement.tcl
source -echo -continue_on_error ../scripts/04_cts.tcl
source -echo -continue_on_error ../scripts/05_route.tcl
source -echo -continue_on_error ../scripts/06_dfm.tcl
source -echo -continue_on_error ../scripts/07_streamout.tcl
source -echo -continue_on_error ../scripts/08_outputfile.tcl