#############################################################################################
# Description: The purpose of the script is to provide same automation as dbAddIOText command 
# which was present in Astro.
#
# This script takes three inputs. 
# First input  --- layer name on which text has to created.
# second input --- height of text
# third input  --- type of text that has to be created on IO's.  
#
# Third input can be of three types as shown below:
#	1. cellInstName
#	2. netName
#       3. portName
#
# If cellInstName is given as third input then texts will be created with Instance names.If 
# netName is given as third input then texts will be created with net names. If portName is 
# given as third input then texts will be created with port names.
#
#
# Author: kapilr@synopsys.com 
##############################################################################################
#
# usage:
# icc_shell> source add_io_text.tcl
# icc_shell> add_io_text METAL 20 portName
#
##############################################################################################




proc add_io_text {layernam h texttype} {

#set num [get_cells -hier -filter "is_io == TRUE &&  ref_name != PVDD1CDGM_H && ref_name != PVDD1CDGM_V && ref_name != PVDD2CDGM_H && ref_name != PVDD2CDGM_V && ref_name != PFILLER10080 && ref_name != PFILLER01008 && ref_name != PFILLER00048 && ref_name != PFILLER00001 && ref_name != PCORNER"]
set num [get_cells -hier -filter "is_io == TRUE &&  ref_name == PAD80APB_LF_BU"]
foreach_in_collection z $num {
set box [get_attribute -objects $z -name bbox]
set distance 0
set x1 [lindex [lindex $box 0] 0]
set y1 [lindex [lindex $box 0] 1]
set x2 [lindex [lindex $box 1] 0]
set y2 [lindex [lindex $box 1] 1]
set px [expr [expr $x1+$x2]/2]
set py [expr [expr $y1+$y2]/2]
if {[string equal cellInstName $texttype]} {
if {[string equal S [get_attribute [get_attribute -objects $z -name full_name] orientation]]} {
create_shape -height $h -orient R90 -layer $layernam -origin [list $px [expr $py+$distance]] -text [get_attribute -objects $z -name full_name] -shape_type text
} elseif {[string equal N [get_attribute [get_attribute $z full_name] orientation]]} {
create_shape -height $h -orient R90 -layer $layernam -origin [list $px [expr $py-$distance]] -text [get_attribute -objects $z -name full_name] -shape_type text
} elseif {[string equal E [get_attribute [get_attribute $z full_name] orientation]]} {
create_shape -height $h -layer $layernam -origin [list [expr $px-$distance] $py] -text [get_attribute -objects $z -name full_name] -shape_type text
} else {
create_shape -height $h -layer $layernam -origin [list [expr $px-$distance] $py] -text [get_attribute -objects $z -name full_name] -shape_type text
}
} 


if {[string equal netName $texttype]} {
set tot [get_ports]
foreach_in_collection i $tot {
set t [get_pins -quiet -of [get_attribute -objects $z -name full_name]]
foreach_in_collection j $t {
set test1 [get_attribute -quiet [all_connected $j] -name full_name]
# echo "$test1"
set test2 [get_attribute -objects $i -name full_name]
# echo "$test2"
if {[string equal $test2 $test1]} {
set str $test2
}
}
}


if {[string equal S [get_attribute -objects [get_attribute -objects $z -name full_name] -name orientation]]} {
create_shape -height $h -orient R90 -layer $layernam -origin [list $px $py] -text $str -shape_type text
} elseif {[string equal N [get_attribute -objects [get_attribute -objects $z -name full_name] -name orientation]]} {
create_shape -height $h -orient R90 -layer $layernam -origin [list $px $py] -text $str -shape_type text
} else {
create_shape -height $h -layer $layernam -origin [list $px $py] -text $str -shape_type text
}
}

set str ""
if {[string equal portName $texttype]} {
set tot [get_ports]
foreach_in_collection i $tot {
set t [get_pins -quiet -of [get_attribute -objects $z -name full_name]]
foreach_in_collection j $t {
set test1 [get_attribute -quiet [all_connected $j] -name full_name]
# echo "1 $test1"
set test2 [get_attribute -objects $i -name full_name]
# echo "2 $test2"
if {[string equal $test2 $test1]} {
set str $test2
}
}
}


if {[string equal S [get_attribute -objects [get_attribute -objects $z -name full_name] -name orientation]]} {
create_shape -height $h -orient R0 -layer $layernam -origin [list $px [expr $py+$distance]] -text $str -shape_type text
} elseif {[string equal N [get_attribute -objects [get_attribute -objects $z -name full_name] -name orientation]]} {
create_shape -height $h -orient R0 -layer $layernam -origin [list $px [expr $py-$distance]] -text $str -shape_type text
} elseif {[string equal E [get_attribute -objects [get_attribute -objects $z -name full_name] -name orientation]]} {
create_shape -height $h -orient R0 -layer $layernam -origin [list [expr $px-$distance] $py] -text $str -shape_type text
} else {
create_shape -height $h -layer $layernam -origin [list [expr $px+$distance] $py] -text $str -shape_type text
}
}

}
}
remove_shapes *TEXT*
add_io_text TEXT_AP 5 portName


