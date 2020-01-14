-------------------------------------------------------------------------------
-- Title      : PE (Processing Element) Interface
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : PE_Ifc.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 2019-12-02
-- Last update: 2019-01-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Network interface for TaPaSCo's processing elements sending
--              data to and receiving data from architecture/memory interface.
--              Data received from PEs AXI4 Master is converted to appropriate
--              network data format and the other way round.
--              Same procedure is applied for data from/to PEs AXI4 Lite Slave.
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NIC_pkg.all;
use work.Arke_pkg.all;

-------------------------------------------------------------------------------

entity PE_Ifc is
    generic (
        A4L_addr_width  : integer;
        A4L_data_width  : integer;
        A4F_addr_width  : integer;
        A4F_data_width  : integer;
        A4F_id_width    : integer;
        A4F_strb_width  : integer;
        NoC_address     : std_logic_vector;
        NoC_address_mem : std_logic_vector;
        NoC_address_arch: std_logic_vector
    );
    port (
        signal clk                  : in  std_logic := '1';
        signal rst                  : in  std_logic := '1';
        signal A4L_AXI_arvalid      : out std_logic;
        signal A4L_AXI_arready      : in  std_logic;
        signal A4L_AXI_araddr       : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
        signal A4L_AXI_arprot       : out std_logic_vector( 2 downto 0 );
        signal A4L_AXI_awvalid      : out std_logic;
        signal A4L_AXI_awready      : in  std_logic;
        signal A4L_AXI_awaddr       : out std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
        signal A4L_AXI_awprot       : out std_logic_vector( 2 downto 0 );
        signal A4L_AXI_wvalid       : out std_logic;
        signal A4L_AXI_wready       : in  std_logic;
        signal A4L_AXI_wdata        : out std_logic_vector( A4L_data_width - 1 + 4 downto 4 );
        signal A4L_AXI_wstrb        : out std_logic_vector( 3 downto 0 );
        signal A4L_AXI_rready       : out std_logic;
        signal A4L_AXI_rvalid       : in  std_logic;
        signal A4L_AXI_rdata        : in  std_logic_vector( A4L_data_width - 1 + 2 downto 2 );
        signal A4L_AXI_rresp        : in  std_logic_vector( 1 downto 0 );
        signal A4L_AXI_bready       : out std_logic;
        signal A4L_AXI_bvalid       : in  std_logic;
        signal A4L_AXI_bresp        : in  std_logic_vector( 1 downto 0 );

        signal A4F_AXI_arvalid      : in  std_logic;
        signal A4F_AXI_arready      : out std_logic;
        signal A4F_AXI_araddr       : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
        signal A4F_AXI_arid         : in  std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
        signal A4F_AXI_arlen        : in  std_logic_vector( 24 downto 17 );
        signal A4F_AXI_arsize       : in  std_logic_vector( 16 downto 14 );
        signal A4F_AXI_arburst      : in  std_logic_vector( 13 downto 12 );
        signal A4F_AXI_arlock       : in  std_logic_vector( 11 downto 11 );
        signal A4F_AXI_arcache      : in  std_logic_vector( 10 downto 7 );
        signal A4F_AXI_arprot       : in  std_logic_vector(  6 downto 4 );
        signal A4F_AXI_arqos        : in  std_logic_vector(  3 downto 0 );
        signal A4F_AXI_awvalid      : in  std_logic;
        signal A4F_AXI_awready      : out std_logic;
        signal A4F_AXI_awaddr       : in  std_logic_vector( A4F_addr_width - 1 + A4F_id_width + 25 downto A4F_id_width + 25 );
        signal A4F_AXI_awid         : in  std_logic_vector( A4F_id_width - 1 + 25 downto 25 );
        signal A4F_AXI_awlen        : in  std_logic_vector( 24 downto 17 );
        signal A4F_AXI_awsize       : in  std_logic_vector( 16 downto 14 );
        signal A4F_AXI_awburst      : in  std_logic_vector( 13 downto 12 );
        signal A4F_AXI_awlock       : in  std_logic_vector( 11 downto 11 );
        signal A4F_AXI_awcache      : in  std_logic_vector( 10 downto 7 );
        signal A4F_AXI_awprot       : in  std_logic_vector(  6 downto 4 );
        signal A4F_AXI_awqos        : in  std_logic_vector(  3 downto 0 );
        signal A4F_AXI_wvalid       : in  std_logic;
        signal A4F_AXI_wready       : out std_logic;
        signal A4F_AXI_wdata        : in  std_logic_vector( A4F_addr_width - 1 + A4F_strb_width + 1 downto A4F_strb_width + 1 );
        signal A4F_AXI_wstrb        : in  std_logic_vector( A4F_strb_width - 1 + 1 downto 1 );
        signal A4F_AXI_wlast        : in  std_logic_vector(  0 downto 0 );
        signal A4F_AXI_rready       : in  std_logic;
        signal A4F_AXI_rvalid       : out std_logic;
        signal A4F_AXI_rdata        : out std_logic_vector( A4F_data_width - 1 + A4F_id_width + 3 downto A4F_id_width + 3 );
        signal A4F_AXI_rid          : out std_logic_vector( A4F_id_width - 1 + 3 downto 3 );
        signal A4F_AXI_rresp        : out std_logic_vector(  2 downto 1 );
        signal A4F_AXI_rlast        : out std_logic_vector(  0 downto 0 );
        signal A4F_AXI_bready       : in  std_logic;
        signal A4F_AXI_bvalid       : out std_logic;
        signal A4F_AXI_bid          : out std_logic_vector( A4F_id_width - 1 + 2 downto 2 );
        signal A4F_AXI_bresp        : out std_logic_vector(  1 downto 0 );

        signal dataOut          : out std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlOut       : out std_logic_vector( CONTROL_WIDTH - 1 downto 0 );
        signal dataIn           : in  std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlIn        : in  std_logic_vector( CONTROL_WIDTH - 1 downto 0 )
    );
end PE_Ifc;

-------------------------------------------------------------------------------

architecture Behavioral of PE_Ifc is

    ---------------
    -- Constants --
    ---------------
    constant A4L_rdrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqd_width    : natural := A4L_data_width + 4;
    constant A4L_rdrsp_width    : natural := A4L_data_width + 2;
    constant A4L_wrrsp_width    : natural := 2;

    constant A4F_rdrqa_width    : natural := A4F_addr_width + A4F_id_width + NoC_addr_width + 25;
    constant A4F_wrrqa_width    : natural := A4F_addr_width + A4F_id_width + NoC_addr_width + 25;
    constant A4F_wrrqd_width    : natural := A4F_data_width + A4F_strb_width + 1;
    constant A4F_rdrsp_width    : natural := A4F_data_width + A4F_id_width + NoC_addr_width + 3;
    constant A4F_wrrsp_width    : natural := A4F_id_width + NoC_addr_width + 2;

    constant DIM_X_W    : integer := Log2(DIM_X);
    constant DIM_Y_W    : integer := Log2(DIM_Y);
    constant DIM_Z_W    : integer := Log2(DIM_Z);
    constant ADDR_W     : integer := DIM_X_W + DIM_Y_W + DIM_Z_W;

    -------------
    -- Signals --
    -------------
    signal A4L_rdrqA_put_ready : std_logic;
    signal A4L_rdrqA_put_en    : std_logic;
    signal A4L_rdrqA_put_data  : std_logic_vector(A4L_rdrqa_width - 1 downto 0);
    signal A4L_wrrqA_put_ready : std_logic;
    signal A4L_wrrqA_put_en    : std_logic;
    signal A4L_wrrqA_put_data  : std_logic_vector(A4L_wrrqa_width - 1 downto 0);
    signal A4L_wrrqD_put_ready : std_logic;
    signal A4L_wrrqD_put_en    : std_logic;
    signal A4L_wrrqD_put_data  : std_logic_vector(A4L_wrrqd_width - 1 downto 0);
    signal A4L_rdrsp_get_valid : std_logic;
    signal A4L_rdrsp_get_en    : std_logic;
    signal A4L_rdrsp_get_data  : std_logic_vector(A4L_rdrsp_width - 1 downto 0);
    signal A4L_wrrsp_get_valid : std_logic;
    signal A4L_wrrsp_get_en    : std_logic;
    signal A4L_wrrsp_get_data  : std_logic_vector(A4L_wrrsp_width - 1 downto 0);

    signal A4F_rdrqA_get_valid : std_logic;
    signal A4F_rdrqA_get_en    : std_logic;
    signal A4F_rdrqA_get_data  : std_logic_vector(A4F_rdrqa_width - 1 downto 0);
    signal A4F_wrrqA_get_valid : std_logic;
    signal A4F_wrrqA_get_en    : std_logic;
    signal A4F_wrrqA_get_data  : std_logic_vector(A4F_wrrqa_width - 1 downto 0);
    signal A4F_wrrqD_get_valid : std_logic;
    signal A4F_wrrqD_get_en    : std_logic;
    signal A4F_wrrqD_get_data  : std_logic_vector(A4F_wrrqd_width - 1 downto 0);
    signal A4F_rdrsp_put_ready : std_logic;
    signal A4F_rdrsp_put_en    : std_logic;
    signal A4F_rdrsp_put_data  : std_logic_vector(A4F_rdrsp_width - 1 downto 0);
    signal A4F_wrrsp_put_ready : std_logic;
    signal A4F_wrrsp_put_en    : std_logic;
    signal A4F_wrrsp_put_data  : std_logic_vector(A4F_wrrsp_width - 1 downto 0);

    signal A4F_AXI_custom_arid : std_logic_vector(A4F_id_width + NoC_addr_width - 1 downto 0);
    signal A4F_AXI_custom_awid : std_logic_vector(A4F_id_width + NoC_addr_width - 1 downto 0);
    signal A4F_AXI_custom_rid  : std_logic_vector(A4F_id_width + NoC_addr_width - 1 downto 0);
    signal A4F_AXI_custom_bid  : std_logic_vector(A4F_id_width + NoC_addr_width - 1 downto 0);

    signal dataInStalled   : std_logic_vector(dataIn'range);
    signal put_last_state  : ChannelsType;
    signal put_stalled     : std_logic;
    signal state_send      : ChannelsType;
    signal send_stalled    : std_logic;


    --------------------------------
    -- RUNTIME SENDING PROCEDURES --
    --------------------------------
    
    -- DETERMINE NEXT DATA OUT --
    -- generates the next data to send and returns it as a variable
    procedure send_determineNextDataOut(constant axi_protocol    : in std_logic_vector;
                                        constant axi_channel     : in std_logic_vector;
                                        signal axi_data          : in std_logic_vector;
                                        variable dest_address    : in std_logic_vector;
                                        variable nextDataOut     : out std_logic_vector) is
    begin
        nextDataOut := axi_protocol & axi_channel &
                       ZERO(nextDataOut'left - 3 downto axi_data'length + ADDR_W) &
                       axi_data & dest_address;
    end procedure;

    -- SEND DATA AND PROCEED --
    -- writes the data and control signal and proceeds to the next state
    procedure send_sendDataAndProceed(variable dataToSend    : in std_logic_vector;
                                      signal send_stalled    : out std_logic;
                                      signal dataOut         : out std_logic_vector;
                                      signal controlOut      : out std_logic_vector;
                                      signal nextChannelEn   : out std_logic;
                                      signal state_send      : out ChannelsType;
                                      constant nextState     : in ChannelsType) is
    begin
        send_stalled    <= '0';
        dataOut         <= dataToSend;
        controlOut(TX)  <= '1';
        controlOut(EOP) <= '1';

        nextChannelEn   <= '1';
        state_send      <= nextState;
    end procedure;

    -- STALL DATA AND WAIT --
    -- stall is set and channel enable is unset in order to stop sending new data from axi bus
    procedure send_stallDataAndWait(signal send_stalled  : out std_logic;
                                    signal nextChannelEn : out std_logic) is
    begin
        send_stalled    <= '1';
        nextChannelEn   <= '0';
    end procedure;

    -- UNSET PREVIOUS TX --
    -- control signals from previous transmission are unset
    procedure send_unsetPreviousTX(signal controlOut : out std_logic_vector) is
    begin
        controlOut(TX)  <= '0';
        controlOut(EOP) <= '0';
    end procedure;

    -- DO NOTHING AND PROCEED --
    -- no data output, next channel is enabled to proceed to next state 
    procedure send_doNothingAndProceed(signal send_stalled   : out std_logic;
                                       signal nextChannelEn  : out std_logic;
                                       signal state_send     : out ChannelsType;
                                       constant nextState    : in ChannelsType) is
    begin
        send_stalled    <= '0';
        nextChannelEn   <= '1';
        state_send      <= nextState;       
    end procedure;

    -- DO NOTHING AND WAIT --
    -- no data output, state remains the same with unset channel enable signal
    procedure send_doNothingAndWait(signal send_stalled   : out std_logic;
                                    signal nextChannelEn  : out std_logic) is
    begin
        send_stalled    <= '0';
        nextChannelEn   <= '0';      
    end procedure;

    procedure send_sendDataAndProceedAfterLast(variable dataToSend      : in  std_logic_vector;
                                               signal send_stalled      : out std_logic;
                                               signal dataOut           : out std_logic_vector;
                                               signal controlOut        : out std_logic_vector;
                                               signal isLast            : in  std_logic;
                                               signal send_last         : out std_logic;
                                               signal nextChannelEn_P   : out std_logic;
                                               signal nextChannelEn_W   : out std_logic;
                                               signal state_send        : out ChannelsType;
                                               constant nextState       : in  ChannelsType) is
    begin
        send_stalled    <= '0';
        dataOut         <= dataToSend;
        controlOut(TX)  <= '1';
                    
        if (isLast = '1') then
            nextChannelEn_W     <= '0';

            controlOut(EOP)     <= '1';
            nextChannelEn_P     <= '1';
            state_send          <= nextState;
            send_last           <= '1'
        else
            nextChannelEn_P     <= '0';
            
            controlOut(EOP)     <= '0';
            nextChannelEn_W     <= '1';
            send_last           <= '0';
        end if;
    end procedure;


    ----------------------------------
    -- RUNTIME RECEIVING PROCEDURES --
    ----------------------------------

    -- CHECK IF LAST RECEPTION IS VALID --
    -- checks if the reception for the last state was successful by checking the put_ready signal
    function recv_lastReceptionIsValid(signal put_last_state    : ChannelsType;
                                       signal wrrsp_put_ready   : std_logic;
                                       signal rdrsp_put_ready   : std_logic)
    return boolean is
    begin
        if ((put_last_state = WrRsp and wrrsp_put_ready = '1') or
            (put_last_state = RdRsp and rdrsp_put_ready = '1')) then
                return true;
        else
                return false;
        end if;
    end function;

    -- PROCESS DATA --
    -- forward dataIn to axi bus (if last reception was successful)
    procedure recv_processData(signal axi_data           : out std_logic_vector;
                               constant axi_width        : in integer;
                               signal dataIn             : in  std_logic_vector;
                               signal rdrsp_put_en       : out std_logic;
                               constant rdrsp_put_en_v   : in  std_logic;
                               signal wrrsp_put_en       : out std_logic;
                               constant wrrsp_put_en_v   : in  std_logic;
                               signal controlOut         : out std_logic_vector) is
    begin
        axi_data                <= dataIn(ADDR_W + axi_width - 1 downto NoC_addr_width);
        rdrsp_put_en            <= rdrsp_put_en_v;
        wrrsp_put_en            <= wrrsp_put_en_v;
        controlOut(STALL_GO)    <= '1';
    end procedure;

    -- STALL DATA --
    -- stall data (if the last reception was unsuccessful) in order to avoid data loss caused by latency
    procedure recv_stallData(signal dataInStalled      : out std_logic_vector;
                             signal dataIn             : in  std_logic_vector;
                             signal controlOut         : out std_logic_vector;
                             signal put_last_state     : out ChannelsType;
                             constant put_last_state_v : in  ChannelsType;
                             signal put_stalled        : out std_logic) is
    begin
        dataInStalled           <= dataIn;
        controlOut(STALL_GO)    <= '0';
        put_stalled             <= '1';
        put_last_state          <= put_last_state_v;
    end procedure;

    -- PROCESS STALLED DATA --
    -- forward stalled dataIn to axi bus (if last reception was successful)
    procedure recv_processStalledData(signal axi_data           : out std_logic_vector;
                                      constant axi_width        : in integer;
                                      signal dataInStalled      : in  std_logic_vector;
                                      signal rdrsp_put_en       : out std_logic;
                                      constant rdrsp_put_en_v   : in  std_logic;
                                      signal wrrsp_put_en       : out std_logic;
                                      constant wrrsp_put_en_v   : in  std_logic;
                                      signal controlOut         : out std_logic_vector;
                                      signal put_last_state     : out ChannelsType;
                                      constant put_last_state_v : in  ChannelsType;
                                      signal put_stalled        : out std_logic) is
    begin
        axi_data                <= dataInStalled(ADDR_W + axi_width - 1 downto NoC_addr_width);
        rdrsp_put_en            <= rdrsp_put_en_v;
        wrrsp_put_en            <= wrrsp_put_en_v;
        controlOut(STALL_GO)    <= '1';
        put_stalled             <= '0';
        put_last_state          <= put_last_state_v;
    end procedure;


begin

    A4F_AXI_custom_arid <= NoC_address & A4F_AXI_arid;
    A4F_AXI_custom_awid <= NoC_address & A4F_AXI_awid;
    A4F_AXI_rid         <= A4F_AXI_custom_rid(A4F_id_width - 1 downto 0);
    A4F_AXI_bid         <= A4F_AXI_custom_bid(A4F_id_width - 1 downto 0);

    AXI_Master : AXI4_Lite_Master
    generic map (
        A4L_addr_width  => A4L_addr_width,
        A4L_data_width  => A4L_data_width
    )
    port map (
        clk             => clk,
        rst             => rst,
        AXI_arvalid     => A4L_AXI_arvalid,
        AXI_arready     => A4L_AXI_arready,
        AXI_araddr      => A4L_AXI_araddr,
        AXI_arprot      => A4L_AXI_arprot,
        AXI_awvalid     => A4L_AXI_awvalid,
        AXI_awready     => A4L_AXI_awready,
        AXI_awaddr      => A4L_AXI_awaddr,
        AXI_awprot      => A4L_AXI_awprot,
        AXI_wvalid      => A4L_AXI_wvalid,
        AXI_wready      => A4L_AXI_wready,
        AXI_wdata       => A4L_AXI_wdata,
        AXI_wstrb       => A4L_AXI_wstrb,
        AXI_rready      => A4L_AXI_rready,
        AXI_rvalid      => A4L_AXI_rvalid,
        AXI_rdata       => A4L_AXI_rdata,
        AXI_rresp       => A4L_AXI_rresp,
        AXI_bready      => A4L_AXI_bready,
        AXI_bvalid      => A4L_AXI_bvalid,
        AXI_bresp       => A4L_AXI_bresp,
        rdrqA_put_en    => A4L_rdrqA_put_en,
        rdrqA_put_ready => A4L_rdrqA_put_ready,
        rdrqA_put_data  => A4L_rdrqA_put_data,
        wrrqA_put_en    => A4L_wrrqA_put_en,
        wrrqA_put_ready => A4L_wrrqA_put_ready,
        wrrqA_put_data  => A4L_wrrqA_put_data,
        wrrqD_put_en    => A4L_wrrqD_put_en,
        wrrqD_put_ready => A4L_wrrqD_put_ready,
        wrrqD_put_data  => A4L_wrrqD_put_data,
        rdrsp_get_valid => A4L_rdrsp_get_valid,
        rdrsp_get_en    => A4L_rdrsp_get_en,
        rdrsp_get_data  => A4L_rdrsp_get_data,
        wrrsp_get_valid => A4L_wrrsp_get_valid,
        wrrsp_get_en    => A4L_wrrsp_get_en,
        wrrsp_get_data  => A4L_wrrsp_get_data
    );

    AXI_Slave : AXI4_Full_Slave
    generic map (
        A4F_addr_width  => A4F_addr_width,
        A4F_data_width  => A4F_data_width,
        A4F_id_width    => A4F_id_width + NoC_addr_width,
        A4F_strb_width  => A4F_strb_width
    )
    port map (
        clk             => clk,
        rst             => rst,
        AXI_arvalid     => A4F_AXI_arvalid,
        AXI_arready     => A4F_AXI_arready,
        AXI_araddr      => A4F_AXI_araddr,
        AXI_arid        => A4F_AXI_custom_arid,
        AXI_arlen       => A4F_AXI_arlen,
        AXI_arsize      => A4F_AXI_arsize,
        AXI_arburst     => A4F_AXI_arburst,
        AXI_arlock      => A4F_AXI_arlock,
        AXI_arcache     => A4F_AXI_arcache,
        AXI_arprot      => A4F_AXI_arprot,
        AXI_arqos       => A4F_AXI_arqos,
        AXI_awvalid     => A4F_AXI_awvalid,
        AXI_awready     => A4F_AXI_awready,
        AXI_awaddr      => A4F_AXI_awaddr,
        AXI_awid        => A4F_AXI_custom_awid,
        AXI_awlen       => A4F_AXI_awlen,
        AXI_awsize      => A4F_AXI_awsize,
        AXI_awburst     => A4F_AXI_awburst,
        AXI_awlock      => A4F_AXI_awlock,
        AXI_awcache     => A4F_AXI_awcache,
        AXI_awprot      => A4F_AXI_awprot,
        AXI_awqos       => A4F_AXI_awqos,
        AXI_wvalid      => A4F_AXI_wvalid,
        AXI_wready      => A4F_AXI_wready,
        AXI_wdata       => A4F_AXI_wdata,
        AXI_wstrb       => A4F_AXI_wstrb,
        AXI_wlast       => A4F_AXI_wlast,
        AXI_rready      => A4F_AXI_rready,
        AXI_rvalid      => A4F_AXI_rvalid,
        AXI_rdata       => A4F_AXI_rdata,
        AXI_rid         => A4F_AXI_custom_rid,
        AXI_rresp       => A4F_AXI_rresp,
        AXI_rlast       => A4F_AXI_rlast,
        AXI_bready      => A4F_AXI_bready,
        AXI_bvalid      => A4F_AXI_bvalid,
        AXI_bid         => A4F_AXI_custom_bid,
        AXI_bresp       => A4F_AXI_bresp,
        rdrqA_get_valid => A4F_rdrqA_get_valid,
        rdrqA_get_en    => A4F_rdrqA_get_en,
        rdrqA_get_data  => A4F_rdrqA_get_data,
        wrrqA_get_valid => A4F_wrrqA_get_valid,
        wrrqA_get_en    => A4F_wrrqA_get_en,
        wrrqA_get_data  => A4F_wrrqA_get_data,
        wrrqD_get_valid => A4F_wrrqD_get_valid,
        wrrqD_get_en    => A4F_wrrqD_get_en,
        wrrqD_get_data  => A4F_wrrqD_get_data,
        rdrsp_put_ready => A4F_rdrsp_put_ready,
        rdrsp_put_en    => A4F_rdrsp_put_en,
        rdrsp_put_data  => A4F_rdrsp_put_data,
        wrrsp_put_ready => A4F_wrrsp_put_ready,
        wrrsp_put_en    => A4F_wrrsp_put_en,
        wrrsp_put_data  => A4F_wrrsp_put_data
    );
                
    process(clk)

        --todo
        variable A4L_rdrqA_put_data_tmp : std_logic_vector(A4L_rdrqa_width - 1 downto 0);
        variable A4L_wrrqA_put_data_tmp : std_logic_vector(A4L_wrrqa_width - 1 downto 0);
        variable A4L_wrrqD_put_data_tmp : std_logic_vector(A4L_wrrqd_width - 1 downto 0);
        variable A4F_rdrsp_put_data_tmp : std_logic_vector(A4F_rdrsp_width - 1 downto 0);
        variable A4F_wrrsp_put_data_tmp : std_logic_vector(A4F_wrrsp_width - 1 downto 0);
        
        variable dest_address       : std_logic_vector(NoC_addr_width - 1 downto 0);
        variable dataOutNext        : std_logic_vector(DATA_WIDTH - 1 downto 0);

    begin if rising_edge(clk) then
        -----------
        -- RESET --
        -----------
        if (rst = '1') then
            controlOut          <= "100";
            dataOut             <= (others => '0');
            state_send          <= None;
            put_last_state      <= RdRsp;
            put_stalled         <= '0';
        else

        --------------------------------------------------------
        -- A4L R/W RESPONSE & A4F R/W REQUEST TO NETWORK DATA --
        --------------------------------------------------------
        -- Incoming r/w requests are being handed over to the network as they are valid using round-robin.
        -- If a request is valid, but the local router isn't able to receive data, the state remains the same
        -- otherwise it changes to the next state to look for valid data.
        -- Same procedure is applied for r/w responses.
        -- The network destination is chosen by a address map in conjunction with the AXI address.
        --------------------------------------------------------
        
        -- STATE 0: INIT
        if (state_send = None) then
            send_stalled        <= '0';
            A4L_rdrsp_get_en    <= '1';
            state_send          <= RdRsp;

        -- STATE 1: RDRSP
        elsif (state_send = RdRsp) then
            A4L_rdrsp_get_en    <= '0';
            A4F_rdrqA_get_en    <= '0';
            A4F_wrrqA_get_en    <= '0';
            A4F_wrrqD_get_en    <= '0';

            if (A4L_rdrsp_get_valid = '1') then
                if(send_stalled = '0') then
                    dest_address    := NoC_address_arch;
                    send_determineNextDataOut(P_A4L, C_R,
                                              A4L_rdrsp_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext,
                                            send_stalled,
                                            dataOut,
                                            controlOut,
                                            A4L_wrrsp_get_en,
                                            state_send, WrRsp);
                else
                    send_stallDataAndWait(send_stalled, 
                                          A4L_wrrsp_get_en);
                end if;
            else
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                send_doNothingAndProceed(send_stalled, 
                                         A4L_wrrsp_get_en, 
                                         state_send, WrRsp);
            end if;

        -- STATE 2: WRRSP
        elsif (state_send = WrRsp) then
            A4L_rdrsp_get_en    <= '0';
            A4L_wrrsp_get_en    <= '0';
            A4F_wrrqA_get_en    <= '0';
            A4F_wrrqD_get_en    <= '0';

            if (A4L_wrrsp_get_valid = '1') then
                if(send_stalled = '0') then
                    dest_address    := NoC_address_arch;
                    send_determineNextDataOut(P_A4L, C_B,
                                              A4L_wrrsp_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext,
                                            send_stalled,
                                            dataOut,
                                            controlOut,
                                            A4F_rdrqA_get_en,
                                            state_send, RdRqA);
                else
                    send_stallDataAndWait(send_stalled, 
                                          A4F_rdrqA_get_en);
                end if;
            else
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                send_doNothingAndProceed(send_stalled, 
                                         A4F_rdrqA_get_en, 
                                         state_send, RdRqA);
            end if;

        -- STATE 3: RDRQA
        elsif (state_send = RdRqA) then
            A4L_rdrsp_get_en    <= '0';
            A4L_wrrsp_get_en    <= '0';
            A4F_rdrqA_get_en    <= '0';
            A4F_wrrqD_get_en    <= '0';

            if (A4F_rdrqA_get_valid = '1') then
                if(send_stalled = '0') then
                    dest_address    := NoC_address_arch;
                    send_determineNextDataOut(P_A4F, C_AR,
                                              A4F_rdrqA_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext,
                                            send_stalled,
                                            dataOut,
                                            controlOut,
                                            A4F_wrrqA_get_en,
                                            state_send, WrRqA);
                else
                    send_stallDataAndWait(send_stalled,
                                          A4F_wrrqA_get_en);
                end if;
            else
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                send_doNothingAndProceed(send_stalled,
                                         A4F_wrrqA_get_en,
                                         state_send, WrRqA);
            end if;

        -- STATE 4: WRRQA
        elsif (state_send = WrRqA) then
            A4L_wrrsp_get_en    <= '0';
            A4F_rdrqA_get_en    <= '0';
            A4F_wrrqA_get_en    <= '0';
            
            if (A4F_wrrqA_get_valid = '1') then
                A4L_rdrsp_get_en    <= '0';

                if(send_stalled = '0') then
                    dest_address    := NoC_address_arch;
                    send_determineNextDataOut(P_A4F, C_AW,
                                              A4F_wrrqA_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext,
                                            send_stalled,
                                            dataOut,
                                            controlOut,
                                            A4F_wrrqD_get_en,
                                            state_send, WrRqD);
                else
                    send_stallDataAndWait(send_stalled, 
                                          A4F_wrrqD_get_en);
                end if;
            else --TODO: IMPLEMENT EVERYWHERE
                if (send_stalled = '1') then
                    if (controlIn(STALL_GO) = '1') then
                        send_sendDataAndProceed(dataOutNext,
                                                send_stalled,
                                                dataOut,
                                                controlOut,
                                                A4F_wrrqD_get_en,
                                                state_send, WrRqD);
                    -- else remain stalled
                    end if;
                else
                    A4F_wrrqD_get_en    <= '0';

                    if (controlIn(STALL_GO) = '1') then
                        send_unsetPreviousTX(controlOut);
                    end if;

                    send_doNothingAndProceed(send_stalled,
                                             A4L_rdrsp_get_en,
                                             state_send, RdRsp);
                end if;
            end if;

        -- STATE 5: WRRQD (only if valid WrRqA) w/ Burst Mode
        elsif (state_send = WrRqD) then
            A4L_wrrsp_get_en        <= '0';
            A4F_rdrqA_get_en        <= '0';
            A4F_wrrqA_get_en        <= '0';

            if (A4F_wrrqD_get_valid = '1') then
                if(send_stalled = '0') then
                    dest_address    := NoC_address_arch;
                    send_determineNextDataOut(P_A4F, C_W,
                                              A4F_wrrqD_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceedAfterLast(dataOutNext,
                                                     send_stalled,
                                                     dataOut,
                                                     controlOut,
                                                     isLast,
                                                     send_last,
                                                     A4L_rdrsp_get_en,
                                                     A4F_wrrqD_get_en,
                                                     state_send, RdRsp);
                    send_stalled        <= '0';
                    dataOut             <= dataOutNext;
                    controlOut(TX)      <= '1';
                    
                    -- send_last check in else case?
                    if (A4F_wrrqD_get_data(A4F_AXI_wlast'right) = '1') then
                        A4F_wrrqD_get_en    <= '0';

                        controlOut(EOP)     <= '1';
                        A4L_rdrsp_get_en    <= '1';
                        state_send          <= RdRsp;
                        send_last           <= '1'
                    else
                        A4L_rdrsp_get_en    <= '0';
                        
                        controlOut(EOP)     <= '0';
                        A4F_wrrqD_get_en    <= '1';
                        send_last           <= '0';
                    end if;
                else
                    send_stalled        <= '1';
                    A4L_rdrsp_get_en    <= '0';
                    A4F_wrrqD_get_en    <= '0';
                end if;
            else
                if (send_stalled = '1') then
                    if (controlIn(STALL_GO) = '1') then
                        send_sendDataAndProceedAfterLast(dataOutNext,
                                                         send_stalled,
                                                         dataOut,
                                                         controlOut,
                                                         isLast, send_last,
                                                         A4L_rdrsp_get_en,
                                                         A4F_wrrqD_get_en,
                                                         state_send, RdRsp); --todo
                    -- else remain stalled
                    end if;
                else
                    if (controlIn(STALL_GO) = '1') then
                        send_unsetPreviousTX(controlOut);
                    end if;
                    if (send_last = '1') then
                        send_doNothingAndProceed(send_stalled,
                                                 A4L_rdrsp_get_en,
                                                 state_send, RdRsp);
                    else
                        send_doNothingAndWait(send_stalled,
                                              A4L_rdrsp_get_en);
                    end if;
                end if;
            end if;
        end if;

        
        --------------------------------------
        -- NETWORK DATA TO A4L R/W RESPONSE --
        --------------------------------------
        -- If the network sends data or data transfer is stalled because of the receiver not being ready
        -- attempts are made to hand the data to the receiver until it is ready
        --------------------------------------
        
        if (put_stalled = '1') then
            if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                if (dataInStalled(dataIn'left downto dataIn'left - 2) = "110") then
                    A4F_wrrsp_put_en            <= '1';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4F_wrrsp_put_data_tmp      := dataInStalled(NoC_addr_width + A4F_wrrsp_width - 1 downto NoC_addr_width);
                    A4F_wrrsp_put_data          <= A4F_wrrsp_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                    put_last_state          <= WrRsp;
                    put_stalled             <= '0';
                elsif (dataInStalled(dataIn'left downto dataIn'left - 2) = "100") then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '1';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4F_rdrsp_put_data_tmp      := dataInStalled(NoC_addr_width + A4F_rdrsp_width - 1 downto NoC_addr_width);
                    A4F_rdrsp_put_data          <= A4F_rdrsp_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                    put_last_state          <= RdRsp;
                    put_stalled             <= '0';
                elsif (dataInStalled(dataIn'left downto dataIn'left - 2) = "010") then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '1';
                    A4L_wrrqD_put_en            <= '0';
                    A4L_wrrqA_put_data_tmp      := dataIn(NoC_addr_width + A4L_wrrqA_width - 1 downto NoC_addr_width);
                    A4L_wrrqA_put_data          <= A4L_wrrqA_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                    put_last_state          <= WrRqA;
                    put_stalled             <= '0';
                elsif (dataInStalled(dataIn'left downto dataIn'left - 2) = "011") then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '1';
                    A4L_wrrqD_put_data_tmp      := dataIn(NoC_addr_width + A4L_wrrqD_width - 1 downto NoC_addr_width);
                    A4L_wrrqD_put_data          <= A4L_wrrqD_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                    put_last_state          <= WrRqD;
                    put_stalled             <= '0';
                elsif (dataInStalled(dataIn'left downto dataIn'left - 2) = "000") then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '1';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4L_rdrqA_put_data_tmp      := dataIn(NoC_addr_width + A4L_rdrqA_width - 1 downto NoC_addr_width);
                    A4L_rdrqA_put_data          <= A4L_rdrqA_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                    put_last_state          <= WrRqA;
                    put_stalled             <= '0';
                end if;
            end if;
        elsif (controlIn(RX) = '1') then
            if (dataIn(dataIn'left downto dataIn'left - 2) = "110") then
                if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                    (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                    (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                    A4F_wrrsp_put_en            <= '1';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4F_wrrsp_put_data_tmp      := dataIn(NoC_addr_width + A4F_wrrsp_width - 1 downto NoC_addr_width);
                    A4F_wrrsp_put_data          <= A4F_wrrsp_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                else
                    dataInStalled           <= dataIn;
                    controlOut(STALL_GO)    <= '0';
                    put_last_state          <= WrRsp;
                    put_stalled             <= '1';
                end if;
            elsif (dataIn(dataIn'left downto dataIn'left - 2) = "100") then
                if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                    (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                    (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '1';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4F_rdrsp_put_data_tmp      := dataIn(NoC_addr_width + A4F_rdrsp_width - 1 downto NoC_addr_width);
                    A4F_rdrsp_put_data          <= A4F_rdrsp_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                else
                    dataInStalled           <= dataIn;
                    controlOut(STALL_GO)    <= '0';
                    put_last_state          <= RdRsp;
                    put_stalled             <= '1';
                end if;
            elsif (dataIn(dataIn'left downto dataIn'left - 2) = "010") then
                if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                    (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                    (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '1';
                    A4L_wrrqD_put_en            <= '0';
                    A4L_wrrqA_put_data_tmp      := dataIn(NoC_addr_width + A4L_wrrqA_width - 1 downto NoC_addr_width);
                    A4L_wrrqA_put_data          <= A4L_wrrqA_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                else
                    dataInStalled           <= dataIn;
                    controlOut(STALL_GO)    <= '0';
                    put_last_state          <= WrRqA;
                    put_stalled             <= '1';
                end if;
            elsif (dataIn(dataIn'left downto dataIn'left - 2) = "011") then
                if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                    (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                    (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '0';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '1';
                    A4L_wrrqD_put_data_tmp      := dataIn(NoC_addr_width + A4L_wrrqD_width - 1 downto NoC_addr_width);
                    A4L_wrrqD_put_data          <= A4L_wrrqD_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                else
                    dataInStalled           <= dataIn;
                    controlOut(STALL_GO)    <= '0';
                    put_last_state          <= WrRqD;
                    put_stalled             <= '1';
                end if;
            elsif (dataIn(dataIn'left downto dataIn'left - 2) = "000") then
                if ((put_last_state = WrRsp and A4F_wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and A4F_rdrsp_put_ready = '1') or
                    (put_last_state = WrRqA and A4L_wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and A4L_wrrqD_put_ready = '1') or
                    (put_last_state = RdRqA and A4L_rdrqA_put_ready = '1')) then
                    A4F_wrrsp_put_en            <= '0';
                    A4F_rdrsp_put_en            <= '0';
                    A4L_rdrqA_put_en            <= '1';
                    A4L_wrrqA_put_en            <= '0';
                    A4L_wrrqD_put_en            <= '0';
                    A4L_rdrqA_put_data_tmp      := dataIn(NoC_addr_width + A4L_rdrqA_width - 1 downto NoC_addr_width);
                    A4L_rdrqA_put_data          <= A4L_rdrqA_put_data_tmp;
                    controlOut(STALL_GO)    <= '1';
                else
                    dataInStalled           <= dataIn;
                    controlOut(STALL_GO)    <= '0';
                    put_last_state          <= RdRqA;
                    put_stalled             <= '1';
                end if;
            end if;
        elsif (controlIn(RX) = '0') then
            if(A4F_wrrsp_put_ready = '1') then
                A4F_wrrsp_put_en    <= '0';
            end if;
            if(A4F_rdrsp_put_ready = '1') then
                A4F_rdrsp_put_en    <= '0';
            end if;
            if(A4L_wrrqA_put_ready = '1') then
                A4L_wrrqA_put_en    <= '0';
            end if;
            if(A4L_wrrqD_put_ready = '1') then
                A4L_wrrqD_put_en    <= '0';
            end if;
            if(A4L_rdrqA_put_ready = '1') then
                A4L_rdrqA_put_en    <= '0';
            end if;
        end if;
    end if;
    end if;
end process;
end architecture;

-------------------------------------------------------------------------------
