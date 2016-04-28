library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_testbench is
  
end i2c_testbench;

architecture behavioral of i2c_testbench is

  signal CLK : std_logic := '0';
  signal reset : std_logic := '1';

begin

  uut : entity work.i2c_controller
    port map (
    CLK => CLK,
    reset => reset
    );

  CLK <= not CLK after 10 ns;

  reset <= '0' after 40 ns;

end behavioral;
