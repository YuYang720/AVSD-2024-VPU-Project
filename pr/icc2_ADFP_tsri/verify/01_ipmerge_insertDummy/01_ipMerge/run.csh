#!/bin/tcsh
mkdir log output

source /usr/cad/mentor/CIC/calibre.cshrc

calibredrv -64 ./scr/runset.cmd | tee log/runset.log

