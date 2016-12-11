library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity mixer is
	port
	(
		clock   : in  std_logic;
		reset   : in  std_logic;
		speaker : in  std_logic;
		ear     : in  std_logic;
		mic     : in  std_logic;
		a       : in  std_logic_vector(7 downto 0);
		b       : in  std_logic_vector(7 downto 0);
		c       : in  std_logic_vector(7 downto 0);
		l       : out std_logic;
		r       : out std_logic
	);
end;

architecture behavioral of mixer is

	signal src  : std_logic_vector(2 downto 0);
	signal ula  : std_logic_vector(7 downto 0);
	signal mixl : std_logic_vector(7 downto 0);
	signal mixr : std_logic_vector(7 downto 0);

begin

	src <= ear&mic&speaker;
	ula <= x"11" when src = "000"
	else   x"24" when src = "010"
	else   x"B8" when src = "001"
	else   x"C0" when src = "011"
	else   x"16" when src = "100"
	else   x"30" when src = "110"
	else   x"F4" when src = "101"
	else   x"FF";

	process(clock)
		variable tmp : std_logic_vector(1 downto 0) := (others => '0');
	begin
		if falling_edge(clock)
		then
			case tmp is
				when "00" => mixl <= a; mixr <= b;
				when "01" => mixl <= c; mixr <= c;
				when "10" => mixl <= a; mixr <= b;
				when "11" => mixl <= ula; mixr <= ula;
				when others =>
			end case;

			tmp := tmp+1;
		end if;
	end process;

	UdacL: entity work.dac port map
	(
		clock => clock,
		reset => reset,
		i     => mixl,
		o     => l
	);
	UdacR: entity work.dac port map
	(
		clock => clock,
		reset => reset,
		i     => mixr,
		o     => r
	);

end;
