-------------------------------------------------------------------------------
-- Title      : Architecture Interface
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : Arch_Ifc.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 2019-11-24
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Network interface for TaPaSCo's architecture sending data to 
--              and receiving data from PEs (processing elements).
--              Data received from AXI4 Lite Master is being received by a
--              Slave and converted to appropriate network data format and the 
--              other way round.
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.NIC_pkg.all;
use work.Arke_pkg.all;

-------------------------------------------------------------------------------

entity Arch_Ifc is
    generic (
        A4L_addr_width  : integer := 32;
        A4L_data_width  : integer := 32;
        A4L_strb_width  : integer := 4;
        NoC_address     : std_logic_vector;

        AXI_base_addr   : std_logic_vector;
        AXI_ranges      : std_logic_vector;
        AXI_ranges_cnt  : integer := 18;
        NoC_targets     : std_logic_vector
    );
    port (
        signal clk              : in  std_logic := '1';
        signal rst              : in  std_logic := '1';
        signal AXI_arvalid      : in  std_logic;
        signal AXI_arready      : out std_logic;
        signal AXI_araddr       : in  std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
        signal AXI_arprot       : in  std_logic_vector( 2 downto 0 );
        signal AXI_awvalid      : in  std_logic;
        signal AXI_awready      : out std_logic;
        signal AXI_awaddr       : in  std_logic_vector( A4L_addr_width - 1 + 3 downto 3 );
        signal AXI_awprot       : in  std_logic_vector( 2 downto 0 );
        signal AXI_wvalid       : in  std_logic;
        signal AXI_wready       : out std_logic;
        signal AXI_wdata        : in  std_logic_vector( A4L_data_width - 1 + A4L_strb_width downto A4L_strb_width );
        signal AXI_wstrb        : in  std_logic_vector( A4L_strb_width - 1 downto 0 );
        signal AXI_rready       : in  std_logic;
        signal AXI_rvalid       : out std_logic;
        signal AXI_rdata        : out std_logic_vector( A4L_data_width - 1 + 2 downto 2 );
        signal AXI_rresp        : out std_logic_vector( 1 downto 0 );
        signal AXI_bready       : in  std_logic;
        signal AXI_bvalid       : out std_logic;
        signal AXI_bresp        : out std_logic_vector( 1 downto 0 );

        signal dataOut          : out std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlOut       : out std_logic_vector( CONTROL_WIDTH - 1 downto 0 );
        signal dataIn           : in  std_logic_vector(    DATA_WIDTH - 1 downto 0 );
        signal controlIn        : in  std_logic_vector( CONTROL_WIDTH - 1 downto 0 )
    );
end Arch_Ifc;

-------------------------------------------------------------------------------

architecture Behavioral of Arch_Ifc is

    constant A4L_rdrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqd_width    : natural := A4L_data_width + A4L_strb_width;
    constant A4L_rdrsp_width    : natural := A4L_data_width + 2;
    constant A4L_wrrsp_width    : natural := 2;

    constant DIM_X_W    : integer := Log2(DIM_X);
    constant DIM_Y_W    : integer := Log2(DIM_Y);
    constant DIM_Z_W    : integer := Log2orZero(DIM_Z);
    constant ADDR_W     : integer := DIM_X_W + DIM_Y_W + DIM_Z_W;

    type ChannelsType is (None, RdRsp, WrRsp, RdRqA, WrRqA, WrRqD);

    
    -- AXI ADDRESS MAP GENERATION --
    type AXI_ADDR_MAP_TYPE is array (0 to AXI_ranges_cnt) of std_logic_vector(AXI_base_addr'range);

    function generate_AXI_ADDR_MAP return AXI_ADDR_MAP_TYPE is
        constant one_c          : unsigned(AXI_base_addr'range) := unsigned(ZERO(AXI_base_addr'reverse_range)) + unsigned'(B"1");
        variable bits_to_shift  : integer := 0;
        variable result         : AXI_ADDR_MAP_TYPE := (others => (others => '0'));
    begin
        -- lower border of PE(0)
        result(0) := AXI_base_addr;
        for i in 0 to AXI_ranges_cnt - 1 loop
            -- the 5 bits representing the axi address range of the PE determine the shift amount, minimum shift is 12 representing a 4k range
            bits_to_shift   := 12 + to_integer(unsigned(AXI_ranges(i * 5 to (i+1) * 5 - 1)));
            -- write upper border by shifting 1 by the determined shift amount and adding the lower border
            result(i+1)     := std_logic_vector(unsigned(result(i)) + shift_left(one_c, bits_to_shift));
        end loop;
        return result;
    end function;


    -- NOC ADDRESS MAP GENERATION --
    type NOC_ADDR_MAP_TYPE is array (0 to AXI_ranges_cnt - 1) of std_logic_vector(ADDR_W - 1 downto 0);

    -- unused, address map given by parameter to handle multiple ranges to one target
    function generate_NOC_ADDR_MAP return NOC_ADDR_MAP_TYPE is
        variable result : NOC_ADDR_MAP_TYPE := (others => (others => '0'));
        variable i      : integer := 0;
        variable x_addr : std_logic_vector(DIM_X_W - 1 downto 0) := (others => '0');
        variable y_addr : std_logic_vector(DIM_Y_W - 1 downto 0) := (others => '0');
        variable z_addr : std_logic_vector(DIM_Z_W - 1 downto 0) := (others => '0');
    begin
        -- iterate through the axes
        for z in 0 to DIM_Z - 1 loop
            for y in 0 to DIM_Y - 1 loop
                for x in 0 to DIM_X - 1 loop
                    -- array boundary check
                    if (i < AXI_ranges_cnt) then 
                        -- leaving 0,0,0 out for arch_ifc
                        if ((x = 0) and (y = 0) and (z = 0)) then
                            null;   
                        else
                            x_addr := std_logic_vector(to_unsigned(x, x_addr'length));
                            y_addr := std_logic_vector(to_unsigned(y, y_addr'length));
                            z_addr := std_logic_vector(to_unsigned(z, z_addr'length));
                            result(i) := x_addr & y_addr & z_addr;
                            i := i + 1;
                        end if;
                    end if;
                end loop;
            end loop;
        end loop;
        return result;
    end function;

    function read_NOC_TARGETS return NOC_ADDR_MAP_TYPE is
        variable result : NOC_ADDR_MAP_TYPE := (others => (others => '0'));
    begin
        for i in 0 to AXI_ranges_cnt - 1 loop
            -- every ADDR_W bits from NoC_targets parameter is read into result array 
            result(i)     := std_logic_vector(unsigned(NoC_targets(i * ADDR_W to (i+1) * ADDR_W - 1)));
        end loop;
        return result;
    end function;

    -- GENERATE THE CONSTANTS --
    constant axi_addr_map_c : AXI_ADDR_MAP_TYPE := generate_AXI_ADDR_MAP;
    constant noc_addr_map_c : NOC_ADDR_MAP_TYPE := read_NOC_TARGETS;

    signal rdrqA_get_valid : std_logic;
    signal rdrqA_get_en    : std_logic;
    signal rdrqA_get_data  : std_logic_vector(A4L_rdrqa_width - 1 downto 0);
    signal wrrqA_get_valid : std_logic;
    signal wrrqA_get_en    : std_logic;
    signal wrrqA_get_data  : std_logic_vector(A4L_wrrqa_width - 1 downto 0);
    signal wrrqD_get_valid : std_logic;
    signal wrrqD_get_en    : std_logic;
    signal wrrqD_get_data  : std_logic_vector(A4L_wrrqd_width - 1 downto 0);
    signal rdrsp_put_ready : std_logic;
    signal rdrsp_put_en    : std_logic;
    signal rdrsp_put_data  : std_logic_vector(A4L_rdrsp_width - 1 downto 0);
    signal wrrsp_put_ready : std_logic;
    signal wrrsp_put_en    : std_logic;
    signal wrrsp_put_data  : std_logic_vector(A4L_wrrsp_width - 1 downto 0);

    signal dataInStalled   : std_logic_vector(dataIn'range);
    signal put_last_state  : ChannelsType;
    signal put_stalled     : std_logic;
    signal state_send      : ChannelsType;
    signal send_stalled    : std_logic;


    procedure determineTargetPE(variable axi_address    : in  std_logic_vector;
                                variable dest_address   : out std_logic_vector) is
        variable targetPE : integer := 0;
    begin
        -- compare every axi range to the given axi_address and determine the targetPE
        for i in 0 to AXI_ranges_cnt - 1 loop
            if (unsigned(axi_addr_map_c(i)) <= unsigned(axi_address) and
                unsigned(axi_address) < unsigned(axi_addr_map_c(i+1))) then
                targetPE := i;
            end if;
        end loop;
        -- select the noc address
        dest_address := noc_addr_map_c(targetPE);
    end procedure;


    begin
        AXI_Slave : AXI4_Lite_Slave
        generic map (
            A4L_addr_width  => A4L_addr_width,
            A4L_data_width  => A4L_data_width,
            A4L_strb_width  => A4L_strb_width
        )
        port map (
            clk             => clk,
            rst             => rst,
            AXI_arvalid     => AXI_arvalid,
            AXI_arready     => AXI_arready,
            AXI_araddr      => AXI_araddr,
            AXI_arprot      => AXI_arprot,
            AXI_awvalid     => AXI_awvalid,
            AXI_awready     => AXI_awready,
            AXI_awaddr      => AXI_awaddr,
            AXI_awprot      => AXI_awprot,
            AXI_wvalid      => AXI_wvalid,
            AXI_wready      => AXI_wready,
            AXI_wdata       => AXI_wdata,
            AXI_wstrb       => AXI_wstrb,
            AXI_rready      => AXI_rready,
            AXI_rvalid      => AXI_rvalid,
            AXI_rdata       => AXI_rdata,
            AXI_rresp       => AXI_rresp,
            AXI_bready      => AXI_bready,
            AXI_bvalid      => AXI_bvalid,
            AXI_bresp       => AXI_bresp,
            rdrqA_get_valid => rdrqA_get_valid,
            rdrqA_get_en    => rdrqA_get_en,
            rdrqA_get_data  => rdrqA_get_data,
            wrrqA_get_valid => wrrqA_get_valid,
            wrrqA_get_en    => wrrqA_get_en,
            wrrqA_get_data  => wrrqA_get_data,
            wrrqD_get_valid => wrrqD_get_valid,
            wrrqD_get_en    => wrrqD_get_en,
            wrrqD_get_data  => wrrqD_get_data,
            rdrsp_put_ready => rdrsp_put_ready,
            rdrsp_put_en    => rdrsp_put_en,
            rdrsp_put_data  => rdrsp_put_data,
            wrrsp_put_ready => wrrsp_put_ready,
            wrrsp_put_en    => wrrsp_put_en,
            wrrsp_put_data  => wrrsp_put_data
        );
                    
        process(clk)

            variable rdrqA_get_data_tmp : std_logic_vector(A4L_rdrqA_width - 1 downto 0);
            variable wrrqA_get_data_tmp : std_logic_vector(A4L_wrrqA_width - 1 downto 0);
            variable wrrqD_get_data_tmp : std_logic_vector(A4L_wrrqD_width - 1 downto 0);
            variable rdrsp_put_data_tmp : std_logic_vector(A4L_rdrsp_width - 1 downto 0);
            variable wrrsp_put_data_tmp : std_logic_vector(A4L_wrrsp_width - 1 downto 0);
            
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
                dest_address        := (others => '1');
            else

            -------------------------------------
            -- A4L R/W REQUEST TO NETWORK DATA --
            -------------------------------------
            -- Incoming r/w requests are being handed over to the network as they are valid using round-robin.
            -- If a request is valid, but the local router isn't able to receive data, the state remains the same
            -- otherwise it changes to the next state to look for valid data.
            -- The network destination is chosen by a address map in conjunction with the AXI address.
            -------------------------------------
            
            -- STATE 0: INIT
            if (state_send = None) then
                send_stalled        <= '0';
                rdrqA_get_en        <= '1';
                state_send          <= RdRqA;

            -- STATE 1: RDRQA
            elsif (state_send = RdRqA) then
                rdrqA_get_en        <= '0';
                wrrqD_get_en        <= '0';

                if (rdrqA_get_valid = '1' or send_stalled = '1') then
                    if(send_stalled = '0') then
                        rdrqA_get_data_tmp  := rdrqA_get_data;
                        determineTargetPE(rdrqA_get_data_tmp(AXI_araddr'left downto AXI_araddr'right),
                                          dest_address);
                        dataOutNext         := '0' & "00" & ZERO(dataOut'left - 3 downto rdrqA_get_data_tmp'length + NoC_addr_width) & rdrqA_get_data_tmp & dest_address;
                    end if;

                    if (controlIn(STALL_GO) = '1') then
                        send_stalled        <= '0';
                        dataOut             <= dataOutNext;
                        controlOut(TX)      <= '1';
                        controlOut(EOP)     <= '1';

                        wrrqA_get_en        <= '1';
                        state_send          <= WrRqA;
                    else
                        send_stalled        <= '1';
                        wrrqA_get_en        <= '0';
                    end if;
                else
                    send_stalled        <= '0';
                    
                    if (controlIn(STALL_GO) = '1') then
                        controlOut(TX)      <= '0';
                        controlOut(EOP)     <= '0';
                    end if;

                    wrrqA_get_en        <= '1';
                    state_send          <= WrRqA;
                end if;

            -- STATE 2: WRRQA
            elsif (state_send = WrRqA) then
                wrrqA_get_en        <= '0';

                if (wrrqA_get_valid = '1' or send_stalled = '1') then
                    rdrqA_get_en        <= '0';

                    if(send_stalled = '0') then
                        wrrqA_get_data_tmp  := wrrqA_get_data;
                        determineTargetPE(wrrqA_get_data_tmp(AXI_awaddr'left downto AXI_awaddr'right),
                                          dest_address);
                        dataOutNext         := '0' & "10" & ZERO(dataOut'left - 3 downto wrrqA_get_data_tmp'length + NoC_addr_width) & wrrqA_get_data_tmp & dest_address;
                    end if;

                    if (controlIn(STALL_GO) = '1') then
                        send_stalled        <= '0';
                        dataOut             <= dataOutNext;
                        controlOut(TX)      <= '1';
                        controlOut(EOP)     <= '0';

                        wrrqD_get_en        <= '1';
                        state_send          <= WrRqD;
                    else
                        send_stalled        <= '1';
                        wrrqD_get_en        <= '0';
                    end if;
                else
                    send_stalled        <= '0';
                    wrrqD_get_en        <= '0';

                    if (controlIn(STALL_GO) = '1') then
                        controlOut(TX)      <= '0';
                        controlOut(EOP)     <= '0';
                    end if;

                    rdrqA_get_en        <= '1';
                    state_send          <= RdRqA; --if no valid wr address continue with rd -- CHANGED was wrong
                end if;

            -- STATE 3: WRRQD
            else
                wrrqA_get_en        <= '0';
                wrrqD_get_en        <= '0';

                if (wrrqD_get_valid = '1' or send_stalled = '1') then
                    if(send_stalled = '0') then
                        wrrqD_get_data_tmp  := wrrqD_get_data;
                        dataOutNext         := '0' & "11" & ZERO(dataOut'left - 3 downto wrrqD_get_data_tmp'length + NoC_addr_width) & wrrqD_get_data_tmp & dest_address;
                    end if;

                    if (controlIn(STALL_GO) = '1') then
                        send_stalled        <= '0';
                        dataOut             <= dataOutNext;
                        controlOut(TX)      <= '1';
                        controlOut(EOP)     <= '1';

                        rdrqA_get_en        <= '1';
                        state_send          <= RdRqA;
                    else
                        send_stalled        <= '1';
                        rdrqA_get_en        <= '0';
                    end if;
                else
                    send_stalled        <= '0';

                    if (controlIn(STALL_GO) = '1') then
                        controlOut(TX)      <= '0';
                        controlOut(EOP)     <= '0';
                    end if;

                    rdrqA_get_en        <= '0';
                    --if not valid remain in state until valid to complete the packet
                end if;
            end if;
            

            --------------------------------------
            -- NETWORK DATA TO A4L R/W RESPONSE --
            --------------------------------------
            -- If the network sends data or data transfer is stalled because of the receiver not being ready
            -- attempts are made to hand the data to the receiver until it is ready
            --------------------------------------

            if (put_stalled = '1') then
                if ((put_last_state = WrRsp and wrrsp_put_ready = '1') or
                    (put_last_state = RdRsp and rdrsp_put_ready = '1')) then
                    if (dataInStalled(dataIn'left - 1) = '1') then
                        rdrsp_put_en            <= '0';
                        wrrsp_put_en            <= '1';
                        wrrsp_put_data_tmp      := dataInStalled(NoC_addr_width + A4L_wrrsp_width - 1 downto NoC_addr_width);
                        wrrsp_put_data          <= wrrsp_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                        put_last_state          <= WrRsp;
                        put_stalled             <= '0';
                    elsif (dataIn(dataIn'left - 1) = '0') then
                        wrrsp_put_en            <= '0';
                        rdrsp_put_en            <= '1';
                        rdrsp_put_data_tmp      := dataInStalled(NoC_addr_width + A4L_rdrsp_width - 1 downto NoC_addr_width);
                        rdrsp_put_data          <= rdrsp_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                        put_last_state          <= RdRsp;
                        put_stalled             <= '0';
                    end if;
                end if;
            elsif (controlIn(RX) = '1') then
                if (dataIn(dataIn'left - 1) = '1') then
                    if ((put_last_state = WrRsp and wrrsp_put_ready = '1') or
                        (put_last_state = RdRsp and rdrsp_put_ready = '1')) then
                        rdrsp_put_en            <= '0';
                        wrrsp_put_en            <= '1';
                        wrrsp_put_data_tmp      := dataIn(NoC_addr_width + A4L_wrrsp_width - 1 downto NoC_addr_width);
                        wrrsp_put_data          <= wrrsp_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                    else
                        dataInStalled           <= dataIn;
                        controlOut(STALL_GO)    <= '0';
                        put_last_state          <= WrRsp;
                        put_stalled             <= '1';
                    end if;
                elsif (dataIn(dataIn'left - 1) = '0') then
                    if ((put_last_state = WrRsp and wrrsp_put_ready = '1') or
                        (put_last_state = RdRsp and rdrsp_put_ready = '1')) then
                        wrrsp_put_en            <= '0';
                        rdrsp_put_en            <= '1';
                        rdrsp_put_data_tmp      := dataIn(NoC_addr_width + A4L_rdrsp_width - 1 downto NoC_addr_width);
                        rdrsp_put_data          <= rdrsp_put_data_tmp;
                        controlOut(STALL_GO)    <= '1';
                    else
                        dataInStalled           <= dataIn;
                        controlOut(STALL_GO)    <= '0';
                        put_last_state          <= RdRsp;
                        put_stalled             <= '1';
                    end if;
                end if;
            elsif (controlIn(RX) = '0') then
                if(wrrsp_put_ready = '1') then
                    wrrsp_put_en    <= '0';
                end if;
                if(rdrsp_put_ready = '1') then
                    rdrsp_put_en    <= '0';
                end if;
            end if;

            end if;
        end if;
    end process;
end architecture;

-------------------------------------------------------------------------------
