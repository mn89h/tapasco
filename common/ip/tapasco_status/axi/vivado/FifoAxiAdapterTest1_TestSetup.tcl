
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
#    create_project project_1 myproj -part xc7a100tcsg324-1
#    set_property BOARD_PART digilentinc.com:nexys4_ddr:part0:1.1 [current_project]

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

  # Create instance: FifoAxiAdapterTest1_0, and set properties
  set FifoAxiAdapterTest1_0 [ create_bd_cell -type ip -vlnv esa.cs.tu-darmstadt.de:chisel:FifoAxiAdapterTest1:0.1 FifoAxiAdapterTest1_0 ]

  # Create instance: cdn_axi_bfm_0, and set properties
  set cdn_axi_bfm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cdn_axi_bfm:5.0 cdn_axi_bfm_0 ]
  set_property -dict [ list CONFIG.C_CHANNEL_LEVEL_INFO {1} CONFIG.C_DISABLE_RESET_VALUE_CHECKS {0} CONFIG.C_ERROR_ON_DECERR {0} CONFIG.C_MODE_SELECT {1} CONFIG.C_S_AXI4_MEMORY_MODEL_MODE {1}  ] $cdn_axi_bfm_0

  # Create instance: clk_gen_0, and set properties
  set clk_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_gen:1.0 clk_gen_0 ]
  set_property -dict [ list CONFIG.RESET_POLARITY {ACTIVE_HIGH}  ] $clk_gen_0

  # Create instance: rst_gen_0, and set properties
  set rst_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:rst_gen:1.0 rst_gen_0 ]
  set_property -dict [ list CONFIG.RST_PERIOD {100}  ] $rst_gen_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list CONFIG.CONST_VAL {10000} CONFIG.CONST_WIDTH {32}  ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net FifoAxiAdapterTest1_0_M_AXI [get_bd_intf_pins FifoAxiAdapterTest1_0/M_AXI] [get_bd_intf_pins cdn_axi_bfm_0/S_AXI]

  # Create port connections
  connect_bd_net -net clk_gen_0_clk [get_bd_pins FifoAxiAdapterTest1_0/clk] [get_bd_pins cdn_axi_bfm_0/s_axi_aclk] [get_bd_pins clk_gen_0/clk]
  connect_bd_net -net clk_gen_0_sync_rst [get_bd_pins FifoAxiAdapterTest1_0/reset] [get_bd_pins clk_gen_0/sync_rst]
  connect_bd_net -net rst_gen_0_rst [get_bd_pins cdn_axi_bfm_0/s_axi_aresetn] [get_bd_pins rst_gen_0/rst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins FifoAxiAdapterTest1_0/base] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  create_bd_addr_seg -range 0x100000000 -offset 0x0 [get_bd_addr_spaces FifoAxiAdapterTest1_0/M_AXI] [get_bd_addr_segs cdn_axi_bfm_0/axi_slave/Mem0] SEG_cdn_axi_bfm_0_Mem0
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


