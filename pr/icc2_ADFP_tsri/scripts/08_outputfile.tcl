write_verilog -exclude {scalar_wire_declarations \
                         leaf_module_declarations \
                         pg_objects \
                         end_cap_cells \
                         well_tap_cells \
                         filler_cells \
                         pad_spacer_cells \
                         physical_only_cells \
                         empty_modules feedthrough_cells flip_chip_pad_cells \
                         cover_cells } ../../CHIP_pr.v

write_verilog -exclude {empty_modules feedthrough_cells flip_chip_pad_cells physical_only_cells} -force_reference {PVDD*} CHIP_pr_lvs.v

#uncomment
write_sdf ../../CHIP_pr.sdf