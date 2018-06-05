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
	
ENTITY pokey_noise_filter IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	NOISE_SELECT : IN STD_LOGIC_VECTOR(2 downto 0);
		
	PULSE_IN : IN STD_LOGIC;

	NOISE_4 : IN STD_LOGIC;
	NOISE_5 : IN STD_LOGIC;
	NOISE_LARGE : IN STD_LOGIC;

	SYNC_RESET : IN STD_LOGIC;
	
	PULSE_OUT : OUT STD_LOGIC
);
END pokey_noise_filter;

ARCHITECTURE vhdl OF pokey_noise_filter IS
--	signal pulse_noise_a : std_logic;
--	signal pulse_noise_b : std_logic;

	signal audclk : std_logic;
	signal out_next : std_logic;
	signal out_reg : std_logic;
BEGIN
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			out_reg <= '0';
		elsif (clk'event and clk='1') then
			out_reg <= out_next;
		end if;
	end process;

	pulse_out <= out_reg;

	process(pulse_in, noise_4, noise_5, noise_large, noise_select, audclk, out_reg, sync_reset)
	begin
		audclk <= pulse_in;
		out_next <= out_reg;

		if (NOISE_SELECT(2) = '0') then
			audclk <= pulse_in and noise_5;
		end if;

		if (audclk = '1') then
			if (NOISE_SELECT(0) = '1') then
				-- toggle
				out_next <= not(out_reg);
			else
				-- sample
				if (NOISE_SELECT(1) = '1') then
					out_next <= noise_4;
				else
					out_next <= noise_large;
				end if;
			end if;
		end if;

		if (sync_reset = '1') then
			out_next <= '0';
		end if;

	end process;
end vhdl;
