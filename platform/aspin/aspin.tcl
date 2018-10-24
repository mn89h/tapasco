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
    set design_res [tapasco::subsystem::get_port "design" "rst" "peripheral" "reset"]
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

    # add Commando Processor
    set microblaze [create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:10.0 CoP]
    set_property CONFIG.C_FSL_LINKS {1} $microblaze
    set_property CONFIG.C_D_AXI {1} $microblaze
    # add local memory to microblaze
    set lmb_bram [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram]
    set_property -dict [list \
        CONFIG.Memory_Type {True_Dual_Port_RAM} \
        CONFIG.use_bram_block {BRAM_Controller} \
        CONFIG.Assume_Synchronous_Clk {true} \
    ] $lmb_bram
    set dlmb_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_ctrl]
    connect_bd_intf_net [get_bd_intf_pins $dlmb_ctrl/BRAM_PORT] [get_bd_intf_pins $lmb_bram/BRAM_PORTA]
    connect_bd_intf_net [get_bd_intf_pins $dlmb_ctrl/SLMB] [get_bd_intf_pins $microblaze/DLMB]
    connect_bd_net [get_bd_pins $dlmb_ctrl/LMB_Clk] $design_clk
    connect_bd_net [get_bd_pins $dlmb_ctrl/LMB_Rst] $design_res
    set ilmb_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_ctrl]
    connect_bd_intf_net [get_bd_intf_pins $ilmb_ctrl/BRAM_PORT] [get_bd_intf_pins $lmb_bram/BRAM_PORTB]
    connect_bd_intf_net [get_bd_intf_pins $ilmb_ctrl/SLMB] [get_bd_intf_pins $microblaze/ILMB]
    connect_bd_net [get_bd_pins $ilmb_ctrl/LMB_Clk] $design_clk
    connect_bd_net [get_bd_pins $ilmb_ctrl/LMB_Rst] $design_res
    assign_bd_address [get_bd_addr_segs {$dlmb_ctrl/SLMB/Mem}]
    assign_bd_address [get_bd_addr_segs {$ilmb_ctrl/SLMB/Mem}]

    # add AXI slave conversion logic
    # careful: rx and tx naming on extoll cell may be a bit confusing
    set tx_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_tx]
    set_property CONFIG.M_TDATA_NUM_BYTES {4} $tx_converter
    set rx_converter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_rx]
    set_property CONFIG.M_TDATA_NUM_BYTES {64} $rx_converter
    set axis_converter [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:extoll_axis_converter axis_converter]
    connect_bd_intf_net [get_bd_intf_pins "$microblaze/S0_AXIS"] [get_bd_intf_pins "$tx_converter/M_AXIS"]
    connect_bd_intf_net [get_bd_intf_pins "$microblaze/M0_AXIS"] [get_bd_intf_pins "$rx_converter/S_AXIS"]
    connect_bd_intf_net [get_bd_intf_pins "$tx_converter/S_AXIS"] [get_bd_intf_pins "$axis_converter/tx_m_axis"]
    connect_bd_intf_net [get_bd_intf_pins "$rx_converter/M_AXIS"] [get_bd_intf_pins "$axis_converter/rx_s_axis"]
    connect_bd_intf_net [get_bd_intf_pins "$network/m_axis_tx_inca"] [get_bd_intf_pins "$axis_converter/tx_s_axis"]
    connect_bd_intf_net [get_bd_intf_pins "$network/s_axis_rx_inca"] [get_bd_intf_pins "$axis_converter/rx_m_axis"]
    connect_bd_net [get_bd_pins "$microblaze/Clk"] $design_clk
    connect_bd_net [get_bd_pins "$microblaze/Reset"] $design_res
    connect_bd_net [get_bd_pins "$tx_converter/aclk"] $design_clk
    connect_bd_net [get_bd_pins "$tx_converter/aresetn"] $design_res_n
    connect_bd_net [get_bd_pins "$rx_converter/aclk"] $design_clk
    connect_bd_net [get_bd_pins "$rx_converter/aresetn"] $design_res_n
    connect_bd_net [get_bd_pins "$axis_converter/clk"] $design_clk

    # connect ARCH and STATUS to MicroBlaze
    set mb_ic [tapasco::ip::create_axi_ic "mb_ic" 1 3]

    set m_axi_arch [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 "M_ARCH"]
    set m_axi_mem [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 "M_MEM_C"]
    set m_axi_tapasco_status [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 "M_TAPASCO"]

    connect_bd_intf_net [get_bd_intf_pins "$mb_ic/M00_AXI"] $m_axi_arch
    connect_bd_intf_net [get_bd_intf_pins "$mb_ic/M01_AXI"] $m_axi_tapasco_status
    connect_bd_intf_net [get_bd_intf_pins "$mb_ic/M02_AXI"] $m_axi_mem
    connect_bd_intf_net [get_bd_intf_pins "$microblaze/M_AXI_DP"] [get_bd_intf_pins "$mb_ic/S00_AXI"]
    connect_bd_net $design_clk [get_bd_pins -filter {NAME =~ "M*_ACLK"} -of_objects $mb_ic]
    connect_bd_net $design_clk [get_bd_pins -filter {NAME =~ "S*_ACLK"} -of_objects $mb_ic]
    connect_bd_net $design_res_n [get_bd_pins -filter {NAME =~ "M*_ARESETN"} -of_objects $mb_ic]
    connect_bd_net $design_res_n [get_bd_pins -filter {NAME =~ "S*_ARESETN"} -of_objects $mb_ic]
    connect_bd_net $design_clk [get_bd_pins -filter {NAME == "ACLK"} -of_objects $mb_ic]
    connect_bd_net $design_res_n [get_bd_pins -filter {NAME == "ARESETN"} -of_objects $mb_ic]

    # connect RDMA bypass to memory
    set ntl2htl_port [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_tx_ntl]
    connect_bd_intf_net $ntl2htl_port $network/m_axis_tx_data
    set ntl2htl_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rx_ntl]
    connect_bd_intf_net $ntl2htl_port $network/s_axis_rx_data

    # TODO
    save_bd_design
  }

  proc create_subsystem_clocks_and_resets {} {
    # clocking infrastructure
    #  host_clk -> clk_extoll 160MHz
    #  design_clk -> clk_cr
    #  mem_clk: from clk_hmc in MEM
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
        if {$name != "mem"} {
          connect_bd_net -net [get_bd_nets -boundary_type lower -of_objects $ex_clk] $clk
        }
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
        if {$name != "mem"} {
          connect_bd_net $clkp $clk
          connect_bd_net $clkp [get_bd_pins "$rstgen/slowest_sync_clk"]
        }
        connect_bd_net $reset_in [get_bd_pins "$rstgen/ext_reset_in"]
        connect_bd_net [get_bd_pins "$rstgen/peripheral_reset"] $p_rst
        connect_bd_net [get_bd_pins "$rstgen/peripheral_aresetn"] $p_rstn
        connect_bd_net [get_bd_pins "$rstgen/interconnect_aresetn"] $i_rstn
        incr clkn
      }
    }

    # remove mem_clk, it is provided by /memory
    set mem_clk [tapasco::subsystem::get_port "mem" "clk"]
    delete_bd_objs $mem_clk
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

    # add openHMC
    set openHMC [create_bd_cell -type ip -vlnv ra.ziti.uni-heidelberg.de:openHMC:openHMC:1.5 openHMC]
    set_property -dict [list CONFIG.HMC_RX_AC_COUPLED {0} CONFIG.PASS_ERR_RSP {0} CONFIG.USE_RF {0} CONFIG.RX_RELAX_INIT_TIMING {0}] $openHMC

    set openhmc_transceiver [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:openhmc_transceiver openhmc_transceiver]
    set_property -dict [list CONFIG.LOG_NUM_LANES {3} CONFIG.NUM_LANES {8} CONFIG.LANE_WIDTH {64}] $openhmc_transceiver

    set hmc_init [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:hmc_init hmc_init]

    connect_bd_net [get_bd_pins $openhmc_transceiver/clk_hmc] [get_bd_pins $openHMC/clk_hmc]
    connect_bd_net [get_bd_pins $openhmc_transceiver/to_serializers] [get_bd_pins $openHMC/phy_data_tx_link2phy]
    connect_bd_net [get_bd_pins $openhmc_transceiver/from_deserializers] [get_bd_pins $openHMC/phy_data_rx_phy2link]
    connect_bd_net [get_bd_pins $openHMC/phy_bit_slip] [get_bd_pins $openhmc_transceiver/bit_slip]
    connect_bd_net [get_bd_pins $openhmc_transceiver/trans_rx_ready] [get_bd_pins $openHMC/phy_rx_ready]

    connect_bd_net [get_bd_pins $hmc_init/hmc_init_res_n_phy] [get_bd_pins $openhmc_transceiver/hmc_init_res_n_phy]
    connect_bd_net [get_bd_pins $openhmc_transceiver/hmc_init_cont_set] [get_bd_pins $hmc_init/hmc_init_cont_set]
    connect_bd_net [get_bd_pins $openHMC/hmc_link_is_up] [get_bd_pins $hmc_init/hmc_link_is_up]
    connect_bd_net [get_bd_pins $openHMC/err_cnt_not_zero_any] [get_bd_pins $hmc_init/openhmc_err_cnt_not_zero_any]

    set init_rst_n_or [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 init_rst_n_or]

    # Make HMC interface pins external
    # openhmc_transceiver
    set external_pins [list {HMC_TXP_OUT} {HMC_TXN_OUT} {HMC_RXP_IN} {HMC_RXN_IN}]
    foreach ep $external_pins {
      set ep_pin [get_bd_pins $openhmc_transceiver/$ep]
      set eport [create_bd_port -dir [get_property DIR $ep_pin] -from [get_property LEFT $ep_pin] -to 0 $ep]
      connect_bd_net $eport $ep_pin
    }
    set external_pins [list {MGTREFCLKQ2_P_IN} {MGTREFCLKQ2_N_IN} {MGTREFCLKQ3_P_IN} {MGTREFCLKQ3_N_IN}]
    foreach ep $external_pins {
      set ep_pin [get_bd_pins $openhmc_transceiver/$ep]
      set eport [create_bd_port -dir [get_property DIR $ep_pin] $ep]
      connect_bd_net $eport $ep_pin
    }
    set ep "L0RXPS"
    set ep_pin [get_bd_pins $openHMC/LXRXPS]
    set eport [create_bd_port -dir [get_property DIR $ep_pin] $ep]
    connect_bd_net $eport $ep_pin
    # hmc_init
    set external_pins [list {I2C_SDA} {I2C_SCL}]
    foreach ep $external_pins {
      set ep_pin [get_bd_pins $hmc_init/$ep]
      set eport [create_bd_port -dir [get_property DIR $ep_pin] $ep]
      connect_bd_net $eport $ep_pin
    }
    set ep "LED"
    set ep_pin [get_bd_pins $hmc_init/$ep]
    set eport [create_bd_port -dir [get_property DIR $ep_pin] -from [get_property LEFT $ep_pin] -to 0 $ep]
    connect_bd_net $eport $ep_pin
    # generate P_RST_N
    set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png}] $init_rst_n_or
    connect_bd_net [get_bd_pins $openHMC/P_RST_N] [get_bd_pins $init_rst_n_or/Op1]
    connect_bd_net [get_bd_pins $hmc_init/P_RST_N] [get_bd_pins $init_rst_n_or/Op2]
    set ep "P_RST_N"
    set ep_pin [get_bd_pins $init_rst_n_or/Res]
    set eport [create_bd_port -dir [get_property DIR $ep_pin] $ep]
    connect_bd_net $eport $ep_pin

    # HTL
    set htl [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:HTL HTL]
    set_property -dict [list CONFIG.NUM_EXTOLL_CELLS {8} CONFIG.OPENHMC_CTRL_BITS {12} \
      CONFIG.NTL2HTL_CTRL_BITS {9} CONFIG.HTL2NTL_CTRL_BITS {9} CONFIG.HTL_CTRL_BITS {12} \
      CONFIG.NAM_TAG_SIZE {7} CONFIG.OPENHMC_TAG_SIZE {6} CONFIG.HMC_ADRS_SIZE {31} \
      CONFIG.HTL_RF_AWIDTH {6}] $htl
    connect_bd_intf_net [get_bd_intf_pins $htl/m_axis_tx_hmc] [get_bd_intf_pins $openHMC/s_axis_tx]
    connect_bd_intf_net [get_bd_intf_pins $htl/s_axis_rx_hmc] [get_bd_intf_pins $openHMC/m_axis_rx]
    set htl2ntl_port [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_tx_htl]
    connect_bd_intf_net $htl2ntl_port $htl/out

    # Arbitrate HTL input
    set htl_in_arbiter [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:extoll_axis_arbiter axis_arbiter]
    set ntl2htl_port [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rx_htl]
    connect_bd_intf_net $ntl2htl_port $htl_in_arbiter/s1_axis
    connect_bd_intf_net $htl_in_arbiter/m_axis $htl/in_arb

    # Add AXI-MM input to HTL arbiter
    set axi_mm [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:aximm_to_extoll_axis axi_mm]
    connect_bd_intf_net $axi_mm/m_axis $htl_in_arbiter/s0_axis
    connect_bd_intf_net $axi_mm/s_axis $htl/out_cr
    # Add Interconnect (Clock-Domain-Crossing + width conversion + second AXI slave port)
    set mem_interconnect [tapasco::ip::create_axi_ic "mem_interconnect" 2 1]
    set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] $mem_interconnect
    # remove AXI IDs in interconnect
    set_property -dict [list CONFIG.STRATEGY {1}] $mem_interconnect
    # Add AXI wstrb remover
    set axi_wstrb [create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:inca:axi_wstrb_remover axi_wstrb]
    set s_axi_mem_c [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 "S_MEM_C"]
    connect_bd_intf_net $s_axi_mem $mem_interconnect/S00_AXI
    connect_bd_intf_net $s_axi_mem_c $mem_interconnect/S01_AXI
    connect_bd_intf_net $axi_mm/s $axi_wstrb/m_axi
    connect_bd_intf_net $axi_wstrb/s_axi $mem_interconnect/M00_AXI

    # Connect clocks
    set i2c_clk [create_bd_pin -type clk -dir I "i2c_clk"]
    set mem_clk [tapasco::subsystem::get_port "mem" "clk"]
    set design_clk [tapasco::subsystem::get_port "design" "clk"]
    delete_bd_objs $mem_clk
    set mem_clk [create_bd_pin -dir O -type clk "mem_clk"]
    set mem_res_n [tapasco::subsystem::get_port "mem" "rst" "peripheral" "resetn"]
    set design_res_n [tapasco::subsystem::get_port "design" "rst" "peripheral" "resetn"]
    set i2c_res_n $mem_res_n
    connect_bd_net $i2c_clk [get_bd_pins $hmc_init/clk_i2c]
    connect_bd_net $i2c_res_n [get_bd_pins $hmc_init/res_n_i2c]
    connect_bd_net $i2c_clk [get_bd_pins $openhmc_transceiver/clk_init]
    connect_bd_net $mem_clk [get_bd_pins $openHMC/clk_user]
    connect_bd_net $mem_clk [get_bd_pins $openhmc_transceiver/clk_hmc]
    connect_bd_net $mem_clk [get_bd_pins $htl/clk]
    connect_bd_net $mem_clk [get_bd_pins $htl_in_arbiter/clk]
    connect_bd_net $mem_clk [get_bd_pins $axi_mm/clk]
    connect_bd_net $mem_clk [get_bd_pins $axi_wstrb/clk]
    connect_bd_net $mem_clk [get_bd_pins $mem_interconnect/ACLK]
    connect_bd_net $mem_clk [get_bd_pins $mem_interconnect/M00_ACLK]
    connect_bd_net $mem_res_n [get_bd_pins $openHMC/res_n_user]
    connect_bd_net $mem_res_n [get_bd_pins $openHMC/res_n_hmc]
    connect_bd_net $mem_res_n [get_bd_pins $htl/res_n]
    connect_bd_net $mem_res_n [get_bd_pins $htl_in_arbiter/res_n]
    connect_bd_net $mem_res_n [get_bd_pins $axi_mm/res_n]
    connect_bd_net $mem_res_n [get_bd_pins $axi_wstrb/res_n]
    connect_bd_net $mem_res_n [get_bd_pins $mem_interconnect/ARESETN]
    connect_bd_net $mem_res_n [get_bd_pins $mem_interconnect/M00_ARESETN]
    connect_bd_net $design_clk [get_bd_pins $mem_interconnect/S00_ACLK]
    connect_bd_net $design_clk [get_bd_pins $mem_interconnect/S01_ACLK]
    connect_bd_net $design_res_n [get_bd_pins $mem_interconnect/S00_ARESETN]
    connect_bd_net $design_res_n [get_bd_pins $mem_interconnect/S01_ARESETN]
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
        "M_INTC"    { foreach {base stride range comp} [list 0x7a000000 0x10000 0 "PLATFORM_COMPONENT_INTC0"] {} }
        "M_MEM_C"   { foreach {base stride range comp} [list 0x80000000 0       0x80000000 ""] {} }
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
