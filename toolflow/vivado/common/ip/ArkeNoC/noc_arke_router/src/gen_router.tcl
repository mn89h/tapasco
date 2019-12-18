##HELPERS##
#dec2bin: returns a string, e.g. dec2bin 10 => 1010 
proc dec2bin i {
    set res {} 
    while {$i>0} {
        set res [expr {$i%2}]$res
        set i [expr {$i/2}]
    }
    if {$res == {}} {set res 0}
    return $res
}

##PROGRAM##
    set projectname noc_benchmark3
    set ROUTER_IP user.org:user:Router:1.0
    set DIM_X 3
    set DIM_Y 3
    set DIM_Z 2
    set DIM_X_W [expr {round(log($DIM_X)/log(2.0))}] 
    set DIM_Y_W [expr {round(log($DIM_Y)/log(2.0))}] 
    set DIM_Z_W [expr {round(log($DIM_Z)/log(2.0))}] 
    set DATA_WIDTH 16

create_project $projectname /home/malte/$projectname -part xc7z020clg400-1
ipx::open_ipxact_file /home/malte/Arke-Legacy/router_src/component.xml
#set data_width
set_property widget {hexEdit} [ipgui::get_guiparamspec -name "address" -component [ipx::current_core] ]
set_property value {"0000000000000000"} [ipx::get_user_parameters address -of_objects [ipx::current_core]]
set_property value {"0000000000000000"} [ipx::get_hdl_parameters address -of_objects [ipx::current_core]]
set_property value_bit_string_length 16 [ipx::get_user_parameters address -of_objects [ipx::current_core]]
set_property value_bit_string_length 16 [ipx::get_hdl_parameters address -of_objects [ipx::current_core]]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  /home/malte/Arke-Legacy/router_src [current_project]
update_ip_catalog
create_bd_design "design_1"

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

for {set z 0} {$z < $DIM_Z} {incr z} {
    for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {
            create_bd_cell -type ip -vlnv $ROUTER_IP Router_$x\_$y\_$z
            set xyz ""
            append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
            append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
            append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]
            set xyz [format {%0*s} $DATA_WIDTH $xyz]
            set_property -dict [list CONFIG.address {"$xyz"}] [get_bd_cells Router_$x\_$y\_$z]
            apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins Router_$x\_$y\_$z/clk]
        }
    }
}

for {set z 0} {$z < $DIM_Z} {incr z} {
    for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {
            if { $x+1 < $DIM_X } then {
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_out_east]    [get_bd_pins Router_[expr $x+1]\_$y\_$z/data_in_west]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_out_east] [get_bd_pins Router_[expr $x+1]\_$y\_$z/control_in_west]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_in_east]     [get_bd_pins Router_[expr $x+1]\_$y\_$z/data_out_west]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_in_east]  [get_bd_pins Router_[expr $x+1]\_$y\_$z/control_out_west]
            }
            if { $y+1 < $DIM_Y } then {
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_out_north]    [get_bd_pins Router_$x\_[expr $y+1]\_$z/data_in_south]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_out_north] [get_bd_pins Router_$x\_[expr $y+1]\_$z/control_in_south]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_in_north]     [get_bd_pins Router_$x\_[expr $y+1]\_$z/data_out_south]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_in_north]  [get_bd_pins Router_$x\_[expr $y+1]\_$z/control_out_south]
            }
            if { $z+1 < $DIM_Z } then {
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_out_up]    [get_bd_pins Router_$x\_$y\_[expr $z+1]/data_in_down]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_out_up] [get_bd_pins Router_$x\_$y\_[expr $z+1]/control_in_down]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/data_in_up]     [get_bd_pins Router_$x\_$y\_[expr $z+1]/data_out_down]
                connect_bd_net [get_bd_pins Router_$x\_$y\_$z/control_in_up]  [get_bd_pins Router_$x\_$y\_[expr $z+1]/control_out_down]
            }
        }
    }
}