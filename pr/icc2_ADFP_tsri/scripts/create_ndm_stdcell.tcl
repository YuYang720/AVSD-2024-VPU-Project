if !{[file exists "export_creation"]} {file mkdir "export_creation"}
if !{[file exists "icc2_cell_lib"]} {file mkdir "icc2_cell_lib"}

set_app_options -as_user_default -name lib.workspace.group_libs_naming_strategies -value "common_prefix common_suffix common_prefix_and_common_suffix first_logical_lib_name"
          
create_workspace -scale_factor 10000 -flow exploration -technology N16ADFP_APR_ICC2_11M.10a_addPW.tf ADFP_stdCell

### BEGIN_COMMAND from tech_only.tcl
set_attribute [get_layers {M1 M3 M5 M7 M9 M11} -quiet] routing_direction vertical
set_attribute [get_layers M1 -quiet] track_offset 0.045
set_attribute [get_layers {M3 M5 M7 M9 M11} -quiet] track_offset 0
set_attribute [get_layers {M2 M4 M6 M8 M10 AP} -quiet] routing_direction horizontal 
set_attribute [get_layers {M2 M4 M6 M8 M10 AP} -quiet] track_offset 0
set_attribute [get_site_defs] is_default false
set_attribute [get_site_defs unit] is_default true
set_attribute [get_site_defs unit] symmetry Y
### END_COMMAND from tech_only.tcl

### BEGIN_COMMAND from read_logic.tcl
set_app_options -as_user_default -name lib.logic_model.require_same_opt_attrs -value false
set_app_options -as_user_default -name lib.logic_model.use_db_rail_names -value true
set_app_options -as_user_default -name lib.logic_model.auto_remove_timing_only_designs -value true

read_db { 
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/CCS/N16ADFP_StdCellff0p88v125c_ccs.db
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/CCS/N16ADFP_StdCellff0p88vm40c_ccs.db
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/CCS/N16ADFP_StdCellss0p72v125c_ccs.db
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/CCS/N16ADFP_StdCellss0p72vm40c_ccs.db
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/CCS/N16ADFP_StdCelltt0p8v25c_ccs.db
}

#read_lib { 
#}


read_lef -convert_sites {{core unit}} -cell_boundary by_cell_size { 
/eng/nschang/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/LEF/lef/N16ADFP_StdCell.lef
}

#== FOR FLIP CHIP ===
#set DBYTE_pins "BP_DAT8 BP_DAT7 BP_DAT6 BP_DAT5 BP_DAT4 VDD VDDQ VSS"
#foreach pin $DBYTE_pins {
#        set_attribute [get_lib_pins */dwc_ddrphydbyte_top_ns/$pin] is_pad true
#            set_attribute [get_lib_pins */dwc_ddrphydbyte_top_ew/$pin] is_pad true
#}
#============

#set_app_options -as_user_default  -name lib.physical_model.block_all -value false
#set_app_options -as_user_default  -name lib.physical_model.convert_metal_blockage_to_zero_spacing -value {{M3 0 all} {M4 0 all} {M5 0 all} {M6 0 all} {M7 0 all} {M8 0 all}}



set_app_options -as_user_default -name file.gds.port_type_map -value {{power VDD} {ground VSS}}
set_app_options -as_user_default -name file.gds.text_layer_map -value {}

report_workspace
group_libs
#set_attribute -objects [get_lib_pins */ANTENNA*/A] -name is_diode -value true

report_app_options > ./export_creation/ADFP_exploration_report_app_options.rep
write_workspace -file ./export_creation/ADFP_exploration_write_workspace.tcl
process_workspaces -check_options "-allow_missing"
remove_workspace
sh mv *.ndm icc2_cell_lib
exit
