-------------------------------------------------------------------------------
-- Title      : Memory Interface
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : Mem_Ifc.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 2019-12-09
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Memory interface for sending data to and receiving data from
--              PEs (processing elements).
--              Data received from AXI4 Full Master is being received by a
--              Slave and converted to appropriate network data format and the 
--              other way round.
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NIC_pkg.all;
use work.Arke_pkg.all;

-------------------------------------------------------------------------------

entity Mem_Ifc is
    generic (
        A4F_addr_width  : integer;
        A4F_data_width  : integer;
        A4F_id_width    : integer;
        NoC_address     : std_logic_vector;
        NoC_address_map : std_logic_vector
    );
    port (
        signal clk              : in  std_logic := '1';
        signal rst              : in  std_logic := '1';
        signal AXI_arvalid      : out std_logic;
        signal AXI_arready      : in  std_logic;
        signal AXI_araddr       : out std_logic_vector( A4F_addr_width - 1 + A4F_id_width + NoC_addr_width + 20 downto A4F_id_width + NoC_addr_width + 20 );
        signal AXI_arid         : out std_logic_vector( A4F_id_width + NoC_addr_width - 1 + 20 downto 20 );
        signal AXI_arlen        : out std_logic_vector( 19 downto 16 );
        signal AXI_arsize       : out std_logic_vector( 15 downto 13 );
        signal AXI_arburst      : out std_logic_vector( 12 downto 11 );
        signal AXI_arlock       : out std_logic_vector( 10 downto 9 );
        signal AXI_arcache      : out std_logic_vector(  8 downto 6 );
        signal AXI_arprot       : out std_logic_vector(  5 downto 3 );
        signal AXI_arqos        : out std_logic_vector(  2 downto 0 );
        signal AXI_awvalid      : out std_logic;
        signal AXI_awready      : in  std_logic;
        signal AXI_awaddr       : out std_logic_vector( A4F_addr_width - 1 + A4F_id_width + NoC_addr_width + 20 downto A4F_id_width + NoC_addr_width + 20 );
        signal AXI_awid         : out std_logic_vector( A4F_id_width + NoC_addr_width - 1 + 20 downto 20 );
        signal AXI_awlen        : out std_logic_vector( 19 downto 16 );
        signal AXI_awsize       : out std_logic_vector( 15 downto 13 );
        signal AXI_awburst      : out std_logic_vector( 12 downto 11 );
        signal AXI_awlock       : out std_logic_vector( 10 downto 9 );
        signal AXI_awcache      : out std_logic_vector(  8 downto 6 );
        signal AXI_awprot       : out std_logic_vector(  5 downto 3 );
        signal AXI_awqos        : out std_logic_vector(  2 downto 0 );
        signal AXI_wvalid       : out std_logic;
        signal AXI_wready       : in  std_logic;
        signal AXI_wdata        : out std_logic_vector( A4F_data_width - 1 + A4F_id_width + NoC_addr_width + 5 downto A4F_id_width + NoC_addr_width + 5 );
        signal AXI_wid          : out std_logic_vector( A4F_id_width + NoC_addr_width - 1 + 5 downto 5 );
        signal AXI_wstrb        : out std_logic_vector(  4 downto 1 );
        signal AXI_wlast        : out std_logic_vector(  0 downto 0 );
        signal AXI_rready       : out std_logic;
        signal AXI_rvalid       : in  std_logic;
        signal AXI_rdata        : in  std_logic_vector( A4F_data_width - 1 + A4F_id_width + NoC_addr_width + 3 downto A4F_id_width + NoC_addr_width + 3 );
        signal AXI_rid          : in  std_logic_vector( A4F_id_width + NoC_addr_width - 1 + 3 downto 3 );
        signal AXI_rresp        : in  std_logic_vector(  2 downto 1 );
        signal AXI_rlast        : in  std_logic_vector(  0 downto 0 );
        signal AXI_bready       : out std_logic;
        signal AXI_bvalid       : in  std_logic;
        signal AXI_bid          : in  std_logic_vector( A4F_id_width + NoC_addr_width - 1 + 2 downto 2 );
        signal AXI_bresp        : in  std_logic_vector(  1 downto 0 );

        signal dataOut          : out std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlOut       : out std_logic_vector( CONTROL_WIDTH - 1 downto 0 );
        signal dataIn           : in  std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlIn        : in  std_logic_vector( CONTROL_WIDTH - 1 downto 0 )
    );
end Mem_Ifc;

-------------------------------------------------------------------------------

architecture Behavioral of Mem_Ifc is

    constant A4F_rdrqa_width    : natural := A4F_addr_width + A4F_id_width + NoC_addr_width + 20;
    constant A4F_wrrqa_width    : natural := A4F_addr_width + A4F_id_width + NoC_addr_width + 20;
    constant A4F_wrrqd_width    : natural := A4F_data_width + A4F_id_width + NoC_addr_width + 5;
    constant A4F_rdrsp_width    : natural := A4F_data_width + A4F_id_width + NoC_addr_width + 3;
    constant A4F_wrrsp_width    : natural := A4F_id_width + NoC_addr_width + 2;

    constant DIM_X_W    : integer := Log2(DIM_X);
    constant DIM_Y_W    : integer := Log2(DIM_Y);
    constant DIM_Z_W    : integer := Log2(DIM_Z);
    constant ADDR_W     : integer := DIM_X_W + DIM_Y_W + DIM_Z_W;

    type ADDR_MAP_TYPE is array (0 to DIM_X * DIM_Y * DIM_Z - 1) of std_logic_vector(ADDR_W - 1 downto 0);
    type State is (RdRsp, WrRsp, RdRqA, WrRqA, WrRqD);
    type StallState is (None, RdRqA, WrRqA, WrRqD);

    function to_ADDR_MAP_TYPE (
        slv : std_logic_vector
        ) return ADDR_MAP_TYPE is
        variable result : ADDR_MAP_TYPE := (others => (others => '0'));
    begin
        for i in 0 to DIM_X * DIM_Y * DIM_Z - 1 loop
            result(i) := slv(i * NoC_addr_width to (i+1) * NoC_addr_width - 1);
        end loop;
        return result;
    end function;

    constant address_map_c : ADDR_MAP_TYPE := to_ADDR_MAP_TYPE(NoC_address_map);

    signal rdrqA_put_ready : std_logic;
    signal rdrqA_put_en    : std_logic;
    signal rdrqA_put_data  : std_logic_vector(A4F_rdrqa_width - 1 downto 0);
    signal wrrqA_put_ready : std_logic;
    signal wrrqA_put_en    : std_logic;
    signal wrrqA_put_data  : std_logic_vector(A4F_wrrqa_width - 1 downto 0);
    signal wrrqD_put_ready : std_logic;
    signal wrrqD_put_en    : std_logic;
    signal wrrqD_put_data  : std_logic_vector(A4F_wrrqd_width - 1 downto 0);
    signal rdrsp_get_valid : std_logic;
    signal rdrsp_get_en    : std_logic;
    signal rdrsp_get_data  : std_logic_vector(A4F_rdrsp_width - 1 downto 0);
    signal wrrsp_get_valid : std_logic;
    signal wrrsp_get_en    : std_logic;
    signal wrrsp_get_data  : std_logic_vector(A4F_wrrsp_width - 1 downto 0);

    signal dataInStalled   : std_logic_vector(dataIn'range);
    signal put_last_state  : StallState;
    signal put_stalled     : std_logic;
    signal state_send      : State;

    begin

        AXI_Master : AXI4_Full_Master
        generic map (
            A4F_addr_width  => A4F_addr_width,
            A4F_data_width  => A4F_data_width,
            A4F_id_width    => A4F_id_width + NoC_addr_width
        )
        port map (
            clk             => clk,
            rst             => rst,
            AXI_arvalid     => AXI_arvalid,
            AXI_arready     => AXI_arready,
            AXI_araddr      => AXI_araddr,
            AXI_arid        => AXI_arid,
            AXI_arlen       => AXI_arlen,
            AXI_arsize      => AXI_arsize,
            AXI_arburst     => AXI_arburst,
            AXI_arlock      => AXI_arlock,
            AXI_arcache     => AXI_arcache,
            AXI_arprot      => AXI_arprot,
            AXI_arqos       => AXI_arqos,
            AXI_awvalid     => AXI_awvalid,
            AXI_awready     => AXI_awready,
            AXI_awaddr      => AXI_awaddr,
            AXI_awid        => AXI_awid,
            AXI_awlen       => AXI_awlen,
            AXI_awsize      => AXI_awsize,
            AXI_awburst     => AXI_awburst,
            AXI_awlock      => AXI_awlock,
            AXI_awcache     => AXI_awcache,
            AXI_awprot      => AXI_awprot,
            AXI_awqos       => AXI_awqos,
            AXI_wvalid      => AXI_wvalid,
            AXI_wready      => AXI_wready,
            AXI_wdata       => AXI_wdata,
            AXI_wid         => AXI_wid,
            AXI_wstrb       => AXI_wstrb,
            AXI_wlast       => AXI_wlast,
            AXI_rready      => AXI_rready,
            AXI_rvalid      => AXI_rvalid,
            AXI_rdata       => AXI_rdata,
            AXI_rid         => AXI_rid,
            AXI_rresp       => AXI_rresp,
            AXI_rlast       => AXI_rlast,
            AXI_bready      => AXI_bready,
            AXI_bvalid      => AXI_bvalid,
            AXI_bid         => AXI_bid,
            AXI_bresp       => AXI_bresp,
            rdrqA_put_en    => rdrqA_put_en,
            rdrqA_put_ready => rdrqA_put_ready,
            rdrqA_put_data  => rdrqA_put_data,
            wrrqA_put_en    => wrrqA_put_en,
            wrrqA_put_ready => wrrqA_put_ready,
            wrrqA_put_data  => wrrqA_put_data,
            wrrqD_put_en    => wrrqD_put_en,
            wrrqD_put_ready => wrrqD_put_ready,
            wrrqD_put_data  => wrrqD_put_data,
            rdrsp_get_valid => rdrsp_get_valid,
            rdrsp_get_en    => rdrsp_get_en,
            rdrsp_get_data  => rdrsp_get_data,
            wrrsp_get_valid => wrrsp_get_valid,
            wrrsp_get_en    => wrrsp_get_en,
            wrrsp_get_data  => wrrsp_get_data
        );

        process(clk)

            variable rdrqA_put_data_tmp : std_logic_vector(A4F_rdrqa_width - 1 downto 0);
            variable wrrqA_put_data_tmp : std_logic_vector(A4F_wrrqa_width - 1 downto 0);
            variable wrrqD_put_data_tmp : std_logic_vector(A4F_wrrqd_width - 1 downto 0);
            variable rdrsp_get_data_tmp : std_logic_vector(A4F_rdrsp_width - 1 downto 0);
            variable wrrsp_get_data_tmp : std_logic_vector(A4F_wrrsp_width - 1 downto 0);
            
            variable dest_address       : std_logic_vector(NoC_addr_width - 1 downto 0);
            
        begin if rising_edge(clk) then
            -----------
            -- RESET --
            -----------
            if (rst = '1') then
                controlOut          <= "100";
                dataOut             <= (others => '0');
                state_send          <= RdRsp;
                put_stalled         <= '0';
                put_last_state      <= RdRqA;
            else

            --------------------------------------
            -- A4F R/W RESPONSE TO NETWORK DATA --
            --------------------------------------
            -- Incoming r/w responses are being handed over to the network as they are valid using round-robin.
            -- If a response is valid, but the local router isn't able to receive data, the state remains the same
            -- otherwise it changes to the next state to look for valid data.
            -- The network destination is chosen by a address map in conjunction with the AXI address.
            --------------------------------------
            
            -- STATE 1: RDRSP
            if (state_send = RdRsp) then
                wrrsp_get_en        <= '0';

                if (rdrsp_get_valid = '1') then
                    if (controlIn(STALL_GO) = '1') then
                        rdrsp_get_data_tmp  := rdrsp_get_data;
                        dest_address        := rdrsp_get_data(AXI_rid'left downto AXI_rid'right + A4F_id_width);
                        dataOut             <= '0' & "00" & ZERO(dataOut'left - 3 downto rdrsp_get_data_tmp'length + NoC_addr_width) & rdrsp_get_data_tmp & dest_address;
                        controlOut(TX)      <= '1';
                        controlOut(EOP)     <= '1';

                        rdrsp_get_en    <= '1';
                        state_send          <= WrRsp;
                    else
                        rdrsp_get_en    <= '0';
                    end if;
                else
                    if (controlIn(STALL_GO) = '1') then
                        controlOut(TX)      <= '0';
                        controlOut(EOP)     <= '0';
                    end if;

                    rdrsp_get_en        <= '0';
                    state_send              <= WrRsp;
                end if;

            -- STATE 2: WRRSP
            elsif (state_send = WrRsp) then
                rdrsp_get_en        <= '0';

                if (wrrsp_get_valid = '1') then
                    if (controlIn(STALL_GO) = '1') then
                        wrrsp_get_data_tmp  := wrrsp_get_data;
                        dest_address        := rdrsp_get_data(AXI_bid'left downto AXI_bid'right + A4F_id_width);
                        dataOut             <= '0' & "10" & ZERO(dataOut'left - 3 downto wrrsp_get_data_tmp'length + NoC_addr_width) & wrrsp_get_data_tmp & dest_address;
                        controlOut(TX)      <= '1';
                        controlOut(EOP)     <= '0';

                        wrrsp_get_en    <= '1';
                        state_send          <= RdRsp;
                    else
                        wrrsp_get_en    <= '0';
                    end if;
                else
                    if (controlIn(STALL_GO) = '1') then
                        controlOut(TX)      <= '0';
                        controlOut(EOP)     <= '0';
                    end if;

                    wrrsp_get_en        <= '0';
                    state_send              <= RdRsp;
                end if;
            end if;

            
            -------------------------------------
            -- NETWORK DATA TO A4F R/W REQUEST --
            -------------------------------------
            -- If the network sends data or data transfer is stalled because of the receiver not being ready
            -- attempts are made to hand the data to the receiver until it is ready
            -------------------------------------

            if (put_stalled = '1') then
                if ((put_last_state = RdRqA and rdrqA_put_ready = '1') or
                    (put_last_state = WrRqA and wrrqA_put_ready = '1') or
                    (put_last_state = WrRqD and wrrqD_put_ready = '1')) then
                    if (dataInStalled(dataIn'left - 1 downto dataIn'left - 2) = "10") then
                        rdrqA_put_en            <= '0';
                        wrrqD_put_en            <= '0';
                        wrrqA_put_en            <= '1';
                        wrrqA_put_data_tmp      := dataInStalled(A4F_wrrqA_width - 1 + NoC_addr_width downto NoC_addr_width);
                        wrrqA_put_data          <= wrrqA_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                        put_last_state          <= WrRqA;
                        put_stalled             <= '0';
                    elsif (dataInStalled(dataIn'left - 1 downto dataIn'left - 2) = "11") then
                        rdrqA_put_en            <= '0';
                        wrrqA_put_en            <= '0';
                        wrrqD_put_en            <= '1';
                        wrrqD_put_data_tmp      := dataInStalled(A4F_wrrqD_width - 1 + NoC_addr_width downto NoC_addr_width);
                        wrrqD_put_data          <= wrrqD_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                        put_last_state          <= WrRqD;
                        put_stalled             <= '0';
                    elsif (dataInStalled(dataIn'left - 1 downto dataIn'left - 2) = "00") then
                        wrrqA_put_en            <= '0';
                        wrrqD_put_en            <= '0';
                        rdrqA_put_en            <= '1';
                        rdrqA_put_data_tmp      := dataInStalled(A4F_rdrqA_width - 1 + NoC_addr_width downto NoC_addr_width);
                        rdrqA_put_data          <= rdrqA_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                        put_last_state          <= RdRqA;
                        put_stalled             <= '0';
                    end if;
                end if;
            elsif (controlIn(RX) = '1') then
                if (dataIn(dataIn'left - 1 downto dataIn'left - 2) = "10") then
                    if ((put_last_state = WrRqA and wrrqA_put_ready = '1') or
                        (put_last_state = WrRqD and wrrqD_put_ready = '1') or
                        (put_last_state = RdRqA and rdrqA_put_ready = '1')) then
                        rdrqA_put_en            <= '0';
                        wrrqD_put_en            <= '0';
                        wrrqA_put_en            <= '1';
                        wrrqA_put_data_tmp      := dataIn(A4F_wrrqA_width - 1 + NoC_addr_width downto NoC_addr_width);
                        wrrqA_put_data          <= wrrqA_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                    else
                        dataInStalled           <= dataIn;
                        controlOut(STALL_GO)    <= '0';
                        put_last_state          <= WrRqA;
                        put_stalled             <= '1';
                    end if;
                elsif (dataIn(dataIn'left - 1 downto dataIn'left - 2) = "11") then
                    if ((put_last_state = WrRqA and wrrqA_put_ready = '1') or
                        (put_last_state = WrRqD and wrrqD_put_ready = '1') or
                        (put_last_state = RdRqA and rdrqA_put_ready = '1')) then
                        rdrqA_put_en            <= '0';
                        wrrqA_put_en            <= '0';
                        wrrqD_put_en            <= '1';
                        wrrqD_put_data_tmp      := dataIn(A4F_wrrqD_width - 1 + NoC_addr_width downto NoC_addr_width);
                        wrrqD_put_data          <= wrrqD_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                    else
                        dataInStalled           <= dataIn;
                        controlOut(STALL_GO)    <= '0';
                        put_last_state          <= WrRqD;
                        put_stalled             <= '1';
                    end if;
                elsif (dataIn(dataIn'left - 1 downto dataIn'left - 2) = "00") then
                    if ((put_last_state = WrRqA and wrrqA_put_ready = '1') or
                        (put_last_state = WrRqD and wrrqD_put_ready = '1') or
                        (put_last_state = RdRqA and rdrqA_put_ready = '1')) then
                        wrrqA_put_en            <= '0';
                        wrrqD_put_en            <= '0';
                        rdrqA_put_en            <= '1';
                        rdrqA_put_data_tmp      := dataIn(A4F_rdrqA_width - 1 + NoC_addr_width downto NoC_addr_width);
                        rdrqA_put_data          <= rdrqA_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                    else
                        dataInStalled           <= dataIn;
                        controlOut(STALL_GO)    <= '0';
                        put_last_state          <= RdRqA;
                        put_stalled             <= '1';
                    end if;
                end if;
            elsif (controlIn(RX) = '0') then
                if(wrrqA_put_ready = '1') then
                    wrrqA_put_en    <= '0';
                end if;
                if(wrrqD_put_ready = '1') then
                    wrrqA_put_en    <= '0';
                end if;
                if(rdrqA_put_ready = '1') then
                    rdrqA_put_en    <= '0';
                end if;
            end if;

            end if;
        end if;
    end process;
end architecture;

-------------------------------------------------------------------------------
