---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY delay_line IS
generic(COUNT : natural := 1);
PORT 
( 
	CLK : IN STD_LOGIC;
	SYNC_RESET : IN STD_LOGIC;
	DATA_IN : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC; -- i.e. shift on this clock
	RESET_N : IN STD_LOGIC;
	
	DATA_OUT : OUT STD_LOGIC
);
END delay_line;

ARCHITECTURE vhdl OF delay_line IS
	signal shift_reg : std_logic_vector(COUNT-1 downto 0);
	signal shift_next : std_logic_vector(COUNT-1 downto 0);
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_N = '0') then
			shift_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			shift_reg <= shift_next;
		end if;
	end process;

	-- shift on enable
	process(shift_reg,enable,data_in,sync_reset)
	begin
		shift_next <= shift_reg;
				
		if (enable = '1') then
			shift_next <= data_in&shift_reg(COUNT-1 downto 1);
		end if;		
		
		if (sync_reset = '1') then
			shift_next <= (others=>'0');
		end if;		
	end process;
	
	-- output
	data_out <= shift_reg(0) and enable;
		
END vhdl;
