#
# Copyright (C) 2018 Carsten Heinz, TU Darmstadt
#
# This file is part of Tapasco (TaPaSCo).
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
# @file         aspin.tcl
# @brief        Implementation for EXTOLL ASPIN board.
# @author       C. Heinz, TU Darmstadt (heinz@esa.tu-darmstadt.de)
#
source -notrace $::env(TAPASCO_HOME)/platform/common/platform.tcl

namespace eval ::platform {
  namespace export max_masters
  namespace export create_subsystem_clocks_and_resets
  namespace export create_subsystem_intc
  namespace export create_subsystem_memory
  namespace export get_pe_base_address
  namespace export get_address_map
  namespace export number_of_interrupt_controllers

  # scan plugin directory
  foreach f [glob -nocomplain -directory "$::env(TAPASCO_HOME)/platform/aspin/plugins" "*.tcl"] {
    source -notrace $f
  }

  proc max_masters {} {
    return [list [::tapasco::get_platform_num_slots]]
  }

  proc create_subsystem_host {} {
    puts "Creating INCA Host subsystem ..."

    # Add proprietary ip
    set ip_paths [get_property IP_REPO_PATHS [current_project]]
    set repo_path "$::env(TAPASCO_HOME)/platform/aspin/ip_repo"
    lappend ip_paths $repo_path
    file delete -force $repo_path
    file mkdir $repo_path
    set_property IP_REPO_PATHS $ip_paths [current_project]
    update_ip_catalog
    update_ip_catalog -add_ip $repo_path/../esa.cs.tu-darmstadt.de_inca_extoll_network.zip -repo_path $repo_path
    update_ip_catalog
    set network [create_bd_cell -type ip -vlnv "esa.cs.tu-darmstadt.de:inca:extoll_network" "network"]
    add_files -fileset constrs_1 [glob $repo_path/../*.xdc]

    # set global defines (had a global include before)
    set_property verilog_define { \
      IMPLEMENTATION_OR_FULL_SIMULATIONNETWORK_NTL \
      CAG_XILINX \
      USE_XILINX \
      XILINX \
      NETWORK_AND_NTL \
    } [current_fileset]

    # Connect clocks
    set i2c_clk [create_bd_pin -type clk -dir I "i2c_clk"]
    set host_clk [tapasco::subsystem::get_port "host" "clk"]
    set host_res_n [tapasco::subsystem::get_port "host" "rst" "peripheral" "resetn"]
    set design_clk [tapasco::subsystem::get_port "design" "clk"]
    set design_res_n [tapasco::subsystem::get_port "design" "rst" "peripheral" "resetn"]
    set mem_clk [tapasco::subsystem::get_port "mem" "clk"]
    set mem_res_n [tapasco::subsystem::get_port "mem" "rst" "peripheral" "resetn"]
    connect_bd_net $i2c_clk [get_bd_pins "$network/clk_i2c"]
    connect_bd_net $host_res_n [get_bd_pins "$network/res_n_i2c"]
    connect_bd_net $host_clk [get_bd_pins "$network/clk_extoll"]
    connect_bd_net $host_res_n [get_bd_pins "$network/res_n_extoll"]
    connect_bd_net $design_clk [get_bd_pins "$network/clk_cr"]
    connect_bd_net $design_res_n [get_bd_pins "$network/res_n_cr"]
    connect_bd_net $mem_clk [get_bd_pins "$network/clk_nam"]
    connect_bd_net $mem_res_n [get_bd_pins "$network/res_n_nam"]

    # Make network interface pins external
    set external_pins [list {MGTREFCLK_EXTOLL_Q0_P_IN} {MGTREFCLK_EXTOLL_Q0_N_IN} {MGTREFCLK_EXTOLL_Q1_P_IN} {MGTREFCLK_EXTOLL_Q1_N_IN} \
      {EXTOLL_RXN_IN} {EXTOLL_RXP_IN} {EXTOLL_TXP_OUT} {EXTOLL_TXN_OUT} {LINK_CABLE_DET_IN}]
    foreach ep $external_pins {
      set ep_pin [get_bd_pins "$network/$ep"]
      set eport [create_bd_port -dir [get_property DIR $ep_pin] -from [get_property LEFT $ep_pin] -to 0 $ep]
      connect_bd_net $eport [get_bd_pins "$network/$ep"]
    }

    # add a AXI master (dummy for now)
    set axi_mm [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_mm2s_mapper:1.1 axi_mm2s_mapper_0]
    set_property -dict [list CONFIG.INTERFACES {M_AXI}] $axi_mm
    set m_axi_arch [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 "M_ARCH"]
    set m_axi_tapasco_status [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 "M_TAPASCO"]
    connect_bd_intf_net [get_bd_intf_pins "$axi_mm/S_AXIS"] [get_bd_intf_pins "$network/m_axis_tx_inca"]
    connect_bd_intf_net [get_bd_intf_pins "$axi_mm/M_AXI"] $m_axi_arch
    connect_bd_net [get_bd_pins "$axi_mm/aclk"] $design_clk
    connect_bd_net [get_bd_pins "$axi_mm/aresetn"] $design_res_n
  }

  proc create_subsystem_clocks_and_resets {} {
    # clocking infrastructure
    #  host_clk -> clk_extoll 160MHz
    #  design_clk -> clk_cr
    #  mem_clk -> clk_hmc
    #  + clk_i2c 25 MHz
    set freqs [::tapasco::get_frequencies]
    lappend freqs  "i2c" 25
    puts "Creating clock and reset subsystem ..."
    puts "  frequencies: $freqs"

    set clk_wiz [::tapasco::ip::create_clk_wiz "clk_wiz"]
    set_property -dict [list \
      CONFIG.USE_LOCKED {true} \
      CONFIG.USE_RESET {false} \
      CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
      CONFIG.PRIM_IN_FREQ {127.273} \
    ] $clk_wiz

    set reset_in [get_bd_pins "$clk_wiz/locked"]
    set cport [get_bd_intf_pins -of_objects $clk_wiz]
    puts "  clk_wiz: $clk_wiz, cport: $cport"
    #Do not use a differential clock port, as vivado appends _clk_(p|n) to name
    #set bport_p [platform::create_clock_port "SYSCLK_P"]
    set bport_p [create_bd_port -dir I -type clk "SYSCLK_P"]
    set bport_n [create_bd_port -dir I -type clk "SYSCLK_N"]
    set_property CONFIG.FREQ_HZ 127273000 $bport_p
    set_property CONFIG.FREQ_HZ 127273000 $bport_n
    #connect_bd_intf_net $cport $bport
    connect_bd_net [get_bd_pins "$clk_wiz/clk_in1_p"] $bport_p
    connect_bd_net [get_bd_pins "$clk_wiz/clk_in1_n"] $bport_n

    for {set i 0; set clkn 1} {$i < [llength $freqs]} {incr i 2} {
      set name [lindex $freqs $i]
      set freq [lindex $freqs [expr $i + 1]]
      #set clkn [expr "$i / 2 + 1"]
      puts "  instantiating clock: $name @ $freq MHz"
      for {set j 0} {$j < $i} {incr j 2} {
        if {[lindex $freqs [expr $j + 1]] == $freq} {
          puts "    $name is same frequency as [lindex $freqs $j], re-using"
          break
        }
      }
      # get ports
      puts "current name: $name"
      if {$name == "memory"} { set name "mem" }
      if {$name == "i2c"} {
	# i2c has a non-standardized clock pin within this platform definition
        set_property -dict [list \
	  CONFIG.CLKOUT${clkn}_USED {true} \
	  CONFIG.CLKOUT${clkn}_REQUESTED_OUT_FREQ $freq \
	  CONFIG.CLK_OUT${clkn}_PORT "${name}_clk" \
	] $clk_wiz
	set clkp [get_bd_pins "$clk_wiz/${name}_clk"]
	set clk [create_bd_pin -type clk -dir O "i2c_clk"]
	connect_bd_net $clkp $clk
	incr clkn
	continue
      }
      set clk    [::tapasco::subsystem::get_port $name "clk"]
      set p_rstn [::tapasco::subsystem::get_port $name "rst" "peripheral" "resetn"]
      set p_rst  [::tapasco::subsystem::get_port $name "rst" "peripheral" "reset"]
      set i_rstn [::tapasco::subsystem::get_port $name "rst" "interconnect"]

      if {[expr "$j < $i"]} {
        # simply re-wire sources
        set rst_gen [get_bd_cells "[lindex $freqs $j]_rst_gen"]
        set ex_clk [::tapasco::subsystem::get_port [lindex $freqs $j] "clk"]
        puts "rst_gen = $rst_gen"
        connect_bd_net -net [get_bd_nets -boundary_type lower -of_objects $ex_clk] $clk
        connect_bd_net [get_bd_pins $rst_gen/peripheral_aresetn] $p_rstn
        connect_bd_net [get_bd_pins $rst_gen/peripheral_reset] $p_rst
        connect_bd_net [get_bd_pins $rst_gen/interconnect_aresetn] $i_rstn
      } {
	set_property -dict [list \
          CONFIG.CLKOUT${clkn}_USED {true} \
          CONFIG.CLKOUT${clkn}_REQUESTED_OUT_FREQ $freq \
          CONFIG.CLK_OUT${clkn}_PORT "${name}_clk" \
        ] $clk_wiz
        set clkp [get_bd_pins "$clk_wiz/${name}_clk"]
        set rstgen [::tapasco::ip::create_rst_gen "${name}_rst_gen"]
        connect_bd_net $clkp $clk
        connect_bd_net $reset_in [get_bd_pins "$rstgen/ext_reset_in"]
        connect_bd_net $clkp [get_bd_pins "$rstgen/slowest_sync_clk"]
        connect_bd_net [get_bd_pins "$rstgen/peripheral_reset"] $p_rst
        connect_bd_net [get_bd_pins "$rstgen/peripheral_aresetn"] $p_rstn
        connect_bd_net [get_bd_pins "$rstgen/interconnect_aresetn"] $i_rstn
        incr clkn
      }
    }
  }
  proc create_clock_port {{name "sys_clk"}} {
    puts "creating 127.273 MHz diff clock port ..."
    set clk [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 $name]
    set_property CONFIG.FREQ_HZ 127273000 $clk
    return $clk
  }

  proc create_subsystem_intc {} {
    # TODO it cannot be empty, so adding random stuff
    set host_clk [tapasco::subsystem::get_port "host" "clk"]
    set intc [create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0]
    connect_bd_net $host_clk [get_bd_pins "$intc/CLK"]
  }

  proc create_subsystem_memory {} {
    set s_axi_mem [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 "S_MEM_0"]
    # TODO do some clock synchronizing (clk_design -> clk_mem)
    set s_axi_clk [tapasco::subsystem::get_port "design" "clk"]
    set s_axi_aresetn [tapasco::subsystem::get_port "design" "rst" "peripheral" "resetn"]

    # add a BRAM as dummy
    set bram_mem [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 bram_mem]
    set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM}] $bram_mem
    set bram_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 bram_ctrl]

    connect_bd_intf_net [get_bd_intf_pins "$bram_ctrl/BRAM_PORTA"] [get_bd_intf_pins "$bram_mem/BRAM_PORTA"]
    connect_bd_intf_net [get_bd_intf_pins "$bram_ctrl/BRAM_PORTB"] [get_bd_intf_pins "$bram_mem/BRAM_PORTB"]
    connect_bd_intf_net $s_axi_mem [get_bd_intf_pins "$bram_ctrl/S_AXI"]
    connect_bd_net $s_axi_clk [get_bd_pins "$bram_ctrl/s_axi_aclk"]
    connect_bd_net $s_axi_aresetn [get_bd_pins "$bram_ctrl/s_axi_aresetn"]
  }

  proc get_pe_base_address {} {
    return 0x02000000
  }

  proc get_address_map {{pe_base ""}} {
    # from zynq.tcl
    set max32 [expr "1 << 32"]
    if {$pe_base == ""} { set pe_base [get_pe_base_address] }
    puts "Computing addresses for PEs ..."
    set peam [::arch::get_address_map $pe_base]
    puts "Computing addresses for masters ..."
    foreach m [::tapasco::get_aximm_interfaces [get_bd_cells -filter "PATH !~ [::tapasco::subsystem::get arch]/*"]] {
      switch -glob [get_property NAME $m] {
        "M_TAPASCO" { foreach {base stride range comp} [list 0x77770000 0       0 "PLATFORM_COMPONENT_STATUS"] {} }
        "M_INTC"    { foreach {base stride range comp} [list 0x81800000 0x10000 0 "PLATFORM_COMPONENT_INTC0"] {} }
        "M_ARCH"    { set base "skip" }
        default     { foreach {base stride range comp} [list 0 0 0 ""] {} }
      }
      if {$base != "skip"} { set peam [addressmap::assign_address $peam $m $base $stride $range $comp] }
    }
    #TODO
    return $peam
  }

  proc number_of_interrupt_controllers {} {
    return 0
  }
}
