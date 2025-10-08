set_host_options -max_cores 16

#####################	strat	1	#################################
create_lib -ref_libs \
           {/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/N16ADFP_StdCell.ndm \
	/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/ADFP_stdIO_physical_only.ndm \
	/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/StdIO/N16ADFP_StdIO.ndm \
	/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/SRAM/SRAM.ndm \
	/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/tag_array/tag_array.ndm \
	/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/data_array/data_array.ndm} \
	-technology /usr/cad/CBDK/Executable_Package/ADFP/ndm/N16ADFP_APR_ICC2_11M.10a_addPW.tf \
	CHIP

read_verilog -top CHIP ../../../syn/CHIP_syn.v
link_block
report_ref_libs

source ../design_data/CHIP.upf

#uncomment
commit_upf  

read_parasitic_tech -tlup /usr/cad/CBDK/Executable_Package/Collaterals/Tech/RC/N16ADFP_STARRC/N16ADFP_STARRC_worst.nxtgrd -name rcworst
read_parasitic_tech -tlup /usr/cad/CBDK/Executable_Package/Collaterals/Tech/RC/N16ADFP_STARRC/N16ADFP_STARRC_best.nxtgrd -name rcbest
report_lib -parasitic_tech [current_lib]

set_attribute [get_site_defs unit] is_default true
set_attribute [get_site_defs unit] symmetry Y

set_attribute [get_layers {M1}] track_offset  0.045
set_attribute [get_layers {M1 M3 M5 M7 M9 M11}] routing_direction vertical
set_attribute [get_layers {M2 M4 M6 M8 M10 AP}] routing_direction horizontal


report_ignored_layers

source -echo ../design_data/mcmm/CHIP.mcmm.tcl
report_mode

save_block 
save_block -as CHIP:design_setup.design
save_lib
#####################	end	1	#################################