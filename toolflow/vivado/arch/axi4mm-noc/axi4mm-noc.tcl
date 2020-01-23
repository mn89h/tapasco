#
# Copyright (C) 2014 Jens Korinth, TU Darmstadt
#
# This file is part of Tapasco (TPC).
#
# Tapasco is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Tapasco is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
#
# @file    axi4mm.tcl
# @brief  AXI4 memory mapped master/slave interface based Architectures.
# @author  J. Korinth, TU Darmstadt (jk@esa.tu-darmstadt.de)
#
namespace eval arch {
  namespace export get_arch_name
  namespace export create
  namespace export get_irqs
  namespace export get_masters
  namespace export get_processing_elements
  namespace export get_slaves

  set arch_mem_ics [list]
  set arch_mem_ports [list]
  set arch_host_ics [list]
  set arch_irq_concats [list]

  set arch_host_routers [list]
  set arch_pe_routers [list]
  set arch_mem_routers [list]

  variable DIM_X 2
  variable DIM_Y 2
  variable DIM_Z 1
  variable BUFFER_DEPTH 8
  variable DATA_WIDTH 128
  variable CONTROL_WIDTH 3

  variable DIM_X_W 2
  variable DIM_Y_W 2
  variable DIM_Z_W 0
  variable ADDRESS_WIDTH 4

  variable A4L_ADDR_W 32
  variable A4L_DATA_W 32
  variable A4F_ADDR_W 32
  variable A4F_DATA_W 32
  variable A4F_ID_W 0



  proc dec2bin i {
      set res {} 
      while {$i>0} {
          set res [expr {$i%2}]$res
          set i [expr {$i/2}]
      }
      if {$res == {}} {set res 0}
      return $res
  }
  proc splitline {string countChar} {
    set rc [llength [split $string $countChar]]
    incr rc -1
    return $rc
  }

  # scan plugin directory
  foreach f [glob -nocomplain -directory "$::env(TAPASCO_HOME_TCL)/arch/axi4mm/plugins" "*.tcl"] {
    source -notrace $f
  }

  # Return arch name
  proc get_arch_name {} {
    return "axi4mm-noc"
  }

  # Returns a list of the bd_cells of slave interfaces of the threadpool.
  proc get_slaves {} {
    set inst [current_bd_instance]
    current_bd_instance [::tapasco::subsystem::get arch]
    set r [list [get_bd_intf_pins -of [get_bd_cells "in1"] -filter { MODE == "Slave" }]]
    current_bd_instance $inst
    return $r
  }

  # Returns a list of the bd_cells of master interfaces of the threadpool.
  proc get_masters {} {
    variable arch_mem_ports
    return $arch_mem_ports
  }

  proc get_processing_elements {} {
    return [get_bd_cells -of_objects [::tapasco::subsystem::get arch] -filter { NAME =~ target*}]
  }

  # Returns a list of interrupt lines from the threadpool.
  proc get_irqs {} {
    return [get_bd_pins -of_objects [::tapasco::subsystem::get arch] -filter {TYPE == "intr" && DIR == "O"}]
  }

  # Checks, if the current composition can be instantiated. Exits script with
  # error message otherwise.
  proc arch_check_instance_count {kernels} {
    set totalInst 0
    set mc 0
    set sc 0
    dict for {k v} $kernels {
      # add count to total instances
      set no [dict get $kernels $k count]
      set totalInst [expr "$totalInst + $no"]
      # get first instance
      set example [get_bd_cells [format "target_ip_%02d_000" $k]]
      # add masters and slaves to total count
      set masterc [llength [get_bd_intf_pins -of $example -filter { MODE == "Master" && CONFIG.PROTOCOL =~ "AXI*" }]]
      set slavec  [llength [get_bd_intf_pins -of $example -filter { MODE == "Slave" && CONFIG.PROTOCOL =~ "AXI*" }]]
      set mc [expr "$mc + ($no * $masterc)"]
      set sc [expr "$sc + ($no * $slavec)"]
    }
    if {$totalInst > [::tapasco::get_platform_num_slots]} {
      error "ERROR: Currently only [::tapasco::get_platform_num_slots] instances of target IP are supported."
      exit 1
    }
    set max_masters [expr [join [platform::max_masters] +]]
    if {$mc > $max_masters} {
      puts "ERROR: Configuration requires connection of $mc M-AXI interfaces, but the Platform supports only $max_masters."
      exit 1
    }
    if {$sc > [::tapasco::get_platform_num_slots]} {
      puts "ERROR: Configuration requires connection of $sc S-AXI interfaces; at the moment only [::tapasco::get_platform_num_slots] are supported."
      exit 1
    }
  }

  # Instantiates all IP cores in the composition and return an array with their
  # bd_cells.
  proc arch_create_instances {composition} {
    set insts [list]

    set no_kinds [llength [dict keys $composition]]
    puts "Creating $no_kinds different IP cores ..."

    for {set i 0} {$i < $no_kinds} {incr i} {
      set no_inst [dict get $composition $i count]
      set vlnv [dict get $composition $i vlnv]
      puts "Creating $no_inst instances of target IP core ..."
      puts "  VLNV: $vlnv"
      for {set j 0} {$j < $no_inst} {incr j} {
        set name [format "target_ip_%02d_%03d" $i $j]
        set inst [lindex [tapasco::call_plugins "post-pe-create" [create_bd_cell -type ip -vlnv "$vlnv" $name]] 0]
        lappend insts $inst
      }
    }
    puts "insts = $insts"
    return $insts
  }

  # Retrieve AXI-MM interfaces of given instance of kernel kind and mode.
  proc get_aximm_interfaces {kind inst {mode "Master"}} {
    set name [format "target_ip_%02d_%03d" $kind $inst]
    puts "Retrieving list of slave interfaces for $name ..."
    return [tapasco::get_aximm_interfaces [get_bd_cell -hier -filter "NAME == $name"] $mode]
  }






  # Instantiates the host interconnect hierarchy.
  proc arch_create_arke_noc_arch_interface {composition {no_slaves 1}} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z

    variable DIM_X_W 
    variable DIM_Y_W 
    variable DIM_Z_W
    variable DATA_WIDTH


    set out_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 "S_ARCH"]
    
    ##TODO: pass parameters
    set ai [tapasco::ip::create_noc_arke_arch_ifc [format "arke_noc_arch_ifc"]]
    connect_bd_intf_net $out_port [get_bd_intf_pins -of_objects $ai -filter {NAME == "AXI"}]

    set x 0
    set y 0
    set z 0
    set xyz ""
    append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
    append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
    if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}
    set xyz 0b[format {%0*s} $DATA_WIDTH $xyz]
    set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz]

    connect_bd_net [get_bd_pins -filter {NAME == "dataIn"} -of_objects $ai] \
                   [get_bd_pins -filter {NAME == "data_out_local"} -of_objects $r]
    connect_bd_net [get_bd_pins -filter {NAME == "controlIn"} -of_objects $ai] \
                   [get_bd_pins -filter {NAME == "control_out_local"} -of_objects $r]
    connect_bd_net [get_bd_pins -filter {NAME == "dataOut"} -of_objects $ai] \
                   [get_bd_pins -filter {NAME == "data_in_local"} -of_objects $r]
    connect_bd_net [get_bd_pins -filter {NAME == "controlOut"} -of_objects $ai] \
                   [get_bd_pins -filter {NAME == "control_in_local"} -of_objects $r]

    set airlist [list [list $x $y $z]]
    
    return $airlist
  }

  proc findmax { items } {
    set max 0
    foreach i $items { 
      foreach j $i {
        if { $j > $max } {
          set max $j
        }
      }
    }
    return $max
  }

  # Instantiates the pe interconnect hierarchy.
  proc arch_create_arke_noc_pe_interfaces {composition insts routerlist} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z

    variable DIM_X_W 
    variable DIM_Y_W 
    variable DIM_Z_W
    variable DATA_WIDTH

    variable A4L_ADDR_W
    variable A4L_DATA_W
    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_ID_W
    
    set no_pes [llength $insts]
    set no_kinds [llength [dict keys $composition]]
    set perlist [list]

    ## get all address widths

    foreach pe $insts {
      set intpe $pe
      if {[get_bd_cells -filter {Name=~"internal*"} -of_objects $pe] != ""} {
        ## internal
        set intpe [get_bd_cells -filter {Name=~"internal*"} -of_objects $pe]
      }
      lappend a4l_addr_ws [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $intpe]]
      lappend a4l_data_ws [get_property CONFIG.DATA_WIDTH [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $intpe]]
      lappend a4f_addr_ws [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $intpe]]
      lappend a4f_data_ws [get_property CONFIG.DATA_WIDTH [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $intpe]]
      lappend a4f_id_ws [get_property CONFIG.ID_WIDTH [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $intpe]]
    }

    set A4L_ADDR_W [findmax $a4l_addr_ws]
    set A4L_DATA_W [findmax $a4l_data_ws]
    set A4F_ADDR_W [findmax $a4f_addr_ws]
    set A4F_DATA_W [findmax $a4f_data_ws]
    set A4F_ID_W [findmax $a4f_id_ws]
    set A4F_STRB_W [expr $A4F_DATA_W / 8]
          
    ## create pe ifcs, interconnects and router
    puts "Creating $no_pes PE Interfaces and Routers."
    set ik 0
    set ii 0
    set done 0
    set start 0
    for {set z 0} {$z < $DIM_Z} {incr z} {
      for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {

          save_bd_design

          if {[lindex $routerlist end 0] == $x && [lindex $routerlist end 1] == $y && [lindex $routerlist end 2] == $z} {
            set start 1
            continue
          }
          if {!$start} {continue} {
            set no_inst [dict get $composition $ik count]
            set pe [lindex $insts $ii]

            set xyz ""
            append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
            append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
            if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}

            ## create pe ifc
            set pi [tapasco::ip::create_noc_arke_pe_ifc [format "arke_noc_pe_ifc_%02d_%03d" $ik $ii] $A4L_ADDR_W $A4L_DATA_W $A4F_ADDR_W $A4F_DATA_W $A4F_ID_W $A4F_STRB_W $xyz]

            ## create and configure pe slaves interconnect
            set pepins [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $pe]
            set name [format "interconnect_%02d_%03d_slaves" $ik $ii]
            set ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $name]
            set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI [llength $pepins]] $ic
            # connect pe to ic
            set icpins [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $ic]
            set i 0
            foreach icpin $icpins {
              connect_bd_intf_net $icpin [lindex $pepins $i]
              incr i
            }
            # connect ic to pe ifc
            connect_bd_intf_net [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $ic] \
                                [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $pi]


            ## create and configure pe masters interconnect
            set pepins [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $pe]
            set name [format "interconnect_%02d_%03d_master" $ik $ii]
            set ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $name]
            set_property -dict [list CONFIG.NUM_SI [llength $pepins] CONFIG.NUM_MI {1}] $ic
            # connect pe to ic
            set icpins [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $ic]
            set i 0
            foreach icpin $icpins {
              connect_bd_intf_net $icpin [lindex $pepins $i]
              incr i
            }
            # connect ic to pe ifc
            connect_bd_intf_net [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $ic] \
                                [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $pi]
            

            ## connect pe ifc to router
            set xyz 0b[format {%0*s} $DATA_WIDTH $xyz]
            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz]
            lappend perlist [list $x $y $z]

            connect_bd_net [get_bd_pins -filter {NAME == "dataIn"} -of_objects $pi] \
                           [get_bd_pins -filter {NAME == "data_out_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "controlIn"} -of_objects $pi] \
                           [get_bd_pins -filter {NAME == "control_out_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "dataOut"} -of_objects $pi] \
                           [get_bd_pins -filter {NAME == "data_in_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "controlOut"} -of_objects $pi] \
                           [get_bd_pins -filter {NAME == "control_in_local"} -of_objects $r]


            incr ii
            if {$ii == $no_inst} {
              incr ik
              if {$ik == $no_kinds} {
                set done 1
                break
              }
              set ii 0
            }
          }
        }
        if {$done} {break}
      }
      if {$done} {break}
    }
    return $perlist
  }
  

  # Instantiates the memory interconnect hierarchy.
  proc arch_create_arke_noc_mem_interfaces {composition outs routerlist} {
    variable arch_mem_ports
    
    variable DIM_X
    variable DIM_Y
    variable DIM_Z

    variable DIM_X_W 
    variable DIM_Y_W 
    variable DIM_Z_W
    variable DATA_WIDTH
    
    set no_kinds [llength [dict keys $composition]]
    set ic_m 0
    set m_total 0
    set mirlist [list]

    # determine number of masters from composition
    for {set i 0} {$i < $no_kinds} {incr i} {
      set no_inst [dict get $composition $i count]
      set example [get_bd_cells [format "target_ip_%02d_000" $i]]
      set masters [tapasco::get_aximm_interfaces $example]
      set ic_m [expr "$ic_m + [llength $masters] * $no_inst"]

      set m_total [expr "$m_total + [llength $masters] * $no_inst"]
    }
    puts "  Found a total of $m_total masters in composition."
    set no_masters $m_total
    puts "  no_masters : $no_masters"

    # compare composition masters with memory interfaces
    set no_mis [expr {[llength $outs] <= $no_masters ? [llength $outs] : $no_masters}]
    
    puts "Creating $no_mis Mem Interfaces and Routers."
    # create ports and interconnect trees together with arke_noc_mem_ifcs and their routers
    set ic_ports [list]
    set mdist [list]
    set mis [list]
    set mii 0
    set done 0
    set start 0
    for {set z 0} {$z < $DIM_Z} {incr z} {
      for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {
          puts "PE ROUTERLIST:"
          puts [lindex $routerlist end]
          if {[lindex $routerlist end 0] == $x && [lindex $routerlist end 1] == $y && [lindex $routerlist end 2] == $z} {
            set start 1
            continue
          }
          if {!$start} {continue} {
            lappend ic_ports [create_bd_intf_pin -mode Master -vlnv "xilinx.com:interface:aximm_rtl:1.0" [format "M_MEM_%d" $mii]]
            lappend mdist 1 ;# MemIfc count for every ic_port is initialized to 1

            
            set xyz ""
            append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
            append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
            if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}

            set mi [tapasco::ip::create_noc_arke_mem_ifc [format "arke_noc_mem_ifc_%d" $mii] $xyz]
            lappend mis $mi
            puts $mi
            
            set xyz 0b[format {%0*s} $DATA_WIDTH $xyz]
            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz]
            lappend mirlist [list $x $y $z]

            connect_bd_net [get_bd_pins -filter {NAME == "dataIn"} -of_objects $mi] \
                           [get_bd_pins -filter {NAME == "data_out_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "controlIn"} -of_objects $mi] \
                           [get_bd_pins -filter {NAME == "control_out_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "dataOut"} -of_objects $mi] \
                           [get_bd_pins -filter {NAME == "data_in_local"} -of_objects $r]
            connect_bd_net [get_bd_pins -filter {NAME == "controlOut"} -of_objects $mi] \
                           [get_bd_pins -filter {NAME == "control_in_local"} -of_objects $r]

            incr mii
            if {$mii == [llength $outs] || $mii == $no_masters} {
              set done 1
              break
            }
          }
        }
        if {$done} {break}
      }
      if {$done} {break}
    }

    # generate output trees (generate out blocks with a single ic)
    for {set i 0} {$i < [llength $mdist]} {incr i} {
      puts "  mdist[$i] = [lindex $mdist $i]"
      set out [tapasco::create_interconnect_tree "out_$i" [lindex $mdist $i]]
      connect_bd_intf_net [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $out] [lindex $ic_ports $i]
      connect_bd_intf_net [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $out] [get_bd_intf_pins -of_objects [lindex $mis $i] -filter {NAME == "AXI"}]
    }

    set arch_mem_ports $ic_ports
    
    return $mirlist
  }

  proc arch_connect_routers {routerlist} {

    variable DIM_X
    variable DIM_Y
    variable DIM_Z

    variable DIM_X_W 
    variable DIM_Y_W 
    variable DIM_Z_W
    variable DATA_WIDTH

    set rlist routerlist

    # create adjunct routers for proper routing
    set done 0
    set start 0

    for {set z 0} {$z < $DIM_Z} {incr z} {
      for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {
          if {[lindex $routerlist end 0] == $x && [lindex $routerlist end 1] == $y && [lindex $routerlist end 2] == $z} {
            set start 1
            continue
          }
          if {!$start} {continue} {
            set done 1

            set xyz ""
            append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
            append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
            if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}


            puts "Creating adjunct Router $x $y $z."
            set xyz 0b[format {%0*s} $DATA_WIDTH $xyz]
            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz]
            lappend rlist [list $x $y $z]

            puts "  removing local ports"
            set_property -dict [list CONFIG.use_data_in_local {false} CONFIG.use_control_in_local {false} CONFIG.use_data_out_local {false} CONFIG.use_control_out_local {false}] [get_bd_cells $r]
          }
        }
      }
      if {$done} {break}
    }

    # configure and connect all routers
    set done 0
    for {set z 0} {$z < $DIM_Z} {incr z} {
      for {set y 0} {$y < $DIM_Y} {incr y} {
        for {set x 0} {$x < $DIM_X} {incr x} {
          
          puts "Connecting and configuring Router $x $y $z."

          set r /arch/arke_noc_router_$x\_$y\_$z
          set rxp1 /arch/arke_noc_router_[expr $x+1]\_$y\_$z
          set ryp1 /arch/arke_noc_router_$x\_[expr $y+1]\_$z
          set rzp1 /arch/arke_noc_router_$x\_$y\_[expr $z+1]
          set rxm1 /arch/arke_noc_router_[expr $x-1]\_$y\_$z
          set rym1 /arch/arke_noc_router_$x\_[expr $y-1]\_$z
          set rzm1 /arch/arke_noc_router_$x\_$y\_[expr $z-1]

          # configure and connect east
          if {[get_bd_cells $rxp1] == ""} {
            puts "  removing east ports"
            set_property -dict [list CONFIG.use_data_in_east {false} CONFIG.use_control_in_east {false} CONFIG.use_data_out_east {false} CONFIG.use_control_out_east {false}] [get_bd_cells $r]
          } {
            puts "  connecting east to west ([expr $x+1] $y $z)"
            connect_bd_net [get_bd_pins $r/data_out_east]    [get_bd_pins $rxp1/data_in_west]
            connect_bd_net [get_bd_pins $r/control_out_east] [get_bd_pins $rxp1/control_in_west]
            connect_bd_net [get_bd_pins $r/data_in_east]     [get_bd_pins $rxp1/data_out_west]
            connect_bd_net [get_bd_pins $r/control_in_east]  [get_bd_pins $rxp1/control_out_west]
          }

          # configure and connect north
          if {[get_bd_cells $ryp1] == ""} {
            puts "  removing north ports"
            set_property -dict [list CONFIG.use_data_in_north {false} CONFIG.use_control_in_north {false} CONFIG.use_data_out_north {false} CONFIG.use_control_out_north {false}] [get_bd_cells $r]
          } {
            puts "  connecting north to south ($x [expr $y+1] $z)"
            connect_bd_net [get_bd_pins $r/data_out_north]    [get_bd_pins $ryp1/data_in_south]
            connect_bd_net [get_bd_pins $r/control_out_north] [get_bd_pins $ryp1/control_in_south]
            connect_bd_net [get_bd_pins $r/data_in_north]     [get_bd_pins $ryp1/data_out_south]
            connect_bd_net [get_bd_pins $r/control_in_north]  [get_bd_pins $ryp1/control_out_south]
          }

          # configure and connect up
          if {[get_bd_cells $rzp1] == ""} {
            puts "  removing up ports"
            set_property -dict [list CONFIG.use_data_in_up {false} CONFIG.use_control_in_up {false} CONFIG.use_data_out_up {false} CONFIG.use_control_out_up {false}] [get_bd_cells $r]
          } {
            puts "  connecting up to down ($x $y [expr $z+1])"
            connect_bd_net [get_bd_pins $r/data_out_up]    [get_bd_pins $rzp1/data_in_down]
            connect_bd_net [get_bd_pins $r/control_out_up] [get_bd_pins $rzp1/control_in_down]
            connect_bd_net [get_bd_pins $r/data_in_up]     [get_bd_pins $rzp1/data_out_down]
            connect_bd_net [get_bd_pins $r/control_in_up]  [get_bd_pins $rzp1/control_out_down]
          }

          # configure west
          if {[get_bd_cells $rxm1] == ""} {
            puts "  removing west ports"
            set_property -dict [list CONFIG.use_data_in_west {false} CONFIG.use_control_in_west {false} CONFIG.use_data_out_west {false} CONFIG.use_control_out_west {false}] [get_bd_cells $r]
          }

          # configure south
          if {[get_bd_cells $rym1] == ""} {
            puts "  removing south ports"
            set_property -dict [list CONFIG.use_data_in_south {false} CONFIG.use_control_in_south {false} CONFIG.use_data_out_south {false} CONFIG.use_control_out_south {false}] [get_bd_cells $r]
          }

          # configure down
          if {[get_bd_cells $rzm1] == ""} {
            puts "  removing down ports"
            set_property -dict [list CONFIG.use_data_in_down {false} CONFIG.use_control_in_down {false} CONFIG.use_data_out_down {false} CONFIG.use_control_out_down {false}] [get_bd_cells $r]
          }
          
          # break after last router
          if {[lindex $rlist end 0] == $x && [lindex $rlist end 1] == $y && [lindex $rlist end 2] == $z} {
            set done 1
            break
          }
        }
        if {$done} {break}
      }
      if {$done} {break}
    }
  }



  proc hex2bin {hex} {
    binary scan [binary format H* $hex] B* bin
    return $bin
  }

  proc arch_set_noc_parameters {perlist} {
    
    variable A4L_ADDR_W
    variable A4L_DATA_W
    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_ID_W
    
    
    set ais [get_bd_cells -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_arch_ifc:1.0"}]
    set pis [get_bd_cells -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_pe_ifc:1.0"}]
    set mis [get_bd_cells -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_mem_ifc:1.0"}]
    set pes [get_processing_elements]
    set pe_map [get_address_map [::platform::get_pe_base_address]]
    set rveclength 500

    # Setup ArchIfc
    dict for {pe data} $pe_map {
      lappend interfaces_t [get_bd_cells -of_objects [get_bd_intf_pins [dict get $data "interface"]]]
      lappend offsets_t [dict get $data "offset"]
      lappend ranges_t [dict get $data "range"]
    }
    set range_no [llength $ranges_t]

    set targetlist ""
    set rangelist ""
    set ri 0
    for {set i 0} {$i < $range_no} {incr i} {
      # append interfaces corresponding range to rangelist
      if {$i == $range_no - 1} {
        set range_t [lindex $ranges_t $i]
      } {
        set range_t [expr {[lindex $offsets_t [expr $i + 1]] - [lindex $offsets_t $i]}]
      }
      #rshift 12, convert to bin, count 0s, convert to bin, fill with 0s to a length of 5
      set range_t [format {%0*s} 5 [dec2bin [splitline [dec2bin [expr {$range_t >> 12}]] 0]]]
      append rangelist $range_t


      # append interfaces corresponding pe address to targetlist
      set x [lindex $perlist $ri 0] 
      set y [lindex $perlist $ri 1]
      set z [lindex $perlist $ri 2]

      set xyz ""
      append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
      append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
      if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}

      append targetlist $xyz

      if {[lindex $interfaces_t $i] != [lindex $interfaces_t [expr $i + 1]]} {
        incr ri
      }
    }

    set base_address [::platform::get_pe_base_address]
    set rangelist 0b[format %-0*s $rveclength $rangelist]
    set targetlist 0b[format %-0*s $rveclength $targetlist]

    foreach ai $ais {
      set_property -dict [list CONFIG.A4L_addr_width $A4L_ADDR_W \
                               CONFIG.A4L_addr_width $A4L_DATA_W \
                               CONFIG.AXI_base_addr $base_address \
                               CONFIG.AXI_ranges $rangelist \
                               CONFIG.AXI_ranges_cnt $range_no \
                               CONFIG.NoC_targets] $ai
    }

    # Setup PEIfc
    set i 0
    foreach pi $pis {
      set mi [lindex $mis $i]
      set mia [get_property CONFIG.NoC_address $mi]

      set_property -dict [list CONFIG.NoC_address_mem $mia] $pi
      incr i
      if {$i == [llength $mis]} {
        set i 0
      }
    }

    # Setup MemIfc
    foreach mi $mis {
      set_property -dict [list CONFIG.A4F_addr_width $A4F_ADDR_W \
                               CONFIG.A4F_data_width $A4F_DATA_W \
                               CONFIG.A4F_id_width $A4F_ID_W \
                               CONFIG.A4F_strb_width [expr {$A4F_DATA_W / 8}]] $mi
    }
  }










  # Instantiates the memory interconnect hierarchy.
  proc arch_create_mem_interconnects {composition outs} {
    variable arch_mem_ports
    set no_kinds [llength [dict keys $composition]]
    set ic_m 0
    set m_total 0

    # determine number of masters from composition
    for {set i 0} {$i < $no_kinds} {incr i} {
      set no_inst [dict get $composition $i count]
      set example [get_bd_cells [format "target_ip_%02d_000" $i]]
      set masters [tapasco::get_aximm_interfaces $example]
      set ic_m [expr "$ic_m + [llength $masters] * $no_inst"]

      set m_total [expr "$m_total + [llength $masters] * $no_inst"]
    }

    puts "  Found a total of $m_total masters."
    set no_masters $m_total
    puts "  no_masters : $no_masters"

    # check if all masters can be connected with the outs config
    set total_ports [expr [join $outs +]]
    if {$total_ports < $no_masters} {
      error "  ERROR: can only connect up to $total_ports masters"
    } {
      puts "  total available ports: $total_ports"
    }

    # create ports and interconnect trees
    set ic_ports [list]
    set mdist [list]
    for {set i 0} {$i < [llength $outs] && $i < $no_masters} {incr i} {
      lappend ic_ports [create_bd_intf_pin -mode Master -vlnv "xilinx.com:interface:aximm_rtl:1.0" [format "M_MEM_%d" $i]]
      lappend mdist 0
    }

    # distribute masters round-robin on all output ports: mdist holds
    # number of masters for each port
    set j 0
    for {set i 0} {$i < $no_masters} {incr i} {
      lset mdist $j [expr "[lindex $mdist $j] + 1"]
      incr j
      if {$j >= [llength $mdist]} { set j 0 }
      if {$i + 1 < $no_masters} {
        # find new port with capacity
        while {[lindex $mdist $j] == [lindex $outs $j]} {
          incr j
          if {$j >= [llength $mdist]} { set j 0 }
        }
      }
    }

    # generate output trees
    for {set i 0} {$i < [llength $mdist]} {incr i} {
      puts "  mdist[$i] = [lindex $mdist $i]"
      set out [tapasco::create_interconnect_tree "out_$i" [lindex $mdist $i]]
      connect_bd_intf_net [get_bd_intf_pins -filter {MODE == Master && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $out] [lindex $ic_ports $i]
    }

    set arch_mem_ports $ic_ports
  }

  # Instantiates the host interconnect hierarchy.
  proc arch_create_host_interconnects {composition {no_slaves 1}} {
    set no_kinds [llength [dict keys $composition]]
    set ic_s 0

    # compute number of pe slaves
    for {set i 0} {$i < $no_kinds} {incr i} {
      set no_inst [dict get $composition $i count]
      set example [get_bd_cells [format "target_ip_%02d_000" $i]]
      set slaves  [get_bd_intf_pins -of $example -filter { MODE == "Slave" && VLNV == "xilinx.com:interface:aximm_rtl:1.0" }]
      set ic_s [expr "$ic_s + [llength $slaves] * $no_inst"]
    }

    set out_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 "S_ARCH"]

    if {$ic_s == 1} {
      puts "Connecting one slave to host"
      return $out_port
    } {
      set in1 [tapasco::create_interconnect_tree "in1" $ic_s false]

      puts "Creating interconnects toward peripherals ..."
      puts "  $ic_s slaves to connect to host"

      connect_bd_intf_net $out_port [get_bd_intf_pins -of_objects $in1 -filter {NAME == "S000_AXI"}]
    }

    return $in1
  }

  # Connects the host interconnects to the threadpool.
  proc arch_connect_host {periph_ics ips} {
    puts "Connecting PS to peripherals ..."
    puts "  periph_ics = $periph_ics"
    puts "  ips = $ips"

    set pic 0
    set ic [lindex $periph_ics $pic]
    set conn 0

    set ms [get_bd_intf_pins -of_objects $periph_ics -filter {MODE == "Master" && VLNV == "xilinx.com:interface:aximm_rtl:1.0"}]
    if {[llength $ms] == 0 && [get_property CLASS $periph_ics] == "bd_intf_pin"} {
      set ms $periph_ics
    }
    set ss [get_bd_intf_pins -of_objects $ips -filter {MODE == "Slave" && VLNV == "xilinx.com:interface:aximm_rtl:1.0"}]

    puts "  ms = $ms"
    puts "  ss = $ss"

    if {[llength $ms] != [llength $ss]} {
      error "master slave count mismatch ([llength $ms]/[llength $ss])"
    }

    for {set i 0} {$i < [llength $ms]} {incr i} {
      connect_bd_intf_net [lindex $ms $i] [lindex $ss $i]
    }
    return

    foreach ip $ips {
      # connect target IP slaves
      set slaves [get_bd_intf_pins -of $ip -filter { MODE == "Slave" && VLNV == "xilinx.com:interface:aximm_rtl:1.0"}]
      foreach slave $slaves {
        set m_name [format "axi_periph_ic_$pic/M%02d_AXI" $conn]
        connect_bd_intf_net [get_bd_intf_pins $m_name] -boundary_type upper $slave
        incr conn
      }
      if {$conn == 16} { incr pic; set ic [lindex $periph_ics $pic]; set conn 0 }
    }
  }

  # Connects the threadpool to memory interconnects.
  proc arch_connect_mem {mem_ics ips} {
    # get PE masters
    set masters [lsort -dictionary [tapasco::get_aximm_interfaces $ips]]
    # interleave slaves of out ic trees
    set outs [get_bd_cells -filter {NAME =~ "out_*"}]
    set sc [llength [tapasco::get_aximm_interfaces $outs "Slave"]]
    set tmp [list]
    foreach out $outs { lappend tmp [tapasco::get_aximm_interfaces $out "Slave"] }
    set outs $tmp
    set slaves [list]
    set j 0
    for {set i 0} {$i < $sc} {incr i} {
      # skip outs without slaves
      while {[llength [lindex $outs $j]] == 0} {
        incr j
        set j [expr "$j % [llength $outs]"]
      }
      # remove slave from current out
      set slave [lindex [lindex $outs $j] end]
      set outs [lreplace $outs $j $j [lreplace [lindex $outs $j] end end]]
      lappend slaves $slave
      # next out
      incr j
      set j [expr "$j % [llength $outs]"]
    }

    puts "Connecting memory interconnect topology ... "
    puts "  Number of masters: [llength $masters]"
    puts "  Masters in order : $masters"
    puts "  Number of slaves: [llength $slaves]"
    puts "  Slaves in order : $slaves"

    if {[llength $masters] != [llength $slaves]} {
      error "  ERROR: Mismatch between #slaves and #masters - probably a BUG"
    }

    # simply connect masters to output slaves
    for {set i 0} {$i < [llength $masters]} {incr i} {
      connect_bd_intf_net [lindex $masters $i] [lindex $slaves $i]
    }
  }

  # Connects the architecture interrupt lines.
  proc arch_connect_interrupts {ips} {
    variable arch_irq_concats
    puts "Connecting [llength $ips] target IP interrupts ..."

    set i 0
    set j 0
    set num_slaves [llength [tapasco::get_aximm_interfaces $ips "Slave"]]
    set left $num_slaves
    puts "  total number of slave interfaces: $num_slaves"
    set cc [tapasco::ip::create_xlconcat "xlconcat_$j" [expr "$num_slaves > 32 ? 32 : $num_slaves"]]
    lappend arch_irq_concats $cc
    set zero [tapasco::ip::create_constant "zero" 1 0]
    # Only one Interrupt per IP is connected
    foreach ip [lsort $ips] {
      set selected 0
      foreach pin [get_bd_pins -of $ip -filter { TYPE == intr }] {
        if { $selected == 0 } {
          set selected 1
          connect_bd_net $pin [get_bd_pins -of $cc -filter "NAME == In$i"]
        } else {
          puts "Skipping pin $pin because ip $ip is already connected to the interrupt controller."
        }
      }

      if { $selected == 0 } {
        puts "IP $ip does not seem to have any interrupts. Skipping."
      }

      incr i
      incr left -1
      if {$i > 31} {
        set i 0
        incr j
        if { $left > 0 } {
          set cc [tapasco::ip::create_xlconcat "xlconcat_$j" [expr "$left > 32 ? 32 : $left"]]
          lappend arch_irq_concats $cc
        }
      }

      set num_slaves [llength [tapasco::get_aximm_interfaces $ip "Slave"]]
      puts "    number of slave interfaces on $ip: $num_slaves"
      for {set tieoff 1} {$tieoff < $num_slaves} {incr tieoff} {
        connect_bd_net [get_bd_pins -of $zero] [get_bd_pins -of $cc -filter "NAME == In$i"]
        incr i
        incr left -1
        if {$i > 31} {
          set i 0
          incr j
          if { $left > 0 } {
            set cc [tapasco::ip::create_xlconcat "xlconcat_$j" [expr "$left > 32 ? 32 : $left"]]
            lappend arch_irq_concats $cc
          }
        }
      }
    }
    set i 0
    foreach irq_concat $arch_irq_concats {
      # create hierarchical port with correct width
      set port [get_bd_pins -of_objects $irq_concat -filter {DIR == "O"}]
      set out_port [create_bd_pin -type INTR -dir O -from [get_property LEFT $port] -to [get_property RIGHT $port] "intr_$i"]
      connect_bd_net $port $out_port
      incr i
    }
  }

  # Connect internal clock lines.
  proc arch_connect_clocks {} {
    connect_bd_net [tapasco::subsystem::get_port "design" "clk"] \
      [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == clk && DIR == I"]
  }

  # Connect internal reset lines.
  proc arch_connect_resets {} {
    connect_bd_net -quiet [tapasco::subsystem::get_port "design" "rst" "interconnect"] \
      [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && NAME =~ *interconnect_aresetn && DIR == I"]
    connect_bd_net [tapasco::subsystem::get_port "design" "rst" "peripheral" "resetn"] \
      [get_bd_pins -of_objects [get_bd_cells -of_objects [current_bd_instance .]] -filter "TYPE == rst && NAME =~ *peripheral_aresetn && DIR == I"] \
      [get_bd_pins -filter { TYPE == rst && DIR == I && CONFIG.POLARITY != ACTIVE_HIGH } -of_objects [get_bd_cells -filter {NAME =~ "target_ip*"}]]
    connect_bd_net [tapasco::subsystem::get_port "design" "rst" "peripheral" "reset"] \
      [get_bd_pins -of_objects [get_bd_cells -of_objects [current_bd_instance .]] -filter "TYPE == rst && NAME =~ rst && DIR == I"]
    set active_high_resets [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && DIR == I && CONFIG.POLARITY == ACTIVE_HIGH"]
    if {[llength $active_high_resets] > 0} {
      connect_bd_net [tapasco::subsystem::get_port "design" "rst" "peripheral" "reset"] $active_high_resets
    }
  }

  # Instantiates the architecture.
  proc create {{mgroups 0}} {
    variable arch_mem_ics
    variable arch_host_ics



    if {$mgroups == 0} {
      set mgroups [platform::max_masters]
    }

    # create hierarchical group
    set group [tapasco::subsystem::create "arch"]
    set instance [current_bd_instance .]
    current_bd_instance $group

    # create instances of target IP
    set kernels [tapasco::get_composition]
    set insts [arch_create_instances $kernels]

    set no_inst 0
    for {set i 0} {$i < [llength [dict keys $kernels]]} {incr i} { set no_inst [expr "$no_inst + [dict get $kernels $i count]"] }
    arch_connect_interrupts $insts

    arch_check_instance_count $kernels

    tapasco::ip::build_arke_noc_ips

    set arch_host_routers [arch_create_arke_noc_arch_interface $kernels 1]
    set arch_pe_routers [arch_create_arke_noc_pe_interfaces $kernels $insts $arch_host_routers]
    set arch_mem_routers [arch_create_arke_noc_mem_interfaces $kernels $mgroups $arch_pe_routers]

    arch_connect_routers $arch_mem_routers

    arch_set_noc_parameters $arch_pe_routers
    arch_connect_clocks
    arch_connect_resets

    # exit the hierarchical group
    current_bd_instance $instance
  }
}
