-------------------------------------------------------------------------------
-- Title      : AXI4 Lite Master
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : AXI4_Lite_Master.vhd
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

entity AXI4_Lite_Master is
  generic (
    A4L_addr_width  : integer;
    A4L_data_width  : integer;
    A4L_strb_width  : integer
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
    AXI_arready : in  std_logic;
    AXI_arvalid : out std_logic;
    AXI_araddr  : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
    AXI_arprot  : out std_logic_vector(  2 downto 0 );

    ------------------------
    -- Write address channel    
    ------------------------
    AXI_awready : in  std_logic;
    AXI_awvalid : out std_logic;
    AXI_awaddr  : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
    AXI_awprot  : out std_logic_vector(  2 downto 0 );

    ------------------------
    -- Write Data channel    
    ------------------------
    AXI_wready  : in  std_logic;
    AXI_wvalid  : out std_logic;
    AXI_wdata   : out std_logic_vector( A4L_data_width - 1 + A4L_strb_width downto A4L_strb_width );
    AXI_wstrb   : out std_logic_vector( A4L_strb_width - 1 downto 0 );

    ------------------------
    -- Read data channel
    ------------------------
    AXI_rready  : out std_logic;
    AXI_rvalid  : in  std_logic;
    AXI_rdata   : in  std_logic_vector( A4L_data_width - 1 + 2 downto 2 );
    AXI_rresp   : in  std_logic_vector(  1 downto 0 );

    ------------------------
    -- Write status channel 
    ------------------------
    AXI_bready  : out std_logic;
    AXI_bvalid  : in  std_logic;
    AXI_bresp   : in  std_logic_vector(  1 downto 0 );

    ---------------------------------
    -- User interface
    -- Access GET Ifc: Enable the get request and validate the received data
    -- Access PUT Ifc: Check the ready signal and enable the data transfer
    ---------------------------------
    rdrqA_put_en    : in  std_logic;
    rdrqA_put_ready : out std_logic;
    rdrqA_put_data  : in  std_logic_vector;

    wrrqA_put_en    : in  std_logic;
    wrrqA_put_ready : out std_logic;
    wrrqA_put_data  : in  std_logic_vector;

    wrrqD_put_en    : in  std_logic;
    wrrqD_put_ready : out std_logic;
    wrrqD_put_data  : in  std_logic_vector;

    rdrsp_get_valid : out std_logic;
    rdrsp_get_en    : in  std_logic;
    rdrsp_get_data  : out std_logic_vector;

    wrrsp_get_valid : out std_logic;
    wrrsp_get_en    : in  std_logic;
    wrrsp_get_data  : out std_logic_vector
    );
end AXI4_Lite_Master;

-------------------------------------------------------------------------------

architecture Behavioral of AXI4_Lite_Master is

    constant A4L_rdrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqd_width    : natural := A4L_data_width + A4L_strb_width;
    constant A4L_rdrsp_width    : natural := A4L_data_width + 2;
    constant A4L_wrrsp_width    : natural := 2;

    signal AXI_rdrqa_data   : std_logic_vector(A4L_rdrqa_width - 1 downto 0);
    signal AXI_wrrqa_data   : std_logic_vector(A4L_wrrqa_width - 1 downto 0);
    signal AXI_wrrqd_data   : std_logic_vector(A4L_wrrqd_width - 1 downto 0);
    signal AXI_rdrsp_data   : std_logic_vector(A4L_rdrsp_width - 1 downto 0);
    signal AXI_wrrsp_data   : std_logic_vector(A4L_wrrsp_width - 1 downto 0);
begin

    AXI_araddr      <= AXI_rdrqA_data(AXI_araddr'range);
    AXI_arprot      <= AXI_rdrqA_data(AXI_arprot'range);
    AXI_awaddr      <= AXI_wrrqA_data(AXI_awaddr'range);
    AXI_awprot      <= AXI_wrrqA_data(AXI_awprot'range);
    AXI_wdata       <= AXI_wrrqD_data(AXI_wdata'range);
    AXI_wstrb       <= AXI_wrrqD_data(AXI_wstrb'range);

    AXI_rdrsp_data  <= AXI_rdata & AXI_rresp;
    AXI_wrrsp_data  <= AXI_bresp;

    FIFO_RDRQA: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

        WrValid_in      => rdrqA_put_en,
        WrReady_out     => rdrqA_put_ready,
		WrData_in       => rdrqA_put_data,
		RdValid_out     => AXI_arvalid,
		RdReady_in      => AXI_arready,
		RdData_out      => AXI_rdrqA_data
    );

    FIFO_WRRQA: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => wrrqA_put_en,
        WrReady_out     => wrrqA_put_ready,
		WrData_in       => wrrqA_put_data,
		RdValid_out     => AXI_awvalid,
		RdReady_in      => AXI_awready,
		RdData_out      => AXI_wrrqA_data
    );

    FIFO_WRRQD: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => wrrqD_put_en,
        WrReady_out     => wrrqD_put_ready,
		WrData_in       => wrrqD_put_data,
		RdValid_out     => AXI_wvalid,
		RdReady_in      => AXI_wready,
		RdData_out      => AXI_wrrqD_data
    );
    
    FIFO_RDRSP: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => AXI_rvalid,
        WrReady_out     => AXI_rready,
		WrData_in       => AXI_rdrsp_data,
		RdValid_out     => rdrsp_get_valid,
		RdReady_in      => rdrsp_get_en,
		RdData_out      => rdrsp_get_data
    );

    FIFO_WRRSP: STD_FIFO
    generic map(
        fifo_depth      => 2
    )
    port map(
        clk             => clk,
        rst             => rst,

		WrValid_in      => AXI_bvalid,
        WrReady_out     => AXI_bready,
		WrData_in       => AXI_wrrsp_data,
		RdValid_out     => wrrsp_get_valid,
		RdReady_in      => wrrsp_get_en,
		RdData_out      => wrrsp_get_data
    );

end Behavioral;

-------------------------------------------------------------------------------
