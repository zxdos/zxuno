library ieee;
	use ieee.numeric_std.all;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

--	|VGA 640x480 | Horizontal|   Vertical|
--	+------------+-----------+-----------+
--	|Visible area|  0-639:640|  0-479:480|
--	|Front porch |640-655: 16|480-489: 10|
--	|Sync pulse  |656-751: 96|490-491:  2|
--	|Back porch  |752-799: 48|492-524: 33|
--	|Whole line  |        800|        525|

entity vga is
	port
	(
		clock25 : in  std_logic;
		hs      : out std_logic;
		vs      : out std_logic;
		rgb     : out std_logic_vector(11 downto 0)
	);
end;

architecture behavioral of vga is

	signal x : std_logic_vector(9 downto 0);
	signal y : std_logic_vector(9 downto 0);

begin

	process(clock25)
	begin
		if rising_edge(clock25) then
			if x < 799 then x <= x+1;
			else
				x <= (others => '0');
				if y < 524 then y <= y+1; 
				else
					y <= (others => '0');
				end if;
			end if;

			if x >= 640+16 and x < 640+16+96 then hs <= '0'; else hs <= '1'; end if;
			if y >= 480+10 and y < 480+10+ 2 then vs <= '0'; else vs <= '1'; end if;

			if x < 640 and y < 480 then
				rgb <= x"777";
			else
				rgb <= x"000";
			end if;
		end if;
	end process;

end;
