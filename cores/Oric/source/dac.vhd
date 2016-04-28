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
--   dac_o 0---XXXXX---+---0 analog audio
--              3k3    |
--                    === 4n7
--                     |
--                    GND
--
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity dac is
	generic (
		msbi_g : integer := 7
	);
	port (
		clk_i   : in  std_logic;
		resetn  : in  std_logic;
		dac_i   : in  std_logic_vector(msbi_g downto 0);
		dac_o   : out std_logic
	);
end dac;

architecture rtl of dac is
	signal sig_in : unsigned(msbi_g+2 downto 0) := (others => '0');

begin
	seq: process
	begin
		wait until rising_edge(clk_i);
		if resetn = '0' then
			sig_in <= to_unsigned(2**(msbi_g+1), sig_in'length);
			dac_o  <= '0';
		else
			sig_in <= sig_in + unsigned(sig_in(msbi_g+2) & sig_in(msbi_g+2) & dac_i);
			dac_o  <= sig_in(msbi_g+2);
		end if;
	end process seq;
end rtl;

