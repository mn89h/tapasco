set routercs [get_cells -hierarchical "*router*"]
set xsl_no [expr {[lindex [regexp -all -inline {(X)(\d+)} [lindex [get_sites -filter { NAME =~  "*Y0*" && SITE_TYPE == "SLICEL" }] end]] 2] + 1}]
set ysl_no [expr {[lindex [regexp -all -inline {(Y)(\d+)} [lindex [get_sites -filter { NAME =~  "*X0*" && SITE_TYPE == "SLICEL" }] 0]] 2] + 1}]
set rno [llength $routercs]

set xyz [regexp -all -inline {\d+} [lindex $routercs end]]
set x_no [expr [lindex $xyz 0] + 1]
set y_no [expr [lindex $xyz 1] + 1]
set z_no [expr [lindex $xyz 2] + 1]

set xw [expr {$xsl_no / (2 * $x_no + 1)}] 
set yw [expr {$ysl_no / (2 * $y_no + 1)}] 

set i 0
for {set z 0} {$z < $z_no} {incr z} {
    for {set y 0} {$y < $y_no} {incr y} {
        for {set x 0} {$x < $x_no} {incr x} {
            set pb [create_pblock "plock_$i"]
            
            set x0 [expr {(2*$x+1) * $xw}]
            set y0 [expr {(2*$y+1) * $yw}]
            set x1 [expr {(2*$x+2) * $xw - 1}]
            set y1 [expr {(2*$y+2) * $yw - 1}]
            
            resize_pblock $pb -add [get_sites -range "SLICE_X$x0\Y$y0 SLICE_X$x1\Y$y1"]
            add_cells_to_pblock plock_$i [get_cells [list system_i/arch/arke_noc_router_$x\_$y\_$z]] -clear_locs
            incr i
        }
    }
}
