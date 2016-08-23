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

	component loram
	port
	(
		clka 	  : in  std_logic;	
		wea  	  : in  std_logic_vector( 0 downto 0);	
		addra	  : in  std_logic_vector(13 downto 0);	
		dina 	  : in  std_logic_vector( 7 downto 0);	
		douta	  : out std_logic_vector( 7 downto 0);	
		clkb 	  : in  std_logic;	
		web  	  : in  std_logic_vector( 0 downto 0);	
		addrb	  : in  std_logic_vector(13 downto 0);	
		dinb 	  : in  std_logic_vector( 7 downto 0);	
		doutb   : out std_logic_vector( 7 downto 0)
	);
	end component;

	component vga is
	port
	(
		clock25 : in  std_logic;
		va      : out std_logic_vector(12 downto 0);
		vd      : in  std_logic_vector( 7 downto 0);
		hs      : out std_logic;
		vs      : out std_logic;
		rgb     : out std_logic_vector(11 downto 0)
	);
	end component;

	signal clock25 : std_logic;
	signal clock14 : std_logic;
	signal va      : std_logic_vector(12 downto 0);
	signal vd      : std_logic_vector( 7 downto 0);

begin

	Uclock: clock port map
	(
		clock32          => netCLK,
		clock25          => clock25,
		clock14          => clock14
	);
	Uloram: loram port map
	(
		clka               => '0',
		wea(0)             => '0',
		addra              => (others => '0'),
		dina               => (others => '0'),
		douta              => open,
		clkb               => clock25,
		web(0)             => '0',
		addrb(13)          => '0',
		addrb(12 downto 0) => va,
		dinb               => (others => '0'),
		doutb              => vd
	);
	Uvga: vga port map
	(
		clock25          => clock25,
		va               => va,
		vd               => vd,
		hs               => netHS,
		vs               => netVS,
		rgb(11 downto 8) => netR,
		rgb( 7 downto 4) => netG,
		rgb( 3 downto 0) => netB
	);

end;
