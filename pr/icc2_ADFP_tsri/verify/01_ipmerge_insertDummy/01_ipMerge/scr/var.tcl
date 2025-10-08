set ProjRoot /usr/cad/CBDK

set blockGds ../../../run/CHIP.gds 
set gdsList  " \
    $ProjRoot/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/GDS/N16ADFP_StdCell.gds \
    $ProjRoot/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/GDS/N16ADFP_StdIO.gds \
    $ProjRoot/Executable_Package/Collaterals/IP/bondpad/N16ADFP_BondPad/GDS/N16ADFP_BondPad.gds \
/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/SRAM/N16ADFP_SRAM_100a.gds \
/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/tag_array/N16ADFP_tag_array_100a.gds \
/usr/cad/CBDK/Executable_Package/AVSD_cell_lib/data_array/N16ADFP_data_array_100a.gds \
"

