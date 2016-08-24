library ieee;
	use ieee.std_logic_1164.all;

entity zxpp is
	port
	(
		netCLK   : in  std_logic;
		netRST   : in  std_logic;
		netNMI   : in  std_logic;
		--
		ps2CLK   : inout std_logic;
		ps2DAT   : inout std_logic;
		--
		joyBTN   : in  std_logic_vector(4 downto 0);
		joyGND   : out std_logic;
		--
		audioL   : out std_logic;
		audioR   : out std_logic;
		audioEAR : in  std_logic;
		audioGND : out std_logic;
		--
		videoV   : out std_logic;
		videoH   : out std_logic;
		videoR   : out std_logic_vector(3 downto 0);
		videoG   : out std_logic_vector(3 downto 0);
		videoB   : out std_logic_vector(3 downto 0)
	);
end;

architecture structural of zxpp is

	signal clockVGA : std_logic;
	signal clockCPU : std_logic;
	signal clockPS2 : std_logic;
	signal clockDAC : std_logic;
	signal clockAY  : std_logic;
	--
	signal reset    : std_logic;
	signal kreset   : std_logic;
	--
	signal iorq     : std_logic;
	signal mreq     : std_logic;
	signal nmi      : std_logic;
	signal int      : std_logic;
	signal rd       : std_logic;
	signal wr       : std_logic;
	signal a        : std_logic_vector(15 downto 0);
	signal d        : std_logic_vector( 7 downto 0);
	signal dcpu     : std_logic_vector( 7 downto 0);
	--
	signal ear      : std_logic;
	signal mic      : std_logic;
	signal speaker  : std_logic;
	signal va       : std_logic_vector(12 downto 0);
	signal vd       : std_logic_vector( 7 downto 0);
	signal dula     : std_logic_vector( 7 downto 0);
--
	signal rps2     : std_logic;
	signal dps2     : std_logic_vector( 7 downto 0);
	signal keys     : std_logic_vector( 4 downto 0);
--
	signal erom     : std_logic;
	signal drom     : std_logic_vector( 7 downto 0);
	--
	signal eloram   : std_logic;
	signal wloram   : std_logic;
	signal dloram   : std_logic_vector( 7 downto 0);
	--
	signal ehiram   : std_logic;
	signal whiram   : std_logic;
	signal dhiram   : std_logic_vector( 7 downto 0);
	--
	signal aybdir   : std_logic;
	signal aybc1    : std_logic;
	signal ayoe     : std_logic;
	signal aydata   : std_logic_vector( 7 downto 0);
	signal ayaudio  : std_logic_vector( 7 downto 0);
	--
	signal kempston : std_logic_vector( 7 downto 0);

begin

	Uclock: entity work.clock port map
	(
		clock32            => netCLK,
		clockVGA           => clockVGA,
		clockCPU           => clockCPU,
		clockPS2           => clockPS2,
		clockDAC           => clockDAC,
		clockAY            => clockAY
	);
	Ucpu: entity work.tv80n port map
	(
		clk                => clockCPU,
		reset_n            => reset,
		busrq_n            => '1',
		wait_n             => '1',
		busak_n            => open,
		halt_n             => open,
		rfsh_n             => open,
		m1_n               => open,
		mreq_n             => mreq,
		iorq_n             => iorq,
		nmi_n              => nmi,
		int_n              => int,
		rd_n               => rd,
		wr_n               => wr,
		a                  => a,
		di                 => d,
		dout               => dcpu
	);
	Uula: entity work.ula port map
	(
		clockVGA           => clockVGA,
		clockCPU           => clockCPU,
		keys               => keys,
		iorq               => iorq,
		int                => int,
		rd                 => rd,
		wr                 => wr,
		a0                 => a(0),
		di                 => dcpu,
		do                 => dula,
		ear                => audioEAR,
		mic                => mic,
		speaker            => speaker,
		va                 => va,
		vd                 => vd,
		hs                 => videoH,
		vs                 => videoV,
		rgb(11 downto 8)   => videoR,
		rgb( 7 downto 4)   => videoG,
		rgb( 3 downto 0)   => videoB
	);
	Ups2: entity work.ps2 port map
	(
		clock              => clockPS2,
		ps2c               => ps2CLK,
		ps2d               => ps2DAT,
		received           => rps2,
		scancode           => dps2
	);
	Ukeyboard: entity work.keyboard port map
	(
		received           => rps2,
		scancode           => dps2,
		rows               => a(15 downto 8),
		cols               => keys,
		reset              => kreset
	);
	Urom: entity work.rom port map
	(
		clka               => clockCPU,
		ena                => erom,
		addra              => a(13 downto 0),
		douta              => drom
	);
	Uloram: entity work.loram port map
	(
		clka               => clockCPU,
		ena                => eloram,
		wea(0)             => wloram,
		addra              => a(13 downto 0),
		dina               => dcpu,
		douta              => dloram,
		clkb               => clockVGA,
		web(0)             => '0',
		addrb(13)          => '0',
		addrb(12 downto 0) => va,
		dinb               => (others => '0'),
		doutb              => vd
	);
	Uhiram: entity work.hiram port map
	(
		clka               => clockCPU,
		ena                => ehiram,
		wea(0)             => whiram,
		addra              => a(14 downto 0),
		dina               => dcpu,
		douta              => dhiram
	);
	Uym2149: entity work.ym2149 port map
	(
		clk                => clockAY,
		ena                => '1',
		reset_l            => reset,
		i_da               => dcpu,
		o_da               => aydata,
		o_da_oe_l          => ayoe,
		i_a9_l             => '0',
		i_a8               => '1',
		i_bc2              => '1',
		i_bc1              => aybc1,
		i_bdir             => aybdir,
		i_sel_l            => '0',
		o_audio            => ayaudio,
		i_ioa              => (others => '0'),
		o_ioa              => open,
		o_ioa_oe_l         => open,
		i_iob              => (others => '0'),
		o_iob              => open,
		o_iob_oe_l         => open
	);
	Umixer: entity work.mixer port map
	(
		clock              => clockDAC,
		reset              => reset,
		speaker            => speaker,
		ear                => audioEAR,
		mic                => mic,
		ay                 => ayaudio,
		l                  => audioL,
		r                  => audioR
	);

	reset  <= not (netRST or kreset);
	nmi    <= not netNMI;

	audioGND <= '0';
	joyGND   <= '0';
	kempston <= not ("111"&joyBTN(4)&joyBTN(0)&joyBTN(1)&joyBTN(2)&joyBTN(3));

	erom   <= '1' when mreq = '0' and a(15 downto 14) = "00" else '0';
	eloram <= '1' when mreq = '0' and a(15 downto 14) = "01" else '0';
	ehiram <= '1' when mreq = '0' and a(15) = '1' else '0';
	
	wloram <= not wr;
	whiram <= not wr;

	aybdir <= '1' when iorq = '0' and wr = '0' and a(15) = '1' and a(1 downto 0) = "01" else '0';
	aybc1  <= '1' when iorq = '0' and a(15 downto 14) = "11" and a(1 downto 0) = "01" else '0';

	d <= dhiram   when ehiram  = '1' and rd = '0'
	else dloram   when eloram  = '1' and rd = '0'
	else drom     when erom    = '1' and rd = '0'
	else kempston when iorq    = '0' and rd = '0' and a(7 downto 5) = "000"
	else aydata   when ayoe    = '0'
	else dula;

end;
