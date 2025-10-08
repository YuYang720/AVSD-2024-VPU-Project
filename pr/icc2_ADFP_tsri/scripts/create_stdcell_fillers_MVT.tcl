#Create MVT fillers
set defaultFillers "*/FILL*BWP16P90"

set vtTypelvtFillers "*/FILL*BWP16P90LVT"

set_cell_vt_type -lib_cells "*/*P90" -vt_type default
set_cell_vt_type -lib_cells "*/*LVT" -vt_type vtTypelvt
set_vt_filler_rule -vt_type "default default" -filler_cells $defaultFillers
set_vt_filler_rule -vt_type "default vtTypelvt" -filler_cells $defaultFillers
set_vt_filler_rule -vt_type "vtTypelvt default" -filler_cells $defaultFillers
set_vt_filler_rule -vt_type "vtTypelvt vtTypelvt" -filler_cells $vtTypelvtFillers

#create_vtcell_fillers -clear_vt_information

create_vtcell_fillers 

create_stdcell_fillers -lib_cells "*/FILL*BWP16P90LVT"

connect_pg_net -automatic

remove_stdcell_fillers_with_violation

