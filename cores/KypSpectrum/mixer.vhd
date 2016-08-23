library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity mixer is
	port
	(
		clock   : in  std_logic;
		speaker : in  std_logic;
		ear     : in  std_logic;
		mic     : in  std_logic;
		l       : out std_logic;
		r       : out std_logic
	);
end;

architecture behavioral of mixer is

	signal mix : std_logic;

begin

	l <= mix;
	r <= mix;

	process(clock)
		variable count : std_logic_vector(4 downto 0) := (others => '0');
	begin
		if rising_edge(clock) then
			count := count+1;
			case count is
				when "00000" => mix <= speaker;
				when "01000" => mix <= ear;
				when "10000" => mix <= speaker;
				when "11000" => mix <= mic;
				when others  => mix <= '0';
			end case;
		end if;
	end process;
end;
