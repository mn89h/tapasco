--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Switch Control                                                    --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- MODIFIED BY  : Malte Nilges                                                      --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : 1.0                                                               --
-- HISTORY      : Version 0.1 - Jun 16th, 2015                                      --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

entity SwitchControl is
    generic(
        address         : std_logic_vector;
        -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
        -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
        DIM_X           : integer;
        DIM_Y           : integer;
        DIM_Z           : integer;
        PORTS           : integer; -- 5 for 2D and 7 for 3D
        -- Data and control buses
        DATA_WIDTH      : integer;
        CONTROL_WIDTH   : integer
    );
    port(
        clk         :    in    std_logic;
        rst         :    in    std_logic;

        -- Input buffers interface
        routingReq  :    in  std_logic_vector(PORTS-1 downto 0);    -- Routing request from input buffers
        routingAck  :    out std_logic_vector(PORTS-1 downto 0);    -- Routing acknowledgement to input buffers
        data        :    in  std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);     -- Each array element corresponds to a input buffer data_out
        sending     :    in  std_logic_vector(PORTS-1 downto 0);  -- Each array element signals an input buffer transmiting data

        -- Crossbar interface
        table       :    out std_logic_vector(PORTS*3-1 downto 0)    -- Routing table to be connected to crossbar. Each array element encodes a direction.
    );
end SwitchControl;

architecture behavioral of SwitchControl is

    type state is (IDLE,ROUTING_ACK);
    signal currentState: state;

    signal freePorts: std_logic_vector(PORTS-1 downto 0);   -- Status of all output ports (0 = free; 1 = busy)
    signal routingTable: std_logic_vector(PORTS*3-1 downto 0); -- routingTable(inPort): value = outPort
    signal selectedInPort: integer range 0 to PORTS-1;  -- Input port selected to routing
    signal nextInPort: integer range 0 to PORTS-1;  -- Next input port to be selected to routing
    signal routedOutPort: integer range 0 to PORTS-1;   -- Output port selected by the routing algorithm

    signal req: std_logic_vector(7 downto 0);
    signal lowerPriority, code: std_logic_vector(2 downto 0);
    signal newRequest: std_logic;


    -- Function returns the address of a router in flit header format.
    --
    --                       DATA_WIDTH
    --      |--------------------------------------------|
    --
    --      +--------+-----------+-----------+-----------+
    --      | 00...0 |  X_FIELD  |  Y_FIELD  |  Z_FIELD  |
    --      +--------+-----------+-----------+-----------+
    --
    constant X_FIELD    : integer := Log2(DIM_X);
    constant Y_FIELD    : integer := Log2(DIM_Y);
    constant Z_FIELD    : integer := Log2(DIM_Z);

    function GetAddress(x,y,z : natural) return std_logic_vector is
        variable address : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable binX : std_logic_vector(X_FIELD-1 downto 0);
        variable binY : std_logic_vector(Y_FIELD-1 downto 0);
        variable binZ : std_logic_vector(Z_FIELD-1 downto 0);
        variable zeros2D: std_logic_vector(DATA_WIDTH-1-(X_FIELD+Y_FIELD) downto 0);
        variable zeros3D: std_logic_vector(DATA_WIDTH-1-(X_FIELD+Y_FIELD+Z_FIELD) downto 0);
    begin
        if(DIM_Z = 1) then -- NoC 2D
            binX := std_logic_vector(TO_UNSIGNED(x,X_FIELD));
            binY := std_logic_vector(TO_UNSIGNED(y,Y_FIELD));
            zeros2D := (others=>'0');
            address := zeros2D & binX & binY;
        else  -- NoC 3D
            binX := std_logic_vector(TO_UNSIGNED(x,X_FIELD));
            binY := std_logic_vector(TO_UNSIGNED(y,Y_FIELD));
            binZ := std_logic_vector(TO_UNSIGNED(z,Z_FIELD));
            zeros3D := (others=>'0');
            address := zeros3D & binX & binY & binZ;
        end if;

        return address;
    end function GetAddress;

    --Function returns the port that should be used to send the packet according the XYZ algorithm.
    function XYZ(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer is
        -- Routed output port
        variable outputPort : integer range 0 to PORTS-1;

        -- Current router address
        variable currentX   : std_logic_vector(X_FIELD-1 downto 0) := current(Z_FIELD+Y_FIELD+X_FIELD-1 downto Z_FIELD+Y_FIELD);
        variable currentY   : std_logic_vector(Y_FIELD-1 downto 0) := current(Y_FIELD+Z_FIELD-1 downto Z_FIELD);
        variable currentZ   : std_logic_vector(Z_FIELD-1 downto 0) := current(Z_FIELD-1 downto 0);

        -- Target router address
        variable targetX    : std_logic_vector(X_FIELD-1 downto 0) := target(Z_FIELD+Y_FIELD+X_FIELD-1 downto Z_FIELD+Y_FIELD);
        variable targetY    : std_logic_vector(Y_FIELD-1 downto 0) := target(Y_FIELD+Z_FIELD-1 downto Z_FIELD);
        variable targetZ    : std_logic_vector(Z_FIELD-1 downto 0) := target(Z_FIELD-1 downto 0);
    begin
        if(currentX = targetX) then

            if(currentY = targetY) then

                if(currentZ = targetZ) then
                    outputPort := LOCAL;
                elsif(currentZ < targetZ) then
                    outputPort := UP;
                else --currentZ > targetZ
                    outputPort := DOWN;
                end if;

            elsif (currentY < targetY) then
                outputPort := NORTH;
            else --currentY > targetY
                outputPort := SOUTH;
            end if;

        elsif (currentX < targetX) then
            outputPort := EAST;
        else --currentX > targetX
            outputPort := WEST;
        end if;

        return outputPort;

    end XYZ;

    -- Function returns the port that should be used to send the packet according the XYZ algorithm.
    function XY(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer is
        -- Routed output port
        variable outputPort : integer range 0 to PORTS-1;

        -- Current router address
        variable currentX   : std_logic_vector(X_FIELD-1 downto 0) := current(Y_FIELD+X_FIELD-1 downto Y_FIELD);
        variable currentY   : std_logic_vector(Y_FIELD-1 downto 0) := current(Y_FIELD-1 downto 0);

        -- Target router address
        variable targetX    : std_logic_vector(X_FIELD-1 downto 0) := target(Y_FIELD+X_FIELD-1 downto Y_FIELD);
        variable targetY    : std_logic_vector(Y_FIELD-1 downto 0) := target(Y_FIELD-1 downto 0);
    begin
        if(currentX = targetX) then

            if(currentY = targetY) then
                outputPort := LOCAL;
            elsif (currentY < targetY) then
                outputPort := NORTH;
            else --currentY > targetY
                outputPort := SOUTH;
            end if;

        elsif (currentX < targetX) then
            outputPort := EAST;
        else --currentX > targetX
            outputPort := WEST;
        end if;

        return outputPort;

    end XY;

begin

    -- Set the priority encoder input request and routing algorithm for 2D NoCs
    MESH_2D : if(DIM_X>1 and DIM_Y>1 and DIM_Z=1) generate

        req <= ("000" & routingReq);

        -- Routing (XY algorithm)
        routedOutPort <= XY(data((nextInPort+1)*DATA_WIDTH-1 downto nextInPort*DATA_WIDTH),address);

    end generate;

    -- Set the priority encoder input request and routing algorithm for 3D NoCs
    MESH_3D : if(DIM_X>1 and DIM_Y>1 and DIM_Z>1) generate

         req <= ('0' & routingReq);

        -- Routing (XYZ algorithm)
        routedOutPort <= XYZ(data((nextInPort+1)*DATA_WIDTH-1 downto nextInPort*DATA_WIDTH),address);

    end generate;

    lowerPriority <= STD_LOGIC_VECTOR(TO_UNSIGNED(selectedInPort,3));

    -------------------------------------------------------------
    -- Round robin policy to chose the input port to be served --
    -------------------------------------------------------------
    PPE: ProgramablePriorityEncoder
        port map(
            request         => req,
            lowerPriority   => lowerPriority,
            code            => code,
            newRequest      => newRequest
        );

    nextInPort <= TO_INTEGER(UNSIGNED(code));

    ------------------------------
    -- Routing table management --
    ------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            routingAck      <= (others=>'0');
            routingTable    <= (others=>'1'); --NOT_ROUTED
            freePorts       <= (others=>FREE);
            currentState    <= IDLE;

        elsif rising_edge(clk) then
            case currentState is

                -- Takes the port selected by the round robin
                when IDLE =>
                    selectedInPort <= nextInPort;

                    -- Updates the routing table.
                    -- Frees the output ports released by the input ones
                    for i in 0 to PORTS-1 loop
                        if sending(i) = '0' and routingTable((i+1)*3-1 downto i*3) /= NOT_ROUTED then
                            routingTable((i+1)*3-1 downto i*3) <= NOT_ROUTED;
                            freePorts(TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3)))) <= FREE;
                        end if;
                    end loop;

                    -- Wait for a port request.
                    -- Sets the routing table if the routed output port is available
                    if newRequest = '1' and freePorts(routedOutPort) = FREE then
                        routingTable((nextInPort+1)*3-1 downto nextInPort*3) <= STD_LOGIC_VECTOR(TO_UNSIGNED(routedOutPort,3));
                        routingAck(nextInPort) <= '1';
                        freePorts(routedOutPort) <= BUSY;
                        currentState <= ROUTING_ACK;
                    else
                        currentState <= IDLE;
                    end if;

                -- Holds the routing acknowledgement active for one cycle
                when ROUTING_ACK =>
                    routingAck(selectedInPort) <= '0';
                    currentState <= IDLE;

                when others =>
                    currentState <= IDLE;

            end case;
        end if;

    end process;

    table <= routingTable;

end architecture;