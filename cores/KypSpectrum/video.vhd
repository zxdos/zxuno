library ieee;
	use ieee.numeric_std.all;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity video is
	port
	(
		clockCPU : in  std_logic;
		int      : out std_logic
	);
end;

architecture behavioral of video is
begin

	process(clockCPU)
		variable c : std_logic_vector(17 downto 0) := (others => '0');
	begin
		if rising_edge(clockCPU) then
			if c < 69887 then c := c+1; else c := (others => '0'); end if;
			if c >= 16 and c < 48 then int <= '0'; else int <= '1'; end if;
		end if;
	end process;

end;
