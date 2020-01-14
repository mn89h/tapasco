#
# Copyright (C) 2018 Jens Korinth, TU Darmstadt
#
# This file is part of Tapasco (TPC).
#
# Tapasco is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Tapasco is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
#
# @file		addressmap.tcl
#apasco @brief	Helper procs to maintain an address map of components.
# @authors	J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
#
namespace eval addressmap {
  namespace export add_platform_component
  namespace export add_processing_element
  namespace export get_platform_component_bases
  namespace export get_processing_element_bases
  namespace export reset

  set platform_components [dict create]
  set processing_elements [dict create]

  proc reset {} {
    variable processing_elements
    set processing_elements [dict create]
  }

  proc get_known_platform_components {} {
    set f [open "$::env(TAPASCO_HOME_RUNTIME)/platform/include/platform_components.h" "r"]
    set fl [split [read $f] "\n"]
    foreach line $fl {
      if {[regexp {.*(PLATFORM_COMPONENT_[^\s,]*)} $line _ name]} {
        lappend components $name
      }
    }
    return $components
  }

  proc add_platform_component {name base size} {
    variable platform_components
    puts "Adding platform component $name at [format "0x%08x" $base] ..."
    if {[dict exists $platform_components $name]} {
      puts "WARNING: platform component $name already exists, overwriting!"
    }
    dict set platform_components $name $base $size
  }

  proc get_platform_component {name} {
    variable platform_components
    if {[dict exists $platform_components $name]} {
      set comp [dict get $platform_components $name]
      set base [lindex $comp 0]
      set size [lindex $comp 1]
      puts "  platform component $name found at $base ($size B)"
      return [list $base $size]
    }
    return [list 0xFFFFFFFFF 0xFFFFFFFFF]
  }

  proc get_platform_component_bases {} {
    set ret [list]
    foreach c [get_known_platform_components] {
      set comp [get_platform_component $c]
      set comp_addr [lindex $comp 0]
      set size [lindex $comp 1]
      if {$comp_addr != 0xFFFFFFFFF} {
        lappend ret $c $comp_addr $size
      }
    }
    puts "Platform component bases: $ret"
    return $ret
  }

  proc add_processing_element {slot base size} {
    variable processing_elements
    puts "Adding processing element in slot $slot with base [format "0x%08x" $base] and size $size ..."
    if {[dict exists $processing_elements $slot]} {
      puts "WARNING: processing element in slot $slot already exists, overwriting!"
    }
    dict set processing_elements $slot $base $size
  }

  proc get_processing_element {slot} {
    variable processing_elements
    if {[dict exists $processing_elements $slot]} {
      return [dict get $processing_elements $slot]
    }
    return 0
  }

  proc get_processing_element_bases {} {
    variable processing_elements
    set max_slot [lindex [lsort -integer -decreasing [dict keys $processing_elements]] 0]
    set ret [list]
    for {set i 0} {$i <= $max_slot} {incr i} {
      lappend ret [get_processing_element $i]
    }
    return $ret
  }

  proc increase_component_name {component} {
    if {[regexp {(.*)(\d+)} $component _ prefix suffix]} {
      incr suffix
      return [format "%s%d" $prefix $suffix]
    }
    return $component
  }

  proc assign_address {address_map master base {stride 0} {range 0} {component ""}} {
    foreach seg [lsort [get_bd_addr_segs -addressables -of_objects $master]] { ;# e.g. HP0_DDR_LOWOCM
      puts [format "  $master: $seg -> 0x%08x (range: 0x%08x)" $base $range]
      set sintf [get_bd_intf_pins -of_objects $seg]
      set srange $range
      if {$range <= 0} { set srange [get_property RANGE $seg] } ;# for pynq HP0_DDR_LOWOCM 0x2000000
      set kind [get_property USAGE $seg]
      dict set address_map $sintf "interface $sintf offset $base range $srange kind $kind"
      if {[string compare $component ""] != 0} {
        add_platform_component $component $base $srange
        set component [increase_component_name $component]
      }
      if {$stride == 0} { incr base $srange } else { incr base $stride }
    }
    return $address_map
  }

  proc apply_address_map_mods {map} {
    foreach p [lsort [info commands ::platform::modify_address_map_*]] {
      puts "  found address map extension proc: $p"
      set map [eval {$p} {$map}]
    }
    return $map
  }

  proc construct_address_map {{map ""}} {
    set arch_ifc [::arch::get_arch_name]
    #if {$arch_ifc == "axi4mm-noc"} {
    #  set pe_base 0x00000000
    #} {
    #}
      set pe_base [::platform::get_pe_base_address]
    if {$map == ""} { set map [::platform::get_address_map $pe_base $arch_ifc] }
    set map [apply_address_map_mods $map]
    set ignored [::platform::get_ignored_segments]
    set seg_i 0
    foreach space [get_bd_addr_spaces] {
      puts "space: $space"
      set intfs [get_bd_intf_pins -quiet -of_objects $space -filter { MODE == Master }]
      foreach intf $intfs {
        set segs [get_bd_addr_segs -of_objects $intf]
        foreach seg $segs {
          puts "Deleting pre-mapped $seg"
          delete_bd_objs $seg
        }
        set segs [get_bd_addr_segs -excluded -of_objects $intf]
        foreach seg $segs {
          puts "Deleting excluded $seg"
          delete_bd_objs $seg
        }
        set segs [get_bd_addr_segs -addressables -of_objects $intf]
        foreach seg $segs {
          if {[lsearch $ignored $seg] >= 0 } {
            puts "Skipping ignored segment $seg"
          } else {
            puts "  seg: $seg"
            set sintf [get_bd_intf_pins -quiet -of_objects $seg]
            if {[catch {dict get $map $intf}]} {
              if {[catch {dict get $map $sintf}]} { ;# e.g. noc internal connection from pe to pe_ifc's reg0
                puts "    neither $intf nor $sintf were found in address map for $seg: $::errorInfo"
                puts "    assuming internal connection, setting values as found in segment:"
                set range  [get_property RANGE $seg]
                if {$range eq ""} {
                  puts "      found no range on segment $seg, setting to max"
                  report_property $seg
                  set range [expr "1 << 64"]
                }
                puts "      range: $range"
                set offset [get_property OFFSET $seg]
                if {$offset eq ""} {
                  puts "      found no offset on segment $seg, setting to zero"
                  report_property $seg
                  set offset 0
                }
                puts "      offset: $offset"
                set me [dict create "range" $range "offset" $offset "space" $space seg "$seg"]
              } else {
                set me [dict get $map $sintf]
              }
            } else {
              set me [dict get $map $intf]
            }
            puts "    address map info: $me]"
            set range  [expr "max([dict get $me range], 4096)"]
            if {[expr {[get_property Name $intf] == "A4L_AXI"}]} { ;# axi4mm-noc pe offset
              set offset 0
            } {
              set offset [expr "max([dict get $me "offset"], [get_property OFFSET $intf])"]
            }
            set range  [expr "min($range, [get_property RANGE $intf])"]
            puts "      range: $range"
            puts "      offset: $offset"
            puts "      space: $space"
            puts "      seg: $seg"
            if {[expr "(1 << 64) == $range"]} { set range "16E" }
            create_bd_addr_seg -quiet \
              -offset $offset \
              -range $range \
              $space \
              $seg \
              [format "AM_SEG_%03d" $seg_i]
            incr seg_i
          }
        }
      }
    }
    #assign_bd_address ;# mapping unmapped target_ips
  }
}
