--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Crossbar                                                          --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- MODIFIED BY  : Malte Nilges                                                      --
-- CREATED      : Jul 6th, 2015                                                     --
-- VERSION      : 1.0                                                               --
-- HISTORY      : Version 0.1 - Jul 6th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

entity Crossbar is
    generic(
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
        -- Switch Control interface
        routingTable    : in std_logic_vector(PORTS*3-1 downto 0);

        -- Input buffers interface
        data_in         : in std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_in      : in std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0);

        -- Router output ports interface
        data_out        : out std_logic_vector(PORTS*DATA_WIDTH-1 downto 0);
        control_out     : out std_logic_vector(PORTS*CONTROL_WIDTH-1 downto 0)
    );
end Crossbar;

architecture full of Crossbar is
begin

    MESH_2D : if(DIM_X>1 and DIM_Y>1 and DIM_Z=1) generate
        --DATA_OUT
        DATAOUT: for i in 0 to PORTS-1 generate
        data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) <=
           data_in((LOCAL+1)*DATA_WIDTH-1 downto LOCAL*DATA_WIDTH) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
           data_in((EAST+1)*DATA_WIDTH-1  downto EAST*DATA_WIDTH)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1  downto EAST*3))) = i else
           data_in((SOUTH+1)*DATA_WIDTH-1 downto SOUTH*DATA_WIDTH) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
           data_in((WEST+1)*DATA_WIDTH-1  downto WEST*DATA_WIDTH)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1  downto WEST*3))) = i else
           data_in((NORTH+1)*DATA_WIDTH-1 downto NORTH*DATA_WIDTH);
        end generate;
        --EOP
        EOPP: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+EOP) <=
            control_in(CONTROL_WIDTH*LOCAL+EOP) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
            control_in(CONTROL_WIDTH*EAST+EOP)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1 downto EAST*3))) = i else
            control_in(CONTROL_WIDTH*SOUTH+EOP) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
            control_in(CONTROL_WIDTH*WEST+EOP)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1 downto WEST*3))) = i else
            control_in(CONTROL_WIDTH*NORTH+EOP) when TO_INTEGER(UNSIGNED(routingTable((NORTH+1)*3-1 downto NORTH*3))) = i else
            '0';
        end generate;

        --RX/TX
        RXTX: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+RX) <=
            control_in(CONTROL_WIDTH*LOCAL+RX) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
            control_in(CONTROL_WIDTH*EAST+RX)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1  downto EAST*3))) = i else
            control_in(CONTROL_WIDTH*SOUTH+RX) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
            control_in(CONTROL_WIDTH*WEST+RX)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1  downto WEST*3))) = i else
            control_in(CONTROL_WIDTH*NORTH+RX) when TO_INTEGER(UNSIGNED(routingTable((NORTH+1)*3-1 downto NORTH*3))) = i else
            '0';
        end generate;

        --STALL_GO
        STALLGO: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+STALL_GO) <=
            control_in(CONTROL_WIDTH*LOCAL+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = LOCAL else
            control_in(CONTROL_WIDTH*EAST+STALL_GO)  when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = EAST else
            control_in(CONTROL_WIDTH*SOUTH+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = SOUTH else
            control_in(CONTROL_WIDTH*WEST+STALL_GO)  when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = WEST else
            control_in(CONTROL_WIDTH*NORTH+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = NORTH else
            '0';
        end generate;
    end generate;

    MESH_3D : if(DIM_X>1 and DIM_Y>1 and DIM_Z>1) generate
        --DATA_OUT
        DATAOUT: for i in 0 to PORTS-1 generate
        data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) <=
           data_in((LOCAL+1)*DATA_WIDTH-1 downto LOCAL*DATA_WIDTH) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
           data_in((EAST+1)*DATA_WIDTH-1  downto EAST*DATA_WIDTH)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1  downto EAST*3))) = i else
           data_in((SOUTH+1)*DATA_WIDTH-1 downto SOUTH*DATA_WIDTH) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
           data_in((WEST+1)*DATA_WIDTH-1  downto WEST*DATA_WIDTH)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1  downto WEST*3))) = i else
           data_in((NORTH+1)*DATA_WIDTH-1 downto NORTH*DATA_WIDTH) when TO_INTEGER(UNSIGNED(routingTable((NORTH+1)*3-1 downto NORTH*3))) = i else
           data_in((UP+1)*DATA_WIDTH-1    downto UP*DATA_WIDTH)    when TO_INTEGER(UNSIGNED(routingTable((UP+1)*3-1    downto UP*3))) = i else
           data_in((DOWN+1)*DATA_WIDTH-1  downto DOWN*DATA_WIDTH);
        end generate;

        -- --EOP
        EOPP: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+EOP) <=
            control_in(CONTROL_WIDTH*LOCAL+EOP) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
            control_in(CONTROL_WIDTH*EAST+EOP)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1  downto EAST*3))) = i else
            control_in(CONTROL_WIDTH*SOUTH+EOP) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
            control_in(CONTROL_WIDTH*WEST+EOP)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1  downto WEST*3))) = i else
            control_in(CONTROL_WIDTH*NORTH+EOP) when TO_INTEGER(UNSIGNED(routingTable((NORTH+1)*3-1 downto NORTH*3))) = i else
            control_in(CONTROL_WIDTH*UP+EOP)    when TO_INTEGER(UNSIGNED(routingTable((UP+1)*3-1    downto UP*3))) = i else
            control_in(CONTROL_WIDTH*DOWN+EOP)  when TO_INTEGER(UNSIGNED(routingTable((DOWN+1)*3-1  downto DOWN*3))) = i else
            '0';
        end generate;

        --RX/TX
        RXTX: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+RX) <=
            control_in(CONTROL_WIDTH*LOCAL+RX) when TO_INTEGER(UNSIGNED(routingTable((LOCAL+1)*3-1 downto LOCAL*3))) = i else
            control_in(CONTROL_WIDTH*EAST+RX)  when TO_INTEGER(UNSIGNED(routingTable((EAST+1)*3-1  downto EAST*3))) = i else
            control_in(CONTROL_WIDTH*SOUTH+RX) when TO_INTEGER(UNSIGNED(routingTable((SOUTH+1)*3-1 downto SOUTH*3))) = i else
            control_in(CONTROL_WIDTH*WEST+RX)  when TO_INTEGER(UNSIGNED(routingTable((WEST+1)*3-1  downto WEST*3))) = i else
            control_in(CONTROL_WIDTH*NORTH+RX) when TO_INTEGER(UNSIGNED(routingTable((NORTH+1)*3-1 downto NORTH*3))) = i else
            control_in(CONTROL_WIDTH*UP+RX)    when TO_INTEGER(UNSIGNED(routingTable((UP+1)*3-1    downto UP*3))) = i else
            control_in(CONTROL_WIDTH*DOWN+RX)  when TO_INTEGER(UNSIGNED(routingTable((DOWN+1)*3-1  downto DOWN*3))) = i else
            '0';
        end generate;

        --STALL_GO
        STALLGO: for i in 0 to PORTS-1 generate
        control_out(i*CONTROL_WIDTH+STALL_GO) <=
            control_in(CONTROL_WIDTH*LOCAL+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = LOCAL else
            control_in(CONTROL_WIDTH*EAST+STALL_GO)  when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = EAST else
            control_in(CONTROL_WIDTH*SOUTH+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = SOUTH else
            control_in(CONTROL_WIDTH*WEST+STALL_GO)  when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = WEST else
            control_in(CONTROL_WIDTH*NORTH+STALL_GO) when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = NORTH else
            control_in(CONTROL_WIDTH*UP+STALL_GO)    when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = UP else
            control_in(CONTROL_WIDTH*DOWN+STALL_GO)  when TO_INTEGER(UNSIGNED(routingTable((i+1)*3-1 downto i*3))) = DOWN else
            '0';
        end generate;
    end generate;

end architecture;