namespace eval arch {
  namespace export create
  namespace export get_address_map
  
  # Returns the address map of the current composition.
  # Format: <INTF> -> <BASE ADDR> <RANGE> <KIND>
  # Kind is either memory, register or master.
  # Must be implemented by Platforms.
  proc get_address_map {offset} {
    if {$offset == ""} { set offset [platform::get_pe_base_address] }
    set ret [dict create]
    set pes [lsort [get_processing_elements]]
    foreach pe $pes {
      set usrs [lsort [get_bd_addr_segs $pe/* -filter { USAGE != memory }]]
      for {set i 0} {$i < [llength $usrs]} {incr i; incr offset 0x10000} {
        set seg [lindex $usrs $i]
        set intf [get_bd_intf_pins -of_objects $seg]
        set range [get_property RANGE $seg]
        dict set ret $intf "interface $intf [format "offset 0x%08x range 0x%08x" $offset $range] kind register"
      }
      set usrs [lsort [get_bd_addr_segs $pe/* -filter { USAGE == memory }]]
      for {set i 0} {$i < [llength $usrs]} {incr i; incr offset 0x10000} {
        set seg [lindex $usrs $i]
        set intf [get_bd_intf_pins -of_objects $seg]
        set range [get_property RANGE $seg]
        dict set ret $intf "interface $intf [format "offset 0x%08x range 0x%08x" $offset $range] kind memory"
      }

      set masters [lsort [tapasco::get_aximm_interfaces $pe]]
      foreach intf $masters {
        set space [get_bd_addr_spaces -of_objects $intf]
        set offset [get_property OFFSET $space]
        if {$offset == ""} { set offset 0 }
        set range [get_property RANGE $space]
        if {$range == ""} { error "no range found on $space for $intf!" }
        dict set ret $intf "interface $intf [format "offset 0x%08x range 0x%08x" $offset $range] kind master"
      }
    }
    return $ret
  }
}
