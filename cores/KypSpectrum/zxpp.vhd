library ieee;
	use ieee.std_logic_1164.all;

entity zxpp is
	port
	(
		netRST   : in  std_logic;
		netNMI   : in  std_logic;
		netCLK   : in  std_logic;
		--
		videoV   : out std_logic;
		videoH   : out std_logic;
		videoR   : out std_logic_vector(3 downto 0);
		videoG   : out std_logic_vector(3 downto 0);
		videoB   : out std_logic_vector(3 downto 0)
	);
end;

architecture structural of zxpp is

	signal clock25  : std_logic;
	signal clock14  : std_logic;
	signal clock4   : std_logic;
	signal reset    : std_logic;
	signal nmi      : std_logic;
	signal int      : std_logic;
	signal mreq     : std_logic;
	signal iorq     : std_logic;
	signal m1       : std_logic;
	signal rd       : std_logic;
	signal wr       : std_logic;
	signal a        : std_logic_vector(15 downto 0);
	signal d        : std_logic_vector( 7 downto 0);
	signal va       : std_logic_vector(12 downto 0);
	signal vd       : std_logic_vector( 7 downto 0);
	signal dula     : std_logic_vector( 7 downto 0);
	signal dcpu     : std_logic_vector( 7 downto 0);
	signal drom     : std_logic_vector( 7 downto 0);
	signal dloram   : std_logic_vector( 7 downto 0);
	signal wloram   : std_logic;

begin

	Uclock: entity work.clock port map
	(
		clock32            => netCLK,
		clock25            => clock25,
		clock14            => clock14
	);
	Uula: entity work.ula port map
	(
		clock25            => clock25,
		clock14            => clock14,
		clock4             => clock4,
		iorq               => iorq,
		rd                 => rd,
		wr                 => wr,
		a0                 => a(0),
		di                 => dcpu,
		do                 => dula,
		int                => int,
		va                 => va,
		vd                 => vd,
		hs                 => videoH,
		vs                 => videoV,
		rgb(11 downto 8)   => videoR,
		rgb( 7 downto 4)   => videoG,
		rgb( 3 downto 0)   => videoB
	);
	Ucpu: entity work.tv80n port map
	(
		clk                => clock4,
		reset_n            => reset,
		nmi_n              => nmi,
		int_n              => int,
		wait_n             => '1',
		busrq_n            => '1',
		mreq_n             => mreq,
		iorq_n             => iorq,
		rd_n               => rd,
		wr_n               => wr,
		m1_n               => m1,
		rfsh_n             => open,
		halt_n             => open,
		busak_n            => open,
		a                  => a,
		di                 => d,
		dout               => dcpu
	);
	Urom: entity work.rom port map
	(
		clka               => clock4,
		addra              => a(13 downto 0),
		douta              => drom
	);
	Uloram: entity work.loram port map
	(
		clka               => clock4,
		wea(0)             => wloram,
		addra              => a(13 downto 0),
		dina               => dcpu,
		douta              => dloram,
		clkb               => clock25,
		web(0)             => '0',
		addrb(13)          => '0',
		addrb(12 downto 0) => va,
		dinb               => (others => '0'),
		doutb              => vd
	);

	reset    <= not netRST;
	nmi      <= not netNMI;

	wloram   <= '1' when mreq = '0' and wr = '0' and a(15 downto 14) = "01" else '0';

	d <= dula   when iorq = '0' and rd = '0' and a(0) = '0'
	else drom   when mreq = '0' and rd = '0' and a(15 downto 14) = "00"
	else dloram when mreq = '0' and rd = '0' and a(15 downto 14) = "01"
	else (others => '1');

end;
