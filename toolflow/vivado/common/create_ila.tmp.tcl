startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
endgroup
set_property -dict [list CONFIG.C_BRAM_CNT {41.5} CONFIG.C_PROBE9_TYPE {1} CONFIG.C_PROBE7_TYPE {1} CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE1_TYPE {1} CONFIG.C_NUM_OF_PROBES {10} CONFIG.C_ADV_TRIGGER {false} CONFIG.C_NUM_MONITOR_SLOTS {7} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
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





#for mbsX3
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
create_bd_cell: Time (s): cpu = 00:00:04 ; elapsed = 00:00:10 . Memory (MB): peak = 7827.863 ; gain = 0.000 ; free physical = 10185 ; free virtual = 19724
endgroup
set_property -dict [list CONFIG.C_BRAM_CNT {6.5} CONFIG.C_NUM_OF_PROBES {20} CONFIG.C_NUM_MONITOR_SLOTS {3} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_0_AXI] [get_bd_intf_pins arch/arke_noc_arch_ifc/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_002/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI]
undo
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_002/A4F_AXI]
startgroup
set_property -dict [list CONFIG.C_BRAM_CNT {18.5} CONFIG.C_NUM_MONITOR_SLOTS {4}] [get_bd_cells arch/system_ila_0]
endgroup
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_3_AXI] -boundary_type upper [get_bd_intf_pins arch/out_0/S000_AXI]
connect_bd_net [get_bd_pins arch/system_ila_0/probe0] [get_bd_pins arch/arke_noc_arch_ifc/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe1] [get_bd_pins arch/arke_noc_arch_ifc/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe2] [get_bd_pins arch/arke_noc_pe_ifc_00_002/controlIn]
connect_bd_net [get_bd_pins arch/system_ila_0/probe3] [get_bd_pins arch/arke_noc_pe_ifc_00_002/dataIn]
connect_bd_net [get_bd_pins arch/system_ila_0/probe5] [get_bd_pins arch/arke_noc_pe_ifc_00_002/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe4] [get_bd_pins arch/arke_noc_pe_ifc_00_002/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe6] [get_bd_pins arch/arke_noc_mem_ifc_0/controlIn]
connect_bd_net [get_bd_pins arch/system_ila_0/probe7] [get_bd_pins arch/arke_noc_mem_ifc_0/dataIn]
connect_bd_net [get_bd_pins arch/system_ila_0/probe8] [get_bd_pins arch/arke_noc_mem_ifc_0/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe9] [get_bd_pins arch/arke_noc_mem_ifc_0/dataOut]
connect_bd_net [get_bd_pins arch/design_clk] [get_bd_pins arch/system_ila_0/clk]
connect_bd_net [get_bd_pins arch/design_peripheral_aresetn] [get_bd_pins arch/system_ila_0/resetn]
startgroup
set_property -dict [list CONFIG.C_BRAM_CNT {24} CONFIG.C_PROBE15_TYPE {1} CONFIG.C_PROBE13_TYPE {1} CONFIG.C_PROBE11_TYPE {1} CONFIG.C_PROBE9_TYPE {1} CONFIG.C_PROBE7_TYPE {1} CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE1_TYPE {1}] [get_bd_cells arch/system_ila_0]
endgroup
save

#for mbsX1 - returns that crossbar has always a*ready=0
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
set_property -dict [list CONFIG.C_BRAM_CNT {6.5} CONFIG.C_NUM_OF_PROBES {20} CONFIG.C_NUM_MONITOR_SLOTS {3} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_0_AXI] [get_bd_intf_pins arch/arke_noc_arch_ifc/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4F_AXI]
startgroup
set_property -dict [list CONFIG.C_NUM_MONITOR_SLOTS {7}] [get_bd_cells arch/system_ila_0]
endgroup
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_3_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_4_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_1]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_5_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_3]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_6_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_4]
connect_bd_net [get_bd_pins arch/system_ila_0/probe0] [get_bd_pins arch/arke_noc_arch_ifc/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe1] [get_bd_pins arch/arke_noc_arch_ifc/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe2] [get_bd_pins arch/arke_noc_pe_ifc_00_000/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe3] [get_bd_pins arch/arke_noc_pe_ifc_00_000/dataOut]
connect_bd_net [get_bd_pins arch/design_clk] [get_bd_pins arch/system_ila_0/clk]
connect_bd_net [get_bd_pins arch/design_peripheral_aresetn] [get_bd_pins arch/system_ila_0/resetn]
startgroup
set_property -dict [list CONFIG.C_BRAM_CNT {24} CONFIG.C_PROBE15_TYPE {1} CONFIG.C_PROBE13_TYPE {1} CONFIG.C_PROBE11_TYPE {1} CONFIG.C_PROBE9_TYPE {1} CONFIG.C_PROBE7_TYPE {1} CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE1_TYPE {1}] [get_bd_cells arch/system_ila_0]
endgroup


#for mbsX1 - returns that crossbar has always a*ready=0
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {4} CONFIG.C_NUM_MONITOR_SLOTS {5} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_0_AXI] [get_bd_intf_pins arch/arke_noc_arch_ifc/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/target_ip_00_000/S_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_3_AXI] [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_1]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_4_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_000/A4F_AXI]
connect_bd_net [get_bd_pins arch/system_ila_0/probe0] [get_bd_pins arch/arke_noc_arch_ifc/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe1] [get_bd_pins arch/arke_noc_arch_ifc/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe2] [get_bd_pins arch/arke_noc_pe_ifc_00_000/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe3] [get_bd_pins arch/arke_noc_pe_ifc_00_000/dataOut]
connect_bd_net [get_bd_pins arch/design_clk] [get_bd_pins arch/system_ila_0/clk]
connect_bd_net [get_bd_pins arch/design_peripheral_aresetn] [get_bd_pins arch/system_ila_0/resetn]


#for mbsX3 in order to remove multiple master interfaces
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_1]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_2]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_3]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_4]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_5]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_6]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_000/M_AXI_HBM_7]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_1]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_2]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_3]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_4]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_5]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_6]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_001/M_AXI_HBM_7]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_1]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_2]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_3]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_4]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_5]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_6]]
delete_bd_objs [get_bd_intf_nets -of_objects [get_bd_intf_pins /arch/target_ip_00_002/M_AXI_HBM_7]]

create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 arch/system_ila_0
set_property -dict [list CONFIG.C_BRAM_CNT {6.5} CONFIG.C_NUM_OF_PROBES {20} CONFIG.C_NUM_MONITOR_SLOTS {3} CONFIG.C_MON_TYPE {MIX}] [get_bd_cells arch/system_ila_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_0_AXI] [get_bd_intf_pins arch/arke_noc_arch_ifc/AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_1_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_002/A4L_AXI]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_2_AXI] [get_bd_intf_pins arch/arke_noc_pe_ifc_00_002/A4F_AXI]
startgroup
set_property -dict [list CONFIG.C_NUM_MONITOR_SLOTS {7}] [get_bd_cells arch/system_ila_0]
endgroup
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_3_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_000/M_AXI_HBM_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_4_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_001/M_AXI_HBM_0]
connect_bd_intf_net [get_bd_intf_pins arch/system_ila_0/SLOT_5_AXI] -boundary_type upper [get_bd_intf_pins arch/target_ip_00_002/M_AXI_HBM_0]
connect_bd_net [get_bd_pins arch/system_ila_0/probe0] [get_bd_pins arch/arke_noc_arch_ifc/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe1] [get_bd_pins arch/arke_noc_arch_ifc/dataOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe2] [get_bd_pins arch/arke_noc_pe_ifc_00_002/controlOut]
connect_bd_net [get_bd_pins arch/system_ila_0/probe3] [get_bd_pins arch/arke_noc_pe_ifc_00_002/dataOut]
connect_bd_net [get_bd_pins arch/design_clk] [get_bd_pins arch/system_ila_0/clk]
connect_bd_net [get_bd_pins arch/design_peripheral_aresetn] [get_bd_pins arch/system_ila_0/resetn]
startgroup
set_property -dict [list CONFIG.C_BRAM_CNT {24} CONFIG.C_PROBE15_TYPE {1} CONFIG.C_PROBE13_TYPE {1} CONFIG.C_PROBE11_TYPE {1} CONFIG.C_PROBE9_TYPE {1} CONFIG.C_PROBE7_TYPE {1} CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE1_TYPE {1}] [get_bd_cells arch/system_ila_0]
endgroup
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_1/AM_SEG_001]
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_3/AM_SEG_003]
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_1/AM_SEG_009]
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_4/AM_SEG_004] [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_5/AM_SEG_005] [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_6/AM_SEG_006] [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_7/AM_SEG_007]
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_2/AM_SEG_010] [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_3/AM_SEG_011] [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_4/AM_SEG_012] [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_5/AM_SEG_013] [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_6/AM_SEG_014] [get_bd_addr_segs arch/target_ip_00_001/M_AXI_HBM_7/AM_SEG_015] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_1/AM_SEG_017] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_2/AM_SEG_018] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_3/AM_SEG_019] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_4/AM_SEG_020] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_5/AM_SEG_021] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_6/AM_SEG_022] [get_bd_addr_segs arch/target_ip_00_002/M_AXI_HBM_7/AM_SEG_023]
delete_bd_objs [get_bd_addr_segs arch/target_ip_00_000/M_AXI_HBM_2/AM_SEG_002]
