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

package Arke_pkg is
                                      -------------------------
                                      -- Not parameterizable --
                                      -------------------------

    -- Control signals identification
    constant EOP        : integer := 0;
    constant RX         : integer := 1;
    constant TX         : integer := 1;
    constant STALL_GO   : integer := 2;
    
    -- Router ports identification
    constant LOCAL      : integer := 0;
    constant EAST       : integer := 1;
    constant SOUTH      : integer := 2;
    constant WEST       : integer := 3;
    constant NORTH      : integer := 4;
    constant UP         : integer := 5;
    constant DOWN       : integer := 6;
    
    -- 
    constant NOT_ROUTED : std_logic_vector(2 downto 0) := "111";
    constant FREE       : std_logic := '0';
    constant BUSY       : std_logic := '1';
    
    function Log2(temp : natural) return natural;
    
    --------------------------------
    -- NoC components declaration --
    --------------------------------
    component InputBuffer is
    generic(
        -- Input buffers depth 
        BUFFER_DEPTH    : integer := 4; -- Buffer depth must be greater than 1 and a power of 2
        -- Data and control buses 
        DATA_WIDTH      : integer := 100;
        CONTROL_WIDTH   : integer := 3
    );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Receiving/Sending Interface
        data_in         : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in      : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out     : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        
        -- Switch Control Interface
        routingRequest  : out std_logic;
        routingAck      : in  std_logic;
        sending         : out std_logic
    );
    end component;
    
    component Crossbar is
    generic(
        -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
        -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
        DIM_X           : integer := 4;
        DIM_Y           : integer := 4;
        DIM_Z           : integer := 3;
        PORTS           : integer := 5; -- 5 for 2D and 7 for 3D
        -- Data and control buses 
        DATA_WIDTH      : integer := 100;
        CONTROL_WIDTH   : integer := 3
    );
    port(
        -- Switch Control interface
        routingTable    : in std_logic_vector(PORTS*3-1 downto 0);
        
        -- Input buffers interface
        data_in         : in std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_in      : in std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);
        
        -- Router output ports interface
        data_out        : out std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_out     : out std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0)
    );
    end component;
    
    component ProgramablePriorityEncoder is
    port(
        request         : in std_logic_vector(7 downto 0);
        lowerPriority   : in std_logic_vector(2 downto 0);
        code            : out std_logic_vector(2 downto 0);
        newRequest      : out std_logic
    );
    end component;
    
    component SwitchControl is
    generic(
        address         : std_logic_vector;
        -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
        -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
        DIM_X           : integer := 4;
        DIM_Y           : integer := 4;
        DIM_Z           : integer := 3;
        PORTS           : integer := 5; -- 5 for 2D and 7 for 3D
        -- Data and control buses 
        DATA_WIDTH      : integer := 100;
        CONTROL_WIDTH   : integer := 3
    );
    port(
        clk         :    in    std_logic;
        rst         :    in    std_logic;
        
        -- Input buffers interface
        routingReq  :    in  std_logic_vector(PORTS-1 downto 0);    -- Routing request from input buffers
        routingAck  :    out std_logic_vector(PORTS-1 downto 0);    -- Routing acknowledgement to input buffers
        data        :    in  std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);            -- Each array element corresponds to a input buffer data_out
        sending     :    in  std_logic_vector(PORTS-1 downto 0);    -- Each array element signals an input buffer transmiting data
        
        -- Crossbar interface
        table       :    out std_logic_vector(PORTS*3-1 downto 0)    -- Routing table to be connected to crossbar. Each array element encodes a direction.
    );
    end component;
    
    component Router is
    generic(
        address         : std_logic_vector;
        -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
        -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
        DIM_X           : integer := 4;
        DIM_Y           : integer := 4;
        DIM_Z           : integer := 3;
        PORTS           : integer := 7; -- 5 for 2D and 7 for 3D
        -- Input buffers depth 
        BUFFER_DEPTH    : integer := 4; -- Buffer depth must be greater than 1 and a power of 2
        -- Data and control buses 
        DATA_WIDTH      : integer := 100;
        CONTROL_WIDTH   : integer := 3
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- Data and control inputs
        data_in     : in std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_in  : in std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);
        
        -- Data and control outputs
        data_out    : out std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_out : out std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0)
    );
    end component;
    
end package;

package body Arke_pkg is
    
    -- Function returns the logarithm of 2 from the argument.
    function Log2(temp : natural) return natural is
    begin
        for i in 0 to integer'high loop
            if (2**i >= temp) then
                return i;
            end if;
        end loop;
        return 0;
    end function Log2;

end Arke_pkg;
