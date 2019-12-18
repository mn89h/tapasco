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
        address                 : std_logic_vector;
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
    signal data_in              : Array1D_data(0 to PORTS-1);
    signal control_in           : Array1D_control(0 to PORTS-1);
    signal data_out             : Array1D_data(0 to PORTS-1);
    signal control_out          : Array1D_control(0 to PORTS-1);
    signal routingTable         : Array1D_3bits(0 to PORTS-1);  -- From Switch Control to crossbar
    signal crossbarDataIn       : Array1D_data(0 to PORTS-1);   -- Data out from Input Buffers to Crossbar
    signal crossbarControlIn    : Array1D_control(0 to PORTS-1);-- Control out signals from Input Buffers to Crossbar
    signal crossbarControlOut   : Array1D_control(0 to PORTS-1);
    
    -- Signals to connect Switch Control and Input Buffers
    signal routingRequest       : std_logic_vector(PORTS-1 downto 0);
    signal routingAck           : std_logic_vector(PORTS-1 downto 0);
    signal sending              : std_logic_vector(PORTS-1 downto 0);
    
begin

--------------------------------------------------------------------------------------
-- INTERNAL
--------------------------------------------------------------------------------------
    -- Map router ports to Array1D
    data_in(LOCAL)      <= data_in_local;
    data_in(EAST)       <= data_in_east;
    data_in(SOUTH)      <= data_in_south;
    data_in(WEST)       <= data_in_west;
    data_in(NORTH)      <= data_in_north;
    data_in(UP)         <= data_in_up           when PORTS = 7;
    data_in(DOWN)       <= data_in_down         when PORTS = 7;
    
    control_in(LOCAL)   <= control_in_local;
    control_in(EAST)    <= control_in_east;
    control_in(SOUTH)   <= control_in_south;
    control_in(WEST)    <= control_in_west;
    control_in(NORTH)   <= control_in_north;
    control_in(UP)      <= control_in_up        when PORTS = 7;
    control_in(DOWN)    <= control_in_down      when PORTS = 7;

    
    data_out_local      <= data_out(LOCAL);
    data_out_east       <= data_out(EAST);
    data_out_south      <= data_out(SOUTH);
    data_out_west       <= data_out(WEST);
    data_out_north      <= data_out(NORTH);
    data_out_up         <= data_out(UP)         when PORTS = 7;
    data_out_down       <= data_out(DOWN)       when PORTS = 7;

    control_out_local   <= control_out(LOCAL);
    control_out_east    <= control_out(EAST);
    control_out_south   <= control_out(SOUTH);
    control_out_west    <= control_out(WEST);
    control_out_north   <= control_out(NORTH);
    control_out_up      <= control_out(UP)      when PORTS = 7;
    control_out_down    <= control_out(DOWN)    when PORTS = 7;

--------------------------------------------------------------------------------------
-- CROSSBAR
--------------------------------------------------------------------------------------
CROSSBARX: Crossbar
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
    generic map(address  => address)
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
        port map(
            clk                     => clk,
            rst                     => rst,
            
            -- Router interface. Signals coming from the neighboring router.
            data_in                 => data_in(n),
            control_in(EOP)         => control_in(n)(EOP),
            control_in(RX)          => control_in(n)(RX),
            
            -- Crossbar interface
            control_in(STALL_GO)    => crossbarControlOut(n)(STALL_GO),           
            data_out                => crossbarDataIn(n),
            control_out(EOP)        => crossbarControlIn(n)(EOP),
            control_out(RX)         => crossbarControlIn(n)(RX),
            
            -- Router interface. STALL_GO signal to the neighboring router.
            control_out(STALL_GO)   => control_out(n)(STALL_GO),
            
            -- Switch Control interface
            routingRequest          => routingRequest(n),
            routingAck              => routingAck(n),
            sending                 => sending(n)
        );
        
        -- Router interface. Signals coming from crossbar depending on the routingTable.
        control_out(n)(EOP)            <= crossbarControlOut(n)(EOP);
        control_out(n)(RX)             <= crossbarControlOut(n)(RX);
        
        -- Router interface. STALL_GO signal from the neighboring routers.
        crossbarControlIn(n)(STALL_GO) <= control_in(n)(STALL_GO); 
        
    end generate;

end architecture;