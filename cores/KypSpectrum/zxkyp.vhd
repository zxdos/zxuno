library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
library unisim;
	use unisim.vcomponents.all;

entity zxkyp is
	port
	(
		clock50   : in    std_logic;
		led       : out   std_logic;
		--
    sw        : in std_logic_vector(7 downto 0);
    col       : inout std_logic_vector(4 downto 0);
		--
		sramWr    : out   std_logic;
		sramData  : inout std_logic_vector( 7 downto 0);
		sramAddr  : out   std_logic_vector(18 downto 0);
		--
		videoRgb  : out   std_logic_vector( 8 downto 0);
		videoSync : out   std_logic_vector( 1 downto 0);
		videoStdn : out   std_logic_vector( 1 downto 0);
		--
		ear       : in    std_logic;
		audio     : out   std_logic_vector(1 downto 0);
		--
		ps2       : inout std_logic_vector(1 downto 0);
		--
		sdClock   : out std_logic;
		sdCs      : out std_logic;
		sdDi      : out std_logic;
		sdDo      : in  std_logic
	);
end;

architecture structural of zxkyp is

	signal clock14    : std_logic;
	signal clock700   : std_logic;
	signal clock350   : std_logic;
	signal clock175   : std_logic;

	signal boot       : std_logic;

	signal reset      : std_logic;
	signal pause      : std_logic;
	signal mreq       : std_logic;
	signal iorq       : std_logic;
	signal nmi        : std_logic;
	signal int        : std_logic;
	signal m1         : std_logic;
	signal rd         : std_logic;
	signal wr         : std_logic;
	signal data       : std_logic_vector( 7 downto 0);
	signal addr       : std_logic_vector(15 downto 0);

	signal aP         : std_logic;
	signal cpuEnable  : std_logic;
	signal cpuClock   : std_logic;

	signal v          : std_logic;
	signal h          : std_logic;
	signal r          : std_logic;
	signal g          : std_logic;
	signal b          : std_logic;
	signal i          : std_logic;
	signal mic        : std_logic;
	signal speaker    : std_logic;

	signal automap    : std_logic;
	signal conmem     : std_logic;
	signal mapram     : std_logic;
	signal page       : std_logic_vector( 3 downto 0);

	signal cpuData    : std_logic_vector( 7 downto 0);
	signal ulaData    : std_logic_vector( 7 downto 0);

	signal romCs      : std_logic;
	signal romData    : std_logic_vector( 7 downto 0);

	signal ramCs      : std_logic;
	signal ramWr      : std_logic;
	signal ramData    : std_logic_vector( 7 downto 0);
	signal ramAddr    : std_logic_vector(18 downto 0);

	signal vramCs     : std_logic;
	signal vramWe     : std_logic;
	signal vramAddr   : std_logic_vector(12 downto 0);
	signal vramData   : std_logic_vector( 7 downto 0);

	signal dromCs     : std_logic;
	signal dromData   : std_logic_vector( 7 downto 0);

	signal sdOe       : std_logic;
	signal sdAc       : std_logic;
	signal sdData     : std_logic_vector( 7 downto 0);

	signal ayCs       : std_logic;
	signal ayBc       : std_logic;
	signal ayBdir     : std_logic;
	signal ayData     : std_logic_vector( 7 downto 0);
	signal ayA        : std_logic_vector( 7 downto 0);
	signal ayB        : std_logic_vector( 7 downto 0);
	signal ayC        : std_logic_vector( 7 downto 0);

begin

	Umultiboot : entity work.multiboot port map
	(
		clk_icap    => clock14,
		mrst_n      => boot
	);
	Uclock : entity work.clock port map
	(
		clock50     => clock50,
		clock14     => clock14,
		clock700    => clock700,
		clock350    => clock350,
		clock175    => clock175
	);
	Ucpu : entity work.tv80n port map
	(
		clk         => cpuClock,
		reset_n     => reset,
		wait_n      => pause,
		mreq_n      => mreq,
		iorq_n      => iorq,
		nmi_n       => nmi,
		int_n       => int,
		m1_n        => m1,
		rd_n        => rd,
		wr_n        => wr,
		dout        => cpuData,
		di          => data,
		a           => addr,
		busrq_n     => '1',
		busak_n     => open,
		halt_n      => open,
		rfsh_n      => open
	);
	Uula : entity work.ula port map
	(
		cpuClock    => clock350,
		mreq        => mreq,
		iorq        => iorq,
		rd          => rd,
		wr          => wr,
		a0          => addr(0),
		aP          => aP,
		di          => cpuData,
		do          => ulaData,
		cpuEnable   => cpuEnable,
		--
		vramClock   => clock700,
		vramData    => vramData,
		vramAddr    => vramAddr,
		int         => int,
		v           => v,
		h           => h,
		r           => r,
		g           => g,
		b           => b,
		i           => i,
		--
		ear         => ear,
		mic         => mic,
		speaker     => speaker,
		--
    sw          => sw,
    col         => col,
		rows        => addr(15 downto 8),
		boot        => boot,
		reset       => reset,
		nmi         => nmi,
		ps2         => ps2
	);
	Udiv : entity work.div port map
	(
		clock       => clock350,
		reset       => reset,
		mreq        => mreq,
		iorq        => iorq,
		m1          => m1,
		rd          => rd,
		wr          => wr,
		di          => cpuData,
		a           => addr,
		--
		automap     => automap,
		conmem      => conmem,
		mapram      => mapram,
		page        => page
	);
	Umixer: entity work.mixer port map
	(
		clock       => clock350,
		reset       => reset,
		speaker     => speaker,
		ear         => ear,
		mic         => mic,
		a           => ayA,
		b           => ayB,
		c           => ayC,
		l           => audio(0),
		r           => audio(1)
	);
	Urom : entity work.rom port map
	(
		clka        => clock350,
		ena         => romCs,
		douta       => romData,
		addra       => addr(13 downto 0)
	);
	Udrom : entity work.drom port map
	(
		clka        => clock350,
		ena         => dromCs,
		douta       => dromData,
		addra       => addr(12 downto 0)
	);
	Uram : entity work.ram port map
	(
		wr          => ramWr,
		di          => cpuData,
		do          => ramData,
		a           => ramAddr,
		--
		sramWr      => sramWr,
		sramData    => sramData,
		sramAddr    => sramAddr
	);
	Uvram : entity work.vram port map
	(
		clka        => clock350,
		ena         => vramCs,
		wea(0)      => vramWe,
		dina        => cpuData,
		addra       => addr(12 downto 0),
		--
		clkb        => clock700,
		doutb       => vramData,
		addrb       => vramAddr
	);
	Usd : entity work.sd port map
	(
		clock       => clock14,
		pause       => pause,
		iorq        => iorq,
		rd          => rd,
		wr          => wr,
		oe          => sdOe,
		di          => cpuData,
		do          => sdData,
		a           => addr,
		--
		sdClock     => sdClock,
		sdCs        => sdAc,
		sdDi        => sdDi,
		sdDo        => sdDo
	);
	Uay8910 : entity work.ay8910 port map
	(
		CLK         => clock350,
		CLC         => clock175,
		RESET       => reset,
		BDIR        => ayBdir,
		CS          => ayCs,
		BC          => addr(14),
		DI          => cpuData,
		DO          => ayData,
		OUT_A       => ayA,
		OUT_B       => ayB,
		OUT_C       => ayC
	);
	Ubuggce : BUFGCE_1 port map
	(
		I           => clock350,
		O           => cpuClock,
		CE          => cpuEnable
	);

	sdCs <= sdAc;
	led  <= not sdAc;

	aP <= '1' when addr(15 downto 14) = "01" else '0';

	vramCs <= '1' when mreq = '0' and addr(15 downto 13) = "010" else '0';
	dromCs <= '1' when mreq = '0' and addr(15 downto 13) = "000" and (conmem = '1' or automap = '1') and mapram = '0' else '0';
	romCs  <= '1' when mreq = '0' and addr(15 downto 14) = "00" and conmem = '0' and automap = '0' else '0';
	ramCs  <= '1' when (mreq = '0' and addr(15 downto 13) = "000" and (conmem = '1' or automap = '1') and mapram = '1')
				  or   (mreq = '0' and addr(15 downto 13) = "001" and (conmem = '1' or automap = '1'))
				  or   (mreq = '0' and addr(15 downto 14) = "01")
				  or   (mreq = '0' and addr(15) = '1')
				  else '0';

	ayBdir <= not wr;
	ayCs   <= '0' when iorq = '0' and m1 = '1' and addr(15) = '1' and addr(13) = '1' and addr(1) = '0' else '1';

	vramWe <= not (mreq or wr) when addr(15 downto 13) = "010" else '0';
	ramWr <= mreq or wr;

	ramAddr <= "01"&x"3"&addr(12 downto 0) when mreq = '0' and addr(15 downto 13) = "000" and (conmem = '1' or automap = '1') and mapram = '1'
		  else "01"&page&addr(12 downto 0) when mreq = '0' and addr(15 downto 13) = "001" and (conmem = '1' or automap = '1')
		  else "00"&"0"&addr;

	data  <= sdData when iorq = '0' and sdOe = '0'
		else ramData when ramCs = '1'
		else romData when romCs = '1'
		else dromData when dromCs = '1'
		else ayData   when ayCs   = '0'
		else ulaData;

	videoRgb  <= (r&'0'&r)&(g&'0'&g)&(b&'0'&b) when i = '0' else (r&r&r)&(g&g&g)&(b&b&b);
	videoSync <= '1'&(v and h);
	videoStdn <= "01";

end;
