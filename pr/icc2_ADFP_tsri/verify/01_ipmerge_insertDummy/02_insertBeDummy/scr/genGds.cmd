set gdsIn [ glob -nocomplain "*EOL*.gds"]
set inputGds [lindex $gdsIn 0]
set top [layout create $inputGds -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
set TopCell [$top topcell]
set gdsout "./output/N16_ADFP.dmoas.gz"
$top oasisout $gdsout $TopCell

