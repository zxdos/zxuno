library ieee;
	use ieee.std_logic_1164.all;

entity sd is
	port
	(
		clock   : in  std_logic;
		pause   : out std_logic;
		iorq    : in  std_logic;
		rd      : in  std_logic;
		wr      : in  std_logic;
		oe      : out std_logic;
		di      : in  std_logic_vector( 7 downto 0);
		do      : out std_logic_vector( 7 downto 0);
		a       : in  std_logic_vector(15 downto 0);
		--
		sdClock : out std_logic;
		sdCs    : out std_logic;
		sdDi    : out std_logic;
		sdDo    : in  std_logic
	);
end;

architecture behavioral of sd is

	signal rx : std_logic;
	signal tx : std_logic;

begin

	process(clock)
	begin
		if rising_edge(clock)
		then
			if iorq = '0' and wr = '0' and (a(7 downto 0) = x"1F" or a(7 downto 0) = x"E7") then sdCs <= di(0); end if;
		end if;
	end process;

	rx <= '1' when iorq = '0' and rd = '0' and (a(7 downto 0) = x"3F" or a(7 downto 0) = x"EB") else '0';
	tx <= '1' when iorq = '0' and wr = '0' and (a(7 downto 0) = x"3F" or a(7 downto 0) = x"EB") else '0';

	Uspi : entity work.spi port map
	(
		clk          => clock,
		enviar_dato  => tx,
		recibir_dato => rx,
		din          => di,
		dout         => do,
		oe_n         => oe,
		wait_n       => pause,
		--
		spi_clk      => sdClock,
		spi_di       => sdDi,
		spi_do       => sdDo
	);

end;
