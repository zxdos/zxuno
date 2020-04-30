--
-- Abstracao do audio para Delta-Sigma DAC
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Audio_DAC is
	port (
		clock_i		: in    std_logic;
		reset_i		: in    std_logic;
		audio_i		: in    std_logic_vector(7 downto 0);
		dac_out_o	: out   std_logic
	);
end entity;

architecture Behavior of Audio_DAC is

	signal pcm_out_s			: std_logic_vector(7 downto 0);

begin

	audioo : entity work.dac
	generic map (
		msbi_g	=> 7
	)
	port map (
		clk_i		=> clock_i,
		res_i		=> reset_i,
		dac_i		=> pcm_out_s,
		dac_o		=> dac_out_o
	);


	spk_s <= spk_volume when spk = '1' else (others => '0');
	mic_s <= mic_volume when mic = '1' else (others => '0');
	ear_s <= ear_volume when ear = '1' else (others => '0');
	psg_s <=  psg;

	pcm_out <= std_logic_vector(unsigned(spk_s) + unsigned(mic_s) + unsigned(ear_s) + unsigned(psg_s));

end architecture;