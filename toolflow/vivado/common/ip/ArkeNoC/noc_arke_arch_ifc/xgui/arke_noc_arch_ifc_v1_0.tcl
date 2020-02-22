# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "address" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CONTROL_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_X" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_Y" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_Z" -parent ${Page_0}
  ipgui::add_param $IPINST -name "A4L_addr_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "A4L_data_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "A4L_strb_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_base_addr" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_ranges" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_ranges_cnt" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NoC_targets" -parent ${Page_0}


}

proc update_PARAM_VALUE.A4L_addr_width { PARAM_VALUE.A4L_addr_width } {
	# Procedure called to update A4L_addr_width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.A4L_addr_width { PARAM_VALUE.A4L_addr_width } {
	# Procedure called to validate A4L_addr_width
	return true
}

proc update_PARAM_VALUE.A4L_data_width { PARAM_VALUE.A4L_data_width } {
	# Procedure called to update A4L_data_width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.A4L_data_width { PARAM_VALUE.A4L_data_width } {
	# Procedure called to validate A4L_data_width
	return true
}

proc update_PARAM_VALUE.A4L_strb_width { PARAM_VALUE.A4L_strb_width } {
	# Procedure called to update A4L_strb_width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.A4L_strb_width { PARAM_VALUE.A4L_strb_width } {
	# Procedure called to validate A4L_strb_width
	return true
}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXI_base_addr { PARAM_VALUE.AXI_base_addr } {
	# Procedure called to update AXI_base_addr when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_base_addr { PARAM_VALUE.AXI_base_addr } {
	# Procedure called to validate AXI_base_addr
	return true
}

proc update_PARAM_VALUE.AXI_ranges { PARAM_VALUE.AXI_ranges } {
	# Procedure called to update AXI_ranges when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ranges { PARAM_VALUE.AXI_ranges } {
	# Procedure called to validate AXI_ranges
	return true
}

proc update_PARAM_VALUE.AXI_ranges_cnt { PARAM_VALUE.AXI_ranges_cnt } {
	# Procedure called to update AXI_ranges_cnt when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ranges_cnt { PARAM_VALUE.AXI_ranges_cnt } {
	# Procedure called to validate AXI_ranges_cnt
	return true
}

proc update_PARAM_VALUE.CONTROL_WIDTH { PARAM_VALUE.CONTROL_WIDTH } {
	# Procedure called to update CONTROL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONTROL_WIDTH { PARAM_VALUE.CONTROL_WIDTH } {
	# Procedure called to validate CONTROL_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.DIM_X { PARAM_VALUE.DIM_X } {
	# Procedure called to update DIM_X when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIM_X { PARAM_VALUE.DIM_X } {
	# Procedure called to validate DIM_X
	return true
}

proc update_PARAM_VALUE.DIM_Y { PARAM_VALUE.DIM_Y } {
	# Procedure called to update DIM_Y when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIM_Y { PARAM_VALUE.DIM_Y } {
	# Procedure called to validate DIM_Y
	return true
}

proc update_PARAM_VALUE.DIM_Z { PARAM_VALUE.DIM_Z } {
	# Procedure called to update DIM_Z when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIM_Z { PARAM_VALUE.DIM_Z } {
	# Procedure called to validate DIM_Z
	return true
}

proc update_PARAM_VALUE.NoC_targets { PARAM_VALUE.NoC_targets } {
	# Procedure called to update NoC_targets when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NoC_targets { PARAM_VALUE.NoC_targets } {
	# Procedure called to validate NoC_targets
	return true
}

proc update_PARAM_VALUE.address { PARAM_VALUE.address } {
	# Procedure called to update address when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.address { PARAM_VALUE.address } {
	# Procedure called to validate address
	return true
}


proc update_MODELPARAM_VALUE.address { MODELPARAM_VALUE.address PARAM_VALUE.address } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.address}] ${MODELPARAM_VALUE.address}
}

proc update_MODELPARAM_VALUE.DIM_X { MODELPARAM_VALUE.DIM_X PARAM_VALUE.DIM_X } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIM_X}] ${MODELPARAM_VALUE.DIM_X}
}

proc update_MODELPARAM_VALUE.DIM_Y { MODELPARAM_VALUE.DIM_Y PARAM_VALUE.DIM_Y } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIM_Y}] ${MODELPARAM_VALUE.DIM_Y}
}

proc update_MODELPARAM_VALUE.DIM_Z { MODELPARAM_VALUE.DIM_Z PARAM_VALUE.DIM_Z } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIM_Z}] ${MODELPARAM_VALUE.DIM_Z}
}

proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CONTROL_WIDTH { MODELPARAM_VALUE.CONTROL_WIDTH PARAM_VALUE.CONTROL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONTROL_WIDTH}] ${MODELPARAM_VALUE.CONTROL_WIDTH}
}

proc update_MODELPARAM_VALUE.A4L_addr_width { MODELPARAM_VALUE.A4L_addr_width PARAM_VALUE.A4L_addr_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A4L_addr_width}] ${MODELPARAM_VALUE.A4L_addr_width}
}

proc update_MODELPARAM_VALUE.A4L_data_width { MODELPARAM_VALUE.A4L_data_width PARAM_VALUE.A4L_data_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A4L_data_width}] ${MODELPARAM_VALUE.A4L_data_width}
}

proc update_MODELPARAM_VALUE.A4L_strb_width { MODELPARAM_VALUE.A4L_strb_width PARAM_VALUE.A4L_strb_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A4L_strb_width}] ${MODELPARAM_VALUE.A4L_strb_width}
}

proc update_MODELPARAM_VALUE.AXI_base_addr { MODELPARAM_VALUE.AXI_base_addr PARAM_VALUE.AXI_base_addr } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_base_addr}] ${MODELPARAM_VALUE.AXI_base_addr}
}

proc update_MODELPARAM_VALUE.AXI_ranges { MODELPARAM_VALUE.AXI_ranges PARAM_VALUE.AXI_ranges } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ranges}] ${MODELPARAM_VALUE.AXI_ranges}
}

proc update_MODELPARAM_VALUE.AXI_ranges_cnt { MODELPARAM_VALUE.AXI_ranges_cnt PARAM_VALUE.AXI_ranges_cnt } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ranges_cnt}] ${MODELPARAM_VALUE.AXI_ranges_cnt}
}

proc update_MODELPARAM_VALUE.NoC_targets { MODELPARAM_VALUE.NoC_targets PARAM_VALUE.NoC_targets } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NoC_targets}] ${MODELPARAM_VALUE.NoC_targets}
}

