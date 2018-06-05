library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity atari800core_helloworld_tb is
end;

architecture rtl of atari800core_helloworld_tb is

  constant CLK_A_PERIOD : time := 1 us / (1.79*32);

  signal VIDEO_VS : std_logic;
  signal VIDEO_HS : std_logic;

  signal VIDEO_G : std_logic_vector(7 downto 0);
  signal VIDEO_B : std_logic_vector(7 downto 0);
  signal VIDEO_R : std_logic_vector(7 downto 0);

  signal AUDIO_L : std_logic_vector(15 downto 0);
  signal AUDIO_R : std_logic_vector(15 downto 0);

  signal JOY1_n : std_logic_vector(4 downto 0);
  signal JOY2_n : std_logic_vector(4 downto 0);

  signal PS2_CLK : std_logic;
  signal PS2_DAT : std_logic;

  signal CLK_A : std_logic;

  signal reset_n : std_logic;

begin
	p_clk_gen_a : process
	begin
	clk_a <= '1';
	wait for CLK_A_PERIOD/2;
	clk_a <= '0';
	wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	JOY1_n <= (others=>'1');
	JOY2_n <= (others=>'1');

	PS2_CLK <= '1';
	PS2_DAT <= '1';

atari800xl : entity work.atari800core_helloworld
	GENERIC MAP
	(
		cycle_length => 32,
		internal_ram => 16384,
		internal_rom => 1
	)
	PORT MAP
	(
		CLK => clk_a,
		RESET_N => reset_n,

		VIDEO_VS => video_vs,
		VIDEO_HS => video_hs,
		VIDEO_B => video_b,
		VIDEO_G => video_g,
		VIDEO_R => video_r,

		AUDIO_L => audio_l,
		AUDIO_R => audio_r,

		JOY1_n => joy1_n,
		JOY2_n => joy2_n,

		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,

		PAL => '1'
	);

end rtl;

