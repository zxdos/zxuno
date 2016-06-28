--  PS/2 Keyboard
-- 
-- 2015 modified by Quest  - orig: 2011 Mike Stirling

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
port (
	CLOCK		:	in		std_logic;
	PS2_CLK	:	in		std_logic;
	PS2_DATA	:	in		std_logic;
	resetKey	:	out	std_logic;
	MRESET	:  out	std_logic;
   scanSW	:	out	std_logic_vector(7 downto 0)
	);
end entity;

architecture rtl of keyboard is

-- PS/2 interface
component ps2_intf is
generic (filter_length : positive := 8);
port(
	CLK			:	in	std_logic;
	nRESET		:	in	std_logic;
	
	-- PS/2 interface (could be bi-dir)
	PS2_CLK		:	in	std_logic;
	PS2_DATA		:	in	std_logic;
	
	-- Byte-wide data interface - only valid for one clock
	-- so must be latched externally if required
	DATA		:	out	std_logic_vector(7 downto 0);
	VALID		:	out	std_logic
--	;ERROR		:	out	std_logic
	);
end component;

-- Interface to PS/2 block
signal keyb_data	:	std_logic_vector(7 downto 0);
signal keyb_valid	:	std_logic;
--signal keyb_error	:	std_logic;

-- Internal signals
signal release		:	std_logic;
--signal extended	:	std_logic;
signal nRESET		:	std_logic;

-- controles
signal CTRL	: std_logic;
signal ALT	: std_logic;
signal PAUSE: std_logic := '0';
signal VIDEO: std_logic := '0';

begin

	ps2 : ps2_intf port map (
		CLOCK, nRESET,
		PS2_CLK, PS2_DATA,
		keyb_data, keyb_valid --, keyb_error
		);

	-- Decode PS/2 data
	process(CLOCK,nRESET)
	begin
		if nRESET = '0' then
			release <= '0';
--			extended <= '0';			
			resetKey <= '0';
			
		elsif rising_edge(CLOCK) then
		
			if keyb_valid = '1' then
				-- Decode keyboard input
				if keyb_data = X"e0" then
					-- Extended key code follows
--					extended <= '1';
				elsif keyb_data = X"f0" then
					-- Release code follows
					release <= '1';
				else
					-- Cancel extended/release flags for next time
					release <= '0';
--					extended <= '0';
					
					-- Decode scan codes
					case keyb_data is

					--Master reset
					when X"66" =>  
							if (CTRL = '1' and ALT = '1') then
								MRESET <= not release; 
							end if;
					when X"14" =>  CTRL <= not release; 
					when X"11" =>  ALT <= not release; 
					
					when X"07" => resetKey <= not release; -- F12 reset/menu
					
					when X"75" => scanSW(0) <= not release; --up + q
					when X"15" => scanSW(0) <= not release;
					when X"72" => scanSW(1) <= not release; --down + a
					when X"1C" => scanSW(1) <= not release;
					when X"6B" => scanSW(2) <= not release; --left + o
					when X"44" => scanSW(2) <= not release;
					when X"74" => scanSW(3) <= not release; --right + p
					when X"4D" => scanSW(3) <= not release;
					when X"1A" => scanSW(4) <= not release; --bl = z, enter, space
					when X"5A" => scanSW(4) <= not release;
					when X"29" => scanSW(4) <= not release;					
					when X"22" => scanSW(5) <= not release; --br = x, L-win
					when X"1F" => scanSW(5) <= not release; 

					when X"7E" => 									 -- scrolLock RGB/VGA
							if (VIDEO = '0' and release = '0') then
								scanSW(6) <= '1';
								VIDEO <= '1';
							elsif (VIDEO = '1' and release = '0') then
								scanSW(6) <= '0';
								VIDEO <= '0';
							end if;

					when X"E1" => 						  			-- pause 
							if (PAUSE = '0') then
								scanSW(7) <= '1';
								PAUSE <= '1';
							else
								scanSW(7) <= '0';
								PAUSE <= '0';
							end if;
								
					when others => null;
					end case;
					
				end if;
			end if;
		end if;
	end process;
nRESET <= '1';

end architecture;

