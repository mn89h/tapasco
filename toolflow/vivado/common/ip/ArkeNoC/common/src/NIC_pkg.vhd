--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Arke Package                                                       --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : v1.0                                                             --
-- HISTORY      : Version 0.1 - Apr 8th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

package NIC_pkg is
    
    ---------------
    -- Constants --
    ---------------

    constant ZERO : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    type ChannelsType is (None, RdRsp, WrRsp, RdRqA, WrRqA, WrRqD);

    constant P_A4L  : std_logic_vector(0 downto 0) := "0";
    constant P_A4F  : std_logic_vector(0 downto 0) := "1";
    constant C_AR   : std_logic_vector(1 downto 0) := "00";
    constant C_R    : std_logic_vector(1 downto 0) := "00";
    constant C_AW   : std_logic_vector(1 downto 0) := "10";
    constant C_W    : std_logic_vector(1 downto 0) := "11";
    constant C_B    : std_logic_vector(1 downto 0) := "10";

    constant STD_FIFO_FIFO_DEPTH : integer := 8;

    -- unused
    type transmission_data is record
        axi_spec : std_logic_vector ( DATA_WIDTH - 1 downto DATA_WIDTH - 1 ); -- 0 is AXI4Lite, 1 is AXI4Full
        axi_ch   : std_logic_vector ( DATA_WIDTH - 2 downto DATA_WIDTH - 3 ); -- 00 is ar/r, 10 is aw/b, 11 is w
        is_first : std_logic_vector ( DATA_WIDTH - 4 downto DATA_WIDTH - 4 ); -- first contains network address
        data     : std_logic_vector ( DATA_WIDTH - 5 downto 0 );
    end record;

    ---------------------------
    -- Component Declaration --
    ---------------------------

    component STD_FIFO is
        Generic (
            fifo_depth	: positive
        );
        Port ( 
            clk			: in  std_logic;
            rst			: in  std_logic;
            WrValid_in	: in  std_logic;
            WrReady_out	: out std_logic;
            WrData_in	: in  std_logic_vector;
            RdReady_in	: in  std_logic;
            RdData_out  : out std_logic_vector;
            RdValid_out	: out std_logic 
        );
    end component;

    component AXI4_Full_Master is
        generic (
            A4F_addr_width  : integer;
            A4F_data_width  : integer;
            A4F_id_width    : integer;
            A4F_strb_width  : integer
        );
        Port (
            clk             : in  std_logic;
            rst             : in  std_logic; 

            AXI_arready     : in  std_logic;
            AXI_arvalid     : out std_logic;
            AXI_araddr      : out std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
            AXI_arid        : out std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
            AXI_arlen       : out std_logic_vector( 24 downto 17 );
            AXI_arsize      : out std_logic_vector( 16 downto 14 );
            AXI_arburst     : out std_logic_vector( 13 downto 12 );
            AXI_arlock      : out std_logic_vector( 11 downto 11 );
            AXI_arcache     : out std_logic_vector( 10 downto 7 );
            AXI_arprot      : out std_logic_vector(  6 downto 4 );
            AXI_arqos       : out std_logic_vector(  3 downto 0 );

            AXI_awready     : in  std_logic;
            AXI_awvalid     : out std_logic;    
            AXI_awaddr      : out std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
            AXI_awid        : out std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
            AXI_awlen       : out std_logic_vector( 24 downto 17 );
            AXI_awsize      : out std_logic_vector( 16 downto 14 );
            AXI_awburst     : out std_logic_vector( 13 downto 12 );
            AXI_awlock      : out std_logic_vector( 11 downto 11 );
            AXI_awcache     : out std_logic_vector( 10 downto 7 );
            AXI_awprot      : out std_logic_vector(  6 downto 4 );
            AXI_awqos       : out std_logic_vector(  3 downto 0 );

            AXI_wready      : in  std_logic;
            AXI_wvalid      : out std_logic;
            AXI_wdata       : out std_logic_vector( A4F_data_width - 1 + A4F_strb_width + 1 downto A4F_strb_width + 1 );
            AXI_wstrb       : out std_logic_vector( A4F_strb_width - 1 + 1 downto 1 );
            AXI_wlast       : out std_logic_vector(  0 downto 0 );

            AXI_rready      : out std_logic;
            AXI_rvalid      : in  std_logic;
            AXI_rdata       : in  std_logic_vector( A4F_data_width - 1 + A4F_id_width + 3 downto A4F_id_width + 3 );
            AXI_rid         : in  std_logic_vector( A4F_id_width - 1 + 3 downto 3 );
            AXI_rresp       : in  std_logic_vector(  2 downto 1 );
            AXI_rlast       : in  std_logic_vector(  0 downto 0 );

            AXI_bready      : out std_logic;
            AXI_bvalid      : in  std_logic;
            AXI_bid         : in  std_logic_vector( A4F_id_width - 1 + 2 downto 2 );
            AXI_bresp       : in  std_logic_vector(  1 downto 0 );

            rdrqA_put_ready : out std_logic;
            rdrqA_put_en    : in  std_logic;
            rdrqA_put_data  : in  std_logic_vector;

            wrrqA_put_ready : out std_logic;
            wrrqA_put_en    : in  std_logic;
            wrrqA_put_data  : in  std_logic_vector;

            wrrqD_put_ready : out std_logic;
            wrrqD_put_en    : in  std_logic;
            wrrqD_put_data  : in  std_logic_vector;

            rdrsp_get_valid : out std_logic;
            rdrsp_get_en    : in  std_logic;
            rdrsp_get_data  : out std_logic_vector;

            wrrsp_get_valid : out std_logic;
            wrrsp_get_en    : in  std_logic;
            wrrsp_get_data  : out std_logic_vector
        );
    end component;

    component AXI4_Full_Slave is
        generic (
            A4F_addr_width  : integer;
            A4F_data_width  : integer;
            A4F_id_width    : integer;
            A4F_strb_width  : integer
        );
        Port (
            clk             : in  std_logic;
            rst             : in  std_logic; 

            AXI_arready     : out std_logic;
            AXI_arvalid     : in  std_logic;
            AXI_araddr      : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
            AXI_arid        : in  std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
            AXI_arlen       : in  std_logic_vector( 24 downto 17 );
            AXI_arsize      : in  std_logic_vector( 16 downto 14 );
            AXI_arburst     : in  std_logic_vector( 13 downto 12 );
            AXI_arlock      : in  std_logic_vector( 11 downto 11 );
            AXI_arcache     : in  std_logic_vector( 10 downto 7 );
            AXI_arprot      : in  std_logic_vector(  6 downto 4 );
            AXI_arqos       : in  std_logic_vector(  3 downto 0 );

            AXI_awready     : out std_logic;
            AXI_awvalid     : in  std_logic;    
            AXI_awaddr      : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
            AXI_awid        : in  std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
            AXI_awlen       : in  std_logic_vector( 24 downto 17 );
            AXI_awsize      : in  std_logic_vector( 16 downto 14 );
            AXI_awburst     : in  std_logic_vector( 13 downto 12 );
            AXI_awlock      : in  std_logic_vector( 11 downto 11 );
            AXI_awcache     : in  std_logic_vector( 10 downto 7 );
            AXI_awprot      : in  std_logic_vector(  6 downto 4 );
            AXI_awqos       : in  std_logic_vector(  3 downto 0 );

            AXI_wready      : out std_logic;
            AXI_wvalid      : in  std_logic;
            AXI_wdata       : in  std_logic_vector( A4F_data_width - 1 + A4F_strb_width + 1 downto A4F_strb_width + 1 );
            AXI_wstrb       : in  std_logic_vector( A4F_strb_width - 1 + 1 downto 1 );
            AXI_wlast       : in  std_logic_vector(  0 downto 0 );

            AXI_rready      : in  std_logic;
            AXI_rvalid      : out std_logic;
            AXI_rdata       : out std_logic_vector( A4F_data_width - 1 + A4F_id_width + 3 downto A4F_id_width + 3 );
            AXI_rid         : out std_logic_vector( A4F_id_width - 1 + 3 downto 3 );
            AXI_rresp       : out std_logic_vector(  2 downto 1 );
            AXI_rlast       : out std_logic_vector(  0 downto 0 );

            AXI_bready      : in  std_logic;
            AXI_bvalid      : out std_logic;
            AXI_bid         : out std_logic_vector( A4F_id_width - 1 + 2 downto 2 );
            AXI_bresp       : out std_logic_vector(  1 downto 0 );

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
    end component;
    
    component AXI4_Lite_Master is
        generic (
            A4L_addr_width  : integer;
            A4L_data_width  : integer;
            A4L_strb_width  : integer
        );
        Port (
            clk             : in  std_logic;
            rst             : in  std_logic; 

            AXI_arvalid     : out std_logic;
            AXI_arready     : in  std_logic;
            AXI_araddr      : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
            AXI_arprot      : out std_logic_vector( 2 downto 0 );

            AXI_awvalid     : out std_logic;
            AXI_awready     : in  std_logic;
            AXI_awaddr      : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
            AXI_awprot      : out std_logic_vector( 2 downto 0 );

            AXI_wvalid      : out std_logic;
            AXI_wready      : in  std_logic;
            AXI_wdata       : out std_logic_vector( A4L_data_width - 1 + A4L_strb_width downto A4L_strb_width );
            AXI_wstrb       : out std_logic_vector( A4L_strb_width - 1 downto 0 );

            AXI_rready      : out std_logic;
            AXI_rvalid      : in  std_logic;
            AXI_rdata       : in  std_logic_vector( A4L_data_width - 1 + 2 downto 2 );
            AXI_rresp       : in  std_logic_vector( 1 downto 0 );

            AXI_bready      : out std_logic;
            AXI_bvalid      : in  std_logic;
            AXI_bresp       : in  std_logic_vector( 1 downto 0 );

            rdrqA_put_ready : out std_logic;
            rdrqA_put_en    : in  std_logic;
            rdrqA_put_data  : in  std_logic_vector;

            wrrqA_put_ready : out std_logic;
            wrrqA_put_en    : in  std_logic;
            wrrqA_put_data  : in  std_logic_vector;

            wrrqD_put_ready : out std_logic;
            wrrqD_put_en    : in  std_logic;
            wrrqD_put_data  : in  std_logic_vector;

            rdrsp_get_valid : out std_logic;
            rdrsp_get_en    : in  std_logic;
            rdrsp_get_data  : out std_logic_vector;

            wrrsp_get_valid : out std_logic;
            wrrsp_get_en    : in  std_logic;
            wrrsp_get_data  : out std_logic_vector
        );
    end component;

    component AXI4_Lite_Slave is
        generic (
            A4L_addr_width  : integer;
            A4L_data_width  : integer;
            A4L_strb_width  : integer
        );
        Port (
            clk             : in  std_logic;
            rst             : in  std_logic; 

            AXI_arvalid     : in  std_logic;
            AXI_arready     : out std_logic;
            AXI_araddr      : in  std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
            AXI_arprot      : in  std_logic_vector( 2 downto 0 );

            AXI_awvalid     : in  std_logic;
            AXI_awready     : out std_logic;
            AXI_awaddr      : in  std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
            AXI_awprot      : in  std_logic_vector( 2 downto 0 );

            AXI_wvalid      : in  std_logic;
            AXI_wready      : out std_logic;
            AXI_wdata       : in  std_logic_vector( A4L_data_width - 1 + A4L_strb_width downto A4L_strb_width );
            AXI_wstrb       : in  std_logic_vector( A4L_strb_width - 1 downto 0 );

            AXI_rready      : in  std_logic;
            AXI_rvalid      : out std_logic;
            AXI_rdata       : out std_logic_vector( A4L_data_width - 1 + 2 downto 2 );
            AXI_rresp       : out std_logic_vector( 1 downto 0 );

            AXI_bready      : in  std_logic;
            AXI_bvalid      : out std_logic;
            AXI_bresp       : out std_logic_vector( 1 downto 0 );

            rdrqA_get_valid : out std_logic;
            rdrqA_get_en    : in  std_logic;
            rdrqA_get_data  : out std_logic_vector;

            wrrqA_get_valid : out std_logic;
            wrrqA_get_en    : in  std_logic;
            wrrqA_get_data  : out std_logic_vector;

            wrrqD_get_valid : out std_logic;
            wrrqD_get_en    : in  std_logic;
            wrrqD_get_data  : out std_logic_vector;

            rdrsp_put_ready : out std_logic;
            rdrsp_put_en    : in  std_logic;
            rdrsp_put_data  : in  std_logic_vector;

            wrrsp_put_ready : out std_logic;
            wrrsp_put_en    : in  std_logic;
            wrrsp_put_data  : in  std_logic_vector
        );
    end component;

end package NIC_pkg;