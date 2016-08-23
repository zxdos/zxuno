library ieee;
	use ieee.std_logic_1164.all;

entity ula is
	port
	(
		clock25 : in  std_logic;
		clock14 : in  std_logic;
		clock4  : out std_logic;
		iorq    : in  std_logic;
		rd      : in  std_logic;
		wr      : in  std_logic;
		a0      : in  std_logic;
		di      : in  std_logic_vector( 7 downto 0);
		do      : out std_logic_vector( 7 downto 0);
		int     : out std_logic;
		ear     : in  std_logic;
		mic     : out std_logic;
		speaker : out std_logic;
		keycols : in  std_logic_vector( 4 downto 0);
		va      : out std_logic_vector(12 downto 0);
		vd      : in  std_logic_vector( 7 downto 0);
		hs      : out std_logic;
		vs      : out std_logic;
		rgb     : out std_logic_vector(11 downto 0)
	);
end;

architecture behavioral of ula is

	signal clock  : std_logic;
	signal portFF : std_logic_vector(2 downto 0);

	signal rows   : std_logic_vector(7 downto 0);
	signal cols   : std_logic_vector(4 downto 0);

begin

	Uvga: entity work.vga port map
	(
		clock25 => clock25,
		border  => portFF(2 downto 0),
		va      => va,
		vd      => vd,
		hs      => hs,
		vs      => vs,
		rgb     => rgb
	);
	Uvideo: entity work.video port map
	(
		clock14 => clock14,
		clock4  => clock,
		int     => int
	);

	clock4 <= clock;

	process(clock)
	begin
		if rising_edge(clock) then 
			if iorq = '0' and rd = '0' and a0 = '0' then do <= '0'&ear&'0'&keycols; end if;
			if iorq = '0' and wr = '0' and a0 = '0' then
				portFF  <= di(2 downto 0);
				mic     <= di(3);
				speaker <= di(4);
			end if;
		end if;
	end process;

end;
