-- Abstracao do audio para chip TDA1543

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Audio_TDA1543 is
	generic (
		chipSMD_g	: boolean := TRUE
	);
	port (
		clock_i		: in    std_logic;							-- Clock (21 MHz)
		audio_i		: in    std_logic_vector(7 downto 0);	-- Entrada 8 bits mono para o PSG

		i2s_bclk_o	: out   std_logic;							-- Ligar nos pinos do TOP
		i2s_ws_o		: out   std_logic;
		i2s_data_o	: out   std_logic
	);
end entity;

architecture Behavior of Audio_TDA1543 is

	signal clock_div_s		: std_logic_vector(3 downto 0)	:= "0000";

	signal pcm_outl_s			: std_logic_vector(15 downto 0);
	signal pcm_outr_s			: std_logic_vector(15 downto 0);

	signal audio_s				: std_logic_vector(15 downto 0);

begin

	audioout : entity work.tda1543
	generic map (
		chipSMD_g	=> chipSMD_g
	)
	port map (
		clock_i			=> clock_div_s(1),		-- 5 MHz
		left_audio_i	=> pcm_outl_s,
		right_audio_i	=> pcm_outr_s,
		tda_bck_o		=> i2s_bclk_o,
		tda_ws_o			=> i2s_ws_o,
		tda_data_o		=> i2s_data_o
	);

	audio_s <=  audio_i & "00000000";

	pcm_outl_s <= audio_s;
	pcm_outr_s <= audio_s;

	-- Dividir clock
	process(clock_i)
	begin
		if rising_edge(clock_i) then
			clock_div_s <= clock_div_s + '1';
		end if;
	end process;
	-- clock_div(0) = 10 MHz
	-- clock_div(1) =  5 MHz

end architecture;