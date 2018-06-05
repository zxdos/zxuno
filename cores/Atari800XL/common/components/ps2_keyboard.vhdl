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


--	KEY_OUT : OUT STD_LOGIC_vector(7 downto 0); -- Pokey scan code
	
--	KEY_PRESSED : OUT STD_LOGIC; -- high for 1 cycle on new key pressed
--	SHIFT_PRESSED : OUT STD_LOGIC; -- high while shift held
--	CONTROL_PRESSED : OUT STD_LOGIC; -- high while control held
--	BREAK_PRESSED : OUT STD_LOGIC -- high for 1 cycle on break key pressed (pause - no need for modifiers)

ENTITY ps2_keyboard IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	PS2_CLK : IN STD_LOGIC;
	PS2_DAT : IN STD_LOGIC;
	
	KEY_EVENT : OUT STD_LOGIC; -- high for 1 cycle on new key pressed(or repeated)/released
	KEY_VALUE : OUT STD_LOGIC_VECTOR(7 downto 0); -- valid on event, raw scan code
	KEY_EXTENDED : OUT STD_LOGIC;           -- valid on event, if scan code extended
	KEY_UP : OUT STD_LOGIC                 -- value on event, if key released
);
END ps2_keyboard;

ARCHITECTURE vhdl OF ps2_keyboard IS
	component enable_divider IS
	generic(COUNT : natural := 1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;

		ENABLE_IN : IN STD_LOGIC;
		
		ENABLE_OUT : OUT STD_LOGIC
	);
	END component;
	
	function To_Std_Logic(L: BOOLEAN) return std_ulogic is
	begin
		if L then
			return('1');
		else
			return('0');
		end if;
	end function To_Std_Logic;
	
	-- PS2 keyboard sends on its own clock high->low transition
	-- start, 8 data bits, parity, stop
	
	-- Codes are either 1 bytes or 2 bytes (extended) on press
	-- XX
	-- EX YY
	-- Codes are eighter 2 bytes or 3 bytes (extended) on release
	-- F0 XX
	-- EX F0 YY
	
	-- Some keys have multiple codes. e.g. break sends E1,14 and 77. It also sends release immediately E1 F0 14,F0 77
	
	-- LSB first
	-- Start bit 0
	-- Stop bit 1
	-- Parity = not(data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7))
	-- e.g. 
	-- '0 1100 0010 0 1'
	-- not(1 xor 1 xor 0 xor 0 xor 0 xor 0 xor 1 xor 0) = not(1) = 0
	

	-- Receive raw data from ps2 serial interface
	signal ps2_shiftreg_next : std_logic_vector(10 downto 0);
	signal ps2_shiftreg_reg : std_logic_vector(10 downto 0);
	
	signal idle_next : std_logic_vector(3 downto 0);
	signal idle_reg : std_logic_vector(3 downto 0);	

	signal bitcount_next : std_logic_vector(3 downto 0);
	signal bitcount_reg : std_logic_vector(3 downto 0);	
	
	signal enable_ps2 : std_logic;
	
	signal last_ps2_clk_next : std_logic;
	signal last_ps2_clk_reg : std_logic;

	signal ps2_clk_reg : std_logic;
	signal ps2_dat_reg : std_logic;
	
	signal parity : std_logic;
	
	-- Once we have whole parity checked bytes
	signal byte_next : std_logic_vector(7 downto 0);
	signal byte_reg : std_logic_vector(7 downto 0);
	
	signal byte_received_next : std_logic;
	signal byte_received_reg : std_logic;	
	
	-- Decode if they are press(or repeat)/release or extended
	signal pending_extended_next : std_logic;
	signal pending_extended_reg : std_logic;
	
	signal pending_keyup_next : std_logic;
	signal pending_keyup_reg : std_logic;
	
	-- To eventually get the code itself
	signal key_event_next : std_logic;
	signal key_event_reg : std_logic;
	
	signal key_value_next : std_logic_vector(9 downto 0);
	signal key_value_reg : std_logic_vector(9 downto 0);
	
	-- Store the last value, so I can filter repeat. I want repeat handled by Atari OS, not PS2 keyboard
	signal key_value_last_next : std_logic_vector(9 downto 0);
	signal key_value_last_reg : std_logic_vector(9 downto 0);
	
BEGIN

sync_clk: ENTITY work.synchronizer 
	PORT MAP
	( 
		CLK => CLK,
		RAW => PS2_CLK,
		SYNC => PS2_CLK_REG
	);

sync_dat: ENTITY work.synchronizer 
	PORT MAP
	( 
		CLK => CLK,
		RAW => PS2_DAT,
		SYNC => PS2_DAT_REG
	);

	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			-- Convert to bytes/verify
			last_ps2_clk_reg <= '0';
			
			ps2_shiftreg_reg<= (others=>'0');		
			idle_reg <= (others=>'0');
			bitcount_reg <= (others=>'0');
			
			byte_received_reg <= '0';
			byte_reg <= (others=>'0');
			
			-- Handle simple byte strings (extended,byte extended,release,byte byte release,byte)
			pending_extended_reg <= '0';
			pending_keyup_reg <= '0';			

			-- Output registers
			key_event_reg <= '0';
			key_value_reg <= (others=>'0');
			
			key_value_last_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			-- Convert to bytes/verify
			last_ps2_clk_reg <= last_ps2_clk_next;
			
			ps2_shiftreg_reg<= ps2_shiftreg_next;		
			idle_reg <= idle_next;
			bitcount_reg <= bitcount_next;
			
			byte_received_reg <= byte_received_next;
			byte_reg <= byte_next;
			
			-- Handle simple byte strings (extended,byte extended,release,byte byte release,byte)
			pending_extended_reg <= pending_extended_next;
			pending_keyup_reg <= pending_keyup_next;			

			-- Output registers
			key_event_reg <= key_event_next;
			key_value_reg <= key_value_next;
			
			key_value_last_reg <= key_value_last_next;
			
		end if;
	end process;

	-- Divide clock by 256 to get approx 4*ps2 clock
	enable_div : enable_divider
		generic map (COUNT=>256)
		port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>enable_ps2);
	
	-- capture bytes from ps2
	parity<= not(ps2_shiftreg_reg(8) xor ps2_shiftreg_reg(7) xor ps2_shiftreg_reg(6) xor ps2_shiftreg_reg(5) xor  ps2_shiftreg_reg(4) xor ps2_shiftreg_reg(3) xor ps2_shiftreg_reg(2) xor ps2_shiftreg_reg(1));
	process(last_ps2_clk_reg,ps2_clk_reg, ps2_dat_reg, ps2_shiftreg_reg,idle_reg,enable_ps2,bitcount_reg,parity)
	begin	
		ps2_shiftreg_next <= ps2_shiftreg_reg;
		last_ps2_clk_next <= last_ps2_clk_reg;
		
		bitcount_next <= bitcount_reg;
		
		idle_next <= idle_reg;
		
		byte_received_next <= '0';
		byte_next <= (others=>'0');
		
		if (enable_ps2 = '1') then		
			last_ps2_clk_next <= ps2_clk_reg;
			
			-- sample on falling edge
			if (ps2_clk_reg = '0' and last_ps2_clk_reg = '1') then
				ps2_shiftreg_next <= ps2_dat_reg&ps2_shiftreg_reg(10 downto 1);
				bitcount_next <= std_logic_vector(unsigned(bitcount_reg)+1);
			end if;
			
			-- output to next stage when done
			if (bitcount_reg = X"B") then
				byte_received_next <= (parity xnor ps2_shiftreg_reg(9)) and not(ps2_shiftreg_reg(0)) and ps2_shiftreg_reg(10);
				byte_next <= ps2_shiftreg_reg(8 downto 1);
				bitcount_next <= (others=>'0');
			end if;
			
			-- reset if both high for a time period
			idle_next <= std_logic_vector(unsigned(idle_reg) +1);
			if (idle_reg = X"F") then
				ps2_shiftreg_next <= (others=>'0');
				bitcount_next <= (others=>'0');
			end if;
			if (ps2_clk_reg = '0' or ps2_dat_reg = '0') then
				idle_next <= X"0";
			end if;		
		end if;
	end process;
	
	-- process bytes
	process(byte_reg,byte_received_reg, pending_extended_reg, pending_keyup_reg, key_value_last_reg)
	begin
		pending_extended_next <=  pending_extended_reg;
		pending_keyup_next <=  pending_keyup_reg;
		
		key_event_next <= '0';
		key_value_next <= (others =>'0');
		
		key_value_last_next <= key_value_last_reg;
		
		if (byte_received_reg = '1') then		
			case byte_reg is 
				when X"E0" =>
					pending_extended_next <= '1';					
				when X"E1" =>
					pending_extended_next <= '1';
				when X"F0" =>
					pending_keyup_next <= '1';
				when others => 
					pending_extended_next <= '0';
					pending_keyup_next <= '0';	
					
					if (not(key_value_last_reg = pending_keyup_reg&pending_extended_reg&byte_reg(7 downto 0))) then
						key_event_next <= '1';
						key_value_next <= pending_keyup_reg&pending_extended_reg&byte_reg(7 downto 0);
						
						key_value_last_next <= pending_keyup_reg&pending_extended_reg&byte_reg(7 downto 0);
					end if;
			end case;
		end if;
	end process;
			
	-- Output
	key_event <= key_event_reg;
	key_value <= key_value_reg(7 downto 0);
	key_extended <= key_value_reg(8);
	key_up <= key_value_reg(9);
		
END vhdl;
