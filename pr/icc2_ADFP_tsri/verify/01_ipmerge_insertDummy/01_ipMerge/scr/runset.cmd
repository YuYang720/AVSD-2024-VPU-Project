source ./scr/var.tcl

set top [layout create $blockGds -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
set TopCell [$top topcell]
puts "\[INFO\] Merge GDS\n"
foreach gdsFile $gdsList {
    set toImport [layout create "$gdsFile" -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]

    puts "import $gdsFile ....\n"
    $top import layout $toImport FALSE overwrite -dt_expand -preservePaths -preserveTextAttributes -preserveProperties

}

$top create layer 108.250
$top create polygon CHIP 108.250 0 0 1899.72u 1898.496u

$top oasisout ./output/CHIP.oas.gz $TopCell 

