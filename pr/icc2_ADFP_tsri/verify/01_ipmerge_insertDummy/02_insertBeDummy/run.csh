#!/bin/tcsh
mkdir log output

source /usr/cad/mentor/CIC/calibre.cshrc

set NUM_OF_CPU = 12

### sed Deck
set ProjRoot = /usr/cad/CBDK

set deckFile = $ProjRoot/Executable_Package/Collaterals/Tech/DUMMY/N16ADFP_Dummy_Calibre/BEOL/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a.encrypt

cp -rf $deckFile ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified

sed -i -e 's/^LAYOUT PRIMARY/\/\/LAYOUT PRIMARY/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified
sed -i -e 's/^LAYOUT PATH/\/\/LAYOUT PATH/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified
sed -i -e 's/^LAYOUT SYSTEM/\/\/LAYOUT SYSTEM/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified

sed -i -e 's/^DRC RESULTS DATABASE/\/\/DRC RESULTS DATABASE/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified
sed -i -e 's/^DRC SUMMARY REPORT/\/\/DRC SUMMARY REPORT/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified

sed -i -e 's/  #DEFINE WITH_SEALRING/\/\/#DEFINE WITH_SEALRING/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified

sed -i -e 's/\/\/#DEFINE UseprBoundary/#DEFINE UseprBoundary/g' ./scr/Dummy_BEOL_CalibreYE_16nm_ADFP_FFP.10a_eval122121.encrypt.modified

calibre -drc -hier -64 -turbo $NUM_OF_CPU  -hyper -lmretry loop,maxretry:200,interval:200 ./scr/runset.cmd | tee -i log/runset.log

calibredrv -64 ./scr/genGds.cmd -wait 60 | tee -i log/rename_top.log

