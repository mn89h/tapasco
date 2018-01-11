#
# Copyright (C) 2014 David de la Chevallerie, TU Darmstadt
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
#has to be scoped to the dual_dma instance

set dma [get_cells -hier *dual_dma]
set m32 [get_pins -of_objects $dma -filter { NAME =~ *m32_axi_aclk }]
set m64 [get_pins -of_objects $dma -filter { NAME =~ *m64_axi_aclk }]
set m32_clk [get_clocks -of_objects $m32]
set m64_clk [get_clocks -of_objects $m64]
set_false_path -through [get_pins -of_objects $dma -filter {NAME =~ *_axi_aresetn}] -to [filter [get_cells -hierarchical -filter {NAME =~ */rstblk/*}] {IS_SEQUENTIAL}]
set_max_delay -from [filter [all_fanout -from $m32 -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from $m64 -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $m32_clk]
set_max_delay -from [filter [all_fanout -from $m64 -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from $m32 -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $m64_clk]
set_disable_timing -from CLK -to O [filter [all_fanout -from $m32 -flat -endpoints_only -only_cells] {PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==LUTRAM}]
set_disable_timing -from CLK -to O [filter [all_fanout -from $m64 -flat -endpoints_only -only_cells] {PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==LUTRAM}]

set g [get_pins -of_objects $dma -filter { NAME =~ *s_axi_aclk }]
set g_clk [get_clocks -of_objects $g]

set_max_delay -from [filter [all_fanout -from $m32 -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from $g_clk -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $m32_clk]
set_max_delay -from [filter [all_fanout -from $g -flat -endpoints_only] {IS_LEAF}] -to [filter [all_fanout -from $m32 -flat -only_cells] {IS_SEQUENTIAL && (NAME !~ *dout_i_reg[*])}] -datapath_only [get_property -min PERIOD $g_clk]
set_disable_timing -from CLK -to O [filter [all_fanout -from $g -flat -endpoints_only -only_cells] {PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==LUTRAM}]

