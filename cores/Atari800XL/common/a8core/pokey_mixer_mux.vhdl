---------------------------------------------------------------------------
-- (c) 2014 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY pokey_mixer_mux IS
PORT 
( 
	CLK : IN STD_LOGIC;

	CHANNEL_L_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	COVOX_CHANNEL_L_0 : IN STD_LOGIC_VECTOR(7 downto 0);
	COVOX_CHANNEL_L_1 : IN STD_LOGIC_VECTOR(7 downto 0);

	CHANNEL_R_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	COVOX_CHANNEL_R_0 : IN STD_LOGIC_VECTOR(7 downto 0);
	COVOX_CHANNEL_R_1 : IN STD_LOGIC_VECTOR(7 downto 0);
	
	GTIA_SOUND : IN STD_LOGIC;
	
	VOLUME_OUT_L : OUT STD_LOGIC_vector(15 downto 0);
	VOLUME_OUT_R : OUT STD_LOGIC_vector(15 downto 0)
);
END pokey_mixer_mux;

ARCHITECTURE vhdl OF pokey_mixer_mux IS
	signal LEFT_CHANNEL_NEXT : STD_LOGIC;
	signal LEFT_CHANNEL_REG : STD_LOGIC;

	signal CHANNEL_0_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_1_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_2_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_3_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal COVOX_CHANNEL_0_SEL : STD_LOGIC_VECTOR(7 downto 0);
	signal COVOX_CHANNEL_1_SEL : STD_LOGIC_VECTOR(7 downto 0);

	signal VOLUME_OUT_NEXT : STD_LOGIC_VECTOR(15 downto 0);

	signal VOLUME_OUT_L_NEXT : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_L_REG : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_R_NEXT : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_R_REG : STD_LOGIC_VECTOR(15 downto 0);
BEGIN

process(clk)
begin
	if (clk'event and clk='1') then
		LEFT_CHANNEL_REG <= LEFT_CHANNEL_NEXT;

		VOLUME_OUT_L_REG <= VOLUME_OUT_L_NEXT;
		VOLUME_OUT_R_REG <= VOLUME_OUT_R_NEXT;
	END IF;
END PROCESS;

LEFT_CHANNEL_NEXT <= not(LEFT_CHANNEL_REG);

-- mux input
PROCESS(
	CHANNEL_L_0,CHANNEL_L_1,CHANNEL_L_2,CHANNEL_L_3,COVOX_CHANNEL_L_0,COVOX_CHANNEL_L_1,
	CHANNEL_R_0,CHANNEL_R_1,CHANNEL_R_2,CHANNEL_R_3,COVOX_CHANNEL_R_0,COVOX_CHANNEL_R_1,
	LEFT_CHANNEL_REG)
BEGIN
	CHANNEL_0_SEL <= (OTHERS=>'0');
	CHANNEL_1_SEL <= (OTHERS=>'0');
	CHANNEL_2_SEL <= (OTHERS=>'0');
	CHANNEL_3_SEL <= (OTHERS=>'0');

	COVOX_CHANNEL_0_SEL <= (OTHERS=>'0');
	COVOX_CHANNEL_1_SEL <= (OTHERS=>'0');

	IF (LEFT_CHANNEL_REG = '1') THEN
		CHANNEL_0_SEL <= CHANNEL_L_0;
		CHANNEL_1_SEL <= CHANNEL_L_1;
		CHANNEL_2_SEL <= CHANNEL_L_2;
		CHANNEL_3_SEL <= CHANNEL_L_3;

		COVOX_CHANNEL_0_SEL <= COVOX_CHANNEL_L_0;
		COVOX_CHANNEL_1_SEL <= COVOX_CHANNEL_L_1;
	ELSE
		CHANNEL_0_SEL <= CHANNEL_R_0;
		CHANNEL_1_SEL <= CHANNEL_R_1;
		CHANNEL_2_SEL <= CHANNEL_R_2;
		CHANNEL_3_SEL <= CHANNEL_R_3;

		COVOX_CHANNEL_0_SEL <= COVOX_CHANNEL_R_0;
		COVOX_CHANNEL_1_SEL <= COVOX_CHANNEL_R_1;
	END IF;
END PROCESS;

-- shared mixer
shared_pokey_mixer : entity work.pokey_mixer
	port map
	(
		CLK => CLK, -- takes 2 cycles...

		CHANNEL_0 => CHANNEL_0_SEL,
		CHANNEL_1 => CHANNEL_1_SEL,
		CHANNEL_2 => CHANNEL_2_SEL,
		CHANNEL_3 => CHANNEL_3_SEL,

		COVOX_CHANNEL_0 => COVOX_CHANNEL_0_SEL,
		COVOX_CHANNEL_1 => COVOX_CHANNEL_1_SEL,

		GTIA_SOUND => GTIA_SOUND,

		VOLUME_OUT_NEXT => VOLUME_OUT_NEXT
	);

-- mux output
PROCESS(
	VOLUME_OUT_NEXT,
	VOLUME_OUT_L_REG,
	VOLUME_OUT_R_REG,
	LEFT_CHANNEL_REG)
BEGIN
	VOLUME_OUT_L_NEXT <= VOLUME_OUT_L_REG;
	VOLUME_OUT_R_NEXT <= VOLUME_OUT_R_REG;

	if (LEFT_CHANNEL_REG='1') then
		VOLUME_OUT_L_NEXT <= VOLUME_OUT_NEXT;
	else
		VOLUME_OUT_R_NEXT <= VOLUME_OUT_NEXT;
	end if;
END PROCESS;

-- output
	VOLUME_OUT_L <= VOLUME_OUT_L_REG;
	VOLUME_OUT_R <= VOLUME_OUT_R_REG;

END vhdl;

