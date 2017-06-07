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

ENTITY gtia_player IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : in std_logic;
	
	COLOUR_ENABLE : IN STD_LOGIC;
	LIVE_POSITION : in std_logic_vector(7 downto 0);   -- counter ticks as display is drawn
	PLAYER_POSITION : in std_logic_vector(7 downto 0); -- requested position
	SIZE : in std_logic_vector(1 downto 0);
	bitmap : in std_logic_vector(7 downto 0);
	
	output : out std_logic
);
END gtia_player;

ARCHITECTURE vhdl OF gtia_player IS

	-- pmgs
	signal shift_next : std_logic_vector(7 downto 0);
	signal shift_reg : std_logic_vector(7 downto 0);
	signal count_next : std_logic_vector(1 downto 0);
	signal count_reg : std_logic_vector(1 downto 0);
begin
		-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			shift_reg <= (others=>'0');
			count_reg <= (others=>'0');		
		elsif (clk'event and clk='1') then										
			shift_reg <= shift_next;
			count_reg <= count_next;
		end if;
	end process;
	
	
	process(shift_next,COLOUR_ENABLE, live_position, player_position, size, bitmap, shift_reg, count_reg)
	begin
		-- size is 2 bits (00 normal, 01 twice, 10 normal(bugged), 11 four times)
		-- grafp0 is 8 bits of data (2 bits for missiles)
		-- hposp0_reg is position - 0x30 is left side of normal playfield, 0xd0 is right size of normal playfield
		
		-- 'or' into shift register, so if not empty we get extra pixels
		
		-- counter before we shift	
		
		shift_next <= shift_reg;
		count_next <= count_reg;
		
		output <= shift_next(7);
		
		if (COLOUR_ENABLE = '1') then								
			case size is 
				when "00" => -- normal size
					count_next <= "00";
					shift_next <= shift_reg(6 downto 0) &'0';
				when "10" => -- normal size (with bug)
					case count_reg is
						when "00"|"11" =>
							count_next <= "00";
							shift_next <= shift_reg(6 downto 0) &'0';
						when "01"|"10" =>
							count_next <= "10";						
						when others=>
							--hang!
					end case;					
				when "01" =>					
					case count_reg is
						when "01"|"11" =>
							count_next <= "00";
							shift_next <= shift_reg(6 downto 0) &'0';
						when "00"|"10" =>
							count_next <= "01";							
						when others=>
							--hang!
					end case;					

				when "11" =>
					case count_reg is
						when "00" =>
							count_next <= "01";
						when "01" =>
							count_next <= "10";						
						when "10" =>
							count_next <= "11";
						when "11" =>
							shift_next <= shift_reg(6 downto 0) &'0';
							count_next <= "00";
						when others=>
							--hang!
					end case;
				when others=>
					--hang!
			end case;	

			if (live_position = player_position) then
				shift_next <= shift_reg(6 downto 0) &'0' or bitmap;
				count_next <= (others=>'0');
			end if;			
		end if;
		
	end process;
	
end vhdl;
