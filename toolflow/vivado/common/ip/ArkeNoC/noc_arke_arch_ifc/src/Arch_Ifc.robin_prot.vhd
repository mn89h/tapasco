-------------------------------------------------------------------------------
-- Title      : Architecture Interface
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : Arch_Ifc.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 2019-11-24
-- Last update: 2019-01-11
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
        NoC_address     : std_logic_vector;

        AXI_base_addr   : std_logic_vector;
        AXI_ranges      : std_logic_vector;
        PE_count        : integer := 18
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
        signal AXI_wdata        : in  std_logic_vector( A4L_data_width - 1 + 4 downto 4 );
        signal AXI_wstrb        : in  std_logic_vector( 3 downto 0 );
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

    ---------------
    -- Constants --
    ---------------
    constant A4L_rdrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqa_width    : natural := A4L_addr_width + 3;
    constant A4L_wrrqd_width    : natural := A4L_data_width + 4;
    constant A4L_rdrsp_width    : natural := A4L_data_width + 2;
    constant A4L_wrrsp_width    : natural := 2;

    constant DIM_X_W    : integer := Log2(DIM_X);
    constant DIM_Y_W    : integer := Log2(DIM_Y);
    constant DIM_Z_W    : integer := Log2(DIM_Z);
    constant ADDR_W     : integer := DIM_X_W + DIM_Y_W + DIM_Z_W;

    -------------
    -- Signals --
    -------------
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

    --------------------
    -- Init Functions --
    --------------------
    -- AXI ADDRESS MAP GENERATION --
    type AXI_ADDR_MAP_TYPE is array (0 to PE_count) of std_logic_vector(AXI_base_addr'range);

    function generate_AXI_ADDR_MAP return AXI_ADDR_MAP_TYPE is
        constant one_c          : unsigned(AXI_base_addr'range) := unsigned(ZERO(AXI_base_addr'reverse_range)) + unsigned'(B"1");
        variable bits_to_shift  : integer := 0;
        variable result         : AXI_ADDR_MAP_TYPE := (others => (others => '0'));
    begin
        -- lower border of PE(0)
        result(0) := AXI_base_addr;
        for i in 0 to PE_count - 1 loop
            -- the 5 bits representing the axi address range of the PE determine the shift amount, minimum shift is 2 representing a 4k range
            bits_to_shift   := 2 + to_integer(unsigned(AXI_ranges(i * 5 to (i+1) * 5 - 1)));
            -- write upper border by shifting 1 by the determined shift amount and adding the lower border
            result(i+1)     := std_logic_vector(unsigned(result(i)) + shift_left(one_c, bits_to_shift));
        end loop;
        return result;
    end function;


    -- NOC ADDRESS MAP GENERATION --
    type NOC_ADDR_MAP_TYPE is array (0 to PE_count - 1) of std_logic_vector(ADDR_W - 1 downto 0);

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
                    if (i < PE_count) then 
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

    -- GENERATE THE CONSTANTS --
    constant axi_addr_map_c : AXI_ADDR_MAP_TYPE := generate_AXI_ADDR_MAP;
    constant noc_addr_map_c : NOC_ADDR_MAP_TYPE := generate_NOC_ADDR_MAP;

    --------------------------------
    -- RUNTIME SENDING PROCEDURES --
    --------------------------------

    -- DETERMINE TARGET PE --
    -- determines the target PE by a given axi address and the constant axi and noc address maps
    procedure send_determineTargetPE(signal axi_data         : in  std_logic_vector;
                                     variable dest_address   : out std_logic_vector) is
        variable targetPE : integer := 0;
    begin
        -- compare every axi range to the given axi_address and determine the targetPE
        for i in 0 to PE_count - 1 loop
            if (unsigned(axi_addr_map_c(i)) <= unsigned(axi_data) and --TODO!
                unsigned(axi_data) < unsigned(axi_addr_map_c(i+1))) then
                targetPE := i;
            end if;
        end loop;
        -- select the noc address
        dest_address := noc_addr_map_c(targetPE);
    end procedure;
    
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
    AXI_Slave : AXI4_Lite_Slave
    generic map (
        A4L_addr_width  => A4L_addr_width,
        A4L_data_width  => A4L_data_width
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
        
        variable dest_address       : std_logic_vector(ADDR_W - 1 downto 0);
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

            if (rdrqA_get_valid = '1') then

                if(send_stalled = '0') then
                    send_determineTargetPE(rdrqA_get_data(AXI_araddr'left downto AXI_araddr'right),
                                           dest_address);
                    send_determineNextDataOut(P_A4L, C_AR,
                                              rdrqA_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext,
                                            send_stalled,
                                            dataOut,
                                            controlOut,
                                            wrrqA_get_en,
                                            state_send, WrRqA);
                else
                    send_stallDataAndWait(send_stalled, 
                                          wrrqA_get_en);
                end if;
            else
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                send_doNothingAndProceed(send_stalled, 
                                         wrrqA_get_en, 
                                         state_send, WrRqA);
            end if;

        -- STATE 2: WRRQA
        elsif (state_send = WrRqA) then
            wrrqA_get_en        <= '0';

            if (wrrqA_get_valid = '1') then
                rdrqA_get_en        <= '0';

                if(send_stalled = '0') then
                    send_determineTargetPE(wrrqA_get_data(AXI_awaddr'left downto AXI_awaddr'right),
                                           dest_address);
                    send_determineNextDataOut(P_A4L, C_AW,
                                              wrrqA_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext, 
                                            send_stalled, 
                                            dataOut, 
                                            controlOut, 
                                            wrrqD_get_en, 
                                            state_send, WrRqD);
                else
                    send_stallDataAndWait(send_stalled, 
                                          wrrqD_get_en);
                end if;
            else
                wrrqD_get_en        <= '0';
                
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                --if no valid wr address continue with rd
                send_doNothingAndProceed(send_stalled, 
                                         rdrqA_get_en, 
                                         state_send, RdRqA);
            end if;

        -- STATE 3: WRRQD
        else
            wrrqA_get_en        <= '0';
            wrrqD_get_en        <= '0';

            if (wrrqD_get_valid = '1') then
                if(send_stalled = '0') then
                    send_determineNextDataOut(P_A4L, C_W,
                                              wrrqD_get_data,
                                              dest_address,
                                              dataOutNext);
                end if;

                if (controlIn(STALL_GO) = '1') then
                    send_sendDataAndProceed(dataOutNext, 
                                            send_stalled, 
                                            dataOut, 
                                            controlOut, 
                                            rdrqA_get_en, 
                                            state_send, RdRqA);
                else
                    send_stallDataAndWait(send_stalled, 
                                          rdrqA_get_en);
                end if;
            else
                if (controlIn(STALL_GO) = '1') then
                    send_unsetPreviousTX(controlOut);
                end if;

                --if not valid remain in state until valid to complete the packet
                send_doNothingAndWait(send_stalled, 
                                      rdrqA_get_en);
            end if;
        end if;
        

        --------------------------------------
        -- NETWORK DATA TO A4L R/W RESPONSE --
        --------------------------------------
        -- If the network sends data or data transfer is stalled because of the receiver not being ready
        -- attempts are made to hand the data to the receiver until it is ready
        --------------------------------------

        -- stalled data handling
        if (put_stalled = '1') then
            if (recv_lastReceptionIsValid(put_last_state, wrrsp_put_ready, rdrsp_put_ready)) then
                if (dataInStalled(dataIn'left - 1) = C_B(1)) then
                    recv_processStalledData(wrrsp_put_data, A4L_wrrsp_width, dataInStalled,
                                            rdrsp_put_en, '0', wrrsp_put_en, '1',
                                            controlOut,
                                            put_last_state, WrRsp,
                                            put_stalled);
                elsif (dataInStalled(dataIn'left - 1) = C_R(1)) then
                    recv_processStalledData(rdrsp_put_data, A4L_rdrsp_width, dataInStalled,
                                            rdrsp_put_en, '1', wrrsp_put_en, '0',
                                            controlOut,
                                            put_last_state, RdRsp,
                                            put_stalled);
                end if;
            end if;
        -- normal data handling
        elsif (controlIn(RX) = '1') then
            if (dataIn(dataIn'left - 1) = C_B(1)) then
                if (recv_lastReceptionIsValid(put_last_state, wrrsp_put_ready, rdrsp_put_ready)) then
                    recv_processData(wrrsp_put_data, A4L_wrrsp_width, dataIn,
                                     rdrsp_put_en, '0', wrrsp_put_en, '1',
                                     controlOut);
                else
                    recv_stallData(dataInStalled, dataIn,
                                   controlOut,
                                   put_last_state, WrRsp,
                                   put_stalled);
                end if;
            elsif (dataIn(dataIn'left - 1) = C_R(1)) then
                if (recv_lastReceptionIsValid(put_last_state, wrrsp_put_ready, rdrsp_put_ready)) then
                    recv_processData(rdrsp_put_data, A4L_rdrsp_width, dataIn,
                                     rdrsp_put_en, '1', wrrsp_put_en, '0',
                                     controlOut);
                else
                    recv_stallData(dataInStalled, dataIn,
                                   controlOut,
                                   put_last_state, RdRsp,
                                   put_stalled);
                end if;
            end if;
        -- no data handling
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
