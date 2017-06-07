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

ENTITY pokey_poly_5 IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	INIT : IN STD_LOGIC;
	
	BIT_OUT : OUT STD_LOGIC
);
END pokey_poly_5;

ARCHITECTURE vhdl OF pokey_poly_5 IS
	signal shift_reg: std_logic_vector(4 downto 0);
	signal shift_next: std_logic_vector(4 downto 0);
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			shift_reg <= "01010";
		elsif (clk'event and clk='1') then
			shift_reg <= shift_next;
		end if;
	end process;
	
	-- next state
	process(shift_reg,enable,init)
	begin
		shift_next <= shift_reg;
		if (enable = '1') then
			shift_next <= ((shift_reg(2) xnor shift_reg(0)) and not(init))&shift_reg(4 downto 1);
		end if;
	end process;
	
	-- output
	bit_out <= shift_reg(0);
		
END vhdl;
