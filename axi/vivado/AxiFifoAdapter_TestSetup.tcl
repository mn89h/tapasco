
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7z020clg484-1
#    set_property BOARD_PART em.avnet.com:zed:part0:1.3 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set clk [ create_bd_port -dir O -type clk clk ]
  set io_deq_bits [ create_bd_port -dir O -from 31 -to 0 io_deq_bits ]
  set io_deq_ready [ create_bd_port -dir I io_deq_ready ]
  set io_deq_valid [ create_bd_port -dir O io_deq_valid ]
  set reset [ create_bd_port -dir O -from 0 -to 0 -type rst reset ]

  # Create instance: AxiFifoAdapter_0, and set properties
  set AxiFifoAdapter_0 [ create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:chisel:AxiFifoAdapter:0.1 AxiFifoAdapter_0 ]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list CONFIG.NUM_MI {1}  ] $axi_interconnect_0

  # Create instance: clk_gen_0, and set properties
  set clk_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_gen:1.0 clk_gen_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: processing_system7_bfm_0, and set properties
  set processing_system7_bfm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7_bfm:2.0 processing_system7_bfm_0 ]
  set_property -dict [ list CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} CONFIG.PCW_USE_S_AXI_HP0 {1}  ] $processing_system7_bfm_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list CONFIG.CONST_VAL {1048576} CONFIG.CONST_WIDTH {32}  ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net AxiFifoAdapter_0_M_AXI [get_bd_intf_pins AxiFifoAdapter_0/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins processing_system7_bfm_0/S_AXI_HP0]

  # Create port connections
  connect_bd_net -net AxiFifoAdapter_0_io_deq_bits [get_bd_ports io_deq_bits] [get_bd_pins AxiFifoAdapter_0/io_deq_bits]
  connect_bd_net -net AxiFifoAdapter_0_io_deq_valid [get_bd_ports io_deq_valid] [get_bd_pins AxiFifoAdapter_0/io_deq_valid]
  connect_bd_net -net clk_gen_0_clk [get_bd_ports clk] [get_bd_pins AxiFifoAdapter_0/clk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins clk_gen_0/clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins processing_system7_bfm_0/PS_CLK] [get_bd_pins processing_system7_bfm_0/S_AXI_HP0_ACLK]
  connect_bd_net -net clk_gen_0_sync_rst [get_bd_pins clk_gen_0/sync_rst] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins processing_system7_bfm_0/PS_PORB] [get_bd_pins processing_system7_bfm_0/PS_SRSTB]
  connect_bd_net -net io_deq_ready_1 [get_bd_ports io_deq_ready] [get_bd_pins AxiFifoAdapter_0/io_deq_ready]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_ports reset] [get_bd_pins AxiFifoAdapter_0/reset] [get_bd_pins proc_sys_reset_0/peripheral_reset]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins AxiFifoAdapter_0/base] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces AxiFifoAdapter_0/M_AXI] [get_bd_addr_segs processing_system7_bfm_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_bfm_0_HP0_DDR_LOWOCM
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


