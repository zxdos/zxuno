	others => '0'
);

begin

process (clock)
begin
	if (clock'event and clock = '1') then
		q <= rom(to_integer(unsigned(address(addrbits-1 downto 0))));
	end if;
end process;

end arch;

