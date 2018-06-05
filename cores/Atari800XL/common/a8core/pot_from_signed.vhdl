---------------------------------------------------------------------------
-- (c) 2014 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.math_real.ceil;
--USE ieee.math_real.log2; (non-linear version?)
use IEEE.STD_LOGIC_MISC.all;

ENTITY pot_from_signed IS
GENERIC
(
	cycle_length : integer := 32;
	line_length : integer := 114;
	min_lines : integer := 0;
	max_lines : integer := 227;
	reverse : integer := 0
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	ENABLED : IN STD_LOGIC;
	POT_RESET : IN STD_LOGIC;
	POS : IN SIGNED(7 downto 0);
	POT_HIGH : OUT STD_LOGIC
);
END pot_from_signed;

ARCHITECTURE vhdl OF pot_from_signed IS
	signal enable_179 : std_logic;
	signal count_enable : std_logic;

	signal count_reg : std_logic_vector(9 downto 0);
	signal count_next : std_logic_vector(9 downto 0);

	signal pot_out_reg : std_logic;
	signal pot_out_next : std_logic;
	
	constant count_cycles : integer :=(max_lines-min_lines)*line_length/256; -- i.e. how many machines cycles for every change in POS
BEGIN

enable_179_clock_div : entity work.enable_divider
	generic map (COUNT=>cycle_length)
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>enable_179);

---- 114K to 386k (51 to 172) 121 lines.  i.e. 121*114 cycles/256 values = ~54
---- TODO linear or not?
pot_clock_div : entity work.enable_divider
	generic map (COUNT=>count_cycles)
	port map(clk=>clk,reset_n=>reset_n,enable_in=>enable_179,enable_out=>count_enable);

	process(clk, reset_n)
	begin
		if (reset_n='0') then
			count_reg <= (others=>'0');
			pot_out_reg <= '0';
		elsif (clk'event and clk='1') then
			count_reg <= count_next;
			pot_out_reg <= pot_out_next;
		end if;
	end process;

	process(count_reg,pot_reset,count_enable,pot_out_next,enabled,pos)
	begin
		count_next <= count_reg;

		if (pot_reset ='1' or enabled = '0') then
			if (reverse = 1) then
				count_next <= std_logic_vector(to_unsigned(-to_integer(pos)+127+(line_length*min_lines/count_cycles),10));
			else
				count_next <= std_logic_vector(to_unsigned(to_integer(pos)+128+(line_length*min_lines/count_cycles),10));
			end if;
		end if;

		if (count_enable = '1') then
			if (pot_out_next = '0') then
				count_next <= std_logic_vector(unsigned(count_reg) -1);
			end if;
		end if;

		pot_out_next <= not(or_reduce(count_reg));

	end process;

	pot_high <= pot_out_reg;
end vhdl;

