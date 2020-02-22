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
# @file    axi4mm-arkenoc.tcl
# @brief  Arke NoC w/ AXI4 memory mapped master/slave interface based Architectures.
# @author  J. Korinth, TU Darmstadt (jk@esa.tu-darmstadt.de)
# @author  M. Nilges, TU Darmstadt
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

  variable ADDR_PARAM_WIDTH 12

  variable DIM_X
  variable DIM_Y
  variable DIM_Z
  variable PORTS
  variable BUFFER_DEPTH
  variable DATA_WIDTH
  variable CONTROL_WIDTH

  variable DIM_X_W
  variable DIM_Y_W
  variable DIM_Z_W
  variable ADDRESS_WIDTH

  variable A4L_ADDR_W 32
  variable A4L_DATA_W 32
  variable A4L_STRB_W 4
  variable A4F_ADDR_W 32
  variable A4F_DATA_W 32
  variable A4F_STRB_W 4
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

  # scan plugin directory
  foreach f [glob -nocomplain -directory "$::env(TAPASCO_HOME_TCL)/arch/axi4mm-arkenoc/plugins" "*.tcl"] {
    source -notrace $f
  }

  # Return arch name
  proc get_arch_name {} {
    return "axi4mm-arkenoc"
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


  proc get_master_interface_count {composition outs} {
    set no_kinds [llength [dict keys $composition]]
    set ic_m 0
    set m_total 0
    set mirlist [list]

    # determine number of masters from composition
    for {set i 0} {$i < $no_kinds} {incr i} {
      set no_inst [dict get $composition $i count]
      set example [get_bd_cells [format "target_ip_%02d_000" $i]]
      set masters [tapasco::get_aximm_interfaces $example]
      puts $masters
      set masters [expr [llength $masters] >= 1 ? 1 : 0]
      set ic_m [expr "$ic_m + [llength $masters] * $no_inst"]

      set m_total [expr "$m_total + [llength $masters] * $no_inst"]
    }
    puts "  Found a total of $m_total PEs with one or more masters in composition."
    set no_masters $m_total
    puts "  no_masters : $no_masters"

    # compare composition masters with memory interfaces
    set no_mis [expr {[llength $outs] <= $no_masters ? [llength $outs] : $no_masters}]

    return $no_mis
  }

  # Write AXI parameters for NoC components based on given kernels
  proc write_axi_parameters {insts} {
    variable A4L_ADDR_W
    variable A4L_DATA_W
    variable A4L_STRB_W
    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_STRB_W
    variable A4F_ID_W

    lappend a4l_addr_ws $A4L_ADDR_W
    lappend a4l_data_ws $A4L_DATA_W
    lappend a4f_addr_ws $A4F_ADDR_W
    lappend a4f_data_ws $A4F_DATA_W

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
    set A4L_STRB_W [expr $A4L_DATA_W / 8]
    set A4F_ADDR_W [findmax $a4f_addr_ws]
    set A4F_DATA_W [findmax $a4f_data_ws]
    set A4F_STRB_W [expr $A4F_DATA_W / 8]
    set A4F_ID_W [findmax $a4f_id_ws]
  }

  # Write NoC parameters based on users configuration or default values
  proc write_noc_parameters {no_pes no_mis} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z
    variable PORTS
    variable BUFFER_DEPTH
    variable DATA_WIDTH
    variable CONTROL_WIDTH

    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W
    variable ADDRESS_WIDTH

    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_STRB_W
    variable A4F_ID_W

    # determine default dimensions
    set no_routers [expr 1 + $no_pes + $no_mis]
    set x_def 2
    set y_def 2
    set s 0
    while {[expr $x_def * $y_def] < $no_routers} {
      if {$s} {
        incr x_def
        set s 0
      } {
        incr y_def
        set s 1
      }
    }
    set PORTS 5
    set x_def_w [expr {int(ceil(log($x_def)/log(2.0)))}]
    set y_def_w [expr {int(ceil(log($y_def)/log(2.0)))}]
    set addr_w_def [expr {$x_def_w + $y_def_w}]
    puts "Default Network Configuration:"
    puts "  Dimensions: X=$x_def, Y=$y_def, Z=1"
    puts "  Address Width: $addr_w_def"

    # determine default data width
    set default_dw [expr 3 + $addr_w_def] ;# data_width reserved for protocol and channel spec and addressing bits
    lappend dws [expr $A4F_ADDR_W + $A4F_ID_W + $addr_w_def + 25]
    lappend dws [expr $A4F_DATA_W + $A4F_STRB_W + 1]
    lappend dws [expr $A4F_DATA_W + $A4F_ID_W + $addr_w_def + 1]
    incr default_dw [findmax $dws]
    puts "  Data Width: $default_dw"
    puts "  Control Width: 3"
    puts "  Buffer Depth: 4"

    # set dimensions
    set DIM_X [tapasco::get_feature_option "arke_cfg" "x" $x_def]
    set DIM_Y [tapasco::get_feature_option "arke_cfg" "y" $y_def]
    set DIM_Z [tapasco::get_feature_option "arke_cfg" "z" 1]
    if {$DIM_Z > 1} {
      set PORTS 7
    }
    set DIM_X_W [expr {int(ceil(log($DIM_X)/log(2.0)))}]
    set DIM_Y_W [expr {int(ceil(log($DIM_Y)/log(2.0)))}]
    set DIM_Z_W [expr {int(ceil(log($DIM_Z)/log(2.0)))}]
    set ADDRESS_WIDTH [expr {$DIM_X_W + $DIM_Y_W + $DIM_Z_W}]
    puts "Actual Network Configuration:"
    puts "  Dimensions: X=$DIM_X, Y=$DIM_Y, Z=$DIM_Z"
    puts "  Address Width: $ADDRESS_WIDTH"

    # set widths
    set BUFFER_DEPTH [tapasco::get_feature_option "arke_cfg" "buffer_depth" 4]
    set DATA_WIDTH [tapasco::get_feature_option "arke_cfg" "data_width" $default_dw]
    set CONTROL_WIDTH 3
    puts "  Data Width: $DATA_WIDTH"
    puts "  Control Width: $CONTROL_WIDTH"
    puts "  Buffer Depth: $BUFFER_DEPTH"

    # feasibility checks
    if {$DATA_WIDTH < $default_dw} {
      puts "ERROR: Configured Data Width is smaller than the minimum required. Minimum: $default_dw, Configured: $DATA_WIDTH."
      puts "Resolve by adjusting the Data Width in order to fit the largest AXI packages plus the width of the internal signals (dependant on the Address Width)."
      exit 1
    }

    if {[expr $DIM_X * $DIM_Y * $DIM_Z] < $no_routers} {
      puts "ERROR: Configured Data Width is smaller than the minimum required. Minimum: $no_routers, Configured: [expr $DIM_X * $DIM_Y * $DIM_Z]."
      puts "Resolve by adjusting the Dimensions of the network (don't forget to include additional margin for arch (1) and memory ($no_mis) interfaces)."
      exit 1
    }
  }

  # Instantiates the Arch Interface along with its router
  proc arch_create_arke_noc_arch_interface {composition {no_slaves 1}} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z
    variable PORTS
    variable BUFFER_DEPTH
    variable DATA_WIDTH
    variable CONTROL_WIDTH

    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W
    variable ADDRESS_WIDTH

    variable ADDR_PARAM_WIDTH

    variable A4L_ADDR_W
    variable A4L_DATA_W
    variable A4L_STRB_W

    ## create arch ifc and router
    puts "Creating Arch Interface and Router."
    ## create hierarchy interface
    set out_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 "S_ARCH"]

    set x 0
    set y 0
    set z 0
    set xyz ""
    append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
    append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
    if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}
    set xyz 0b[format {%0*s} $ADDR_PARAM_WIDTH $xyz]

    ## create arch ifc
    set ai [tapasco::ip::create_noc_arke_arch_ifc [format "arke_noc_arch_ifc"] $xyz $DIM_X $DIM_Y $DIM_Z $ADDRESS_WIDTH $DATA_WIDTH $CONTROL_WIDTH $A4L_ADDR_W $A4L_DATA_W $A4L_STRB_W]
    connect_bd_intf_net $out_port [get_bd_intf_pins -of_objects $ai -filter {NAME == "AXI"}]

    ## create router
    set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz $DIM_X $DIM_Y $DIM_Z $PORTS $BUFFER_DEPTH $DATA_WIDTH $CONTROL_WIDTH]

    ## connect arch ifc to router
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

  # Instantiates the PE Interfaces along with their routers
  proc arch_create_arke_noc_pe_interfaces {composition insts routerlist} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z
    variable PORTS
    variable BUFFER_DEPTH
    variable DATA_WIDTH
    variable CONTROL_WIDTH

    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W
    variable ADDRESS_WIDTH

    variable ADDR_PARAM_WIDTH

    variable A4L_ADDR_W
    variable A4L_DATA_W
    variable A4L_STRB_W
    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_STRB_W
    variable A4F_ID_W

    set no_pes [llength $insts]
    set no_kinds [llength [dict keys $composition]]
    set perlist [list]

    ## create pe ifcs, interconnects and router
    puts "Creating $no_pes PE Interfaces and Routers."
    set ik 0
    set ii 0
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
            set no_inst [dict get $composition $ik count]
            set pe [lindex $insts $ii]

            set xyz ""
            append xyz [format {%0*s} $DIM_X_W [dec2bin $x]]
            append xyz [format {%0*s} $DIM_Y_W [dec2bin $y]]
            if {$DIM_Z_W != 0} {append xyz [format {%0*s} $DIM_Z_W [dec2bin $z]]}
            set xyz 0b[format {%0*s} $ADDR_PARAM_WIDTH $xyz]

            ## create container
            set c [tapasco::subsystem::create [current_bd_instance .]/[format "container_%02d_%03d" $ik $ii]]
            move_bd_cells $c $pe
            current_bd_instance $c

            ## create pe ifc
            set pi [tapasco::ip::create_noc_arke_pe_ifc [format "arke_noc_pe_ifc_%02d_%03d" $ik $ii] $xyz $DIM_X $DIM_Y $DIM_Z $ADDRESS_WIDTH $DATA_WIDTH $CONTROL_WIDTH $A4L_ADDR_W $A4L_DATA_W $A4L_STRB_W $A4F_ADDR_W $A4F_DATA_W $A4F_ID_W $A4F_STRB_W]

            ## create and configure pe slaves interconnect
            set pepins [get_bd_intf_pins -filter {MODE == Slave && VLNV == "xilinx.com:interface:aximm_rtl:1.0"} -of_objects $pe]
            set name [format "ic_%02d_%03d_slaves" $ik $ii]
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
            set name [format "ic_%02d_%03d_masters" $ik $ii]
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

            ## connect clk and rst to container pins
            arch_connect_clocks
            arch_connect_resets
            current_bd_instance ..

            ## connect pe ifc to router
            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz $DIM_X $DIM_Y $DIM_Z $PORTS $BUFFER_DEPTH $DATA_WIDTH $CONTROL_WIDTH]
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

  # Instantiates the Memory Interfaces along with their routers
  proc arch_create_arke_noc_mem_interfaces {no_mis routerlist} {
    variable arch_mem_ports

    variable DIM_X
    variable DIM_Y
    variable DIM_Z
    variable PORTS
    variable BUFFER_DEPTH
    variable DATA_WIDTH
    variable CONTROL_WIDTH

    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W
    variable ADDRESS_WIDTH

    variable ADDR_PARAM_WIDTH

    variable A4F_ADDR_W
    variable A4F_DATA_W
    variable A4F_STRB_W
    variable A4F_ID_W

    set mirlist [list]

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
            set xyz 0b[format {%0*s} $ADDR_PARAM_WIDTH $xyz]

            set mi [tapasco::ip::create_noc_arke_mem_ifc [format "arke_noc_mem_ifc_%d" $mii] $xyz $DIM_X $DIM_Y $DIM_Z $ADDRESS_WIDTH $DATA_WIDTH $CONTROL_WIDTH $A4F_ADDR_W $A4F_DATA_W $A4F_ID_W $A4F_STRB_W]
            lappend mis $mi
            puts $mi

            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz $DIM_X $DIM_Y $DIM_Z $PORTS $BUFFER_DEPTH $DATA_WIDTH $CONTROL_WIDTH]
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
            if {$mii == $no_mis} {
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

  # Connects the routers of the network and creates adjunct routers if needed.
  proc arch_connect_routers {routerlist} {
    variable DIM_X
    variable DIM_Y
    variable DIM_Z
    variable PORTS
    variable BUFFER_DEPTH
    variable DATA_WIDTH
    variable CONTROL_WIDTH

    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W
    variable ADDR_PARAM_WIDTH

    set rlist routerlist

    ## Create adjunct routers for proper routing.
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
            set xyz 0b[format {%0*s} $ADDR_PARAM_WIDTH $xyz]
            set r [tapasco::ip::create_noc_arke_router "arke_noc_router_$x\_$y\_$z" $xyz $DIM_X $DIM_Y $DIM_Z $PORTS $BUFFER_DEPTH $DATA_WIDTH $CONTROL_WIDTH]
            lappend rlist [list $x $y $z]

            puts "  removing local ports"
            set_property -dict [list CONFIG.use_data_in_local {false} CONFIG.use_control_in_local {false} CONFIG.use_data_out_local {false} CONFIG.use_control_out_local {false}] [get_bd_cells $r]
          }
        }
      }
      if {$done} {break}
    }

    ## Configure and connect all routers.
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

  # Set AXI address map parameters for Arch Ifc and Memory Ifc parameter for PE Ifc.
  proc arch_set_noc_parameters {perlist} {
    variable DIM_X_W
    variable DIM_Y_W
    variable DIM_Z_W

    ## Setup ArchIfc
    set ais [get_bd_cells -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_arch_ifc:1.0"}]
    set pis [get_bd_cells -of_objects [get_bd_cells container*] -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_pe_ifc:1.0"}]
    set mis [get_bd_cells -filter {VLNV == "esa.informatik.tu-darmstadt.de:user:arke_noc_mem_ifc:1.0"}]
    set pes [get_processing_elements]
    set pe_map [get_address_map [::platform::get_pe_base_address]]
    set rveclength 1000

    ## Get AXI offsets and ranges
    dict for {pe data} $pe_map {
      lappend interfaces_t [get_bd_cells -of_objects [get_bd_intf_pins [dict get $data "interface"]]]
      lappend offsets_t [dict get $data "offset"]
      lappend ranges_t [dict get $data "range"]
    }
    set range_no [llength $ranges_t]

    ## Build rangelist and targetlist
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

      # increase router index only if next interface is from a different PE
      if {[lindex $interfaces_t $i] != [lindex $interfaces_t [expr $i + 1]]} {
        incr ri
      }
    }

    set base_address [::platform::get_pe_base_address]
    set rangelist 0b[format %-0*s $rveclength $rangelist]
    set targetlist 0b[format %-0*s $rveclength $targetlist]

    ## Write parameters including rangelist and targetlist
    foreach ai $ais {
      set_property -dict [list CONFIG.AXI_base_addr $base_address \
                               CONFIG.AXI_ranges $rangelist \
                               CONFIG.AXI_ranges_cnt $range_no \
                               CONFIG.NoC_targets $targetlist] $ai
    }

    ## Setup PEIfc
    set i 0
    foreach pi $pis {
      set mia [get_property CONFIG.address [lindex $mis $i]]

      set_property -dict [list CONFIG.address_mem $mia] $pi
      incr i
      if {$i == [llength $mis]} {
        set i 0
      }
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
      [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && NAME =~ *interconnect_aresetn && DIR == I"] \
      [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && NAME =~ ARESETN && DIR == I"]
    connect_bd_net -quiet [tapasco::subsystem::get_port "design" "rst" "peripheral" "resetn"] \
      [get_bd_pins -of_objects [get_bd_cells -of_objects [current_bd_instance .]] -filter "TYPE == rst && NAME =~ *peripheral_aresetn && DIR == I"] \
      [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && NAME =~ *_ARESETN && DIR == I"] \
      [get_bd_pins -filter { TYPE == rst && DIR == I && CONFIG.POLARITY != ACTIVE_HIGH } -of_objects [get_bd_cells -filter {NAME =~ "target_ip*"}]]
    connect_bd_net -quiet [tapasco::subsystem::get_port "design" "rst" "peripheral" "reset"] \
      [get_bd_pins -of_objects [get_bd_cells -of_objects [current_bd_instance .]] -filter "TYPE == rst && NAME =~ rst && DIR == I"]
    set active_high_resets [get_bd_pins -of_objects [get_bd_cells] -filter "TYPE == rst && DIR == I && CONFIG.POLARITY == ACTIVE_HIGH"]
    if {[llength $active_high_resets] > 0} {
      connect_bd_net -quiet [tapasco::subsystem::get_port "design" "rst" "peripheral" "reset"] $active_high_resets
    }
  }

  # Instantiates the architecture.
  proc create {{mgroups 0}} {

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

    write_axi_parameters $insts

    set no_mis [get_master_interface_count $kernels $mgroups]
    write_noc_parameters [llength $insts] $no_mis

    arch_check_instance_count $kernels


    set arch_host_routers [arch_create_arke_noc_arch_interface $kernels 1]
    set arch_pe_routers [arch_create_arke_noc_pe_interfaces $kernels $insts $arch_host_routers]
    set arch_mem_routers [arch_create_arke_noc_mem_interfaces $no_mis $arch_pe_routers]

    arch_connect_routers $arch_mem_routers

    arch_set_noc_parameters $arch_pe_routers

    arch_connect_clocks
    arch_connect_resets

    # exit the hierarchical group
    current_bd_instance $instance
  }
}
