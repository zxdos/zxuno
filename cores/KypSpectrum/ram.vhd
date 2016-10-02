library ieee;
	use ieee.std_logic_1164.all;

entity ram is
	port
	(
		wr        : in    std_logic;
		di        : in    std_logic_vector( 7 downto 0);
		do        : out   std_logic_vector( 7 downto 0);
		a         : in    std_logic_vector(18 downto 0);
		--
		sramWr    : out   std_logic;
		sramData  : inout std_logic_vector( 7 downto 0);
		sramAddr  : out   std_logic_vector(18 downto 0)
	);
end;


architecture structural of ram is
begin

	sramWr   <= wr;
	sramData <= di when wr = '0' else (others => 'Z');
	sramAddr <= a;
	do <= sramData;

end;
