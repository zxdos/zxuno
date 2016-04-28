-- This is a Delta-Sigma Digital to Analog Converter
-- ported from Verilog to VHDL: Frank Buss, 2012

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity dac is
	generic(MSBI: integer := 4);
	port (
		clk : in std_logic;
		Reset : in std_logic;
		
		-- DAC input (excess 2**MSBI)		
		DACin : in std_logic_vector(MSBI downto 0);

		-- This is the average output that feeds low pass filter
		DACout : out std_logic
	);
end;

architecture rtl of dac is

	-- Output of Delta adder
	signal DeltaAdder : std_logic_vector(MSBI+2 downto 0);
	
	-- Output of Sigma adder
	signal SigmaAdder : std_logic_vector(MSBI+2 downto 0);

	-- Latches output of Sigma adder
	signal SigmaLatch : std_logic_vector(MSBI+2 downto 0);

	-- B input of Delta adder
	signal DeltaB : std_logic_vector(MSBI+2 downto 0);

begin

	process(clk)
	begin
		if Reset = '1' then
			SigmaLatch <= "1" & std_logic_vector(to_unsigned(0, MSBI + 2));
			DACout <= '1';
		else
			if rising_edge(clk) then
				SigmaLatch <= SigmaAdder;
				DACout <= SigmaLatch(MSBI + 2);
			end if;
		end if;
	end process;

	DeltaB <= SigmaLatch(MSBI + 2) & SigmaLatch(MSBI + 2) & std_logic_vector(to_unsigned(0, MSBI + 1));
	DeltaAdder <= std_logic_vector(unsigned(DACin) + unsigned(DeltaB));
	SigmaAdder <= std_logic_vector(unsigned(DeltaAdder) + unsigned(SigmaLatch));

end;
