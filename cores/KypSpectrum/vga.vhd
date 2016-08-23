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
		border  : in  std_logic_vector( 2 downto 0);
		va      : out std_logic_vector(12 downto 0);
		vd      : in  std_logic_vector( 7 downto 0);
		hs      : out std_logic;
		vs      : out std_logic;
		rgb     : out std_logic_vector(11 downto 0)
	);
end;

architecture behavioral of vga is

	signal xy     : std_logic_vector(17 downto 0);
	signal x      : std_logic_vector( 9 downto 0) := std_logic_vector(to_unsigned(512-20, 10));
	signal y      : std_logic_vector( 9 downto 0) := std_logic_vector(to_unsigned(383, 10));
	signal f      : std_logic_vector( 5 downto 0);
	signal bmap   : std_logic_vector( 7 downto 0);
	signal attr   : std_logic_vector( 7 downto 0);

	type tpalette is array (0 to 15) of std_logic_vector(11 downto 0);
	constant palette : tpalette := ( x"000", x"007", x"700", x"707", x"070", x"077", x"770", x"777", x"000", x"00f", x"f00", x"f0f", x"0f0", x"0ff", x"ff0", x"fff" );

begin

	process(clock25)
		variable bpre : std_logic_vector(7 downto 0);
		variable apre : std_logic_vector(7 downto 0);
		variable i, p : std_logic_vector(2 downto 0);
		variable b, c : integer;
	begin
		if rising_edge(clock25) then
			if x < 799 then x <= x+1;
			else
				x <= (others => '0');
				if y < 524 then y <= y+1; 
				else
					y <= (others => '0');
					f <= f+1;
				end if;
			end if;

			if x >= 640+16 and x < 640+16+96 then hs <= '0'; else hs <= '1'; end if;
			if y >= 480+10 and y < 480+10+ 2 then vs <= '0'; else vs <= '1'; end if;

			if x >= 64 and x < 64+512 and y >= 48 and y < 48+384 then
				if x = 64+512-16 and y = 48+383 then xy <= (others => '0'); else xy <= xy+1; end if;

				if xy(3 downto 0) = "0000" then va   <=       xy(17 downto 16)&xy(12 downto 10)&xy(15 downto 13)&xy(8 downto 4); end if;
				if xy(3 downto 0) = "1000" then va   <= "110"&xy(17 downto 13)&xy( 8 downto 4); end if;
				if xy(3 downto 0) = "0010" then bpre := vd; end if;
				if xy(3 downto 0) = "1010" then apre := vd; end if;
				if xy(3 downto 0) = "1110" then bmap <= bpre; attr <= apre; end if;

				b := 7-to_integer(unsigned(x(3 downto 1)));
				i := attr(2 downto 0);
				p := attr(5 downto 3);

				if attr(7) = '1' then
					if f(5) = '1' then
						if bmap(b) = '0' then c := to_integer(unsigned(i)); else c := to_integer(unsigned(p)); end if;
					else
						if bmap(b) = '0' then c := to_integer(unsigned(p)); else c := to_integer(unsigned(i)); end if;
					end if;
				else
					if bmap(b) = '1' then c := to_integer(unsigned(i)); else c := to_integer(unsigned(p)); end if;
				end if;

				if attr(6) = '1' then c := c+8; end if;
				rgb <= palette(c);
			elsif x < 640 and y < 480 then
				rgb <= palette(to_integer(unsigned(border)));
			else
				rgb <= x"000";
			end if;
		end if;
	end process;

end;
