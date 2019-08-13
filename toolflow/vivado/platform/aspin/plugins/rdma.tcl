#
# Copyright (C) 2018 Carsten Heinz, TU Darmstadt
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
# @file   rdma.tcl
# @brief  Plugin to connect RDMA axi stream interface.
# @author C. Heinz, TU Darmstadt (heinz@esa.tu-darmstadt.de)
#
namespace eval extoll_rdma {

  proc connect_rdma_bypass {{args {}}} {
    set m_axis_tx [get_bd_intf_pins */m_axis_tx_ntl]
    set s_axis_tx [get_bd_intf_pins */s_axis_rx_htl]
    set m_axis_rx [get_bd_intf_pins */m_axis_tx_htl]
    set s_axis_rx [get_bd_intf_pins */s_axis_rx_ntl]
    if {[llength m_axis_tx] == 1 && [llength s_axis_tx] == 1} {
      puts "Connecting Extoll RDMA TX bypass."
      connect_bd_intf_net $m_axis_tx $s_axis_tx
    }
    if {[llength m_axis_rx] == 1 && [llength s_axis_rx] == 1} {
      puts "Connecting Extoll RDMA RX bypass."
      connect_bd_intf_net $m_axis_rx $s_axis_rx
    }
    return {}
  }
}

tapasco::register_plugin "platform::extoll_rdma::connect_rdma_bypass" "post-platform"
