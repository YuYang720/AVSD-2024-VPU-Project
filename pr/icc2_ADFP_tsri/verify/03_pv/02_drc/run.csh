#!/bin/tcsh
mkdir rpt output log

source /usr/cad/mentor/CIC/calibre.cshrc


set NUM_OF_CPU = 32

### sed Deck
set ProjRoot = /usr/cad/CBDK

set deckFile = $ProjRoot/Executable_Package/Collaterals/Tech/DRC/N16ADFP_DRC_Calibre/LOGIC_TopMr_DRC/N16ADFP_DRC_Calibre_11M.11_1a.encrypt

cp -rf $deckFile ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified

sed -i -e 's/^#DEFINE DUMMY_PRE_CHECK/\/\/#DEFINE DUMMY_PRE_CHECK/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified
sed -i -e 's/\/\/#DEFINE UseprBoundary/#DEFINE UseprBoundary/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified

sed -i -e 's/^LAYOUT SYSTEM/\/\/LAYOUT SYSTEM/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified
sed -i -e 's/^LAYOUT PATH/\/\/LAYOUT PATH/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified
sed -i -e 's/^LAYOUT PRIMARY/\/\/LAYOUT PRIMARY/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified

sed -i -e 's/^DRC RESULTS DATABASE "/\/\/DRC RESULTS DATABASE "/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified
sed -i -e 's/^DRC SUMMARY REPORT/\/\/DRC SUMMARY REPORT/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified

sed -i -e 's/^VARIABLE VDD_TEXT/\/\/VARIABLE VDD_TEXT/g' ./scr/N16ADFP_DRC_Calibre_11M.11_1a.encrypt.modified

calibre -drc -hier -64 -turbo $NUM_OF_CPU  -hyper -lmretry loop,maxretry:200,interval:200 ./scr/runset.cmd | tee -i log/runset.log

mv -f *.density ./rpt
mv -f *.rep     ./rpt

