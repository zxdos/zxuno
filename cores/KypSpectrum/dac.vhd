-------------------------------------------------------------------------------
--
-- Delta-Sigma DAC
--
-- $Id: dac.vhd,v 1.1 2006/05/10 20:57:06 arnim Exp $
--
-- Refer to Xilinx Application Note XAPP154.
--
-- This DAC requires an external RC low-pass filter:
--
--   o 0---XXXXX---+---0 analog audio
--          3k3    |
--                === 4n7
--                 |
--                GND
--
-------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity dac is

	generic
	(
		msbi : integer := 7
	);
	port
	(
		clock : in  std_logic;
		reset : in  std_logic;
		i     : in  std_logic_vector(msbi downto 0);
		o     : out std_logic
	);

end;

architecture rtl of dac is

	signal s : unsigned(msbi+2 downto 0) := (others => '0');

begin
	process(clock, reset)
	begin
	--	if reset = '0' then
	--		s <= to_unsigned(2**(msbi+1), s'length);
	--		o <= '0';
	--	elsif rising_edge(clock) then
	--		s <= s+unsigned(s(msbi+2)&s(msbi+2)&i);
	--		o <= s(msbi+2);
	--	end if;

		if rising_edge(clock)
		then
			if reset = '0'
			then
				s <= to_unsigned(2**(msbi+1), s'length);
				o <= '0';
			else
				s <= s+unsigned(s(msbi+2)&s(msbi+2)&i);
				o <= s(msbi+2);
			end if;
		end if;

	end process seq;
end;
