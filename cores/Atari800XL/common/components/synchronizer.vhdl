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

ENTITY synchronizer IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RAW : IN STD_LOGIC;
	SYNC : OUT STD_LOGIC
);
END synchronizer;

ARCHITECTURE vhdl OF synchronizer IS
	signal ff_next : std_logic_vector(2 downto 0);
	signal ff_reg : std_logic_vector(2 downto 0);
begin
	-- register
	process(clk)
	begin
		if (clk'event and clk='1') then						
			ff_reg <= ff_next;	
		end if;
	end process;
	
	ff_next <= RAW&ff_reg(2 downto 1);
	
	SYNC <= ff_reg(0);

end vhdl;


