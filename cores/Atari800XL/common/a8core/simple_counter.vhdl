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

-- Counter where only some bits are incremented - done in antic to save using larger adders I guess
ENTITY simple_counter IS
generic
(
	COUNT_WIDTH : natural := 1
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_n : IN STD_LOGIC;
	increment : in std_logic;
	load : IN STD_LOGIC;
	load_value : in std_logic_vector(COUNT_WIDTH-1 downto 0);

	current_value : out std_logic_vector(COUNT_WIDTH-1 downto 0)
);
END simple_counter;

ARCHITECTURE vhdl OF simple_counter IS
	signal value_next : std_logic_vector(COUNT_WIDTH-1 downto 0);
	signal value_reg : std_logic_vector(COUNT_WIDTH-1 downto 0);
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			value_reg <= (others=>'0');
		elsif (clk'event and clk='1') then			
			value_reg <= value_next;
		end if;
	end process;

	-- next state
	process(increment, value_reg, load, load_value)
	begin
		value_next <= value_reg;

		if (increment = '1') then
			value_next <= std_logic_vector(unsigned(value_reg(COUNT_WIDTH-1 downto 0)) + 1);
		end if;
		
		if (load = '1') then
			value_next <= load_value;
		end if;
	end process;
	
	-- output
	current_value <= value_reg;
	
END vhdl;
