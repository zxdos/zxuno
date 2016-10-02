library ieee;
	use ieee.std_logic_1164.all;

entity div is
	port
	(
		clock  : in  std_logic;
		reset  : in  std_logic;
		mreq   : in  std_logic;
		iorq   : in  std_logic;
		m1     : in  std_logic;
		rd     : in  std_logic;
		wr     : in  std_logic;
		di     : in  std_logic_vector( 7 downto 0);
		a      : in  std_logic_vector(15 downto 0);
		--
		automap : out std_logic;
		conmem  : out std_logic;
		mapram  : out std_logic;
		page    : out std_logic_vector( 3 downto 0)
	);
end;

architecture behavioral of div is

	signal m1on : std_logic := '0';

begin

	process(clock)
	begin
		if rising_edge(clock)
		then
			if reset = '0'
			then
				m1on    <= '0';
				automap <= '0';
				conmem  <= '0';
				mapram  <= '0';
				page    <= (others => '0');
			else
				if iorq = '0' and wr = '0' and a(7 downto 0) = x"E3"
				then
					conmem <= di(7);
					mapram <= di(6);-- or mapram;
					page   <= di(3 downto 0);
				end if;

				if mreq = '0' and m1 = '0'
				then
					if a = x"0000" or a = x"0008" or a = x"0038" or a = x"0066" or a = x"04C6" or a = x"0562"
					then
						m1on  <= '1'; -- activate automapper after this cycle
					elsif a(15 downto 3) = x"1ff"&'1'
					then
						m1on  <= '0'; -- deactivate automapper after this cycle
					elsif a(15 downto 8) = x"3D"
					then
						automap <= '1';
						m1on    <= '1'; -- activate automapper immediately
					end if;
				end if;
				if m1 = '1' then automap <= m1on; end if;
			end if;
		end if;
	end process;
end;
