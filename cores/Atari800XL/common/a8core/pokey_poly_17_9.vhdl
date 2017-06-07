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

ENTITY pokey_poly_17_9 IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	SELECT_9_17 : IN STD_LOGIC; -- 9 high, 17 low
	INIT : IN STD_LOGIC;
	
	BIT_OUT : OUT STD_LOGIC;
	
	RAND_OUT : OUT std_logic_vector(7 downto 0)
);
END pokey_poly_17_9;

ARCHITECTURE vhdl OF pokey_poly_17_9 IS
	signal shift_reg: std_logic_vector(16 downto 0);
	signal shift_next: std_logic_vector(16 downto 0);

	signal cycle_delay_reg : std_logic;
	signal cycle_delay_next : std_logic;
	
	signal feedback : std_logic;
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			shift_reg <= "01010101010101010";
			cycle_delay_reg <= '0';
		elsif (clk'event and clk='1') then
			shift_reg <= shift_next;
			cycle_delay_reg <= cycle_delay_next;
		end if;
	end process;
	
	-- next state (as pokey decap)
	feedback <= shift_reg(13) xnor shift_reg(8);
	process(enable,shift_reg,feedback,select_9_17,init,cycle_delay_reg)
	begin
		shift_next <= shift_reg;
		cycle_delay_next <= cycle_delay_reg;
		
		if (enable = '1') then	
			shift_next(15 downto 8) <= shift_reg(16 downto 9);	
			shift_next(7) <= feedback;
			shift_next(6 downto 0) <= shift_reg(7 downto 1);

			shift_next(16) <= ((feedback and select_9_17) or (shift_reg(0) and not(select_9_17))) and not(init);

			cycle_delay_next <= shift_reg(9);
		end if;
	end process;
	
		-- output
	bit_out <= cycle_delay_reg; -- from pokey schematics
	RAND_OUT(7 downto 0) <= not(shift_reg(15 downto 8));
		
END vhdl;
