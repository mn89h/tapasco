-------------------------------------------------------------------------------
-- Title      : Testbench for design "PE_Ifc"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : PE_Ifc_tb.vhd
-- Author     : Malte Nilges  <malte@DESKTOP-TF6PRO>
-- Company    : 
-- Created    : 2019-12-02
-- Last update: 2019-12-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-12-02  1.0      malte	Created
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
  signal clk            : std_logic := '1';
  signal rst            : std_logic := '1';
  signal AXI_arvalid    : std_logic;
  signal AXI_arready    : std_logic;
  signal AXI_rdrqA_data : AXI4_Lite_Rd_RqA;
  signal AXI_awvalid    : std_logic;
  signal AXI_awready    : std_logic;
  signal AXI_wrrqA_data : AXI4_Lite_Wr_RqA;
  signal AXI_wvalid     : std_logic;
  signal AXI_wready     : std_logic;
  signal AXI_wrrqD_data : AXI4_Lite_Wr_RqD;
  signal AXI_rready     : std_logic;
  signal AXI_rvalid     : std_logic;
  signal AXI_rdrsp_data : AXI4_Lite_Rd_Rsp;
  signal AXI_bready     : std_logic;
  signal AXI_bvalid     : std_logic;
  signal AXI_wrrsp_data : AXI4_Lite_Wr_Rsp;
  signal dataOut        : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal controlOut     : std_logic_vector(CONTROL_WIDTH - 1 downto 0);
  signal dataIn         : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal controlIn      : std_logic_vector(CONTROL_WIDTH - 1 downto 0);

begin  -- architecture tb1

  -- component instantiation
  DUT: entity work.PE_Ifc
    generic map (
      address     => address,
      address_map => address_map)
    port map (
      clk            => clk,
      rst            => rst,
      AXI_arvalid    => AXI_arvalid,
      AXI_arready    => AXI_arready,
      AXI_rdrqA_data => AXI_rdrqA_data,
      AXI_awvalid    => AXI_awvalid,
      AXI_awready    => AXI_awready,
      AXI_wrrqA_data => AXI_wrrqA_data,
      AXI_wvalid     => AXI_wvalid,
      AXI_wready     => AXI_wready,
      AXI_wrrqD_data => AXI_wrrqD_data,
      AXI_rready     => AXI_rready,
      AXI_rvalid     => AXI_rvalid,
      AXI_rdrsp_data => AXI_rdrsp_data,
      AXI_bready     => AXI_bready,
      AXI_bvalid     => AXI_bvalid,
      AXI_wrrsp_data => AXI_wrrsp_data,
      dataOut        => dataOut,
      controlOut     => controlOut,
      dataIn         => dataIn,
      controlIn      => controlIn);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc : process
  procedure check_cycle (
    --request check
    constant AXI_arready_value    : in std_logic;
    constant AXI_awready_value    : in std_logic;
    constant AXI_wready_value     : in std_logic;
    constant dataIn_value         : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    constant controlIn_value      : in std_logic_vector(CONTROL_WIDTH - 1 downto 0);
    
    --response check
    constant AXI_bvalid_value     : in std_logic;
    constant AXI_rdrsp_data_value : in AXI4_Lite_Rd_Rsp;
    constant AXI_rvalid_value     : in std_logic;
    constant AXI_wrrsp_data_value : in AXI4_Lite_Wr_Rsp
  ) is
  begin
    AXI_arready     <= AXI_arready_value;
    AXI_awready     <= AXI_awready_value;
    AXI_wready      <= AXI_wready_value;
    dataIn          <= dataIn_value;
    controlIn       <= controlIn_value;

    AXI_bvalid      <= AXI_bvalid_value;
    AXI_rdrsp_data  <= AXI_rdrsp_data_value;
    AXI_rvalid      <= AXI_rvalid_value;
    AXI_wrrsp_data  <= AXI_wrrsp_data_value;
    wait until rising_edge(clk);

    --while (AXI_arready = '1') loop
    --  wait until rising_edge(clk);
    --end loop;
  end procedure check_cycle;
  begin
    -- insert signal assignments here

    wait for 30 ns;
    rst <= '0';
    wait until rising_edge(clk);

    ---controlIn <= "100" after 100 ns;
    
    check_cycle (
      AXI_arready_value => '1',
      AXI_awready_value => '1',
      AXI_wready_value => '1',
      dataIn_value  => (others => '0'),
      controlIn_value => "100",

      AXI_rvalid_value      => '1',
      AXI_rdrsp_data_value  => deserialize_A4L_Rd_Rsp((others => '1')),
      AXI_bvalid_value      => '0',
      AXI_wrrsp_data_value  => deserialize_A4L_Wr_Rsp((others => '1'))
    );
    check_cycle (
      AXI_arready_value => '1',
      AXI_awready_value => '1',
      AXI_wready_value => '1',
      dataIn_value  => (others => '0'),
      controlIn_value => "100",

      AXI_rvalid_value      => '1',
      AXI_rdrsp_data_value  => deserialize_A4L_Rd_Rsp((others => '0')),
      AXI_bvalid_value      => '0',
      AXI_wrrsp_data_value  => deserialize_A4L_Wr_Rsp((others => '1'))
    );
    check_cycle (
      AXI_arready_value => '1',
      AXI_awready_value => '1',
      AXI_wready_value => '1',
      dataIn_value  => (others => '0'),
      controlIn_value => "100",

      AXI_rvalid_value      => '1',
      AXI_rdrsp_data_value  => deserialize_A4L_Rd_Rsp((others => '1')),
      AXI_bvalid_value      => '0',
      AXI_wrrsp_data_value  => deserialize_A4L_Wr_Rsp((others => '1'))
    );
    
    --if(AXI_arready = '1') then
    --  AXI_arvalid <= '0';
    --end if;
    --wait until rising_edge(clk);
    wait for 100 ns * 10;
  end process WaveGen_Proc;

end architecture tb1;

-------------------------------------------------------------------------------

configuration PE_Ifc_tb_tb1_cfg of PE_Ifc_tb is
  for tb1
  end for;
end PE_Ifc_tb_tb1_cfg;

-------------------------------------------------------------------------------
