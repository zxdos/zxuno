---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY pokey_mixer IS
PORT 
( 
	CLK : IN STD_LOGIC;

	CHANNEL_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	
	GTIA_SOUND : IN STD_LOGIC;

	COVOX_CHANNEL_0 : IN STD_LOGIC_VECTOR(7 downto 0);
	COVOX_CHANNEL_1 : IN STD_LOGIC_VECTOR(7 downto 0);
	
	VOLUME_OUT_NEXT : OUT STD_LOGIC_vector(15 downto 0)
);
END pokey_mixer;

ARCHITECTURE vhdl OF pokey_mixer IS
	signal volume_sum_next : std_logic_vector(9 downto 0);
	signal volume_sum_reg : std_logic_vector(9 downto 0);
	signal volume_next : std_logic_vector(15 downto 0);

	signal y1 : signed(15 downto 0);
	signal y1_reg : signed(15 downto 0);
	signal y2 : signed(15 downto 0);
	signal ych : signed(15 downto 0);
	signal yadj_next : signed(31 downto 0);
	signal yadj_reg : signed(31 downto 0);

	signal b_in : signed(15 downto 0);
BEGIN
process(clk)
begin
	if (clk'event and clk='1') then
		VOLUME_SUM_REG <= VOLUME_SUM_NEXT;
		YADJ_REG <= YADJ_NEXT;
		Y1_REG <= Y1;
	END IF;
END PROCESS;

	-- next state
	process (channel_0,channel_1,channel_2,channel_3,covox_CHANNEL_0,covox_channel_1,gtia_sound)
		variable channel0_en_long : unsigned(10 downto 0);
		variable channel1_en_long : unsigned(10 downto 0);
		variable channel2_en_long : unsigned(10 downto 0);
		variable channel3_en_long : unsigned(10 downto 0);
		variable gtia_sound_long : unsigned(10 downto 0);
		variable covox_0_long : unsigned(10 downto 0);
		variable covox_1_long : unsigned(10 downto 0);
		
		variable volume_int_sum : unsigned(10 downto 0);
	begin
		channel0_en_long := (others=>'0');
		channel1_en_long := (others=>'0');
		channel2_en_long := (others=>'0');
		channel3_en_long := (others=>'0');
		gtia_sound_long := (others=>'0');
		covox_0_long := (others=>'0');
		covox_1_long := (others=>'0');

		channel0_en_long(7 downto 4) := unsigned(channel_0);
		channel1_en_long(7 downto 4) := unsigned(channel_1);
		channel2_en_long(7 downto 4) := unsigned(channel_2);
		channel3_en_long(7 downto 4) := unsigned(channel_3);
		gtia_sound_long(7 downto 4) := gtia_sound&gtia_sound&gtia_sound&gtia_sound;
		covox_0_long(7 downto 0) := unsigned(covox_channel_0);
		covox_1_long(7 downto 0) := unsigned(covox_channel_1);

		volume_int_sum := ((channel0_en_long + channel1_en_long) + (channel2_en_long + channel3_en_long)) + (gtia_sound_long + (covox_0_long + covox_1_long));

		volume_sum_next(9 downto 0) <= std_logic_vector(volume_int_sum(9 downto 0)) or volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10)&volume_int_sum(10);
		
	end process;
	
 	process (volume_sum_reg, y1, y2, y1_reg, yadj_reg)
		type LOOKUP_TYPE is array (0 to 32) of signed(15 downto 0);
		variable lookup : LOOKUP_TYPE;
	begin
		-- replace with piecewise interp. Takes a mul unit but saves lookup space.

		lookup := (x"86E8" ,x"9E40" ,x"B3E3" ,x"C7E3" ,x"DA52" ,x"EB42" ,x"FAC5" ,x"08ED" ,x"15CB" ,x"2172" ,x"2BF4" ,x"3562" ,x"3DCE" ,x"454B" ,x"4BEA" ,x"51BD" ,x"56D6" ,x"5B47" ,x"5F22" ,x"6278" ,x"655C" ,x"67E0" ,x"6A15" ,x"6C0D" ,x"6DDB" ,x"6F90" ,x"713E" ,x"72F7" ,x"74CD" ,x"76D2" ,x"7918" ,x"7BB0" ,x"7EAD");

		y1 <= lookup(to_integer(unsigned(volume_sum_reg(9 downto 5))));
		y2 <= lookup(to_integer(unsigned(volume_sum_reg(9 downto 5)))+1);

		ych <= y2-y1;

		volume_next <= std_logic_vector(yadj_reg(20 downto 5) + y1_reg);

		--case volume_sum(9 downto 0) is 
		--end case;
        end process;

	B_in <= signed("00000000000"&volume_sum_reg(4 downto 0));
	linterp_mult : entity work.mult_infer
	PORT MAP( A => signed(ych),
		  B => b_in,
		  RESULT => yadj_next);
	
	-- output
	volume_out_next <= volume_next;
		
END vhdl;
