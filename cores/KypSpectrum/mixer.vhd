library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity mixer is
	port
	(
		clock   : in  std_logic;
		reset   : in  std_logic;
		ear     : in  std_logic;
		mic     : in  std_logic;
		speaker : in  std_logic;
		l       : out std_logic;
		r       : out std_logic
	);
end;

architecture behavioral of mixer is

	signal src : std_logic_vector(2 downto 0);
	signal ula : std_logic_vector(7 downto 0);
	signal mix : std_logic_vector(7 downto 0);

begin

	process(clock)
		variable tmp : std_logic_vector(3 downto 0) := (others => '0');
	begin
		if falling_edge(clock)
		then
			tmp := tmp+1;
			if tmp = 0 then mix <= ula; else mix <= (others => '0'); end if;
		end if;
	end process;

	src <= ear&mic&speaker;
	ula <= x"11" when src = "000"
	else   x"24" when src = "010"
	else   x"B8" when src = "001"
	else   x"C0" when src = "011"
	else   x"16" when src = "100"
	else   x"30" when src = "110"
	else   x"F4" when src = "101"
	else   x"FF";

	UdacL: entity work.dac port map
	(
		clock => clock,
		reset => reset,
		i     => mix,
		o     => l
	);
	UdacR: entity work.dac port map
	(
		clock => clock,
		reset => reset,
		i     => mix,
		o     => r
	);

end;
