library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timing_testbench is
  
end timing_testbench;

architecture behavioral of timing_testbench is

  signal CLK_14M : std_logic := '0';

begin

  uut : entity work.timing_generator
    port map (
    CLK_14M => CLK_14M,
    TEXT_MODE => '1',
    PAGE2 => '0',
    HIRES => '1'
    );

  CLK_14M <= not CLK_14M after 34.920639355 ns;

end behavioral;
