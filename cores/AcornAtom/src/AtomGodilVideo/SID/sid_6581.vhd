-------------------------------------------------------------------------------
--
--                                 SID 6581
--
--     A fully functional SID chip implementation in VHDL
--
-------------------------------------------------------------------------------
--	to do:	- filter
--				- smaller implementation, use multiplexed channels
--
--
-- "The Filter was a classic multi-mode (state variable) VCF design. There was
-- no way to create a variable transconductance amplifier in our NMOS process,
-- so I simply used FETs as voltage-controlled resistors to control the cutoff
-- frequency. An 11-bit D/A converter generates the control voltage for the
-- FETs (it's actually a 12-bit D/A, but the LSB had no audible affect so I
-- disconnected it!)."
-- "Filter resonance was controlled by a 4-bit weighted resistor ladder. Each
-- bit would turn on one of the weighted resistors and allow a portion of the
-- output to feed back to the input. The state-variable design provided
-- simultaneous low-pass, band-pass and high-pass outputs. Analog switches
-- selected which combination of outputs were sent to the final amplifier (a
-- notch filter was created by enabling both the high and low-pass outputs
-- simultaneously)."
-- "The filter is the worst part of SID because I could not create high-gain
-- op-amps in NMOS, which were essential to a resonant filter. In addition,
-- the resistance of the FETs varied considerably with processing, so different
-- lots of SID chips had different cutoff frequency characteristics. I knew it
-- wouldn't work very well, but it was better than nothing and I didn't have
-- time to make it better."
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------

entity sid6581 is
	port (
		clk_1MHz			: in std_logic;		-- main SID clock signal
		clk32				: in std_logic;		-- main clock signal
		clk_DAC			: in std_logic;		-- DAC clock signal, must be as high as possible for the best results
		reset				: in std_logic;		-- high active signal (reset when reset = '1')
		cs					: in std_logic;		-- "chip select", when this signal is '1' this model can be accessed
		we					: in std_logic;		-- when '1' this model can be written to, otherwise access is considered as read

		addr				: in std_logic_vector(4 downto 0);	-- address lines
		di					: in std_logic_vector(7 downto 0);	-- data in (to chip)
		do					: out std_logic_vector(7 downto 0);	-- data out	(from chip)

		pot_x				: in std_logic;	-- paddle input-X
		pot_y				: in std_logic;	-- paddle input-Y
		audio_out		: out std_logic;		-- this line holds the audio-signal in PWM format
		audio_data		: out std_logic_vector(17 downto 0)
	);
end sid6581;

architecture Behavioral of sid6581 is

	signal Voice_1_Freq_lo	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Freq_hi	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Pw_lo		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Pw_hi		: std_logic_vector(3 downto 0)	:= (others => '0');
	signal Voice_1_Control	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Att_dec	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Sus_Rel	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Osc		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_1_Env		: std_logic_vector(7 downto 0)	:= (others => '0');

	signal Voice_2_Freq_lo	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Freq_hi	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Pw_lo		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Pw_hi		: std_logic_vector(3 downto 0)	:= (others => '0');
	signal Voice_2_Control	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Att_dec	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Sus_Rel	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Osc		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_2_Env		: std_logic_vector(7 downto 0)	:= (others => '0');

	signal Voice_3_Freq_lo	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_3_Freq_hi	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_3_Pw_lo		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_3_Pw_hi		: std_logic_vector(3 downto 0)	:= (others => '0');
	signal Voice_3_Control	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_3_Att_dec	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Voice_3_Sus_Rel	: std_logic_vector(7 downto 0)	:= (others => '0');

	signal Filter_Fc_lo		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Filter_Fc_hi		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Filter_Res_Filt	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Filter_Mode_Vol	: std_logic_vector(7 downto 0)	:= (others => '0');

	signal Misc_PotX			: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Misc_PotY			: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Misc_Osc3_Random	: std_logic_vector(7 downto 0)	:= (others => '0');
	signal Misc_Env3			: std_logic_vector(7 downto 0)	:= (others => '0');

	signal do_buf				: std_logic_vector(7 downto 0)	:= (others => '0');

	signal voice_1				: std_logic_vector(11 downto 0)	:= (others => '0');
	signal voice_2				: std_logic_vector(11 downto 0)	:= (others => '0');
	signal voice_3				: std_logic_vector(11 downto 0)	:= (others => '0');
	signal voice_mixed		: std_logic_vector(13 downto 0)	:= (others => '0');
	signal voice_volume		: std_logic_vector(35 downto 0)	:= (others => '0');

	signal divide_0			: std_logic_vector(31 downto 0)	:= (others => '0');
	signal voice_1_PA_MSB	: std_logic := '0';
	signal voice_2_PA_MSB	: std_logic := '0';
	signal voice_3_PA_MSB	: std_logic := '0';

	signal voice1_signed		: signed(12 downto 0);
	signal voice2_signed		: signed(12 downto 0);
	signal voice3_signed		: signed(12 downto 0);
	constant ext_in_signed	: signed(12 downto 0) := to_signed(0,13);
	signal filtered_audio	: signed(18 downto 0);
	signal tick_q1, tick_q2	: std_logic;
	signal input_valid		: std_logic;
	signal unsigned_audio	: std_logic_vector(17 downto 0);
	signal unsigned_filt		: std_logic_vector(18 downto 0);
	signal ff1					: std_logic;

-------------------------------------------------------------------------------

begin
	digital_to_analog: entity work.pwm_sddac
		port map(
			clk_i				=> clk_DAC,
			reset				=> reset,
			dac_i				=> unsigned_audio(17 downto 8),
			dac_o				=> audio_out
		);
	
	paddle_x: entity work.pwm_sdadc
		port map (
			clk				=> clk_1MHz,
			reset				=> reset,
			ADC_out 			=> Misc_PotX,
			ADC_in 			=> pot_x
		);

	paddle_y: entity work.pwm_sdadc
		port map (
			clk				=> clk_1MHz,
			reset				=> reset,
			ADC_out 			=> Misc_PotY,
			ADC_in 			=> pot_y
		);

	sid_voice_1: entity work.sid_voice
	port map(
		clk_1MHz				=> clk_1MHz,
		reset					=> reset,
		Freq_lo				=> Voice_1_Freq_lo,
		Freq_hi				=> Voice_1_Freq_hi,
		Pw_lo					=> Voice_1_Pw_lo,
		Pw_hi					=> Voice_1_Pw_hi,
		Control				=> Voice_1_Control,
		Att_dec				=> Voice_1_Att_dec,
		Sus_Rel				=> Voice_1_Sus_Rel,
		PA_MSB_in			=> voice_3_PA_MSB,
		PA_MSB_out			=> voice_1_PA_MSB,
		Osc					=> Voice_1_Osc,
		Env					=> Voice_1_Env,
		voice					=> voice_1
	);

	sid_voice_2: entity work.sid_voice
	port map(
		clk_1MHz				=> clk_1MHz,
		reset					=> reset,
		Freq_lo				=> Voice_2_Freq_lo,
		Freq_hi				=> Voice_2_Freq_hi,
		Pw_lo					=> Voice_2_Pw_lo,
		Pw_hi					=> Voice_2_Pw_hi,
		Control				=> Voice_2_Control,
		Att_dec				=> Voice_2_Att_dec,
		Sus_Rel				=> Voice_2_Sus_Rel,
		PA_MSB_in			=> voice_1_PA_MSB,
		PA_MSB_out			=> voice_2_PA_MSB,
		Osc					=> Voice_2_Osc,
		Env					=> Voice_2_Env,
		voice					=> voice_2
	);

	sid_voice_3: entity work.sid_voice
	port map(
		clk_1MHz				=> clk_1MHz,
		reset					=> reset,
		Freq_lo				=> Voice_3_Freq_lo,
		Freq_hi				=> Voice_3_Freq_hi,
		Pw_lo					=> Voice_3_Pw_lo,
		Pw_hi					=> Voice_3_Pw_hi,
		Control				=> Voice_3_Control,
		Att_dec				=> Voice_3_Att_dec,
		Sus_Rel				=> Voice_3_Sus_Rel,
		PA_MSB_in			=> voice_2_PA_MSB,
		PA_MSB_out			=> voice_3_PA_MSB,
		Osc					=> Misc_Osc3_Random,
		Env					=> Misc_Env3,
		voice					=> voice_3
	);

-------------------------------------------------------------------------------------
	do						<= do_buf;

-- SID filters

	process (clk_1MHz,reset)
	begin
		if reset='1' then
			ff1<='0';
		else
			if rising_edge(clk_1MHz) then
				ff1<=not ff1;
			end if;
		end if;
	end process;

	process(clk32)
	begin
		if rising_edge(clk32) then
			tick_q1 <= ff1;
			tick_q2 <= tick_q1;
		end if;
	end process;

	input_valid <= '1' when tick_q1 /=tick_q2 else '0';

	voice1_signed <= signed("0" & voice_1) - 2048;
	voice2_signed <= signed("0" & voice_2) - 2048;
	voice3_signed <= signed("0" & voice_3) - 2048;

	filters: entity work.sid_filters 
	port map (
		clk			=> clk32,
		rst			=> reset,
		-- SID registers.
		Fc_lo			=> Filter_Fc_lo,
		Fc_hi			=> Filter_Fc_hi,
		Res_Filt		=> Filter_Res_Filt,
		Mode_Vol		=> Filter_Mode_Vol,
		-- Voices - resampled to 13 bit
		voice1		=> voice1_signed,
		voice2		=> voice2_signed,
		voice3		=> voice3_signed,
		--
		input_valid => input_valid,
		ext_in		=> ext_in_signed,

		sound			=> filtered_audio,
		valid			=> open
	);

	unsigned_filt 	<= std_logic_vector(filtered_audio + "1000000000000000000");
	unsigned_audio	<= unsigned_filt(18 downto 1);
	audio_data		<= unsigned_audio;

-- Register decoding
	register_decoder:process(clk32)
	begin
		if rising_edge(clk32) then
			if (reset = '1') then
				--------------------------------------- Voice-1
				Voice_1_Freq_lo	<= (others => '0');
				Voice_1_Freq_hi	<= (others => '0');
				Voice_1_Pw_lo		<= (others => '0');
				Voice_1_Pw_hi		<= (others => '0');
				Voice_1_Control	<= (others => '0');
				Voice_1_Att_dec	<= (others => '0');
				Voice_1_Sus_Rel	<= (others => '0');
				--------------------------------------- Voice-2
				Voice_2_Freq_lo	<= (others => '0');
				Voice_2_Freq_hi	<= (others => '0');
				Voice_2_Pw_lo		<= (others => '0');
				Voice_2_Pw_hi		<= (others => '0');
				Voice_2_Control	<= (others => '0');
				Voice_2_Att_dec	<= (others => '0');
				Voice_2_Sus_Rel	<= (others => '0');
				--------------------------------------- Voice-3
				Voice_3_Freq_lo	<= (others => '0');
				Voice_3_Freq_hi	<= (others => '0');
				Voice_3_Pw_lo		<= (others => '0');
				Voice_3_Pw_hi		<= (others => '0');
				Voice_3_Control	<= (others => '0');
				Voice_3_Att_dec	<= (others => '0');
				Voice_3_Sus_Rel	<= (others => '0');
				--------------------------------------- Filter & volume
				Filter_Fc_lo		<= (others => '0');
				Filter_Fc_hi		<= (others => '0');
				Filter_Res_Filt	<= (others => '0');
				Filter_Mode_Vol	<= (others => '0');
			else
				Voice_1_Freq_lo	<= Voice_1_Freq_lo;
				Voice_1_Freq_hi	<= Voice_1_Freq_hi;
				Voice_1_Pw_lo		<= Voice_1_Pw_lo;
				Voice_1_Pw_hi		<= Voice_1_Pw_hi;
				Voice_1_Control	<= Voice_1_Control;
				Voice_1_Att_dec	<= Voice_1_Att_dec;
				Voice_1_Sus_Rel	<= Voice_1_Sus_Rel;
				Voice_2_Freq_lo	<= Voice_2_Freq_lo;
				Voice_2_Freq_hi	<= Voice_2_Freq_hi;
				Voice_2_Pw_lo		<= Voice_2_Pw_lo;
				Voice_2_Pw_hi		<= Voice_2_Pw_hi;
				Voice_2_Control	<= Voice_2_Control;
				Voice_2_Att_dec	<= Voice_2_Att_dec;
				Voice_2_Sus_Rel	<= Voice_2_Sus_Rel;
				Voice_3_Freq_lo	<= Voice_3_Freq_lo;
				Voice_3_Freq_hi	<= Voice_3_Freq_hi;
				Voice_3_Pw_lo		<= Voice_3_Pw_lo;
				Voice_3_Pw_hi		<= Voice_3_Pw_hi;
				Voice_3_Control	<= Voice_3_Control;
				Voice_3_Att_dec	<= Voice_3_Att_dec;
				Voice_3_Sus_Rel	<= Voice_3_Sus_Rel;
				Filter_Fc_lo		<= Filter_Fc_lo;
				Filter_Fc_hi		<= Filter_Fc_hi;
				Filter_Res_Filt	<= Filter_Res_Filt;
				Filter_Mode_Vol	<= Filter_Mode_Vol;
				do_buf 				<= (others => '0');

				if (cs='1') then
					if (we='1') then	-- Write to SID-register
								------------------------
						case addr is
							-------------------------------------- Voice-1	
							when "00000" =>	Voice_1_Freq_lo	<= di;
							when "00001" =>	Voice_1_Freq_hi	<= di;
							when "00010" =>	Voice_1_Pw_lo		<= di;
							when "00011" =>	Voice_1_Pw_hi		<= di(3 downto 0);
							when "00100" =>	Voice_1_Control	<= di;
							when "00101" =>	Voice_1_Att_dec	<= di;
							when "00110" =>	Voice_1_Sus_Rel	<= di;
							--------------------------------------- Voice-2
							when "00111" =>	Voice_2_Freq_lo	<= di;
							when "01000" =>	Voice_2_Freq_hi	<= di;
							when "01001" =>	Voice_2_Pw_lo		<= di;
							when "01010" =>	Voice_2_Pw_hi		<= di(3 downto 0);
							when "01011" =>	Voice_2_Control	<= di;
							when "01100" =>	Voice_2_Att_dec	<= di;
							when "01101" =>	Voice_2_Sus_Rel	<= di;
							--------------------------------------- Voice-3
							when "01110" =>	Voice_3_Freq_lo	<= di;
							when "01111" =>	Voice_3_Freq_hi	<= di;
							when "10000" =>	Voice_3_Pw_lo		<= di;
							when "10001" =>	Voice_3_Pw_hi		<= di(3 downto 0);
							when "10010" =>	Voice_3_Control	<= di;
							when "10011" =>	Voice_3_Att_dec	<= di;
							when "10100" =>	Voice_3_Sus_Rel	<= di;
							--------------------------------------- Filter & volume
							when "10101" =>	Filter_Fc_lo		<= di;
							when "10110" =>	Filter_Fc_hi		<= di;
							when "10111" =>	Filter_Res_Filt	<= di;
							when "11000" =>	Filter_Mode_Vol	<= di;
							--------------------------------------
							when others	=>	null;
						end case;

					else			-- Read from SID-register
							-------------------------
						--case CONV_INTEGER(addr) is
						case addr is
							-------------------------------------- Misc
							when "11001" =>	do_buf	<= Misc_PotX;
							when "11010" =>	do_buf	<= Misc_PotY;
							when "11011" =>	do_buf	<= Misc_Osc3_Random;
							when "11100" =>	do_buf	<= Misc_Env3;
							--------------------------------------
	--						when others	=>	null;
							when others	=>	do_buf <= (others => '0');
						end case;		
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;
