library ieee;
	use ieee.std_logic_1164.all;

entity ula is
	port
	(
		clockVGA : in  std_logic;
		clockCPU : in  std_logic;
		keys     : in  std_logic_vector( 4 downto 0);
		iorq     : in  std_logic;
		int      : out std_logic;
		rd       : in  std_logic;
		wr       : in  std_logic;
		a0       : in  std_logic;
		di       : in  std_logic_vector( 7 downto 0);
		do       : out std_logic_vector( 7 downto 0);
		ear      : in  std_logic;
		mic      : out std_logic;
		speaker  : out std_logic;
		va       : out std_logic_vector(12 downto 0);
		vd       : in  std_logic_vector( 7 downto 0);
		hs       : out std_logic;
		vs       : out std_logic;
		rgb      : out std_logic_vector(11 downto 0)
	);
end;

architecture behavioral of ula is

	signal portFF : std_logic_vector(2 downto 0);

	signal rows   : std_logic_vector(7 downto 0);
	signal cols   : std_logic_vector(4 downto 0);

begin

	Uvga: entity work.vga port map
	(
		clockVGA => clockVGA,
		border   => portFF(2 downto 0),
		va       => va,
		vd       => vd,
		hs       => hs,
		vs       => vs,
		rgb      => rgb
	);
	Uvideo: entity work.video port map
	(
		clockCPU => clockCPU,
		int      => int
	);

	process(clockCPU)
	begin
		if rising_edge(clockCPU) then 
			if iorq = '0' and rd = '0' and a0 = '0' then do <= '0'&ear&'0'&keys; end if;
			if iorq = '0' and wr = '0' and a0 = '0' then
				portFF  <= di(2 downto 0);
				mic     <= di(3);
				speaker <= di(4);
			end if;
		end if;
	end process;

end;
