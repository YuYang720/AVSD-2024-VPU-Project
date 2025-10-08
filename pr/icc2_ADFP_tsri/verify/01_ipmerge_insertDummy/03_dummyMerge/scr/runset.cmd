source ./scr/var.tcl

set top [layout create $ipmergeGds -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]

set importList ""
set importList [concat $importList  $beDmGds $feDmGds]

foreach gdsFile $importList {
    set toImport [layout create "$gdsFile" -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
    set checkTopCell [$toImport topcell]

    if {$checkTopCell == ""} {
        puts "skip $gdsFile ... due to 0 cell gds"
    } else {
        set gdsRename  [$toImport topcell] 
        $top import layout $toImport FALSE overwrite -dt_expand -preservePaths -preserveTextAttributes -preserveProperties
        $top create ref CHIP $gdsRename 0 0 0 0 1

    }
}

$top oasisout ./output/CHIP.dmmerge.oas.gz CHIP

