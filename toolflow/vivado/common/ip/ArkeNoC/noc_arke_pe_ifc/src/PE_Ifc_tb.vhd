-------------------------------------------------------------------------------
-- Title      : Testbench for design "PE_Ifc"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : PE_Ifc_tb.vhd
-- Author     : Malte Nilges  <malte@DESKTOP-TF6PRO>
-- Company    : 
-- Created    : 2020-01-09
-- Last update: 2020-01-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-01-09  1.0      malte	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;
use work.NIC_pkg.all;

-------------------------------------------------------------------------------

entity PE_Ifc_tb is

end entity PE_Ifc_tb;

-------------------------------------------------------------------------------

architecture tb1 of PE_Ifc_tb is

  -- component generics
  constant A4L_addr_width  : integer := 6;
  constant A4L_data_width  : integer := 32;
  constant A4F_addr_width  : integer := 32;
  constant A4F_data_width  : integer := 32;
  constant A4F_id_width    : integer := 0;
  constant A4F_strb_width  : integer := 4;
  constant NoC_address     : std_logic_vector := "010000";
  constant NoC_address_mem : std_logic_vector := "100000";
  constant NoC_address_arch: std_logic_vector := "000000";

  -- component ports
  signal clk             : std_logic := '1';
  signal rst             : std_logic := '1';
  signal A4L_AXI_arvalid : std_logic;
  signal A4L_AXI_arready : std_logic;
  signal A4L_AXI_araddr  : std_logic_vector(A4L_addr_width - 1 + 3 downto 3);
  signal A4L_AXI_arprot  : std_logic_vector(2 downto 0);
  signal A4L_AXI_awvalid : std_logic;
  signal A4L_AXI_awready : std_logic;
  signal A4L_AXI_awaddr  : std_logic_vector(A4L_addr_width - 1 + 3 downto 3);
  signal A4L_AXI_awprot  : std_logic_vector(2 downto 0);
  signal A4L_AXI_wvalid  : std_logic;
  signal A4L_AXI_wready  : std_logic;
  signal A4L_AXI_wdata   : std_logic_vector(A4L_data_width - 1 + 4 downto 4);
  signal A4L_AXI_wstrb   : std_logic_vector(3 downto 0);
  signal A4L_AXI_rready  : std_logic;
  signal A4L_AXI_rvalid  : std_logic;
  signal A4L_AXI_rdata   : std_logic_vector(A4L_data_width - 1 + 2 downto 2);
  signal A4L_AXI_rresp   : std_logic_vector(1 downto 0);
  signal A4L_AXI_bready  : std_logic;
  signal A4L_AXI_bvalid  : std_logic;
  signal A4L_AXI_bresp   : std_logic_vector(1 downto 0);
  signal A4F_AXI_arvalid : std_logic;
  signal A4F_AXI_arready : std_logic;
  signal A4F_AXI_araddr  : std_logic_vector(A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25);
  signal A4F_AXI_arid    : std_logic_vector(A4F_id_width - 1 + 25 downto 25);
  signal A4F_AXI_arlen   : std_logic_vector(24 downto 17);
  signal A4F_AXI_arsize  : std_logic_vector(16 downto 14);
  signal A4F_AXI_arburst : std_logic_vector(13 downto 12);
  signal A4F_AXI_arlock  : std_logic_vector(11 downto 11);
  signal A4F_AXI_arcache : std_logic_vector(10 downto 7);
  signal A4F_AXI_arprot  : std_logic_vector(6 downto 4);
  signal A4F_AXI_arqos   : std_logic_vector(3 downto 0);
  signal A4F_AXI_awvalid : std_logic;
  signal A4F_AXI_awready : std_logic;
  signal A4F_AXI_awaddr  : std_logic_vector(A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25);
  signal A4F_AXI_awid    : std_logic_vector(A4F_id_width - 1 + 25 downto 25);
  signal A4F_AXI_awlen   : std_logic_vector(24 downto 17);
  signal A4F_AXI_awsize  : std_logic_vector(16 downto 14);
  signal A4F_AXI_awburst : std_logic_vector(13 downto 12);
  signal A4F_AXI_awlock  : std_logic_vector(11 downto 11);
  signal A4F_AXI_awcache : std_logic_vector(10 downto 7);
  signal A4F_AXI_awprot  : std_logic_vector(6 downto 4);
  signal A4F_AXI_awqos   : std_logic_vector(3 downto 0);
  signal A4F_AXI_wvalid  : std_logic;
  signal A4F_AXI_wready  : std_logic;
  signal A4F_AXI_wdata   : std_logic_vector(A4F_addr_width - 1 + A4F_strb_width + 1 downto A4F_strb_width + 1);
  signal A4F_AXI_wstrb   : std_logic_vector(A4F_strb_width - 1 + 1 downto 1);
  signal A4F_AXI_wlast   : std_logic_vector(0 downto 0);
  signal A4F_AXI_rready  : std_logic;
  signal A4F_AXI_rvalid  : std_logic;
  signal A4F_AXI_rdata   : std_logic_vector(A4F_data_width - 1 + A4F_id_width + 3 downto A4F_id_width + 3);
  signal A4F_AXI_rid     : std_logic_vector(A4F_id_width - 1 + 3 downto 3);
  signal A4F_AXI_rresp   : std_logic_vector(2 downto 1);
  signal A4F_AXI_rlast   : std_logic_vector(0 downto 0);
  signal A4F_AXI_bready  : std_logic;
  signal A4F_AXI_bvalid  : std_logic;
  signal A4F_AXI_bid     : std_logic_vector(A4F_id_width - 1 + 2 downto 2);
  signal A4F_AXI_bresp   : std_logic_vector(1 downto 0);
  signal dataOut         : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal controlOut      : std_logic_vector(CONTROL_WIDTH - 1 downto 0);
  signal dataIn          : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal controlIn       : std_logic_vector(CONTROL_WIDTH - 1 downto 0);

  signal Cycle       : natural := 1;
  
  constant A4L_rdrqa_width    : natural := A4L_addr_width + 3;
  constant A4L_wrrqa_width    : natural := A4L_addr_width + 3;
  constant A4L_wrrqd_width    : natural := A4L_data_width + 4;
  constant A4L_rdrsp_width    : natural := A4L_data_width + 2;
  constant A4L_wrrsp_width    : natural := 2;

  constant DIM_X_W    : integer := Log2(DIM_X);
  constant DIM_Y_W    : integer := Log2(DIM_Y);
  constant DIM_Z_W    : integer := Log2(DIM_Z);
  constant ADDR_W     : integer := DIM_X_W + DIM_Y_W + DIM_Z_W;

begin  -- architecture tb1

  -- component instantiation
  DUT: entity work.PE_Ifc
    generic map (
      A4L_addr_width   => A4L_addr_width,
      A4L_data_width   => A4L_data_width,
      A4F_addr_width   => A4F_addr_width,
      A4F_data_width   => A4F_data_width,
      A4F_id_width     => A4F_id_width,
      A4F_strb_width   => A4F_strb_width,
      NoC_address      => NoC_address,
      NoC_address_mem  => NoC_address_mem,
      NoC_address_arch => NoC_address_arch)
    port map (
      clk             => clk,
      rst             => rst,
      A4L_AXI_arvalid => A4L_AXI_arvalid,
      A4L_AXI_arready => A4L_AXI_arready,
      A4L_AXI_araddr  => A4L_AXI_araddr,
      A4L_AXI_arprot  => A4L_AXI_arprot,
      A4L_AXI_awvalid => A4L_AXI_awvalid,
      A4L_AXI_awready => A4L_AXI_awready,
      A4L_AXI_awaddr  => A4L_AXI_awaddr,
      A4L_AXI_awprot  => A4L_AXI_awprot,
      A4L_AXI_wvalid  => A4L_AXI_wvalid,
      A4L_AXI_wready  => A4L_AXI_wready,
      A4L_AXI_wdata   => A4L_AXI_wdata,
      A4L_AXI_wstrb   => A4L_AXI_wstrb,
      A4L_AXI_rready  => A4L_AXI_rready,
      A4L_AXI_rvalid  => A4L_AXI_rvalid,
      A4L_AXI_rdata   => A4L_AXI_rdata,
      A4L_AXI_rresp   => A4L_AXI_rresp,
      A4L_AXI_bready  => A4L_AXI_bready,
      A4L_AXI_bvalid  => A4L_AXI_bvalid,
      A4L_AXI_bresp   => A4L_AXI_bresp,
      A4F_AXI_arvalid => A4F_AXI_arvalid,
      A4F_AXI_arready => A4F_AXI_arready,
      A4F_AXI_araddr  => A4F_AXI_araddr,
      A4F_AXI_arid    => A4F_AXI_arid,
      A4F_AXI_arlen   => A4F_AXI_arlen,
      A4F_AXI_arsize  => A4F_AXI_arsize,
      A4F_AXI_arburst => A4F_AXI_arburst,
      A4F_AXI_arlock  => A4F_AXI_arlock,
      A4F_AXI_arcache => A4F_AXI_arcache,
      A4F_AXI_arprot  => A4F_AXI_arprot,
      A4F_AXI_arqos   => A4F_AXI_arqos,
      A4F_AXI_awvalid => A4F_AXI_awvalid,
      A4F_AXI_awready => A4F_AXI_awready,
      A4F_AXI_awaddr  => A4F_AXI_awaddr,
      A4F_AXI_awid    => A4F_AXI_awid,
      A4F_AXI_awlen   => A4F_AXI_awlen,
      A4F_AXI_awsize  => A4F_AXI_awsize,
      A4F_AXI_awburst => A4F_AXI_awburst,
      A4F_AXI_awlock  => A4F_AXI_awlock,
      A4F_AXI_awcache => A4F_AXI_awcache,
      A4F_AXI_awprot  => A4F_AXI_awprot,
      A4F_AXI_awqos   => A4F_AXI_awqos,
      A4F_AXI_wvalid  => A4F_AXI_wvalid,
      A4F_AXI_wready  => A4F_AXI_wready,
      A4F_AXI_wdata   => A4F_AXI_wdata,
      A4F_AXI_wstrb   => A4F_AXI_wstrb,
      A4F_AXI_wlast   => A4F_AXI_wlast,
      A4F_AXI_rready  => A4F_AXI_rready,
      A4F_AXI_rvalid  => A4F_AXI_rvalid,
      A4F_AXI_rdata   => A4F_AXI_rdata,
      A4F_AXI_rid     => A4F_AXI_rid,
      A4F_AXI_rresp   => A4F_AXI_rresp,
      A4F_AXI_rlast   => A4F_AXI_rlast,
      A4F_AXI_bready  => A4F_AXI_bready,
      A4F_AXI_bvalid  => A4F_AXI_bvalid,
      A4F_AXI_bid     => A4F_AXI_bid,
      A4F_AXI_bresp   => A4F_AXI_bresp,
      dataOut         => dataOut,
      controlOut      => controlOut,
      dataIn          => dataIn,
      controlIn       => controlIn);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc : process

  variable vec_wrrqa      : std_logic_vector(A4L_wrrqa_width - 1 downto 0);
  variable vec_wrrqd      : std_logic_vector(A4L_wrrqd_width - 1 downto 0);
  variable vec_rdrqa      : std_logic_vector(A4L_rdrqa_width - 1 downto 0);
  variable address        : std_logic_vector(ADDR_W - 1 downto 0);
  
  --req in
  variable A4L_AXI_arready_value    : std_logic;
  variable A4L_AXI_awready_value    : std_logic;
  variable A4L_AXI_wready_value     : std_logic;

  --data in
  variable dataIn_value         : std_logic_vector(DATA_WIDTH - 1 downto 0);
  variable controlIn_value      : std_logic_vector(CONTROL_WIDTH - 1 downto 0);

  --rsp in
  variable A4L_AXI_rvalid_value     : std_logic;
  variable A4L_AXI_rdata_value      : std_logic_vector( A4L_data_width - 1 downto 0 );
  variable A4L_AXI_rresp_value      : std_logic_vector( 1 downto 0 );
  variable A4L_AXI_bvalid_value     : std_logic;
  variable A4L_AXI_bresp_value      : std_logic_vector( 1 downto 0 );
  
  procedure check_cycle is
  begin
    report "CYCLE " & to_string(Cycle) & " --------------------------------------";
    Cycle <= Cycle + 1;

    --req in
    A4L_AXI_arready     <= A4L_AXI_arready_value;
    A4L_AXI_awready     <= A4L_AXI_awready_value;
    A4L_AXI_wready      <= A4L_AXI_wready_value;
    
    --data in
    dataIn          <= dataIn_value;
    controlIn       <= controlIn_value;

    --rsp in
    A4L_AXI_rvalid      <= A4L_AXI_rvalid_value;
    A4L_AXI_rdata       <= A4L_AXI_rdata_value;
    A4L_AXI_rresp       <= A4L_AXI_rresp_value;
    A4L_AXI_bvalid      <= A4L_AXI_bvalid_value;
    A4L_AXI_bresp       <= A4L_AXI_bresp_value;

    wait until rising_edge(clk);

  end procedure check_cycle;

  begin
    -- insert signal assignments here

    wait for 30 ns;
    rst <= '0';
    wait until rising_edge(clk);

    -------------------------------------------------------------- 001
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    dataIn_value          := (others => '0');
    controlIn_value       := "100";

    A4L_AXI_rvalid_value      := '1';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    -------------------------------------------------------------- 002
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- AW 40000004
    dataIn_value          := "01000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000100000010000";
    controlIn_value       := "110";

    A4L_AXI_rvalid_value      := '1';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 003
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- W 00000001
    dataIn_value          := "01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111010000";
    controlIn_value       := "111";

    A4L_AXI_rvalid_value      := '1';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 004
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- AW 40000008
    dataIn_value          := "01000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000001000000010000";
    controlIn_value       := "110";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 005
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- W 00000001
    dataIn_value          := "01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111010000";
    controlIn_value       := "111";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 006
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- AW 400000c0
    dataIn_value          := "01000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000001100000010000";
    controlIn_value       := "110";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 007
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- W 00000000
    dataIn_value          := "01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111010000";
    controlIn_value       := "111";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 008
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- AW 40000020
    dataIn_value          := "01000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000100000000010000";
    controlIn_value       := "110";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    -------------------------------------------------------------- 007
    -- in

    A4L_AXI_arready_value     := '1';
    A4L_AXI_awready_value     := '1';
    A4L_AXI_wready_value      := '1';

    -- W 16406000
    dataIn_value          := "01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000101100000010001100000000000001111010000";
    controlIn_value       := "111";

    A4L_AXI_rvalid_value      := '0';
    A4L_AXI_rdata_value       := "11111111111111111111111111111111";
    A4L_AXI_rresp_value       := "01";
    A4L_AXI_bvalid_value      := '0';
    A4L_AXI_bresp_value       := "00";

    check_cycle;
    --------------------------------------------------------------
    controlIn_value       := "100";
    check_cycle;
    check_cycle;
    check_cycle;

    wait until Clk = '1';
  end process WaveGen_Proc;

  

end architecture tb1;

-------------------------------------------------------------------------------

configuration PE_Ifc_tb_tb1_cfg of PE_Ifc_tb is
  for tb1
  end for;
end PE_Ifc_tb_tb1_cfg;

-------------------------------------------------------------------------------
