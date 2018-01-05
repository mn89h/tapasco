module ClockResetsMasterBridge(
	input i_host_clk,
	input i_host_peripheral_resetn,
	input i_host_peripheral_reset,
	input i_host_interconnect_resetn,
	input i_host_interconnect_reset,
	input i_design_clk,
	input i_design_peripheral_resetn,
	input i_design_peripheral_reset,
	input i_design_interconnect_resetn,
	input i_design_interconnect_reset,
	input i_mem_clk,
	input i_mem_peripheral_resetn,
	input i_mem_peripheral_reset,
	input i_mem_interconnect_resetn,
	input i_mem_interconnect_reset,
	output o_host_clk,
	output o_host_peripheral_resetn,
	output o_host_peripheral_reset,
	output o_host_interconnect_resetn,
	output o_host_interconnect_reset,
	output o_design_clk,
	output o_design_peripheral_resetn,
	output o_design_peripheral_reset,
	output o_design_interconnect_resetn,
	output o_design_interconnect_reset,
	output o_mem_clk,
	output o_mem_peripheral_resetn,
	output o_mem_peripheral_reset,
	output o_mem_interconnect_resetn,
	output o_mem_interconnect_reset
);

	assign o_host_clk = i_host_clk;
	assign o_host_peripheral_resetn = i_host_peripheral_resetn;
	assign o_host_peripheral_reset = i_host_peripheral_reset;
	assign o_host_interconnect_resetn = i_host_interconnect_resetn;
	assign o_host_interconnect_reset = i_host_interconnect_reset;
	assign o_design_clk = i_design_clk;
	assign o_design_peripheral_resetn = i_design_peripheral_resetn;
	assign o_design_peripheral_reset = i_design_peripheral_reset;
	assign o_design_interconnect_resetn = i_design_interconnect_resetn;
	assign o_design_interconnect_reset = i_design_interconnect_reset;
	assign o_mem_clk = i_mem_clk;
	assign o_mem_peripheral_resetn = i_mem_peripheral_resetn;
	assign o_mem_peripheral_reset = i_mem_peripheral_reset;
	assign o_mem_interconnect_resetn = i_mem_interconnect_resetn;
	assign o_mem_interconnect_reset = i_mem_interconnect_reset;
	
endmodule
