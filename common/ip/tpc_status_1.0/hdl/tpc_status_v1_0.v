//
// Copyright (C) 2014 Jens Korinth, TU Darmstadt
//
// This file is part of ThreadPoolComposer (TPC).
//
// ThreadPoolComposer is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ThreadPoolComposer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with ThreadPoolComposer.  If not, see <http://www.gnu.org/licenses/>.
//
//! @file   tpc_status_v1_0.v
//! @brief  AXILite register slave containing status information about
//!         the bitstream, e.g., the configured kernel id in each slot.
//! @author J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
//!

`timescale 1 ns / 1 ps

	module tpc_status_v1_0 #
	(
    parameter integer C_INTC_COUNT       = 32'd01,
    parameter integer C_SLOT_KERNEL_ID_1 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_2 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_3 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_4 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_5 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_6 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_7 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_8 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_9 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_10 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_11 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_12 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_13 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_14 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_15 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_16 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_17 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_18 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_19 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_20 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_21 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_22 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_23 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_24 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_25 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_26 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_27 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_28 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_29 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_30 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_31 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_32 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_33 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_34 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_35 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_36 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_37 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_38 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_39 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_40 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_41 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_42 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_43 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_44 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_45 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_46 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_47 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_48 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_49 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_50 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_51 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_52 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_53 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_54 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_55 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_56 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_57 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_58 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_59 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_60 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_61 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_62 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_63 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_64 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_65 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_66 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_67 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_68 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_69 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_70 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_71 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_72 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_73 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_74 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_75 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_76 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_77 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_78 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_79 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_80 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_81 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_82 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_83 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_84 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_85 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_86 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_87 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_88 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_89 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_90 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_91 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_92 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_93 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_94 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_95 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_96 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_97 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_98 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_99 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_100 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_101 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_102 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_103 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_104 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_105 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_106 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_107 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_108 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_109 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_110 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_111 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_112 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_113 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_114 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_115 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_116 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_117 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_118 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_119 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_120 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_121 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_122 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_123 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_124 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_125 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_126 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_127 = 32'b00,
    parameter integer C_SLOT_KERNEL_ID_128 = 32'b00,
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 12
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	tpc_status_v1_0_S00_AXI # (
    .C_INTC_COUNT(C_INTC_COUNT),
    .C_SLOT_KERNEL_ID_1(C_SLOT_KERNEL_ID_1),
    .C_SLOT_KERNEL_ID_2(C_SLOT_KERNEL_ID_2),
    .C_SLOT_KERNEL_ID_3(C_SLOT_KERNEL_ID_3),
    .C_SLOT_KERNEL_ID_4(C_SLOT_KERNEL_ID_4),
    .C_SLOT_KERNEL_ID_5(C_SLOT_KERNEL_ID_5),
    .C_SLOT_KERNEL_ID_6(C_SLOT_KERNEL_ID_6),
    .C_SLOT_KERNEL_ID_7(C_SLOT_KERNEL_ID_7),
    .C_SLOT_KERNEL_ID_8(C_SLOT_KERNEL_ID_8),
    .C_SLOT_KERNEL_ID_9(C_SLOT_KERNEL_ID_9),
    .C_SLOT_KERNEL_ID_10(C_SLOT_KERNEL_ID_10),
    .C_SLOT_KERNEL_ID_11(C_SLOT_KERNEL_ID_11),
    .C_SLOT_KERNEL_ID_12(C_SLOT_KERNEL_ID_12),
    .C_SLOT_KERNEL_ID_13(C_SLOT_KERNEL_ID_13),
    .C_SLOT_KERNEL_ID_14(C_SLOT_KERNEL_ID_14),
    .C_SLOT_KERNEL_ID_15(C_SLOT_KERNEL_ID_15),
    .C_SLOT_KERNEL_ID_16(C_SLOT_KERNEL_ID_16),
    .C_SLOT_KERNEL_ID_17(C_SLOT_KERNEL_ID_17),
    .C_SLOT_KERNEL_ID_18(C_SLOT_KERNEL_ID_18),
    .C_SLOT_KERNEL_ID_19(C_SLOT_KERNEL_ID_19),
    .C_SLOT_KERNEL_ID_20(C_SLOT_KERNEL_ID_20),
    .C_SLOT_KERNEL_ID_21(C_SLOT_KERNEL_ID_21),
    .C_SLOT_KERNEL_ID_22(C_SLOT_KERNEL_ID_22),
    .C_SLOT_KERNEL_ID_23(C_SLOT_KERNEL_ID_23),
    .C_SLOT_KERNEL_ID_24(C_SLOT_KERNEL_ID_24),
    .C_SLOT_KERNEL_ID_25(C_SLOT_KERNEL_ID_25),
    .C_SLOT_KERNEL_ID_26(C_SLOT_KERNEL_ID_26),
    .C_SLOT_KERNEL_ID_27(C_SLOT_KERNEL_ID_27),
    .C_SLOT_KERNEL_ID_28(C_SLOT_KERNEL_ID_28),
    .C_SLOT_KERNEL_ID_29(C_SLOT_KERNEL_ID_29),
    .C_SLOT_KERNEL_ID_30(C_SLOT_KERNEL_ID_30),
    .C_SLOT_KERNEL_ID_31(C_SLOT_KERNEL_ID_31),
    .C_SLOT_KERNEL_ID_32(C_SLOT_KERNEL_ID_32),
    .C_SLOT_KERNEL_ID_33(C_SLOT_KERNEL_ID_33),
    .C_SLOT_KERNEL_ID_34(C_SLOT_KERNEL_ID_34),
    .C_SLOT_KERNEL_ID_35(C_SLOT_KERNEL_ID_35),
    .C_SLOT_KERNEL_ID_36(C_SLOT_KERNEL_ID_36),
    .C_SLOT_KERNEL_ID_37(C_SLOT_KERNEL_ID_37),
    .C_SLOT_KERNEL_ID_38(C_SLOT_KERNEL_ID_38),
    .C_SLOT_KERNEL_ID_39(C_SLOT_KERNEL_ID_39),
    .C_SLOT_KERNEL_ID_40(C_SLOT_KERNEL_ID_40),
    .C_SLOT_KERNEL_ID_41(C_SLOT_KERNEL_ID_41),
    .C_SLOT_KERNEL_ID_42(C_SLOT_KERNEL_ID_42),
    .C_SLOT_KERNEL_ID_43(C_SLOT_KERNEL_ID_43),
    .C_SLOT_KERNEL_ID_44(C_SLOT_KERNEL_ID_44),
    .C_SLOT_KERNEL_ID_45(C_SLOT_KERNEL_ID_45),
    .C_SLOT_KERNEL_ID_46(C_SLOT_KERNEL_ID_46),
    .C_SLOT_KERNEL_ID_47(C_SLOT_KERNEL_ID_47),
    .C_SLOT_KERNEL_ID_48(C_SLOT_KERNEL_ID_48),
    .C_SLOT_KERNEL_ID_49(C_SLOT_KERNEL_ID_49),
    .C_SLOT_KERNEL_ID_50(C_SLOT_KERNEL_ID_50),
    .C_SLOT_KERNEL_ID_51(C_SLOT_KERNEL_ID_51),
    .C_SLOT_KERNEL_ID_52(C_SLOT_KERNEL_ID_52),
    .C_SLOT_KERNEL_ID_53(C_SLOT_KERNEL_ID_53),
    .C_SLOT_KERNEL_ID_54(C_SLOT_KERNEL_ID_54),
    .C_SLOT_KERNEL_ID_55(C_SLOT_KERNEL_ID_55),
    .C_SLOT_KERNEL_ID_56(C_SLOT_KERNEL_ID_56),
    .C_SLOT_KERNEL_ID_57(C_SLOT_KERNEL_ID_57),
    .C_SLOT_KERNEL_ID_58(C_SLOT_KERNEL_ID_58),
    .C_SLOT_KERNEL_ID_59(C_SLOT_KERNEL_ID_59),
    .C_SLOT_KERNEL_ID_60(C_SLOT_KERNEL_ID_60),
    .C_SLOT_KERNEL_ID_61(C_SLOT_KERNEL_ID_61),
    .C_SLOT_KERNEL_ID_62(C_SLOT_KERNEL_ID_62),
    .C_SLOT_KERNEL_ID_63(C_SLOT_KERNEL_ID_63),
    .C_SLOT_KERNEL_ID_64(C_SLOT_KERNEL_ID_64),
    .C_SLOT_KERNEL_ID_65(C_SLOT_KERNEL_ID_65),
    .C_SLOT_KERNEL_ID_66(C_SLOT_KERNEL_ID_66),
    .C_SLOT_KERNEL_ID_67(C_SLOT_KERNEL_ID_67),
    .C_SLOT_KERNEL_ID_68(C_SLOT_KERNEL_ID_68),
    .C_SLOT_KERNEL_ID_69(C_SLOT_KERNEL_ID_69),
    .C_SLOT_KERNEL_ID_70(C_SLOT_KERNEL_ID_70),
    .C_SLOT_KERNEL_ID_71(C_SLOT_KERNEL_ID_71),
    .C_SLOT_KERNEL_ID_72(C_SLOT_KERNEL_ID_72),
    .C_SLOT_KERNEL_ID_73(C_SLOT_KERNEL_ID_73),
    .C_SLOT_KERNEL_ID_74(C_SLOT_KERNEL_ID_74),
    .C_SLOT_KERNEL_ID_75(C_SLOT_KERNEL_ID_75),
    .C_SLOT_KERNEL_ID_76(C_SLOT_KERNEL_ID_76),
    .C_SLOT_KERNEL_ID_77(C_SLOT_KERNEL_ID_77),
    .C_SLOT_KERNEL_ID_78(C_SLOT_KERNEL_ID_78),
    .C_SLOT_KERNEL_ID_79(C_SLOT_KERNEL_ID_79),
    .C_SLOT_KERNEL_ID_80(C_SLOT_KERNEL_ID_80),
    .C_SLOT_KERNEL_ID_81(C_SLOT_KERNEL_ID_81),
    .C_SLOT_KERNEL_ID_82(C_SLOT_KERNEL_ID_82),
    .C_SLOT_KERNEL_ID_83(C_SLOT_KERNEL_ID_83),
    .C_SLOT_KERNEL_ID_84(C_SLOT_KERNEL_ID_84),
    .C_SLOT_KERNEL_ID_85(C_SLOT_KERNEL_ID_85),
    .C_SLOT_KERNEL_ID_86(C_SLOT_KERNEL_ID_86),
    .C_SLOT_KERNEL_ID_87(C_SLOT_KERNEL_ID_87),
    .C_SLOT_KERNEL_ID_88(C_SLOT_KERNEL_ID_88),
    .C_SLOT_KERNEL_ID_89(C_SLOT_KERNEL_ID_89),
    .C_SLOT_KERNEL_ID_90(C_SLOT_KERNEL_ID_90),
    .C_SLOT_KERNEL_ID_91(C_SLOT_KERNEL_ID_91),
    .C_SLOT_KERNEL_ID_92(C_SLOT_KERNEL_ID_92),
    .C_SLOT_KERNEL_ID_93(C_SLOT_KERNEL_ID_93),
    .C_SLOT_KERNEL_ID_94(C_SLOT_KERNEL_ID_94),
    .C_SLOT_KERNEL_ID_95(C_SLOT_KERNEL_ID_95),
    .C_SLOT_KERNEL_ID_96(C_SLOT_KERNEL_ID_96),
    .C_SLOT_KERNEL_ID_97(C_SLOT_KERNEL_ID_97),
    .C_SLOT_KERNEL_ID_98(C_SLOT_KERNEL_ID_98),
    .C_SLOT_KERNEL_ID_99(C_SLOT_KERNEL_ID_99),
    .C_SLOT_KERNEL_ID_100(C_SLOT_KERNEL_ID_100),
    .C_SLOT_KERNEL_ID_101(C_SLOT_KERNEL_ID_101),
    .C_SLOT_KERNEL_ID_102(C_SLOT_KERNEL_ID_102),
    .C_SLOT_KERNEL_ID_103(C_SLOT_KERNEL_ID_103),
    .C_SLOT_KERNEL_ID_104(C_SLOT_KERNEL_ID_104),
    .C_SLOT_KERNEL_ID_105(C_SLOT_KERNEL_ID_105),
    .C_SLOT_KERNEL_ID_106(C_SLOT_KERNEL_ID_106),
    .C_SLOT_KERNEL_ID_107(C_SLOT_KERNEL_ID_107),
    .C_SLOT_KERNEL_ID_108(C_SLOT_KERNEL_ID_108),
    .C_SLOT_KERNEL_ID_109(C_SLOT_KERNEL_ID_109),
    .C_SLOT_KERNEL_ID_110(C_SLOT_KERNEL_ID_110),
    .C_SLOT_KERNEL_ID_111(C_SLOT_KERNEL_ID_111),
    .C_SLOT_KERNEL_ID_112(C_SLOT_KERNEL_ID_112),
    .C_SLOT_KERNEL_ID_113(C_SLOT_KERNEL_ID_113),
    .C_SLOT_KERNEL_ID_114(C_SLOT_KERNEL_ID_114),
    .C_SLOT_KERNEL_ID_115(C_SLOT_KERNEL_ID_115),
    .C_SLOT_KERNEL_ID_116(C_SLOT_KERNEL_ID_116),
    .C_SLOT_KERNEL_ID_117(C_SLOT_KERNEL_ID_117),
    .C_SLOT_KERNEL_ID_118(C_SLOT_KERNEL_ID_118),
    .C_SLOT_KERNEL_ID_119(C_SLOT_KERNEL_ID_119),
    .C_SLOT_KERNEL_ID_120(C_SLOT_KERNEL_ID_120),
    .C_SLOT_KERNEL_ID_121(C_SLOT_KERNEL_ID_121),
    .C_SLOT_KERNEL_ID_122(C_SLOT_KERNEL_ID_122),
    .C_SLOT_KERNEL_ID_123(C_SLOT_KERNEL_ID_123),
    .C_SLOT_KERNEL_ID_124(C_SLOT_KERNEL_ID_124),
    .C_SLOT_KERNEL_ID_125(C_SLOT_KERNEL_ID_125),
    .C_SLOT_KERNEL_ID_126(C_SLOT_KERNEL_ID_126),
    .C_SLOT_KERNEL_ID_127(C_SLOT_KERNEL_ID_127),
    .C_SLOT_KERNEL_ID_128(C_SLOT_KERNEL_ID_128),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) tpc_status_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
