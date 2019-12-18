# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "A4L_addr_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "A4L_data_width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NoC_address" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NoC_address_map" -parent ${Page_0}


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

proc update_PARAM_VALUE.NoC_address { PARAM_VALUE.NoC_address } {
	# Procedure called to update NoC_address when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NoC_address { PARAM_VALUE.NoC_address } {
	# Procedure called to validate NoC_address
	return true
}

proc update_PARAM_VALUE.NoC_address_map { PARAM_VALUE.NoC_address_map } {
	# Procedure called to update NoC_address_map when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NoC_address_map { PARAM_VALUE.NoC_address_map } {
	# Procedure called to validate NoC_address_map
	return true
}


proc update_MODELPARAM_VALUE.A4L_addr_width { MODELPARAM_VALUE.A4L_addr_width PARAM_VALUE.A4L_addr_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A4L_addr_width}] ${MODELPARAM_VALUE.A4L_addr_width}
}

proc update_MODELPARAM_VALUE.A4L_data_width { MODELPARAM_VALUE.A4L_data_width PARAM_VALUE.A4L_data_width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.A4L_data_width}] ${MODELPARAM_VALUE.A4L_data_width}
}

proc update_MODELPARAM_VALUE.NoC_address { MODELPARAM_VALUE.NoC_address PARAM_VALUE.NoC_address } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NoC_address}] ${MODELPARAM_VALUE.NoC_address}
}

proc update_MODELPARAM_VALUE.NoC_address_map { MODELPARAM_VALUE.NoC_address_map PARAM_VALUE.NoC_address_map } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NoC_address_map}] ${MODELPARAM_VALUE.NoC_address_map}
}

