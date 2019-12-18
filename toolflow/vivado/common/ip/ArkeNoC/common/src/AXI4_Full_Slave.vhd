-------------------------------------------------------------------------------
-- Title      : AXI4 Full Slave
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : AXI4_Full_Slave.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NIC_pkg.all;

-------------------------------------------------------------------------------

entity AXI4_Full_Slave is
  generic (
    A4F_addr_width  : integer;
    A4F_data_width  : integer;
    A4F_id_width    : integer
  );
  port (
    ------------------------
    -- Incoming system clock
    ------------------------
    clk         : in std_logic;
    rst         : in std_logic; 

    ---------------------------------
    -- System interface
    -- Connect to a Master Interface
    ---------------------------------
    ------------------------
    -- Read address channel
    ------------------------
    AXI_arready : out std_logic;
    AXI_arvalid : in  std_logic;
    AXI_araddr  : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 20 downto A4F_id_width + 20 );
    AXI_arid    : in  std_logic_vector( A4F_id_width - 1 + 20 downto 20 );
    AXI_arlen   : in  std_logic_vector( 19 downto 16 );
    AXI_arsize  : in  std_logic_vector( 15 downto 13 );
    AXI_arburst : in  std_logic_vector( 12 downto 11 );
    AXI_arlock  : in  std_logic_vector( 10 downto 9 );
    AXI_arcache : in  std_logic_vector(  8 downto 6 );
    AXI_arprot  : in  std_logic_vector(  5 downto 3 );
    AXI_arqos   : in  std_logic_vector(  2 downto 0 );

    ------------------------
    -- Write address channel    
    ------------------------
    AXI_awready : out std_logic;
    AXI_awvalid : in  std_logic;    
    AXI_awaddr  : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 20 downto A4F_id_width + 20 );
    AXI_awid    : in  std_logic_vector( A4F_id_width - 1 + 20 downto 20 );
    AXI_awlen   : in  std_logic_vector( 19 downto 16 );
    AXI_awsize  : in  std_logic_vector( 15 downto 13 );
    AXI_awburst : in  std_logic_vector( 12 downto 11 );
    AXI_awlock  : in  std_logic_vector( 10 downto 9 );
    AXI_awcache : in  std_logic_vector(  8 downto 6 );
    AXI_awprot  : in  std_logic_vector(  5 downto 3 );
    AXI_awqos   : in  std_logic_vector(  2 downto 0 );

    ------------------------
    -- Write Data channel    
    ------------------------
    AXI_wready  : out std_logic;
    AXI_wvalid  : in  std_logic;
    AXI_wdata   : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 5 downto A4F_id_width + 5 );
    AXI_wid     : in  std_logic_vector( A4F_id_width - 1 + 5 downto 5 );
    AXI_wstrb   : in  std_logic_vector(  4 downto 1 );
    AXI_wlast   : in  std_logic_vector(  0 downto 0 );

    ------------------------
    -- Read data channel
    ------------------------
    AXI_rready  : in  std_logic;
    AXI_rvalid  : out std_logic;
    AXI_rdata   : out std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 3 downto A4F_id_width + 3 );
    AXI_rid     : out std_logic_vector( A4F_id_width - 1 + 3 downto 3 );
    AXI_rresp   : out std_logic_vector(  2 downto 1 );
    AXI_rlast   : out std_logic_vector(  0 downto 0 );

    ------------------------
    -- Write status channel 
    ------------------------
    AXI_bready  : in  std_logic;
    AXI_bvalid  : out std_logic;
    AXI_bid     : out std_logic_vector( A4F_id_width - 1 + 2 downto 2 );
    AXI_bresp   : out std_logic_vector(  1 downto 0 );

    ---------------------------------
    -- User interface
    -- Access GET Ifc: Enable the get request and validate the received data
    -- Access PUT Ifc: Check the ready signal and enable the data transfer
    ---------------------------------
    rdrqA_get_valid : out std_logic;
    rdrqA_get_en    : in  std_logic;
    rdrqA_get_data  : out std_logic_vector;

    wrrqA_get_valid : out std_logic;
    wrrqA_get_en    : in  std_logic;
    wrrqA_get_data  : out std_logic_vector;

    wrrqD_get_valid : out std_logic;
    wrrqD_get_en    : in  std_logic;
    wrrqD_get_data  : out std_logic_vector;

    rdrsp_put_en    : in  std_logic;
    rdrsp_put_ready : out std_logic;
    rdrsp_put_data  : in  std_logic_vector;

    wrrsp_put_en    : in  std_logic;
    wrrsp_put_ready : out std_logic;
    wrrsp_put_data  : in  std_logic_vector
    );
end AXI4_Full_Slave;

-------------------------------------------------------------------------------

architecture Behavioral of AXI4_Full_Slave is
    
    constant A4F_rdrqa_width    : natural := A4F_addr_width + A4F_id_width + 20;
    constant A4F_wrrqa_width    : natural := A4F_addr_width + A4F_id_width + 20;
    constant A4F_wrrqd_width    : natural := A4F_data_width + A4F_id_width + 5;
    constant A4F_rdrsp_width    : natural := A4F_data_width + A4F_id_width + 3;
    constant A4F_wrrsp_width    : natural := A4F_id_width + 2;

    signal AXI_rdrqA_data   : std_logic_vector(A4F_rdrqa_width - 1 downto 0);
    signal AXI_wrrqA_data   : std_logic_vector(A4F_wrrqa_width - 1 downto 0);
    signal AXI_wrrqD_data   : std_logic_vector(A4F_wrrqd_width - 1 downto 0);
    signal AXI_rdrsp_data   : std_logic_vector(A4F_rdrsp_width - 1 downto 0);
    signal AXI_wrrsp_data   : std_logic_vector(A4F_wrrsp_width - 1 downto 0);
begin
    AXI_rdrqA_data  <= AXI_araddr & AXI_arid & AXI_arlen & AXI_arsize & AXI_arburst & AXI_arlock & AXI_arcache & AXI_arprot & AXI_arqos;
    AXI_wrrqA_data  <= AXI_awaddr & AXI_awid & AXI_awlen & AXI_awsize & AXI_awburst & AXI_awlock & AXI_awcache & AXI_awprot & AXI_awqos;
    AXI_wrrqD_data  <= AXI_wdata & AXI_wid & AXI_wstrb & AXI_wlast;

    AXI_rdata       <= AXI_rdrsp_data(AXI_rdata'range);
    AXI_rid         <= AXI_rdrsp_data(AXI_rid'range);
    AXI_rresp       <= AXI_rdrsp_data(AXI_rresp'range);
    AXI_rlast       <= AXI_rdrsp_data(AXI_rlast'range);
    AXI_bid         <= AXI_wrrsp_data(AXI_bid'range);
    AXI_bresp       <= AXI_wrrsp_data(AXI_bresp'range);

    FIFO_RDRQA: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => AXI_arvalid,
        WrReady_out     => AXI_arready,
		WrData_in       => AXI_rdrqA_data,
		RdValid_out     => rdrqA_get_valid,
		RdReady_in      => rdrqA_get_en,
		RdData_out      => rdrqA_get_data
    );

    FIFO_WRRQA: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => AXI_awvalid,
        WrReady_out     => AXI_awready,
		WrData_in       => AXI_wrrqA_data,
		RdValid_out     => wrrqA_get_valid,
		RdReady_in      => wrrqA_get_en,
		RdData_out      => wrrqA_get_data
    );

    FIFO_WRRQD: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => AXI_wvalid,
        WrReady_out     => AXI_wready,
		WrData_in       => AXI_wrrqD_data,
		RdValid_out     => wrrqD_get_valid,
		RdReady_in      => wrrqD_get_en,
		RdData_out      => wrrqD_get_data
    );
    
    FIFO_RDRSP: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => rdrsp_put_en,
        WrReady_out     => rdrsp_put_ready,
		WrData_in       => rdrsp_put_data,
		RdValid_out     => AXI_rvalid,
		RdReady_in      => AXI_rready,
		RdData_out      => AXI_rdrsp_data
    );

    FIFO_WRRSP: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => wrrsp_put_en,
        WrReady_out     => wrrsp_put_ready,
		WrData_in       => wrrsp_put_data,
		RdValid_out     => AXI_bvalid,
		RdReady_in      => AXI_bready,
		RdData_out      => AXI_wrrsp_data
    );

end Behavioral;

-------------------------------------------------------------------------------
