namespace eval BuildRouter {
  namespace export build
  set arke_dir $::env(TAPASCO_HOME_TCL)/common/ip/ArkeNoC

  proc create_proj {} {
    variable arke_dir
    create_project project_router $arke_dir/project_router -part xc7z020clg400-1 -force
    set filepaths "$arke_dir/noc_arke_router/src/InputBuffer.vhd $arke_dir/noc_arke_router/src/SwitchControl.vhd $arke_dir/noc_arke_router/src/ProgramablePriorityEncoder.vhd $arke_dir/noc_arke_router/src/Crossbar.vhd $arke_dir/noc_arke_router/src/Router.vhd $arke_dir/common/src/Arke_pkg.vhd"
    add_files -scan_for_includes $filepaths
    set_property library work [get_files $filepaths]
  }

  proc open_proj {} {
    variable arke_dir
    if {[catch {current_project} result ]} {
      puts "DEBUG:$result"
      open_project $arke_dir/project_router/project_router.xpr
    } else {
      if { $result == "project_router" } {
        puts "$result is already open"
      } else {
        open_project $arke_dir/project_router/project_router.xpr
      }
    }
  }

  proc package_proj {} {
    variable arke_dir
    ipx::package_project -root_dir $arke_dir/noc_arke_router -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
    ipx::unload_core $arke_dir/noc_arke_router/component.xml
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $arke_dir/noc_arke_router $arke_dir/noc_arke_router/component.xml
  }

  proc open_ip {} {
    variable arke_dir
    ipx::open_ipxact_file $arke_dir/noc_arke_router/component.xml
    ipx::merge_project_changes hdl_parameters [ipx::current_core]
  }

  proc set_infos {} {
    set_property vendor esa.informatik.tu-darmstadt.de [ipx::current_core]
    set_property library user [ipx::current_core]
    set_property name "arke_noc_router" [ipx::current_core]
    set_property display_name "Arke Router" [ipx::current_core]
    set_property description "Arke Router" [ipx::current_core]
    set_property vendor_display_name "" [ipx::current_core]
  }

  proc add_synthesis_files {} {
    ipx::remove_file_group xilinx_anylanguagesynthesis [ipx::current_core]

    ipx::add_file_group -type synthesis {} [ipx::current_core]
    set_property model_name "Router" [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    ipx::add_file src/InputBuffer.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/InputBuffer.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/InputBuffer.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/SwitchControl.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/SwitchControl.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/SwitchControl.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/ProgramablePriorityEncoder.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/ProgramablePriorityEncoder.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/ProgramablePriorityEncoder.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/Crossbar.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Crossbar.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Crossbar.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/Router.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Router.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Router.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
  }

  proc add_simulation_files {} {
    ipx::remove_file_group xilinx_anylanguagebehavioralsimulation [ipx::current_core]

    ipx::add_file_group -type simulation {} [ipx::current_core]
    set_property model_name "Router" [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    ipx::add_file src/InputBuffer.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/InputBuffer.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/InputBuffer.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/SwitchControl.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/SwitchControl.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/SwitchControl.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/ProgramablePriorityEncoder.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/ProgramablePriorityEncoder.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/ProgramablePriorityEncoder.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/Crossbar.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Crossbar.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Crossbar.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/Router.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Router.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Router.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
  }

  proc set_user_parameters {{address_width 15}} {
    set default_address [format {%0*s} $address_width 0]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "address" -component [ipx::current_core] ]
    set_property value \"$default_address\" [ipx::get_user_parameters address -of_objects [ipx::current_core]]
    set_property value \"$default_address\" [ipx::get_hdl_parameters address -of_objects [ipx::current_core]]
    set_property value_bit_string_length $address_width [ipx::get_user_parameters address -of_objects [ipx::current_core]]
    set_property value_bit_string_length $address_width [ipx::get_hdl_parameters address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters address -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "DIM_X" -component [ipx::current_core] ]
    set_property value 4 [ipx::get_user_parameters DIM_X -of_objects [ipx::current_core]]
    set_property value 4 [ipx::get_hdl_parameters DIM_X -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "DIM_Y" -component [ipx::current_core] ]
    set_property value 4 [ipx::get_user_parameters DIM_Y -of_objects [ipx::current_core]]
    set_property value 4 [ipx::get_hdl_parameters DIM_Y -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "DIM_Z" -component [ipx::current_core] ]
    set_property value 1 [ipx::get_user_parameters DIM_Z -of_objects [ipx::current_core]]
    set_property value 1 [ipx::get_hdl_parameters DIM_Z -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "PORTS" -component [ipx::current_core] ]
    set_property value 5 [ipx::get_user_parameters PORTS -of_objects [ipx::current_core]]
    set_property value 5 [ipx::get_hdl_parameters PORTS -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "BUFFER_DEPTH" -component [ipx::current_core] ]
    set_property value 4 [ipx::get_user_parameters BUFFER_DEPTH -of_objects [ipx::current_core]]
    set_property value 4 [ipx::get_hdl_parameters BUFFER_DEPTH -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core] ]
    set_property value 128 [ipx::get_user_parameters DATA_WIDTH -of_objects [ipx::current_core]]
    set_property value 128 [ipx::get_hdl_parameters DATA_WIDTH -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "CONTROL_WIDTH" -component [ipx::current_core] ]
    set_property value 3 [ipx::get_user_parameters CONTROL_WIDTH -of_objects [ipx::current_core]]
    set_property value 3 [ipx::get_hdl_parameters CONTROL_WIDTH -of_objects [ipx::current_core]]
  }


  proc set_default_driver_values {} {
    set_property driver_value 0 [ipx::get_ports data_in_local -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_east -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_south -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_west -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_north -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_up -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_in_down -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_local -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_east -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_south -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_west -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_north -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_up -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_in_down -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_local -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_east -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_south -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_west -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_north -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_up -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports data_out_down -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_local -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_east -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_south -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_west -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_north -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_up -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports control_out_down -of_objects [ipx::current_core]]
  }

  proc set_port_dependencies {} {
    set_property enablement_dependency {$use_data_in_local = true}      [ipx::get_ports data_in_local -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_east = true}       [ipx::get_ports data_in_east -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_south = true}      [ipx::get_ports data_in_south -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_west = true}       [ipx::get_ports data_in_west -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_north = true}      [ipx::get_ports data_in_north -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_up = true}         [ipx::get_ports data_in_up -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_in_down = true}       [ipx::get_ports data_in_down -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_local = true}   [ipx::get_ports control_in_local -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_east = true}    [ipx::get_ports control_in_east -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_south = true}   [ipx::get_ports control_in_south -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_west = true}    [ipx::get_ports control_in_west -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_north = true}   [ipx::get_ports control_in_north -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_up = true}      [ipx::get_ports control_in_up -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_in_down = true}    [ipx::get_ports control_in_down -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_local = true}     [ipx::get_ports data_out_local -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_east = true}      [ipx::get_ports data_out_east -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_south = true}     [ipx::get_ports data_out_south -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_west = true}      [ipx::get_ports data_out_west -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_north = true}     [ipx::get_ports data_out_north -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_up = true}        [ipx::get_ports data_out_up -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_data_out_down = true}      [ipx::get_ports data_out_down -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_local = true}  [ipx::get_ports control_out_local -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_east = true}   [ipx::get_ports control_out_east -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_south = true}  [ipx::get_ports control_out_south -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_west = true}   [ipx::get_ports control_out_west -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_north = true}  [ipx::get_ports control_out_north -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_up = true}     [ipx::get_ports control_out_up -of_objects [ipx::current_core]]
    set_property enablement_dependency {$use_control_out_down = true}   [ipx::get_ports control_out_down -of_objects [ipx::current_core]]
  }

  proc build_gui {} {
    ipgui::add_group -name {Ports} -component [ipx::current_core] -display_name {Ports} -layout {horizontal}
    ipgui::add_group -name {Data_In} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "Ports" -component [ipx::current_core] ] -display_name {Data_In}
    ipgui::add_group -name {Control_In} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "Ports" -component [ipx::current_core] ] -display_name {Control_In}
    ipgui::add_group -name {Data_Out} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "Ports" -component [ipx::current_core] ] -display_name {Data_Out}
    ipgui::add_group -name {Control_Out} -component [ipx::current_core] -parent [ipgui::get_groupspec -name "Ports" -component [ipx::current_core] ] -display_name {Control_Out}
    ipgui::move_group -component [ipx::current_core] -order 0 [ipgui::get_groupspec -name "Ports" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "use_data_in_local" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "use_data_in_east" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "use_data_in_south" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "use_data_in_west" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "use_data_in_north" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "use_data_in_up" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "use_data_in_down" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "use_control_in_local" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "use_control_in_east" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "use_control_in_south" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "use_control_in_west" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "use_control_in_north" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "use_control_in_up" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "use_control_in_down" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_In" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "use_data_out_local" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "use_data_out_east" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "use_data_out_south" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "use_data_out_west" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "use_data_out_north" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "use_data_out_up" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "use_data_out_down" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Data_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "use_control_out_local" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "use_control_out_east" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "use_control_out_south" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "use_control_out_west" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "use_control_out_north" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "use_control_out_up" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "use_control_out_down" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "Control_Out" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "address" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "BUFFER_DEPTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "CONTROL_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "DIM_X" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "DIM_Y" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "DIM_Z" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 7 [ipgui::get_guiparamspec -name "PORTS" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
  }
  
  proc save_and_exit {} {
    variable arke_dir
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    #update_ip_catalog -rebuild -repo_path $::tapascopath/toolflow/vivado/common
    ipx::unload_core $arke_dir/noc_arke_router/component.xml
  }

  proc purge_proj {} {
    variable arke_dir
    close_project -delete
    close_project -delete
    file delete $arke_dir/project_router
  }

  proc build {} {
    create_proj
    open_proj
    package_proj
    open_ip
    set_infos
    add_synthesis_files
    add_simulation_files
    set_user_parameters
    set_default_driver_values
    set_port_dependencies
    build_gui
    save_and_exit
    purge_proj
  }
}