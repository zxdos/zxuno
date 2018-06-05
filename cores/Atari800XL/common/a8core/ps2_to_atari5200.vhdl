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


ENTITY ps2_to_atari5200 IS
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

	FIRE2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CONTROLLER_SELECT : IN STD_LOGIC_VECTOR(1 downto 0);

	FKEYS : OUT STD_LOGIC_VECTOR(11 downto 0);

	FREEZER_ACTIVATE : OUT STD_LOGIC;
   
	PS2_KEYS : OUT STD_LOGIC_VECTOR(511 downto 0);
	PS2_KEYS_NEXT_OUT : OUT STD_LOGIC_VECTOR(511 downto 0)
);
END ps2_to_atari5200;

ARCHITECTURE vhdl OF ps2_to_atari5200 IS
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

	signal FKEYS_INT : std_logic_vector(11 downto 0);

	signal FREEZER_ACTIVATE_INT : std_logic;

	signal atari_keyboard : std_logic_vector(15 downto 0);

	signal fire_pressed_sel : std_logic;
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
	process(ps2_keys_reg, fire2, controller_select)
	begin
		atari_keyboard <= (others=>'0');

		fire_pressed_sel <= '0';

		case controller_select is
		when "00" =>
			-- todo change order to match keycode! check with petes test
			atari_keyboard(12)<=ps2_keys_reg(16#05#) and not(ps2_keys_reg(16#14#)); --f1
			atari_keyboard(8)<=ps2_keys_reg(16#06#) and not(ps2_keys_reg(16#14#)); --f2
			atari_keyboard(4)<=ps2_keys_reg(16#04#) and not(ps2_keys_reg(16#14#)); --f3
			atari_keyboard(15)<=ps2_keys_reg(16#16#) and not(ps2_keys_reg(16#14#)); --1
			atari_keyboard(14)<=ps2_keys_reg(16#1E#) and not(ps2_keys_reg(16#14#)); --2
			atari_keyboard(13)<=ps2_keys_reg(16#26#) and not(ps2_keys_reg(16#14#)); --3
			atari_keyboard(11)<=ps2_keys_reg(16#15#) and not(ps2_keys_reg(16#14#)); --q
			atari_keyboard(10)<=ps2_keys_reg(16#1D#) and not(ps2_keys_reg(16#14#)); --w
			atari_keyboard(9)<=ps2_keys_reg(16#24#) and not(ps2_keys_reg(16#14#)); --e
			atari_keyboard(7)<=ps2_keys_reg(16#1c#) and not(ps2_keys_reg(16#14#));   --a
			atari_keyboard(6)<=ps2_keys_reg(16#1b#) and not(ps2_keys_reg(16#14#));  --s
			atari_keyboard(5)<=ps2_keys_reg(16#23#) and not(ps2_keys_reg(16#14#));  --d
			atari_keyboard(3)<=ps2_keys_reg(16#1a#) and not(ps2_keys_reg(16#14#));  --z 
			atari_keyboard(2)<=ps2_keys_reg(16#22#) and not(ps2_keys_reg(16#14#));  --x
			atari_keyboard(1)<=ps2_keys_reg(16#21#) and not(ps2_keys_reg(16#14#));  --c
			fire_pressed_sel <= fire2(0);
		when "01" =>
			atari_keyboard(12)<=ps2_keys_reg(16#0c#) and not(ps2_keys_reg(16#14#)); -- f4
			atari_keyboard(8)<=ps2_keys_reg(16#03#) and not(ps2_keys_reg(16#14#));  -- f5
			atari_keyboard(4)<=ps2_keys_reg(16#0b#) and not(ps2_keys_reg(16#14#));  -- f6
			atari_keyboard(15)<=ps2_keys_reg(16#25#) and not(ps2_keys_reg(16#14#)); -- 4
			atari_keyboard(14)<=ps2_keys_reg(16#2e#) and not(ps2_keys_reg(16#14#)); -- 5
			atari_keyboard(13)<=ps2_keys_reg(16#36#) and not(ps2_keys_reg(16#14#)); -- 6
			atari_keyboard(11)<=ps2_keys_reg(16#2d#) and not(ps2_keys_reg(16#14#)); -- r
			atari_keyboard(10)<=ps2_keys_reg(16#2c#) and not(ps2_keys_reg(16#14#)); -- t 
			atari_keyboard(9)<=ps2_keys_reg(16#35#) and not(ps2_keys_reg(16#14#));  -- y
			atari_keyboard(7)<=ps2_keys_reg(16#2b#) and not(ps2_keys_reg(16#14#));  -- f
			atari_keyboard(6)<=ps2_keys_reg(16#34#) and not(ps2_keys_reg(16#14#));  -- g
			atari_keyboard(5)<=ps2_keys_reg(16#33#) and not(ps2_keys_reg(16#14#));  -- h
			atari_keyboard(3)<=ps2_keys_reg(16#2a#) and not(ps2_keys_reg(16#14#));  -- v
			atari_keyboard(2)<=ps2_keys_reg(16#32#) and not(ps2_keys_reg(16#14#));  -- b
			atari_keyboard(1)<=ps2_keys_reg(16#31#) and not(ps2_keys_reg(16#14#));  -- n
			fire_pressed_sel <= fire2(1);
		when "10" =>
			atari_keyboard(12)<=ps2_keys_reg(16#05#) and ps2_keys_reg(16#14#); --f1
			atari_keyboard(8)<=ps2_keys_reg(16#06#) and ps2_keys_reg(16#14#); --f2
			atari_keyboard(4)<=ps2_keys_reg(16#04#) and ps2_keys_reg(16#14#); --f3
			atari_keyboard(15)<=ps2_keys_reg(16#16#) and ps2_keys_reg(16#14#); --1
			atari_keyboard(14)<=ps2_keys_reg(16#1E#) and ps2_keys_reg(16#14#); --2
			atari_keyboard(13)<=ps2_keys_reg(16#26#) and ps2_keys_reg(16#14#); --3
			atari_keyboard(11)<=ps2_keys_reg(16#15#) and ps2_keys_reg(16#14#); --q
			atari_keyboard(10)<=ps2_keys_reg(16#1D#) and ps2_keys_reg(16#14#); --w
			atari_keyboard(9)<=ps2_keys_reg(16#24#) and ps2_keys_reg(16#14#); --e
			atari_keyboard(7)<=ps2_keys_reg(16#1c#) and ps2_keys_reg(16#14#);   --a
			atari_keyboard(6)<=ps2_keys_reg(16#1b#) and ps2_keys_reg(16#14#);  --s
			atari_keyboard(5)<=ps2_keys_reg(16#23#) and ps2_keys_reg(16#14#);  --d
			atari_keyboard(3)<=ps2_keys_reg(16#1a#) and ps2_keys_reg(16#14#);  --z 
			atari_keyboard(2)<=ps2_keys_reg(16#22#) and ps2_keys_reg(16#14#);  --x
			atari_keyboard(1)<=ps2_keys_reg(16#21#) and ps2_keys_reg(16#14#);  --c
			fire_pressed_sel <= fire2(2);
		when "11" =>
			atari_keyboard(12)<=ps2_keys_reg(16#0c#) and ps2_keys_reg(16#14#); -- f4
			atari_keyboard(8)<=ps2_keys_reg(16#03#) and ps2_keys_reg(16#14#);  -- f5
			atari_keyboard(4)<=ps2_keys_reg(16#0b#) and ps2_keys_reg(16#14#);  -- f6
			atari_keyboard(15)<=ps2_keys_reg(16#25#) and ps2_keys_reg(16#14#); -- 4
			atari_keyboard(14)<=ps2_keys_reg(16#2e#) and ps2_keys_reg(16#14#); -- 5
			atari_keyboard(13)<=ps2_keys_reg(16#36#) and ps2_keys_reg(16#14#); -- 6
			atari_keyboard(11)<=ps2_keys_reg(16#2d#) and ps2_keys_reg(16#14#); -- r
			atari_keyboard(10)<=ps2_keys_reg(16#2c#) and ps2_keys_reg(16#14#); -- t 
			atari_keyboard(9)<=ps2_keys_reg(16#35#) and ps2_keys_reg(16#14#);  -- y
			atari_keyboard(7)<=ps2_keys_reg(16#2b#) and ps2_keys_reg(16#14#);  -- f
			atari_keyboard(6)<=ps2_keys_reg(16#34#) and ps2_keys_reg(16#14#);  -- g
			atari_keyboard(5)<=ps2_keys_reg(16#33#) and ps2_keys_reg(16#14#);  -- h
			atari_keyboard(3)<=ps2_keys_reg(16#2a#) and ps2_keys_reg(16#14#);  -- v
			atari_keyboard(2)<=ps2_keys_reg(16#32#) and ps2_keys_reg(16#14#);  -- b
			atari_keyboard(1)<=ps2_keys_reg(16#31#) and ps2_keys_reg(16#14#);  -- n
			fire_pressed_sel <= fire2(3);
		when others =>
		end case;

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
		freezer_activate_int <= ps2_keys_reg(16#7e#) or ps2_keys_reg(16#171#);
	end process;

	-- provide results as if we were a grid to pokey...
	process(keyboard_scan, atari_keyboard, fire_pressed_sel)
		begin	
			keyboard_response <= (others=>'1');		
			
			if (atari_keyboard(to_integer(unsigned(not(keyboard_scan(4 downto 1))))) = '1') then
				keyboard_response(0) <= '0';
			end if;
			
			keyboard_response(1) <= not(fire_pressed_sel);
	end process;		 

	-- outputs
	FKEYS <= FKEYS_INT;
	FREEZER_ACTIVATE <= FREEZER_ACTIVATE_INT;

	PS2_KEYS <= ps2_keys_reg;
	PS2_KEYS_NEXT_OUT <= ps2_keys_next;
END vhdl;

