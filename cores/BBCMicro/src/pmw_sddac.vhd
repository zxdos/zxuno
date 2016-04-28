library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------
--
-- Delta-Sigma DAC
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
--Implementation Digital to Analog converter
entity pwm_sddac is
  generic (
    msbi_g : integer := 7
  );
  port (
    clk_i   : in  std_logic;
    reset   : in  std_logic;
    dac_i   : in  std_logic_vector(msbi_g downto 0);
    dac_o   : out std_logic
  );
end pwm_sddac;

architecture rtl of pwm_sddac is
  signal sig_in : unsigned(msbi_g+2 downto 0) := (others => '0');

begin
  seq: process (clk_i, reset)
  begin
    if reset = '1' then
      sig_in <= to_unsigned(2**(msbi_g+1), sig_in'length);
      dac_o  <= '0';
    elsif rising_edge(clk_i) then
      sig_in <= sig_in + unsigned(sig_in(msbi_g+2) & sig_in(msbi_g+2) & dac_i);
      dac_o  <= sig_in(msbi_g+2);
    end if;
  end process seq;
end rtl;

