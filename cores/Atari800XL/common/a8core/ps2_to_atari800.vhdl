---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- (ILoveSpeccy) Added PS2_KEYS Output
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY ps2_to_atari800 IS
GENERIC
(
	ps2_enable : integer := 1;
	direct_enable : integer := 0
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	PS2_CLK : IN STD_LOGIC := '1';
	PS2_DAT : IN STD_LOGIC := '1';
	INPUT : IN STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
	
	KEYBOARD_SCAN : IN STD_LOGIC_VECTOR(5 downto 0);
	KEYBOARD_RESPONSE : OUT STD_LOGIC_VECTOR(1 downto 0);

	CONSOL_START : OUT STD_LOGIC;
	CONSOL_SELECT : OUT STD_LOGIC;
	CONSOL_OPTION : OUT STD_LOGIC;
   
	FKEYS : OUT STD_LOGIC_VECTOR(11 downto 0);

	FREEZER_ACTIVATE : OUT STD_LOGIC;
   
	PS2_KEYS : OUT STD_LOGIC_VECTOR(511 downto 0);
	PS2_KEYS_NEXT_OUT : OUT STD_LOGIC_VECTOR(511 downto 0);
	MRESET : out std_logic
);
END ps2_to_atari800;

ARCHITECTURE vhdl OF ps2_to_atari800 IS
	signal ps2_keys_next : std_logic_vector(511 downto 0);
	signal ps2_keys_reg : std_logic_vector(511 downto 0);

	signal ps2_key_event : std_logic;
	signal ps2_key_value : std_logic_vector(7 downto 0);
	signal ps2_key_extended : std_logic;
	signal ps2_key_up : std_logic;

	signal direct_key_event : std_logic;
	signal direct_key_value : std_logic_vector(7 downto 0);
	signal direct_key_extended : std_logic;
	signal direct_key_up : std_logic;

	signal key_event : std_logic;
	signal key_value : std_logic_vector(7 downto 0);
	signal key_extended : std_logic;
	signal key_up : std_logic;

	signal CONSOL_START_INT : std_logic;
	signal CONSOL_SELECT_INT : std_logic;
	signal CONSOL_OPTION_INT : std_logic;

	signal FKEYS_INT : std_logic_vector(11 downto 0);

	signal FREEZER_ACTIVATE_INT : std_logic;

	signal atari_keyboard : std_logic_vector(63 downto 0);
	SIGNAL	SHIFT_PRESSED :  STD_LOGIC;
	SIGNAL	BREAK_PRESSED :  STD_LOGIC;
	SIGNAL	CONTROL_PRESSED :  STD_LOGIC;
BEGIN
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			ps2_keys_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			ps2_keys_reg <= ps2_keys_next;
		end if;
	end process;

gen_ps2_on : if ps2_enable=1 generate
	keyboard1: entity work.ps2_keyboard
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		PS2_CLK => PS2_CLK,
		PS2_DAT => PS2_DAT,
		
		KEY_EVENT => PS2_KEY_EVENT,
		KEY_VALUE => PS2_KEY_VALUE,
		KEY_EXTENDED => PS2_KEY_EXTENDED,
		KEY_UP => PS2_KEY_UP
--		KEY_EVENT : OUT STD_LOGIC; -- high for 1 cycle on new key pressed(or repeated)/released
--		KEY_VALUE : OUT STD_LOGIC_VECTOR(7 downto 0); -- valid on event, raw scan code
--		KEY_EXTENDED : OUT STD_LOGIC;           -- valid on event, if scan code extended
--		KEY_UP : OUT STD_LOGIC                 -- value on event, if key released
	);
end generate;

gen_ps2_off : if ps2_enable=0 generate
	PS2_KEY_EVENT <= '0';
	PS2_KEY_VALUE <= (others=>'0');
	PS2_KEY_EXTENDED <= '0';
	PS2_KEY_UP <= '0';
end generate;

gen_direct_on : if direct_enable=1 generate
	direct_key_value <= input(7 downto 0);
	direct_key_extended <= input(12);
	direct_key_up <= not(input(16));
	direct_key_event <= '1';
end generate;

gen_direct_off : if direct_enable=0 generate
	DIRECT_KEY_EVENT <= '0';
	DIRECT_KEY_VALUE <= (others=>'0');
	DIRECT_KEY_EXTENDED <= '0';
	DIRECT_KEY_UP <= '0';
end generate;

	KEY_EVENT <= DIRECT_KEY_EVENT or PS2_KEY_EVENT;
	KEY_VALUE <= PS2_KEY_VALUE when PS2_KEY_EVENT='1' else DIRECT_KEY_VALUE;
	KEY_EXTENDED <= PS2_KEY_EXTENDED when PS2_KEY_EVENT='1' else DIRECT_KEY_EXTENDED;
	KEY_UP <= PS2_KEY_UP when PS2_KEY_EVENT='1' else DIRECT_KEY_UP;

	process(KEY_EVENT, KEY_VALUE, KEY_EXTENDED, KEY_UP, ps2_keys_reg)
	begin
		ps2_keys_next <= ps2_keys_reg;

		if (key_event = '1') then
			ps2_keys_next(to_integer(unsigned(KEY_EXTENDED&KEY_VALUE))) <= NOT(KEY_UP);
		end if;
	end process;

	-- map to atari key code
	process(ps2_keys_reg)
	begin
		atari_keyboard <= (others=>'0');

		shift_pressed <= '0';
		control_pressed <= '0';
		break_pressed <= '0';
		consol_start_int <= '0';
		consol_select_int <= '0';
		consol_option_int <= '0';

		atari_keyboard(63)<=ps2_keys_reg(16#1C#);
		atari_keyboard(21)<=ps2_keys_reg(16#32#);
		atari_keyboard(18)<=ps2_keys_reg(16#21#);
		atari_keyboard(58)<=ps2_keys_reg(16#23#);
		atari_keyboard(42)<=ps2_keys_reg(16#24#);
		atari_keyboard(56)<=ps2_keys_reg(16#2B#);
		atari_keyboard(61)<=ps2_keys_reg(16#34#);
		atari_keyboard(57)<=ps2_keys_reg(16#33#);
		atari_keyboard(13)<=ps2_keys_reg(16#43#);
		atari_keyboard(1)<=ps2_keys_reg(16#3B#);
		atari_keyboard(5)<=ps2_keys_reg(16#42#);
		atari_keyboard(0)<=ps2_keys_reg(16#4B#);
		atari_keyboard(37)<=ps2_keys_reg(16#3A#);
		atari_keyboard(35)<=ps2_keys_reg(16#31#);
		atari_keyboard(8)<=ps2_keys_reg(16#44#);
		atari_keyboard(10)<=ps2_keys_reg(16#4D#);
		atari_keyboard(47)<=ps2_keys_reg(16#15#);
		atari_keyboard(40)<=ps2_keys_reg(16#2D#);
		atari_keyboard(62)<=ps2_keys_reg(16#1B#);
		atari_keyboard(45)<=ps2_keys_reg(16#2C#);
		atari_keyboard(11)<=ps2_keys_reg(16#3C#);
		atari_keyboard(16)<=ps2_keys_reg(16#2A#);
		atari_keyboard(46)<=ps2_keys_reg(16#1D#);
		atari_keyboard(22)<=ps2_keys_reg(16#22#);
		atari_keyboard(43)<=ps2_keys_reg(16#35#);
		atari_keyboard(23)<=ps2_keys_reg(16#1A#);
		atari_keyboard(50)<=ps2_keys_reg(16#45#);
		atari_keyboard(31)<=ps2_keys_reg(16#16#);
		atari_keyboard(30)<=ps2_keys_reg(16#1E#);
		atari_keyboard(26)<=ps2_keys_reg(16#26#);
		atari_keyboard(24)<=ps2_keys_reg(16#25#);
		atari_keyboard(29)<=ps2_keys_reg(16#2E#);
		atari_keyboard(27)<=ps2_keys_reg(16#36#);
		atari_keyboard(51)<=ps2_keys_reg(16#3D#);
		atari_keyboard(53)<=ps2_keys_reg(16#3E#);
		atari_keyboard(48)<=ps2_keys_reg(16#46#);
		--atari_keyboard(17)<=ps2_keys_reg(16#ec#);
		--atari_keyboard(17)<=ps2_keys_reg(16#16c#);
		atari_keyboard(17)<=ps2_keys_reg(16#16c#) or ps2_keys_reg(16#03#);
		atari_keyboard(52)<=ps2_keys_reg(16#66#);
		atari_keyboard(28)<=ps2_keys_reg(16#76#);
		--atari_keyboard(39)<=ps2_keys_reg(16#91#);
		atari_keyboard(39)<=ps2_keys_reg(16#111#);
		atari_keyboard(60)<=ps2_keys_reg(16#58#);
		atari_keyboard(44)<=ps2_keys_reg(16#0D#);
		atari_keyboard(12)<=ps2_keys_reg(16#5A#);
		atari_keyboard(33)<=ps2_keys_reg(16#29#);
		atari_keyboard(54)<=ps2_keys_reg(16#4E#);
		atari_keyboard(55)<=ps2_keys_reg(16#55#);
		atari_keyboard(15)<=ps2_keys_reg(16#5B#);
		atari_keyboard(14)<=ps2_keys_reg(16#54#);
		atari_keyboard(6)<=ps2_keys_reg(16#52#);
		atari_keyboard(7)<=ps2_keys_reg(16#5D#);
		atari_keyboard(38)<=ps2_keys_reg(16#4A#);
		atari_keyboard(2)<=ps2_keys_reg(16#4C#);
		atari_keyboard(32)<=ps2_keys_reg(16#41#);
		atari_keyboard(34)<=ps2_keys_reg(16#49#);

		atari_keyboard(3)<=ps2_keys_reg(16#05#);
		atari_keyboard(4)<=ps2_keys_reg(16#06#);
		atari_keyboard(19)<=ps2_keys_reg(16#04#);
		atari_keyboard(20)<=ps2_keys_reg(16#0c#);

		consol_start_int<=ps2_keys_reg(16#0B#);
		consol_select_int<=ps2_keys_reg(16#83#);
		consol_option_int<=ps2_keys_reg(16#0a#);
		shift_pressed<=ps2_keys_reg(16#12#) or ps2_keys_reg(16#59#);
		--control_pressed<=ps2_keys_reg(16#14#) or ps2_keys_reg(16#94#);
		control_pressed<=ps2_keys_reg(16#14#) or ps2_keys_reg(16#114#);
		break_pressed<=ps2_keys_reg(16#77#);

		fkeys_int(0)<=ps2_keys_reg(16#05#);
		fkeys_int(1)<=ps2_keys_reg(16#06#);
		fkeys_int(2)<=ps2_keys_reg(16#04#);
		fkeys_int(3)<=ps2_keys_reg(16#0C#);
		fkeys_int(4)<=ps2_keys_reg(16#03#);
		fkeys_int(5)<=ps2_keys_reg(16#0B#);
		fkeys_int(6)<=ps2_keys_reg(16#83#);
		fkeys_int(7)<=ps2_keys_reg(16#0a#);
		fkeys_int(8)<=ps2_keys_reg(16#01#);
		fkeys_int(9)<=ps2_keys_reg(16#09#);
		fkeys_int(10)<=ps2_keys_reg(16#78#);
		fkeys_int(11)<=ps2_keys_reg(16#07#);

		-- use scroll lock or delete to activate freezer (same key on my keyboard + scroll lock does not seem to work on mist!)
--		freezer_activate_int <= ps2_keys_reg(16#7e#) or ps2_keys_reg(16#171#);
		
		--master reset
		--MRESET <= ps2_keys_reg(16#14#) and ps2_keys_reg(16#11#) and ps2_keys_reg(16#66#);
		MRESET <= control_pressed and (ps2_keys_reg(16#11#) or ps2_keys_reg(16#111#)) and ps2_keys_reg(16#66#);
	end process;

	-- provide results as if we were a grid to pokey...
	process(keyboard_scan, atari_keyboard, control_pressed, shift_pressed, break_pressed)
		begin	
			keyboard_response <= (others=>'1');		
			
			if (atari_keyboard(to_integer(unsigned(not(keyboard_scan)))) = '1') then
				keyboard_response(0) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="00" and break_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="10" and shift_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;

			if (keyboard_scan(5 downto 4)="11" and control_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
	end process;		 

	-- outputs
	CONSOL_START <= CONSOL_START_INT;
	CONSOL_SELECT <= CONSOL_SELECT_INT;
	CONSOL_OPTION <= CONSOL_OPTION_INT;

	FKEYS <= FKEYS_INT;
	FREEZER_ACTIVATE <= FREEZER_ACTIVATE_INT;

	PS2_KEYS <= ps2_keys_reg;
	PS2_KEYS_NEXT_OUT <= ps2_keys_next;
END vhdl;

