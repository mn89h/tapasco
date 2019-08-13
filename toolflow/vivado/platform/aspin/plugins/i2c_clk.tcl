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
# @file   i2c_clk.tcl
# @brief  Plugin to connect additional i2c clock signals.
# @author C. Heinz, TU Darmstadt (heinz@esa.tu-darmstadt.de)
#
namespace eval i2c_clk {

  proc connect_i2c_clocks {{args {}}} {
    set i2c_clks [get_bd_pins */i2_clk]
    if {[llength i2c_clks] > 1} {
      puts "Connecting i2c clocks."
      connect_bd_net [get_bd_pins */i2c_clk]
    }
    return {}
  }
}

tapasco::register_plugin "platform::i2c_clk::connect_i2c_clocks" "post-platform"
