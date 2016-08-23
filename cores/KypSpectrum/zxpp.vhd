library ieee;
	use ieee.std_logic_1164.all;

entity zxpp is
	port
	(
		netCLK : in  std_logic;
		netVS  : out std_logic;
		netHS  : out std_logic;
		netR   : out std_logic_vector(3 downto 0);
		netG   : out std_logic_vector(3 downto 0);
		netB   : out std_logic_vector(3 downto 0)
	);
end;

architecture structural of zxpp is

	component clock is
	port
	(
		clock32 : in  std_logic;
		clock25 : out std_logic;
		clock14 : out std_logic
	);
	end component;

	component vga is
	port
	(
		clock25 : in  std_logic;
		hs      : out std_logic;
		vs      : out std_logic;
		rgb     : out std_logic_vector(11 downto 0)
	);
	end component;

	signal clock25  : std_logic;
	signal clock14  : std_logic;

begin

	Uclock: clock port map
	(
		clock32          => netCLK,
		clock25          => clock25,
		clock14          => clock14
	);
	Uvga: vga port map
	(
		clock25          => clock25,
		hs               => netHS,
		vs               => netVS,
		rgb(11 downto 8) => netR,
		rgb( 7 downto 4) => netG,
		rgb( 3 downto 0) => netB
	);

end;
