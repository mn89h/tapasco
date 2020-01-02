namespace eval BuildPEIfc {
  namespace export build

  proc create_proj {} {
    create_project project_pe_ifc $::script_path/project_pe_ifc -part xc7z020clg400-1
    add_files -norecurse -scan_for_includes {$::script_path/common/src/STD_FIFO.vhd $::script_path/common/src/AXI4_Full_Slave.vhd $::script_path/common/src/AXI4_Lite_Master.vhd $::script_path/common/src/NIC_pkg.vhd $::script_path/common/src/Arke_pkg.vhd $::script_path/noc_arke_pe_ifc/src/PE_Ifc.vhd}
    set_property library work [get_files  {$::script_path/common/src/STD_FIFO.vhd $::script_path/common/src/AXI4_Full_Slave.vhd $::script_path/common/src/AXI4_Lite_Master.vhd $::script_path/common/src/NIC_pkg.vhd $::script_path/common/src/Arke_pkg.vhd $::script_path/noc_arke_pe_ifc/src/PE_Ifc.vhd}]
  }

  proc open_proj {} {
    if {[catch {current_project} result ]} {
      puts "DEBUG:$result"
      open_project $::script_path/project_pe_ifc/project_pe_ifc.xpr
    } else {
      if { $result == "project_pe_ifc" } {
        puts "$result is already open"
      } else {
        open_project $::script_path/project_pe_ifc/project_pe_ifc.xpr
      }
    }
  }

  proc package_project {} {
    ipx::package_project -root_dir $::script_path/noc_arke_pe_ifc -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
    ipx::unload_core $::script_path/noc_arke_pe_ifc/component.xml
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $::script_path/noc_arke_pe_ifc $::script_path/noc_arke_pe_ifc/component.xml
  }

  proc open_ip {} {
    ipx::open_ipxact_file $::script_path/noc_arke_pe_ifc/component.xml
  }

  proc set_infos {} {
    set_property vendor esa.informatik.tu-darmstadt.de [ipx::current_core]
    set_property library user [ipx::current_core]
    set_property name "arke_noc_pe_ifc" [ipx::current_core]
    set_property display_name "PE Ifc" [ipx::current_core]
    set_property description "PE Ifc" [ipx::current_core]
    set_property vendor_display_name "" [ipx::current_core]
  }

  proc add_synthesis_files {} {
    ipx::remove_file_group xilinx_anylanguagesynthesis [ipx::current_core]

    ipx::add_file_group -type synthesis {} [ipx::current_core]
    set_property model_name "PE_Ifc" [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/PE_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/PE_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/PE_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Full_Slave.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Full_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Full_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Lite_Master.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Lite_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Lite_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/NIC_pkg.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
  }

  proc add_simulation_files {} {
    ipx::remove_file_group xilinx_anylanguagebehavioralsimulation [ipx::current_core]

    ipx::add_file_group -type simulation {} [ipx::current_core]
    set_property model_name "PE_Ifc" [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/PE_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/PE_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/PE_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Full_Slave.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Full_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Full_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Lite_Master.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Lite_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Lite_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/NIC_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
  }

  proc import_parameters {} {
    ipx::remove_all_hdl_parameter -remove_inferred_params [ipx::current_core]
    ipx::add_model_parameters_from_hdl [ipx::current_core] -top_level_hdl_file $::script_path/noc_arke_pe_ifc/src/PE_Ifc.vhd -top_module_name PE_Ifc
    ipx::infer_user_parameters [ipx::current_core]
    ipgui::add_param -name {A4L_addr_width} -component [ipx::current_core] -display_name {A4L_addr_width}
    ipgui::add_param -name {A4L_data_width} -component [ipx::current_core] -display_name {A4L_data_width}
    ipgui::add_param -name {A4F_addr_width} -component [ipx::current_core] -display_name {A4F_addr_width}
    ipgui::add_param -name {A4F_data_width} -component [ipx::current_core] -display_name {A4F_data_width}
    ipgui::add_param -name {A4F_id_width} -component [ipx::current_core] -display_name {A4F_id_width}
    ipgui::add_param -name {NoC_address} -component [ipx::current_core] -display_name {NoC_address}
    ipgui::add_param -name {NoC_address_mem} -component [ipx::current_core] -display_name {NoC_address_mem}
    ipgui::add_param -name {NoC_address_arch} -component [ipx::current_core] -display_name {NoC_address_arch}
  }

  proc set_default_driver_values {} {
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NoC_address" -component [ipx::current_core] ]
    set_property value {"000010"} [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value {"000010"} [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NoC_address_mem" -component [ipx::current_core] ]
    set_property value {"000000"} [ipx::get_user_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property value {"000000"} [ipx::get_hdl_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_user_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_hdl_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters NoC_address_mem -of_objects [ipx::current_core]]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NoC_address_arch" -component [ipx::current_core] ]
    set_property value {"000000"} [ipx::get_user_parameters NoC_address_arch -of_objects [ipx::current_core]]
    set_property value {"000000"} [ipx::get_hdl_parameters NoC_address_arch -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_user_parameters NoC_address_arch -of_objects [ipx::current_core]]
    set_property value_bit_string_length 6 [ipx::get_hdl_parameters NoC_address_arch -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters NoC_address_arch -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters NoC_address_arch -of_objects [ipx::current_core]]
  }
  
  #axi memory map editing?

  proc save_and_exit {} {
    set_property core_revision 1 [ipx::current_core]
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    #update_ip_catalog -rebuild -repo_path $::tapascopath/toolflow/vivado/common
    ipx::unload_core $::script_path/noc_arke_pe_ifc/component.xml
  }

  proc close_proj {} {
    close_project -delete
    close_project
  }

  proc build {} {
    #open_ip
    #set_infos
    #add_synthesis_files
    #add_simulation_files
    #import_parameters
    #set_default_driver_values
    #save_and_exit

    open_proj
    package_project
    open_ip
    ipx::merge_project_changes hdl_parameters [ipx::current_core]
    set_infos
    set_default_driver_values
    save_and_exit
    close_proj
  }
}