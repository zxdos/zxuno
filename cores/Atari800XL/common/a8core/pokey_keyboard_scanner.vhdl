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

entity pokey_keyboard_scanner is
port
(
	clk : in std_logic;
	reset_n : in std_logic;
	
	enable : in std_logic; -- typically hsync or equiv timing
	keyboard_response : in std_logic_vector(1 downto 0);
	debounce_disable : in std_logic;
	scan_enable : in std_logic;
	
	keyboard_scan : out std_logic_vector(5 downto 0);
	
	key_held : out std_logic;
	shift_held : out std_logic;
	keycode : out std_logic_vector(7 downto 0);
	other_key_irq : out std_logic;
	break_irq : out std_logic
);
end pokey_keyboard_scanner;

architecture vhdl of pokey_keyboard_scanner is
	signal bincnt_next : std_logic_vector(5 downto 0);
	signal bincnt_reg : std_logic_vector(5 downto 0);

	signal break_pressed_next : std_logic;
	signal break_pressed_reg : std_logic;

	signal shift_pressed_next : std_logic;
	signal shift_pressed_reg : std_logic;
	
	signal control_pressed_next : std_logic;
	signal control_pressed_reg : std_logic;	
	
	signal compare_latch_next : std_logic_vector(5 downto 0);
	signal compare_latch_reg : std_logic_vector(5 downto 0);
	
	signal keycode_latch_next : std_logic_vector(7 downto 0);
	signal keycode_latch_reg : std_logic_vector(7 downto 0);
	
	signal irq_next : std_logic;
	signal irq_reg : std_logic;

	signal break_irq_next : std_logic;
	signal break_irq_reg : std_logic;
	
	signal key_held_next : std_logic;
	signal key_held_reg : std_logic;
	
	signal my_key : std_logic;
	
	signal state_next : std_logic_vector(1 downto 0);
	signal state_reg : std_logic_vector(1 downto 0);
	constant state_wait_key : std_logic_vector(1 downto 0) := "00";
	constant state_key_bounce : std_logic_vector(1 downto 0) := "01";
	constant state_valid_key : std_logic_vector(1 downto 0) := "10";
	constant state_key_debounce : std_logic_vector(1 downto 0) := "11";
begin

	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			bincnt_reg <= (others=>'0');
			break_pressed_reg <= '0';
			shift_pressed_reg <= '0';
			control_pressed_reg <= '0';
			compare_latch_reg <= (others=>'0');
			keycode_latch_reg <= (others=>'1');
			key_held_reg <= '0';
			state_reg <= state_wait_key;
			irq_reg <= '0';
			break_irq_reg <= '0';
		elsif (clk'event and clk = '1') then
			bincnt_reg <= bincnt_next;
			state_reg <= state_next;
			break_pressed_reg <= break_pressed_next;
			shift_pressed_reg <= shift_pressed_next;
			control_pressed_reg <= control_pressed_next;
			compare_latch_reg <= compare_latch_next;
			keycode_latch_reg <= keycode_latch_next;
			key_held_reg <= key_held_next;
			state_reg <= state_next;
			irq_reg <= irq_next;
			break_irq_reg <= break_irq_next;
		end if;
	end process;

	process (enable, keyboard_response, scan_enable, key_held_reg, my_key, state_reg,bincnt_reg, compare_latch_reg, break_pressed_next, break_pressed_reg, shift_pressed_reg, break_irq_reg, control_pressed_reg, keycode_latch_reg, debounce_disable)
	begin
		bincnt_next <= bincnt_reg;
		state_next <= state_reg;
		compare_latch_next <= compare_latch_reg;
		irq_next <= '0';
		break_irq_next <= '0';
		break_pressed_next <= break_pressed_reg;
		shift_pressed_next <= shift_pressed_reg;
		control_pressed_next <= control_pressed_reg;
		keycode_latch_next <= keycode_latch_reg;
		key_held_next <= key_held_reg;
		
		my_key <= '0';
		if (bincnt_reg = compare_latch_reg or debounce_disable='1') then
			my_key <= '1';
		end if;
		
		if (enable = '1' and scan_enable='1') then			
			bincnt_next <= std_logic_vector(unsigned(bincnt_reg) + 1); -- check another key
		
			key_held_next<= '0';
		
			case state_reg is
			when state_wait_key =>
				if (keyboard_response(0) = '0') then -- detected key press
					if (debounce_disable = '1') then
						keycode_latch_next <= control_pressed_reg&shift_pressed_reg&bincnt_reg;
						irq_next <= '1';
						key_held_next<= '1';
					else
						state_next <= state_key_bounce;
						compare_latch_next <= bincnt_reg;
					end if;
				end if;
				
			when state_key_bounce =>
				if (keyboard_response(0) = '0') then -- detected key press
					if (my_key = '1') then -- same key
						keycode_latch_next <= control_pressed_reg&shift_pressed_reg&compare_latch_reg;
						irq_next <= '1';
						key_held_next<= '1';
						state_next <= state_valid_key;
					else -- different key (multiple keys pressed)
						state_next <= state_wait_key;
					end if;
				else -- key not pressed
					if (my_key = '1') then -- same key, no longer pressed
						state_next <= state_wait_key;
					end if;
				end if;
			
			when state_valid_key =>
				key_held_next<= '1';
				if (my_key = '1') then -- only response to my key
					if (keyboard_response(0) = '1') then -- no longer pressed
						state_next <= state_key_debounce;
					end if;					
				end if;
				
			when state_key_debounce =>
				key_held_next<= '1';
				if (my_key = '1') then
					if (keyboard_response(0) = '1') then -- no longer pressed
						key_held_next<= '0';
						state_next <= state_wait_key;
					else
						state_next <= state_valid_key;
					end if;					
				end if;

			when others=> 
				state_next <= state_wait_key; 
			end case;
			
			if (bincnt_reg(3 downto 0)  = "0000") then
				case bincnt_reg(5 downto 4) is
				when "11" =>
					break_pressed_next <= not(keyboard_response(1)); --0x30
				when "01" =>
					shift_pressed_next <= not(keyboard_response(1)); --0x10
				when "00" =>
					control_pressed_next <= not(keyboard_response(1)); -- 0x00
				when others =>
					--
				end case;
			end if;
		end if;

		if (break_pressed_next='1' and break_pressed_reg='0') then
			break_irq_next <= '1';
		end if;
	end process;
	
	-- outputs
	keyboard_scan <= not(bincnt_reg);
	
	key_held <= key_held_reg;	
	shift_held <= shift_pressed_reg;
	keycode <= keycode_latch_reg;
	other_key_irq <= irq_reg;
	break_irq <= break_irq_reg;
end vhdl;
