--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Router Unit                                                       --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- MODIFIED BY  : Malte Nilges                                                      --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : 1.0                                                               --
-- HISTORY      : Version 1.0 - Oct 22, 2019                                        --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.Arke_pkg.all;

entity Router is
    generic(
        address         : std_logic_vector := "000000000000";
        -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
        -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
        DIM_X           : integer := 4;
        DIM_Y           : integer := 4;
        DIM_Z           : integer := 1;
        PORTS           : integer := 5; -- 5 for 2D and 7 for 3D
        -- Input buffers depth
        BUFFER_DEPTH    : integer := 4; -- Buffer depth must be greater than 1 and a power of 2
        -- Data and control buses
        DATA_WIDTH      : integer := 128;
        CONTROL_WIDTH   : integer := 3;
        -- Parameters for Vivado IP Packager
        use_data_in_local       : boolean := true;
        use_data_in_east        : boolean := true;
        use_data_in_south       : boolean := true;
        use_data_in_west        : boolean := true;
        use_data_in_north       : boolean := true;
        use_data_in_up          : boolean := true;
        use_data_in_down        : boolean := true;
        use_control_in_local    : boolean := true;
        use_control_in_east     : boolean := true;
        use_control_in_south    : boolean := true;
        use_control_in_west     : boolean := true;
        use_control_in_north    : boolean := true;
        use_control_in_up       : boolean := true;
        use_control_in_down     : boolean := true;
        use_data_out_local      : boolean := true;
        use_data_out_east       : boolean := true;
        use_data_out_south      : boolean := true;
        use_data_out_west       : boolean := true;
        use_data_out_north      : boolean := true;
        use_data_out_up         : boolean := true;
        use_data_out_down       : boolean := true;
        use_control_out_local   : boolean := true;
        use_control_out_east    : boolean := true;
        use_control_out_south   : boolean := true;
        use_control_out_west    : boolean := true;
        use_control_out_north   : boolean := true;
        use_control_out_up      : boolean := true;
        use_control_out_down    : boolean := true
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;

        -- Data and control inputs
        data_in_local       : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_east        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_south       : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_west        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_north       : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_up          : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_down        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in_local    : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_east     : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_south    : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_west     : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_north    : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_up       : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_in_down     : in std_logic_vector(CONTROL_WIDTH-1 downto 0);

        -- Data and control outputs
        data_out_local       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_east        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_south       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_west        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_north       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_up          : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_down        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out_local    : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_east     : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_south    : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_west     : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_north    : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_up       : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        control_out_down     : out std_logic_vector(CONTROL_WIDTH-1 downto 0)
    );
end Router;

architecture Router of Router is
    signal data_in              : std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
    signal control_in           : std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);
    signal data_out             : std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
    signal control_out          : std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);
    signal routingTable         : std_logic_vector(PORTS*3-1 downto 0);  -- From Switch Control to crossbar
    signal crossbarDataIn       : std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);   -- Data out from Input Buffers to Crossbar
    signal crossbarControlIn    : std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);-- Control out signals from Input Buffers to Crossbar
    signal crossbarControlOut   : std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);

    -- Signals to connect Switch Control and Input Buffers
    signal routingRequest       : std_logic_vector(PORTS-1 downto 0);
    signal routingAck           : std_logic_vector(PORTS-1 downto 0);
    signal sending              : std_logic_vector(PORTS-1 downto 0);

    constant ZERO               : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    constant fulladdress        : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO(DATA_WIDTH-1 downto address'length) & address;

begin

--------------------------------------------------------------------------------------
-- INTERNAL
--------------------------------------------------------------------------------------
    -- Map router ports to Array1D
    data_in((LOCAL+1)*DATA_WIDTH-1  downto LOCAL*DATA_WIDTH)            <= data_in_local;
    data_in((EAST+1)*DATA_WIDTH-1   downto EAST*DATA_WIDTH)             <= data_in_east;
    data_in((SOUTH+1)*DATA_WIDTH-1  downto SOUTH*DATA_WIDTH)            <= data_in_south;
    data_in((WEST+1)*DATA_WIDTH-1   downto WEST*DATA_WIDTH)             <= data_in_west;
    data_in((NORTH+1)*DATA_WIDTH-1  downto NORTH*DATA_WIDTH)            <= data_in_north;

    control_in((LOCAL+1)*CONTROL_WIDTH-1  downto LOCAL*CONTROL_WIDTH)   <= control_in_local;
    control_in((EAST+1)*CONTROL_WIDTH-1   downto EAST*CONTROL_WIDTH)    <= control_in_east;
    control_in((SOUTH+1)*CONTROL_WIDTH-1  downto SOUTH*CONTROL_WIDTH)   <= control_in_south;
    control_in((WEST+1)*CONTROL_WIDTH-1   downto WEST*CONTROL_WIDTH)    <= control_in_west;
    control_in((NORTH+1)*CONTROL_WIDTH-1  downto NORTH*CONTROL_WIDTH)   <= control_in_north;

    data_out_local      <= data_out((LOCAL+1)*DATA_WIDTH-1  downto LOCAL*DATA_WIDTH);
    data_out_east       <= data_out((EAST+1)*DATA_WIDTH-1   downto EAST*DATA_WIDTH);
    data_out_south      <= data_out((SOUTH+1)*DATA_WIDTH-1  downto SOUTH*DATA_WIDTH);
    data_out_west       <= data_out((WEST+1)*DATA_WIDTH-1   downto WEST*DATA_WIDTH);
    data_out_north      <= data_out((NORTH+1)*DATA_WIDTH-1  downto NORTH*DATA_WIDTH);

    control_out_local   <= control_out((LOCAL+1)*CONTROL_WIDTH-1  downto LOCAL*CONTROL_WIDTH);
    control_out_east    <= control_out((EAST+1)*CONTROL_WIDTH-1   downto EAST*CONTROL_WIDTH);
    control_out_south   <= control_out((SOUTH+1)*CONTROL_WIDTH-1  downto SOUTH*CONTROL_WIDTH);
    control_out_west    <= control_out((WEST+1)*CONTROL_WIDTH-1   downto WEST*CONTROL_WIDTH);
    control_out_north   <= control_out((NORTH+1)*CONTROL_WIDTH-1  downto NORTH*CONTROL_WIDTH);

    P7 : if PORTS = 7 generate
        data_in((UP+1)*DATA_WIDTH-1     downto UP*DATA_WIDTH)               <= data_in_up;
        data_in((DOWN+1)*DATA_WIDTH-1   downto DOWN*DATA_WIDTH)             <= data_in_down;
        control_in((UP+1)*CONTROL_WIDTH-1     downto UP*CONTROL_WIDTH)      <= control_in_up;
        control_in((DOWN+1)*CONTROL_WIDTH-1   downto DOWN*CONTROL_WIDTH)    <= control_in_down;
        data_out_up         <= data_out((UP+1)*DATA_WIDTH-1     downto UP*DATA_WIDTH);
        data_out_down       <= data_out((DOWN+1)*DATA_WIDTH-1   downto DOWN*DATA_WIDTH);
        control_out_up      <= control_out((UP+1)*CONTROL_WIDTH-1     downto UP*CONTROL_WIDTH);
        control_out_down    <= control_out((DOWN+1)*CONTROL_WIDTH-1   downto DOWN*CONTROL_WIDTH);
    end generate;

--------------------------------------------------------------------------------------
-- CROSSBAR
--------------------------------------------------------------------------------------
CROSSBARX: Crossbar
    generic map(
        DIM_X           => DIM_X,
        DIM_Y           => DIM_Y,
        DIM_Z           => DIM_Z,
        PORTS           => PORTS,
        DATA_WIDTH      => DATA_WIDTH,
        CONTROL_WIDTH   => CONTROL_WIDTH
    )
    port map(
        routingTable => routingTable,
        data_in      => crossbarDataIn,
        control_in   => crossbarControlIn,
        data_out     => data_out,
        control_out  => crossbarControlOut
    );

--------------------------------------------------------------------------------------
-- SWITCH CONTROL
--------------------------------------------------------------------------------------
SWITCH_CONTROL: SwitchControl
    generic map(
        address         => fulladdress,
        DIM_X           => DIM_X,
        DIM_Y           => DIM_Y,
        DIM_Z           => DIM_Z,
        PORTS           => PORTS,
        DATA_WIDTH      => DATA_WIDTH,
        CONTROL_WIDTH   => CONTROL_WIDTH
    )
    port map(
        clk         => clk,
        rst         => rst,

        -- Input Buffers interface
        routingReq  => routingRequest,
        routingAck  => routingAck,
        data        => crossbarDataIn,
        sending     => sending,

        -- Crossbar interface
        table       => routingTable
    );

--------------------------------------------------------------------------------------
-- Buffers instantiation with for ... generate
--------------------------------------------------------------------------------------
    PortBuffers: for n in 0 to PORTS-1 generate
        for INPUT_BUFFER: InputBuffer use entity work.InputBuffer(pipeline_4_cycles);
        begin INPUT_BUFFER: InputBuffer
        generic map(
            BUFFER_DEPTH    => BUFFER_DEPTH,
            DATA_WIDTH      => DATA_WIDTH,
            CONTROL_WIDTH   => CONTROL_WIDTH
        )
        port map(
            clk                     => clk,
            rst                     => rst,

            -- Router interface. Signals coming from the neighboring router.
            data_in                 => data_in((n+1)*DATA_WIDTH-1 downto n*DATA_WIDTH),
            control_in(EOP)         => control_in(n*CONTROL_WIDTH+EOP),
            control_in(RX)          => control_in(n*CONTROL_WIDTH+RX),

            -- Crossbar interface
            control_in(STALL_GO)    => crossbarControlOut(n*CONTROL_WIDTH+STALL_GO),
            data_out                => crossbarDataIn((n+1)*DATA_WIDTH-1 downto n*DATA_WIDTH),
            control_out(EOP)        => crossbarControlIn(n*CONTROL_WIDTH+EOP),
            control_out(RX)         => crossbarControlIn(n*CONTROL_WIDTH+RX),

            -- Router interface. STALL_GO signal to the neighboring router.
            control_out(STALL_GO)   => control_out(n*CONTROL_WIDTH+STALL_GO),

            -- Switch Control interface
            routingRequest          => routingRequest(n),
            routingAck              => routingAck(n),
            sending                 => sending(n)
        );

        -- Router interface. Signals coming from crossbar depending on the routingTable.
        control_out(n*CONTROL_WIDTH+EOP)  <= crossbarControlOut(n*CONTROL_WIDTH+EOP);
        control_out(n*CONTROL_WIDTH+RX)   <= crossbarControlOut(n*CONTROL_WIDTH+RX);

        -- Router interface. STALL_GO signal from the neighboring routers.
        crossbarControlIn(n*CONTROL_WIDTH+STALL_GO)   <= control_in(n*CONTROL_WIDTH+STALL_GO);

    end generate;

end architecture;