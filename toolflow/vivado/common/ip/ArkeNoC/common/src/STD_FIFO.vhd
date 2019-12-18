-------------------------------------------------------------------------------
-- Title      : FIFO for usage in AXI modules
-- Project    : TaPaSCo NoC Integration
-------------------------------------------------------------------------------
-- File       : STD_FIFO.vhd
-- Author     : Malte Nilges
-- Company    : 
-- Created    : 2019-11-19
-- Last update: 2019-12-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: FIFO conforming AXI handshaking specification
-------------------------------------------------------------------------------
-- Copyright (c) 2019 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NIC_pkg.all;

entity STD_FIFO is
	Generic (
		fifo_depth	: positive := STD_FIFO_FIFO_DEPTH
	);
	Port ( 
		clk			: in  std_logic;
		rst			: in  std_logic;
		WrValid_in	: in  std_logic;
		WrReady_out	: out std_logic;
		WrData_in	: in  std_logic_vector;
		RdReady_in	: in  std_logic;
		RdData_out	: out std_logic_vector;
		RdValid_out	: out std_logic 
	);
end STD_FIFO;

architecture Behavioral of STD_FIFO is
		type fifo_memory is array (0 to fifo_depth - 1) of std_logic_vector(WrData_in'length - 1 downto 0);
		signal Memory : fifo_memory := (others => (others => '0'));
		
		signal wr_pointer : natural range 0 to fifo_depth - 1 := 0;
		signal rd_pointer : natural range 0 to fifo_depth - 1 := 0;
		
		signal count : natural range 0 to fifo_depth := 0;

begin

	fifo_proc : process (clk)
	begin if rising_edge(clk) then

		-- RESET POINTER AND OUTPUTS
		if (rst = '1') then
			wr_pointer <= 0;
			rd_pointer <= 0;
			
			count <= 0;
			
			WrReady_out  <= '1';
			RdValid_out <= '0';
			Memory <= (others => (others => '0'));
		
		else
			-- SET CONTROL SIGNALS AND UPDATE COUNT
			-- for exclusive wr
			if ((WrValid_in = '1' and RdReady_in = '0' and count /= fifo_depth) or 
				(WrValid_in = '1' and RdReady_in = '1' and count = 0)) then
				count <= count + 1;
				RdValid_out <= '1';
				if (count = fifo_depth - 1) then
					WrReady_out <= '0';
				else
					WrReady_out <= '1';
				end if;
			--for exclusive rd
			elsif ((WrValid_in = '0' and RdReady_in = '1' and count /= 0) or
				   (WrValid_in = '1' and RdReady_in = '1' and count = fifo_depth)) then
				count <= count - 1;
				WrReady_out <= '1';
				if (count = 1) then
					RdValid_out <= '0';
				else
					RdValid_out <= '1';
				end if;
			--for simultaneous rd/wr
			elsif (WrValid_in = '1' and RdReady_in = '1') then
				RdValid_out <= '1';
				WrReady_out <= '1';
			else
				if (count = 0) then
					RdValid_out <= '0';
				else
					RdValid_out <= '1';
				end if;
				if (count = fifo_depth) then
					WrReady_out <= '0';
				else
					WrReady_out <= '1';
				end if;
			end if;
	

			--WRITE DATA AND SET WR_POINTER
			if (WrValid_in = '1' and count /= fifo_depth) then
				Memory(wr_pointer) <= WrData_in;
				if (wr_pointer = fifo_depth - 1) then
					wr_pointer <= 0;
				else
					wr_pointer <= wr_pointer + 1;
				end if;
			end if;
	

			--READ DATA AND SET RD_POINTER

			-- if empty then
			if (count = 0) then
				-- set output to input if next cycle rd_pointer is current cycle wr_pointer (bypass Memory)
				RdData_out <= WrData_in;
			else
				-- if ready and not empty update rd_pointer
				if (RdReady_in = '1' and count /= 0) then
					if (rd_pointer = fifo_depth - 1) then
						rd_pointer <= 0;

						-- set output to input if next cycle rd_pointer is current cycle wr_pointer (bypass Memory)
						if (wr_pointer = 0) then
							RdData_out <= WrData_in;
						else
							RdData_out <= Memory(0);
						end if;
					
					else
						rd_pointer <= rd_pointer + 1;

						-- set output to input if next cycle rd_pointer is current cycle wr_pointer (bypass Memory)
						if (wr_pointer = rd_pointer + 1) then
							RdData_out <= WrData_in;
						else
							RdData_out <= Memory(rd_pointer + 1);
						end if;
					end if;
				-- -- otherwise keep output at Memory(rd_pointer)
				-- else
				-- 	   RdData_out <= Memory(rd_pointer);
				end if;
			end if;
			   
		end if;
		end if;
	end process;
		
end Behavioral;
