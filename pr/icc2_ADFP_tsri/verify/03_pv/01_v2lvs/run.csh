#!/bin/tcsh
source /usr/cad/mentor/CIC/calibre.cshrc

set ProjRoot = /usr/cad/CBDK

set inputLvsvg  = ../../../run/CHIP_pr_lvs.v
set sourceAdded = $ProjRoot/Executable_Package/Collaterals/Tech/LVS/N16ADFP_LVS_Calibre/source.added

echo ".INCLUDE $sourceAdded" > ./N16_ADFP.spi
tclsh ./scr/runset.cmd >> ./N16_ADFP.spi

v2lvs -v $inputLvsvg -o ./N16_ADFP_subckt.spi

sed -i -e 's/^\.GLOBAL.*/**\.GLOBAL/'   ./N16_ADFP_subckt.spi
sed -i -e 's/^Xdefault_bump/****Xdefault_bump/'         ./N16_ADFP_subckt.spi
sed -i -e 's/^\.INCLUDE.*/**\.INCLUDE/' ./N16_ADFP_subckt.spi

set var = `pwd`

echo ".INCLUDE $var/N16_ADFP_subckt.spi" >> ./N16_ADFP.spi

