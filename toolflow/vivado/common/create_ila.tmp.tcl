startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
ipx::get_ipfiles: Time (s): cpu = 00:00:01 ; elapsed = 00:00:06 . Memory (MB): peak = 8639.590 ; gain = 0.000 ; free physical = 7088 ; free virtual = 20003
create_bd_cell: Time (s): cpu = 00:00:03 ; elapsed = 00:00:09 . Memory (MB): peak = 8639.590 ; gain = 0.000 ; free physical = 7083 ; free virtual = 20001
endgroup
set_property -dict [list CONFIG.C_BRAM_CNT {41.5} CONFIG.C_PROBE9_TYPE {1} CONFIG.C_PROBE7_TYPE {1} CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE1_TYPE {1} CONFIG.C_NUM_OF_PROBES {10} CONFIG.C_ADV_TRIGGER {false} CONFIG.C_NUM_MONITOR_SLOTS {7} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
WARNING: [IP_Flow 19-3374] An attempt to modify the value of disabled parameter 'C_BRAM_CNT' from '6.5' to '41.5' has been ignored for IP 'arch/system_ila_0'
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_0_AXI] [get_bd_intf_pins arch/arke_noc_arch_ifc/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4F_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_3_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_001/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_4_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_001/A4F_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_5_AXI] [get_bd_intf_pins arch/arke_noc_mem_ifc_0/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_6_AXI] [get_bd_intf_pins arch/arke_noc_mem_ifc_1/AXI]
connect_bd_net [get_bd_pins arch/system_ila_0/probe0] [get_bd_pins arch/arke_noc_pe_ifc_00_000/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe1] [get_bd_pins arch/arke_noc_pe_ifc_00_000/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe2] [get_bd_pins arch/arke_noc_pe_ifc_00_001/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe3] [get_bd_pins arch/arke_noc_pe_ifc_00_001/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe4] [get_bd_pins arch/arke_noc_mem_ifc_0/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe5] [get_bd_pins arch/arke_noc_mem_ifc_0/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe6] [get_bd_pins arch/arke_noc_mem_ifc_1/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe7] [get_bd_pins arch/arke_noc_mem_ifc_1/dataOut]
connect_bd_net [get_bd_pins arch/design_clk] [get_bd_pins arch/system_ila_0/clk]
connect_bd_net [get_bd_pins arch/design_peripheral_aresetn] [get_bd_pins arch/system_ila_0/resetn]
save_bd_design
