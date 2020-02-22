namespace eval BuildMemIfc {
  namespace export build
  set arke_dir $::env(TAPASCO_HOME_TCL)/common/ip/ArkeNoC

  proc create_proj {} {
    variable arke_dir
    create_project project_mem_ifc $arke_dir/project_mem_ifc -part xc7z020clg400-1 -force
    set filepaths "$arke_dir/common/src/STD_FIFO.vhd $arke_dir/common/src/AXI4_Full_Master.vhd $arke_dir/common/src/NIC_pkg.vhd $arke_dir/common/src/Arke_pkg.vhd $arke_dir/noc_arke_mem_ifc/src/Mem_Ifc.vhd"
    add_files -norecurse -scan_for_includes $filepaths
    set_property library work [get_files $filepaths]
  }

  proc open_proj {} {
    variable arke_dir
    if {[catch {current_project} result ]} {
      puts "DEBUG:$result"
      open_project $arke_dir/project_mem_ifc/project_mem_ifc.xpr
    } else {
      if { $result == "project_mem_ifc" } {
        puts "$result is already open"
      } else {
        open_project $arke_dir/project_mem_ifc/project_mem_ifc.xpr
      }
    }
  }

  proc package_project {} {
    variable arke_dir
    ipx::package_project -root_dir $arke_dir/noc_arke_mem_ifc -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
    ipx::unload_core $arke_dir/noc_arke_mem_ifc/component.xml
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $arke_dir/noc_arke_mem_ifc $arke_dir/noc_arke_mem_ifc/component.xml
  }

  proc open_ip {} {
    variable arke_dir
    ipx::open_ipxact_file $arke_dir/noc_arke_mem_ifc/component.xml
    ipx::merge_project_changes hdl_parameters [ipx::current_core]
  }

  proc set_infos {} {
    set_property vendor esa.informatik.tu-darmstadt.de [ipx::current_core]
    set_property library user [ipx::current_core]
    set_property name "arke_noc_mem_ifc" [ipx::current_core]
    set_property display_name "Mem Ifc" [ipx::current_core]
    set_property description "Mem Ifc" [ipx::current_core]
    set_property vendor_display_name "" [ipx::current_core]
  }

  proc add_synthesis_files {} {
    ipx::remove_file_group xilinx_anylanguagesynthesis [ipx::current_core]

    ipx::add_file_group -type synthesis {} [ipx::current_core]
    set_property model_name "Mem_Ifc" [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file src/Mem_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Mem_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Mem_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Full_Master.vhd [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Full_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Full_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]]
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
    set_property model_name "Mem_Ifc" [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    ipx::add_file ../common/src/STD_FIFO.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/STD_FIFO.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file src/Mem_Ifc.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files src/Mem_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files src/Mem_Ifc.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/AXI4_Full_Master.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/AXI4_Full_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/AXI4_Full_Master.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/NIC_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/NIC_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    ipx::add_file ../common/src/Arke_pkg.vhd [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
    set_property library_name work [ipx::get_files ../common/src/Arke_pkg.vhd -of_objects [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]]
  }

  
  proc set_user_parameters {{address_width 12}} {
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
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "ADDR_WIDTH" -component [ipx::current_core] ]
    set_property value 5 [ipx::get_user_parameters ADDR_WIDTH -of_objects [ipx::current_core]]
    set_property value 5 [ipx::get_hdl_parameters ADDR_WIDTH -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core] ]
    set_property value 128 [ipx::get_user_parameters DATA_WIDTH -of_objects [ipx::current_core]]
    set_property value 128 [ipx::get_hdl_parameters DATA_WIDTH -of_objects [ipx::current_core]]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "CONTROL_WIDTH" -component [ipx::current_core] ]
    set_property value 3 [ipx::get_user_parameters CONTROL_WIDTH -of_objects [ipx::current_core]]
    set_property value 3 [ipx::get_hdl_parameters CONTROL_WIDTH -of_objects [ipx::current_core]]
  }

  proc build_gui {} {
    ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "address" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "CONTROL_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 4 [ipgui::get_guiparamspec -name "DIM_X" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 5 [ipgui::get_guiparamspec -name "DIM_Y" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 6 [ipgui::get_guiparamspec -name "DIM_Z" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 7 [ipgui::get_guiparamspec -name "A4F_addr_width" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 8 [ipgui::get_guiparamspec -name "A4F_data_width" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 9 [ipgui::get_guiparamspec -name "A4F_strb_width" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
    ipgui::move_param -component [ipx::current_core] -order 10 [ipgui::get_guiparamspec -name "A4F_id_width" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
  }

  proc save_and_exit {} {
    variable arke_dir
    set_property core_revision 1 [ipx::current_core]
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    #update_ip_catalog -rebuild -repo_path $::tapascopath/toolflow/vivado/common
    ipx::unload_core $arke_dir/noc_arke_mem_ifc/component.xml
  }

  proc purge_proj {} {
    variable arke_dir
    close_project -delete
    close_project -delete
    file delete $arke_dir/project_mem_ifc
  }

  proc build {} {
    create_proj
    open_proj
    package_project
    open_ip
    set_infos
    add_synthesis_files
    add_simulation_files
    set_user_parameters
    build_gui
    save_and_exit
    purge_proj
  }
}