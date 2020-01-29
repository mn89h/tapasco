namespace eval BuildArchIfc {
  namespace export build
  set arke_dir $::env(TAPASCO_HOME_TCL)/common/ip/ArkeNoC

  proc create_proj {} {
    variable arke_dir
    create_project project_arch_ifc $arke_dir/project_arch_ifc -part xc7z020clg400-1 -force
    set filepaths "$arke_dir/common/src/STD_FIFO.vhd $arke_dir/noc_arke_arch_ifc/src/Arch_Ifc.vhd $arke_dir/common/src/AXI4_Lite_Slave.vhd $arke_dir/common/src/NIC_pkg.vhd $arke_dir/common/src/Arke_pkg.vhd"
    add_files -norecurse -scan_for_includes $filepaths
    set_property library work [get_files $filepaths]
  }

  proc open_proj {} {
    variable arke_dir
    if {[catch {current_project} result ]} {
      puts "DEBUG:$result"
      open_project $arke_dir/project_arch_ifc/project_arch_ifc.xpr
    } else {
      if { $result == "project_arch_ifc" } {
        puts "$result is already open"
      } else {
        open_project $arke_dir/project_arch_ifc/project_arch_ifc.xpr
      }
    }
  }

  proc package_project {} {
    variable arke_dir
    ipx::package_project -root_dir $arke_dir/noc_arke_arch_ifc -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
    ipx::unload_core $arke_dir/noc_arke_arch_ifc/component.xml
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $arke_dir/noc_arke_arch_ifc $arke_dir/noc_arke_arch_ifc/component.xml
  }

  proc open_ip {} {
    variable arke_dir
    ipx::open_ipxact_file $arke_dir/noc_arke_arch_ifc/component.xml
  }

  proc set_infos {} {
    set_property vendor esa.informatik.tu-darmstadt.de [ipx::current_core]
    set_property library user [ipx::current_core]
    set_property name "arke_noc_arch_ifc" [ipx::current_core]
    set_property display_name "Arch Ifc" [ipx::current_core]
    set_property description "Arch Ifc" [ipx::current_core]
    set_property vendor_display_name "" [ipx::current_core]
  }

  proc add_synthesis_files {} {
    ipx::remove_file_group xilinx_anylanguagesynthesis [ipx::current_core]

    ipx::add_file_group -type synthesis {} [ipx::current_core]
    set_property model_name "Arch_Ifc" [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/Arch_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Arch_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Arch_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Lite_Slave.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Lite_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Lite_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
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
    set_property model_name "Arch_Ifc" [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/Arch_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Arch_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Arch_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Lite_Slave.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Lite_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Lite_Slave.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/NIC_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
  }

  proc import_parameters {} {
    variable arke_dir
    ipx::remove_all_hdl_parameter -remove_inferred_params [ipx::current_core]
    ipx::add_model_parameters_from_hdl [ipx::current_core] -top_level_hdl_file $arke_dir/noc_arke_arch_ifc/src/Arch_Ifc.vhd -top_module_name Arch_Ifc
    ipx::infer_user_parameters [ipx::current_core]
    ipgui::add_param -name {A4L_addr_width} -component [ipx::current_core] -display_name {A4L_addr_width}
    ipgui::add_param -name {A4L_data_width} -component [ipx::current_core] -display_name {A4L_data_width}
    ipgui::add_param -name {A4L_strb_width} -component [ipx::current_core] -display_name {A4L_strb_width}
    ipgui::add_param -name {NoC_address} -component [ipx::current_core] -display_name {NoC_address}
    ipgui::add_param -name {AXI_base_addr} -component [ipx::current_core] -display_name {AXI_base_addr}
    ipgui::add_param -name {AXI_ranges} -component [ipx::current_core] -display_name {AXI_ranges}
    ipgui::add_param -name {AXI_ranges_cnt} -component [ipx::current_core] -display_name {AXI_ranges_cnt}
    ipgui::add_param -name {NoC_targets} -component [ipx::current_core] -display_name {NoC_targets}
    
  }

  proc set_user_parameters {address_width} {
    set default_address [format {%0*s} $address_width 0]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "AXI_ranges" -component [ipx::current_core] ]
    set_property value {"00100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100"} [ipx::get_user_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property value {"00100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100"} [ipx::get_hdl_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property value_bit_string_length 800 [ipx::get_user_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property value_bit_string_length 800 [ipx::get_hdl_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters AXI_ranges -of_objects [ipx::current_core]]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NoC_targets" -component [ipx::current_core] ]
    set_property value {"00100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100"} [ipx::get_user_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property value {"00100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100"} [ipx::get_hdl_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property value_bit_string_length 800 [ipx::get_user_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property value_bit_string_length 800 [ipx::get_hdl_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters NoC_targets -of_objects [ipx::current_core]]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "AXI_base_addr" -component [ipx::current_core]]
    set_property value {"01000000000000000000000000000000"} [ipx::get_user_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property value {"01000000000000000000000000000000"} [ipx::get_hdl_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property value_bit_string_length 32 [ipx::get_user_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property value_bit_string_length 32 [ipx::get_hdl_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters AXI_base_addr -of_objects [ipx::current_core]]
    set_property widget {hexEdit} [ipgui::get_guiparamspec -name "NoC_address" -component [ipx::current_core]]
    set_property value \"$default_address\" [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value \"$default_address\" [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_bit_string_length $address_width [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_bit_string_length $address_width [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_user_parameters NoC_address -of_objects [ipx::current_core]]
    set_property value_format bitString [ipx::get_hdl_parameters NoC_address -of_objects [ipx::current_core]]
  }
  
  #axi memory map editing?

  proc save_and_exit {} {
    variable arke_dir
    set_property core_revision 1 [ipx::current_core]
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    #update_ip_catalog -rebuild -repo_path $::tapascopath/toolflow/vivado/common
    ipx::unload_core $arke_dir/noc_arke_arch_ifc/component.xml
  }

  proc close_proj {} {
    close_project -delete
    close_project
  }

  proc build {address_width} {
    create_proj
    open_proj
    package_project
    open_ip
    ipx::merge_project_changes hdl_parameters [ipx::current_core]
    set_infos
    set_user_parameters $address_width
    save_and_exit
    close_proj
  }
}