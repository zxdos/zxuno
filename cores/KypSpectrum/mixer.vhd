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
		ay      : in  std_logic_vector(7 downto 0);
		l       : out std_logic;
		r       : out std_logic
	);
end;

architecture behavioral of mixer is

	signal tmp : std_logic_vector(2 downto 0);
	signal ula : std_logic_vector(7 downto 0);
	signal sum : std_logic_vector(9 downto 0);
	signal mix : std_logic_vector(9 downto 0);
	signal o   : std_logic;
	
begin

	tmp <= ear&mic&speaker;
	ula <= x"11" when tmp = "000"
	else   x"24" when tmp = "010"
	else   x"B8" when tmp = "001"
	else   x"C0" when tmp = "011"
	else   x"16" when tmp = "100"
	else   x"30" when tmp = "110"
	else   x"F4" when tmp = "101"
	else   x"FF";

	sum <= ("00"&ay)+("00"&ula);
	mix <= sum when rising_edge(clock);

	Udac: entity work.dac port map
	(
		clock => clock,
		reset => reset,
		i     => mix,
		o     => o
	);
	l <= o;
	r <= o;

end;
