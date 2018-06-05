library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity zpucore_tb is
end;

architecture rtl of zpucore_tb is

  constant CLK_A_PERIOD : time := 1 us / (1.79*32);

  signal CLK_A : std_logic;

  signal reset_n : std_logic;

	signal ZPU_FETCH : std_logic;
	signal ZPU_32BIT_WRITE_ENABLE : std_logic;
	signal ZPU_16BIT_WRITE_ENABLE : std_logic;
	signal ZPU_8BIT_WRITE_ENABLE : std_logic;
	signal ZPU_READ_ENABLE : std_logic;
	signal ZPU_MEMORY_DATA : std_logic_vector(31 downto 0);
	signal ZPU_MEMORY_READY : std_logic;

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA : std_logic_vector(31 downto 0);

begin
	p_clk_gen_a : process
	begin
	clk_a <= '1';
	wait for CLK_A_PERIOD/2;
	clk_a <= '0';
	wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

zpu1 : entity work.zpucore
	GENERIC MAP
	(
		platform => 42
	)
	PORT MAP
	(
		CLK => CLK_A,
		RESET_N => RESET_N,

		-- TODO - wire up a simple ram...
		ZPU_FETCH => ZPU_FETCH,
		ZPU_32BIT_WRITE_ENABLE => ZPU_32BIT_WRITE_ENABLE,
		ZPU_16BIT_WRITE_ENABLE => ZPU_16BIT_WRITE_ENABLE,
		ZPU_8BIT_WRITE_ENABLE => ZPU_8BIT_WRITE_ENABLE,
		ZPU_READ_ENABLE => ZPU_READ_ENABLE,
		ZPU_MEMORY_DATA => ZPU_MEMORY_DATA,
		ZPU_MEMORY_READY => ZPU_MEMORY_READY,

		-- TODO - wire up a simple rom
		ZPU_ADDR_ROM => ZPU_ADDR_ROM,
		ZPU_ROM_DATA => ZPU_ROM_DATA, 

		ZPU_SD_DAT0 => '1',
		ZPU_SD_CLK => open,
		ZPU_SD_CMD => open,
		ZPU_SD_DAT3 => open,

		-- SIO
		ZPU_POKEY_ENABLE => '1',
		ZPU_SIO_TXD => open,
		ZPU_SIO_RXD => '1',
		ZPU_SIO_COMMAND => '1',

		-- external control
		ZPU_IN1 => x"11345678",
		ZPU_IN2 => x"22345678",
		ZPU_IN3 => x"33345678",
		ZPU_IN4 => x"44345678",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => open,
		ZPU_OUT2 => open,
		ZPU_OUT3 => open,
		ZPU_OUT4 => open
	);

end rtl;

