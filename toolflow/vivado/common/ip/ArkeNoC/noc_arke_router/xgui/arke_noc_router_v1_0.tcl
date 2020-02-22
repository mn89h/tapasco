# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "address" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BUFFER_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CONTROL_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_X" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_Y" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIM_Z" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PORTS" -parent ${Page_0}
  #Adding Group
  set Ports [ipgui::add_group $IPINST -name "Ports" -parent ${Page_0} -layout horizontal]
  #Adding Group
  set Data_In [ipgui::add_group $IPINST -name "Data_In" -parent ${Ports} -display_name {Data_In}]
  ipgui::add_param $IPINST -name "use_data_in_local" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_east" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_south" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_west" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_north" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_up" -parent ${Data_In}
  ipgui::add_param $IPINST -name "use_data_in_down" -parent ${Data_In}

  #Adding Group
  set Control_In [ipgui::add_group $IPINST -name "Control_In" -parent ${Ports} -display_name {Control_In}]
  ipgui::add_param $IPINST -name "use_control_in_local" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_east" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_south" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_west" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_north" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_up" -parent ${Control_In}
  ipgui::add_param $IPINST -name "use_control_in_down" -parent ${Control_In}

  #Adding Group
  set Data_Out [ipgui::add_group $IPINST -name "Data_Out" -parent ${Ports} -display_name {Data_Out}]
  ipgui::add_param $IPINST -name "use_data_out_local" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_east" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_south" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_west" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_north" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_up" -parent ${Data_Out}
  ipgui::add_param $IPINST -name "use_data_out_down" -parent ${Data_Out}

  #Adding Group
  set Control_Out [ipgui::add_group $IPINST -name "Control_Out" -parent ${Ports} -display_name {Control_Out}]
  ipgui::add_param $IPINST -name "use_control_out_local" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_east" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_south" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_west" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_north" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_up" -parent ${Control_Out}
  ipgui::add_param $IPINST -name "use_control_out_down" -parent ${Control_Out}




}

proc update_PARAM_VALUE.BUFFER_DEPTH { PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to update BUFFER_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BUFFER_DEPTH { PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to validate BUFFER_DEPTH
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

proc update_PARAM_VALUE.PORTS { PARAM_VALUE.PORTS } {
	# Procedure called to update PORTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PORTS { PARAM_VALUE.PORTS } {
	# Procedure called to validate PORTS
	return true
}

proc update_PARAM_VALUE.address { PARAM_VALUE.address } {
	# Procedure called to update address when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.address { PARAM_VALUE.address } {
	# Procedure called to validate address
	return true
}

proc update_PARAM_VALUE.use_control_in_down { PARAM_VALUE.use_control_in_down } {
	# Procedure called to update use_control_in_down when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_down { PARAM_VALUE.use_control_in_down } {
	# Procedure called to validate use_control_in_down
	return true
}

proc update_PARAM_VALUE.use_control_in_east { PARAM_VALUE.use_control_in_east } {
	# Procedure called to update use_control_in_east when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_east { PARAM_VALUE.use_control_in_east } {
	# Procedure called to validate use_control_in_east
	return true
}

proc update_PARAM_VALUE.use_control_in_local { PARAM_VALUE.use_control_in_local } {
	# Procedure called to update use_control_in_local when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_local { PARAM_VALUE.use_control_in_local } {
	# Procedure called to validate use_control_in_local
	return true
}

proc update_PARAM_VALUE.use_control_in_north { PARAM_VALUE.use_control_in_north } {
	# Procedure called to update use_control_in_north when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_north { PARAM_VALUE.use_control_in_north } {
	# Procedure called to validate use_control_in_north
	return true
}

proc update_PARAM_VALUE.use_control_in_south { PARAM_VALUE.use_control_in_south } {
	# Procedure called to update use_control_in_south when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_south { PARAM_VALUE.use_control_in_south } {
	# Procedure called to validate use_control_in_south
	return true
}

proc update_PARAM_VALUE.use_control_in_up { PARAM_VALUE.use_control_in_up } {
	# Procedure called to update use_control_in_up when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_up { PARAM_VALUE.use_control_in_up } {
	# Procedure called to validate use_control_in_up
	return true
}

proc update_PARAM_VALUE.use_control_in_west { PARAM_VALUE.use_control_in_west } {
	# Procedure called to update use_control_in_west when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_in_west { PARAM_VALUE.use_control_in_west } {
	# Procedure called to validate use_control_in_west
	return true
}

proc update_PARAM_VALUE.use_control_out_down { PARAM_VALUE.use_control_out_down } {
	# Procedure called to update use_control_out_down when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_down { PARAM_VALUE.use_control_out_down } {
	# Procedure called to validate use_control_out_down
	return true
}

proc update_PARAM_VALUE.use_control_out_east { PARAM_VALUE.use_control_out_east } {
	# Procedure called to update use_control_out_east when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_east { PARAM_VALUE.use_control_out_east } {
	# Procedure called to validate use_control_out_east
	return true
}

proc update_PARAM_VALUE.use_control_out_local { PARAM_VALUE.use_control_out_local } {
	# Procedure called to update use_control_out_local when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_local { PARAM_VALUE.use_control_out_local } {
	# Procedure called to validate use_control_out_local
	return true
}

proc update_PARAM_VALUE.use_control_out_north { PARAM_VALUE.use_control_out_north } {
	# Procedure called to update use_control_out_north when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_north { PARAM_VALUE.use_control_out_north } {
	# Procedure called to validate use_control_out_north
	return true
}

proc update_PARAM_VALUE.use_control_out_south { PARAM_VALUE.use_control_out_south } {
	# Procedure called to update use_control_out_south when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_south { PARAM_VALUE.use_control_out_south } {
	# Procedure called to validate use_control_out_south
	return true
}

proc update_PARAM_VALUE.use_control_out_up { PARAM_VALUE.use_control_out_up } {
	# Procedure called to update use_control_out_up when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_up { PARAM_VALUE.use_control_out_up } {
	# Procedure called to validate use_control_out_up
	return true
}

proc update_PARAM_VALUE.use_control_out_west { PARAM_VALUE.use_control_out_west } {
	# Procedure called to update use_control_out_west when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_control_out_west { PARAM_VALUE.use_control_out_west } {
	# Procedure called to validate use_control_out_west
	return true
}

proc update_PARAM_VALUE.use_data_in_down { PARAM_VALUE.use_data_in_down } {
	# Procedure called to update use_data_in_down when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_down { PARAM_VALUE.use_data_in_down } {
	# Procedure called to validate use_data_in_down
	return true
}

proc update_PARAM_VALUE.use_data_in_east { PARAM_VALUE.use_data_in_east } {
	# Procedure called to update use_data_in_east when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_east { PARAM_VALUE.use_data_in_east } {
	# Procedure called to validate use_data_in_east
	return true
}

proc update_PARAM_VALUE.use_data_in_local { PARAM_VALUE.use_data_in_local } {
	# Procedure called to update use_data_in_local when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_local { PARAM_VALUE.use_data_in_local } {
	# Procedure called to validate use_data_in_local
	return true
}

proc update_PARAM_VALUE.use_data_in_north { PARAM_VALUE.use_data_in_north } {
	# Procedure called to update use_data_in_north when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_north { PARAM_VALUE.use_data_in_north } {
	# Procedure called to validate use_data_in_north
	return true
}

proc update_PARAM_VALUE.use_data_in_south { PARAM_VALUE.use_data_in_south } {
	# Procedure called to update use_data_in_south when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_south { PARAM_VALUE.use_data_in_south } {
	# Procedure called to validate use_data_in_south
	return true
}

proc update_PARAM_VALUE.use_data_in_up { PARAM_VALUE.use_data_in_up } {
	# Procedure called to update use_data_in_up when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_up { PARAM_VALUE.use_data_in_up } {
	# Procedure called to validate use_data_in_up
	return true
}

proc update_PARAM_VALUE.use_data_in_west { PARAM_VALUE.use_data_in_west } {
	# Procedure called to update use_data_in_west when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_in_west { PARAM_VALUE.use_data_in_west } {
	# Procedure called to validate use_data_in_west
	return true
}

proc update_PARAM_VALUE.use_data_out_down { PARAM_VALUE.use_data_out_down } {
	# Procedure called to update use_data_out_down when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_down { PARAM_VALUE.use_data_out_down } {
	# Procedure called to validate use_data_out_down
	return true
}

proc update_PARAM_VALUE.use_data_out_east { PARAM_VALUE.use_data_out_east } {
	# Procedure called to update use_data_out_east when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_east { PARAM_VALUE.use_data_out_east } {
	# Procedure called to validate use_data_out_east
	return true
}

proc update_PARAM_VALUE.use_data_out_local { PARAM_VALUE.use_data_out_local } {
	# Procedure called to update use_data_out_local when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_local { PARAM_VALUE.use_data_out_local } {
	# Procedure called to validate use_data_out_local
	return true
}

proc update_PARAM_VALUE.use_data_out_north { PARAM_VALUE.use_data_out_north } {
	# Procedure called to update use_data_out_north when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_north { PARAM_VALUE.use_data_out_north } {
	# Procedure called to validate use_data_out_north
	return true
}

proc update_PARAM_VALUE.use_data_out_south { PARAM_VALUE.use_data_out_south } {
	# Procedure called to update use_data_out_south when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_south { PARAM_VALUE.use_data_out_south } {
	# Procedure called to validate use_data_out_south
	return true
}

proc update_PARAM_VALUE.use_data_out_up { PARAM_VALUE.use_data_out_up } {
	# Procedure called to update use_data_out_up when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_up { PARAM_VALUE.use_data_out_up } {
	# Procedure called to validate use_data_out_up
	return true
}

proc update_PARAM_VALUE.use_data_out_west { PARAM_VALUE.use_data_out_west } {
	# Procedure called to update use_data_out_west when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.use_data_out_west { PARAM_VALUE.use_data_out_west } {
	# Procedure called to validate use_data_out_west
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

proc update_MODELPARAM_VALUE.PORTS { MODELPARAM_VALUE.PORTS PARAM_VALUE.PORTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PORTS}] ${MODELPARAM_VALUE.PORTS}
}

proc update_MODELPARAM_VALUE.BUFFER_DEPTH { MODELPARAM_VALUE.BUFFER_DEPTH PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BUFFER_DEPTH}] ${MODELPARAM_VALUE.BUFFER_DEPTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CONTROL_WIDTH { MODELPARAM_VALUE.CONTROL_WIDTH PARAM_VALUE.CONTROL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONTROL_WIDTH}] ${MODELPARAM_VALUE.CONTROL_WIDTH}
}

proc update_MODELPARAM_VALUE.use_data_in_local { MODELPARAM_VALUE.use_data_in_local PARAM_VALUE.use_data_in_local } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_local}] ${MODELPARAM_VALUE.use_data_in_local}
}

proc update_MODELPARAM_VALUE.use_data_in_east { MODELPARAM_VALUE.use_data_in_east PARAM_VALUE.use_data_in_east } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_east}] ${MODELPARAM_VALUE.use_data_in_east}
}

proc update_MODELPARAM_VALUE.use_data_in_south { MODELPARAM_VALUE.use_data_in_south PARAM_VALUE.use_data_in_south } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_south}] ${MODELPARAM_VALUE.use_data_in_south}
}

proc update_MODELPARAM_VALUE.use_data_in_west { MODELPARAM_VALUE.use_data_in_west PARAM_VALUE.use_data_in_west } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_west}] ${MODELPARAM_VALUE.use_data_in_west}
}

proc update_MODELPARAM_VALUE.use_data_in_north { MODELPARAM_VALUE.use_data_in_north PARAM_VALUE.use_data_in_north } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_north}] ${MODELPARAM_VALUE.use_data_in_north}
}

proc update_MODELPARAM_VALUE.use_data_in_up { MODELPARAM_VALUE.use_data_in_up PARAM_VALUE.use_data_in_up } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_up}] ${MODELPARAM_VALUE.use_data_in_up}
}

proc update_MODELPARAM_VALUE.use_data_in_down { MODELPARAM_VALUE.use_data_in_down PARAM_VALUE.use_data_in_down } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_in_down}] ${MODELPARAM_VALUE.use_data_in_down}
}

proc update_MODELPARAM_VALUE.use_control_in_local { MODELPARAM_VALUE.use_control_in_local PARAM_VALUE.use_control_in_local } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_local}] ${MODELPARAM_VALUE.use_control_in_local}
}

proc update_MODELPARAM_VALUE.use_control_in_east { MODELPARAM_VALUE.use_control_in_east PARAM_VALUE.use_control_in_east } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_east}] ${MODELPARAM_VALUE.use_control_in_east}
}

proc update_MODELPARAM_VALUE.use_control_in_south { MODELPARAM_VALUE.use_control_in_south PARAM_VALUE.use_control_in_south } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_south}] ${MODELPARAM_VALUE.use_control_in_south}
}

proc update_MODELPARAM_VALUE.use_control_in_west { MODELPARAM_VALUE.use_control_in_west PARAM_VALUE.use_control_in_west } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_west}] ${MODELPARAM_VALUE.use_control_in_west}
}

proc update_MODELPARAM_VALUE.use_control_in_north { MODELPARAM_VALUE.use_control_in_north PARAM_VALUE.use_control_in_north } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_north}] ${MODELPARAM_VALUE.use_control_in_north}
}

proc update_MODELPARAM_VALUE.use_control_in_up { MODELPARAM_VALUE.use_control_in_up PARAM_VALUE.use_control_in_up } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_up}] ${MODELPARAM_VALUE.use_control_in_up}
}

proc update_MODELPARAM_VALUE.use_control_in_down { MODELPARAM_VALUE.use_control_in_down PARAM_VALUE.use_control_in_down } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_in_down}] ${MODELPARAM_VALUE.use_control_in_down}
}

proc update_MODELPARAM_VALUE.use_data_out_local { MODELPARAM_VALUE.use_data_out_local PARAM_VALUE.use_data_out_local } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_local}] ${MODELPARAM_VALUE.use_data_out_local}
}

proc update_MODELPARAM_VALUE.use_data_out_east { MODELPARAM_VALUE.use_data_out_east PARAM_VALUE.use_data_out_east } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_east}] ${MODELPARAM_VALUE.use_data_out_east}
}

proc update_MODELPARAM_VALUE.use_data_out_south { MODELPARAM_VALUE.use_data_out_south PARAM_VALUE.use_data_out_south } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_south}] ${MODELPARAM_VALUE.use_data_out_south}
}

proc update_MODELPARAM_VALUE.use_data_out_west { MODELPARAM_VALUE.use_data_out_west PARAM_VALUE.use_data_out_west } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_west}] ${MODELPARAM_VALUE.use_data_out_west}
}

proc update_MODELPARAM_VALUE.use_data_out_north { MODELPARAM_VALUE.use_data_out_north PARAM_VALUE.use_data_out_north } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_north}] ${MODELPARAM_VALUE.use_data_out_north}
}

proc update_MODELPARAM_VALUE.use_data_out_up { MODELPARAM_VALUE.use_data_out_up PARAM_VALUE.use_data_out_up } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_up}] ${MODELPARAM_VALUE.use_data_out_up}
}

proc update_MODELPARAM_VALUE.use_data_out_down { MODELPARAM_VALUE.use_data_out_down PARAM_VALUE.use_data_out_down } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_data_out_down}] ${MODELPARAM_VALUE.use_data_out_down}
}

proc update_MODELPARAM_VALUE.use_control_out_local { MODELPARAM_VALUE.use_control_out_local PARAM_VALUE.use_control_out_local } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_local}] ${MODELPARAM_VALUE.use_control_out_local}
}

proc update_MODELPARAM_VALUE.use_control_out_east { MODELPARAM_VALUE.use_control_out_east PARAM_VALUE.use_control_out_east } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_east}] ${MODELPARAM_VALUE.use_control_out_east}
}

proc update_MODELPARAM_VALUE.use_control_out_south { MODELPARAM_VALUE.use_control_out_south PARAM_VALUE.use_control_out_south } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_south}] ${MODELPARAM_VALUE.use_control_out_south}
}

proc update_MODELPARAM_VALUE.use_control_out_west { MODELPARAM_VALUE.use_control_out_west PARAM_VALUE.use_control_out_west } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_west}] ${MODELPARAM_VALUE.use_control_out_west}
}

proc update_MODELPARAM_VALUE.use_control_out_north { MODELPARAM_VALUE.use_control_out_north PARAM_VALUE.use_control_out_north } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_north}] ${MODELPARAM_VALUE.use_control_out_north}
}

proc update_MODELPARAM_VALUE.use_control_out_up { MODELPARAM_VALUE.use_control_out_up PARAM_VALUE.use_control_out_up } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_up}] ${MODELPARAM_VALUE.use_control_out_up}
}

proc update_MODELPARAM_VALUE.use_control_out_down { MODELPARAM_VALUE.use_control_out_down PARAM_VALUE.use_control_out_down } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.use_control_out_down}] ${MODELPARAM_VALUE.use_control_out_down}
}

