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

-- Problem - UART on the DE1 does not have all pins connected. Need to use...

ENTITY pokey IS
PORT 
( 
	CLK : IN STD_LOGIC;
	ENABLE_179 :in std_logic;
	ADDR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	RESET_N : IN STD_LOGIC;
	
	-- keyboard interface
	keyboard_scan : out std_logic_vector(5 downto 0);
	keyboard_response : in std_logic_vector(1 downto 0);
	
	-- pots - go high as capacitor charges
	POT_IN : in std_logic_vector(7 downto 0);
	
	-- sio interface
	SIO_IN1 : IN std_logic;
	SIO_IN2 : IN std_logic;
	SIO_IN3 : IN std_logic;
	
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	CHANNEL_0_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_1_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_2_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_3_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
	
	IRQ_N_OUT : OUT std_logic;
	
	SIO_OUT1 : OUT std_logic;
	SIO_OUT2 : OUT std_logic;
	SIO_OUT3 : OUT std_logic;
	
	SIO_CLOCKIN : IN std_logic := '1';
	SIO_CLOCKOUT : OUT std_logic;
	
	POT_RESET : out std_logic
);
END pokey;

ARCHITECTURE vhdl OF pokey IS
	component synchronizer IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RAW : IN STD_LOGIC;
		SYNC : OUT STD_LOGIC
	);
	END component;

	component syncreset_enable_divider IS
	generic(COUNT : natural := 1; RESETCOUNT : natural := 0);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		syncreset : in std_logic;
		reset_n : in std_logic;
		ENABLE_IN : IN STD_LOGIC;
		
		ENABLE_OUT : OUT STD_LOGIC
	);
	END component;
	
	component pokey_poly_17_9 IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		SELECT_9_17 : IN STD_LOGIC; -- 9 high, 17 low
		INIT : IN STD_LOGIC;
		
		BIT_OUT : OUT STD_LOGIC;
		
		RAND_OUT : OUT std_logic_vector(7 downto 0)
	);
	END component;
	
	component pokey_poly_5 IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		INIT : IN STD_LOGIC;
		
		BIT_OUT : OUT STD_LOGIC
	);
	END component;
	
	component pokey_poly_4 IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		INIT : IN STD_LOGIC;
		
		BIT_OUT : OUT STD_LOGIC
	);
	END component;
	
	component pokey_countdown_timer IS
	generic(UNDERFLOW_DELAY : natural := 3);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		ENABLE_UNDERFLOW : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		
		WR_EN : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);

		DATA_OUT : OUT STD_LOGIC
	);
	END component;
	
	component pokey_noise_filter IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;

		NOISE_SELECT : IN STD_LOGIC_VECTOR(2 downto 0);
			
		PULSE_IN : IN STD_LOGIC;

		NOISE_4 : IN STD_LOGIC;
		NOISE_5 : IN STD_LOGIC;
		NOISE_LARGE : IN STD_LOGIC;

		SYNC_RESET : IN STD_LOGIC;
		
		PULSE_OUT : OUT STD_LOGIC
	);
	END component;
	
	COMPONENT complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;
	
	component delay_line IS
	generic(COUNT : natural := 1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		SYNC_RESET : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		
		DATA_OUT : OUT STD_LOGIC
	);
	END component;
	
	component pokey_keyboard_scanner is
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
	end component;
	
	--signal enable_179 : std_logic;
	signal enable_64 : std_logic;
	signal enable_15 : std_logic;

	signal audf0_reg : std_logic_vector(7 downto 0);
	signal audc0_reg : std_logic_vector(7 downto 0);
	signal audf1_reg : std_logic_vector(7 downto 0);
	signal audc1_reg : std_logic_vector(7 downto 0);
	signal audf2_reg : std_logic_vector(7 downto 0);
	signal audc2_reg : std_logic_vector(7 downto 0);
	signal audf3_reg : std_logic_vector(7 downto 0);
	signal audc3_reg : std_logic_vector(7 downto 0);
	signal audctl_reg : std_logic_vector(7 downto 0);	
	signal audf0_next : std_logic_vector(7 downto 0);
	signal audc0_next : std_logic_vector(7 downto 0);
	signal audf1_next : std_logic_vector(7 downto 0);
	signal audc1_next : std_logic_vector(7 downto 0);
	signal audf2_next : std_logic_vector(7 downto 0);
	signal audc2_next : std_logic_vector(7 downto 0);
	signal audf3_next : std_logic_vector(7 downto 0);
	signal audc3_next : std_logic_vector(7 downto 0);
	signal audctl_next : std_logic_vector(7 downto 0);

	signal audf0_pulse : std_logic;
	signal audf1_pulse : std_logic;
	signal audf2_pulse : std_logic;
	signal audf3_pulse : std_logic;
	
	signal audf0_reload : std_logic;
	signal audf1_reload : std_logic;
	signal audf2_reload : std_logic;
	signal audf3_reload : std_logic;
	
	signal stimer_write : std_logic;
	signal stimer_write_delayed : std_logic;
	
	signal audf0_pulse_noise : std_logic;
	signal audf1_pulse_noise : std_logic;
	signal audf2_pulse_noise : std_logic;
	signal audf3_pulse_noise : std_logic;
	
	signal audf0_enable : std_logic;
	signal audf1_enable : std_logic;
	signal audf2_enable : std_logic;
	signal audf3_enable : std_logic;
	
	signal chan0_output_next : std_logic;
	signal chan1_output_next : std_logic;
	signal chan2_output_next : std_logic;
	signal chan3_output_next : std_logic;
	signal chan0_output_reg : std_logic;
	signal chan1_output_reg : std_logic;
	signal chan2_output_reg : std_logic;
	signal chan3_output_reg : std_logic;
	
	signal highpass0_next : std_logic;
	signal highpass1_next : std_logic;	
	signal highpass0_reg : std_logic;
	signal highpass1_reg : std_logic;
	
	signal volume_channel_0_next : std_logic_vector(3 downto 0);
	signal volume_channel_1_next : std_logic_vector(3 downto 0);
	signal volume_channel_2_next : std_logic_vector(3 downto 0);
	signal volume_channel_3_next : std_logic_vector(3 downto 0);
	signal volume_channel_0_reg : std_logic_vector(3 downto 0);
	signal volume_channel_1_reg : std_logic_vector(3 downto 0);
	signal volume_channel_2_reg : std_logic_vector(3 downto 0);
	signal volume_channel_3_reg : std_logic_vector(3 downto 0);
	
	signal addr_decoded : std_logic_vector(15 downto 0);
	
	signal noise_4 : std_logic;
	signal noise_5 : std_logic;
	signal noise_large : std_logic;
	signal noise_4_next : std_logic_vector(2 downto 0);
	signal noise_4_reg : std_logic_vector(2 downto 0);
	signal noise_5_next : std_logic_vector(2 downto 0);
	signal noise_5_reg : std_logic_vector(2 downto 0);
	signal noise_large_next : std_logic_vector(2 downto 0);
	signal noise_large_reg : std_logic_vector(2 downto 0);

	signal rand_out : std_logic_vector(7 downto 0); -- snoop part of the shift reg
	
	signal initmode : std_logic;
	
	signal irqen_next : std_logic_vector(7 downto 0);
	signal irqen_reg : std_logic_vector(7 downto 0);

	signal irqst_next : std_logic_vector(7 downto 0);
	signal irqst_reg : std_logic_vector(7 downto 0);
	
	signal irq_n_next : std_logic;
	signal irq_n_reg : std_logic; -- for output
	
	-- serial ports!
	signal serial_ip_ready_interrupt : std_logic;
	signal serial_ip_framing_next : std_logic;
	signal serial_ip_framing_reg : std_logic;
	signal serial_ip_overrun_next : std_logic;
	signal serial_ip_overrun_reg : std_logic;
	signal serial_op_needed_interrupt : std_logic;
	
	signal skctl_next : std_logic_vector(7 downto 0);
	signal skctl_reg : std_logic_vector(7 downto 0);
	
	signal serin_shift_next : std_logic_vector(9 downto 0);
	signal serin_shift_reg : std_logic_vector(9 downto 0);
	signal serin_next : std_logic_vector(7 downto 0);
	signal serin_reg : std_logic_vector(7 downto 0);
	signal serin_bitcount_next : std_logic_vector(3 downto 0);
	signal serin_bitcount_reg : std_logic_vector(3 downto 0);
	
	signal sio_in1_reg : std_logic;
	signal sio_in2_reg : std_logic;
	signal sio_in3_reg : std_logic;
	signal sio_in_next : std_logic;
	signal sio_in_reg : std_logic;
	
	signal sio_out_next : std_logic;
	signal sio_out_reg : std_logic;
	signal serial_out_next : std_logic;
	signal serial_out_reg : std_logic;
	
	signal serout_shift_next : std_logic_vector(9 downto 0);
	signal serout_shift_reg : std_logic_vector(9 downto 0);
	
	signal serout_holding_full_next : std_logic;
	signal serout_holding_full_reg : std_logic;
	signal serout_holding_next : std_logic_vector(7 downto 0);
	signal serout_holding_reg : std_logic_vector(7 downto 0);
	signal serout_holding_load : std_logic;

	signal serout_bitcount_next : std_logic_vector(3 downto 0);
	signal serout_bitcount_reg : std_logic_vector(3 downto 0);
	
	signal serout_active_next : std_logic;
	signal serout_active_reg : std_logic;
	
	signal serial_reset : std_logic;
	signal serout_sync_reset : std_logic;
	signal skrest_write : std_logic;
	
	signal serout_enable : std_logic;
	signal serout_enable_delayed : std_logic;
	signal serin_enable : std_logic;
	
	signal async_serial_reset : std_logic;
	signal waiting_for_start_bit : std_logic;
	
	signal serin_clock_next : std_logic;
	signal serin_clock_reg : std_logic;
	signal serin_clock_last_next : std_logic;
	signal serin_clock_last_reg : std_logic;

	signal serout_clock_next : std_logic;
	signal serout_clock_reg : std_logic;
	signal serout_clock_last_next : std_logic;
	signal serout_clock_last_reg : std_logic;
	
	signal twotone_reset : std_logic;
	signal twotone_next : std_logic;
	signal twotone_reg : std_logic;
	
	signal clock_next : std_logic;
	signal clock_reg : std_logic;
	signal clock_sync_next : std_logic;
	signal clock_sync_reg : std_logic;
	signal clock_input : std_logic;
	
	-- keyboard
	signal keyboard_overrun_next : std_logic;
	signal keyboard_overrun_reg : std_logic;
	
	signal shift_held : std_logic;
	signal break_irq : std_logic;
	signal key_held : std_logic;
	signal other_key_irq : std_logic;
	
	signal kbcode : std_logic_vector(7 downto 0);
	
	-- pots
	signal pot0_next : std_logic_vector(7 downto 0);
	signal pot0_reg : std_logic_vector(7 downto 0);
	signal pot1_next : std_logic_vector(7 downto 0);
	signal pot1_reg : std_logic_vector(7 downto 0);
	signal pot2_next : std_logic_vector(7 downto 0);
	signal pot2_reg : std_logic_vector(7 downto 0);
	signal pot3_next : std_logic_vector(7 downto 0);
	signal pot3_reg : std_logic_vector(7 downto 0);
	signal pot4_next : std_logic_vector(7 downto 0);
	signal pot4_reg : std_logic_vector(7 downto 0);
	signal pot5_next : std_logic_vector(7 downto 0);
	signal pot5_reg : std_logic_vector(7 downto 0);	
	signal pot6_next : std_logic_vector(7 downto 0);
	signal pot6_reg : std_logic_vector(7 downto 0);
	signal pot7_next : std_logic_vector(7 downto 0);
	signal pot7_reg : std_logic_vector(7 downto 0);	

	signal allpot_next : std_logic_vector(7 downto 0);
	signal allpot_reg : std_logic_vector(7 downto 0);	
	
	signal pot_counter_next : std_logic_vector(7 downto 0);
	signal pot_counter_reg : std_logic_vector(7 downto 0);
	
	signal potgo_write : std_logic;
	
	signal pot_reset_next : std_logic;
	signal pot_reset_reg : std_logic;
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			-- FIXME - Pokey does not have RESET - instead this is caused by 'init' sequence
			audf0_reg <= X"00";
			audc0_reg <= X"00";
			audf1_reg <= X"00";
			audc1_reg <= X"00";
			audf2_reg <= X"00";
			audc2_reg <= X"00";
			audf3_reg <= X"00";
			audc3_reg <= X"00";
			audctl_reg <= X"00";
			
			irqen_reg <= X"00";
			irqst_reg <= X"FF";
			irq_n_reg <= '1';
			
			skctl_reg <= X"00";
			
			highpass0_reg <= '0';
			highpass1_reg <= '0';
			
			chan0_output_reg <= '0';
			chan1_output_reg <= '0';
			chan2_output_reg <= '0';
			chan3_output_reg <= '0';
			
			volume_channel_0_reg <= (others=>'0');
			volume_channel_1_reg <= (others=>'0');
			volume_channel_2_reg <= (others=>'0');
			volume_channel_3_reg <= (others=>'0');
			
			serin_reg <= (others=>'0');
			serin_shift_reg <= (others=>'0');
			serin_bitcount_reg <= (others=>'0');
			serout_shift_reg <= (others=>'0');
			serout_holding_reg <= (others=>'0');
			serout_holding_full_reg <= '0';
			serout_active_reg <= '0';		
			sio_out_reg <= '1';
			serial_out_reg <= '1';
			
			serial_ip_framing_reg <= '0';
			serial_ip_overrun_reg <= '0';
			
			clock_reg <= '0';
			clock_sync_reg <= '0';
	
			keyboard_overrun_reg <= '0';
			
			serin_clock_reg <= '0';
			serin_clock_last_reg <= '0';
			serout_clock_reg <= '0';
			serout_clock_last_reg <= '0';
			
			twotone_reg <= '0';
			
			sio_in_reg <= '0';
			
			pot0_reg <= (others=>'0');
			pot1_reg <= (others=>'0');
			pot2_reg <= (others=>'0');
			pot3_reg <= (others=>'0');
			pot4_reg <= (others=>'0');
			pot5_reg <= (others=>'0');
			pot6_reg <= (others=>'0');
			pot7_reg <= (others=>'0');

			allpot_reg <= (others=>'1');
			
			pot_counter_reg <= (others=>'0');
			
			pot_reset_reg <= '1';

			noise_4_reg <= (others=>'0');
			noise_5_reg <= (others=>'0');
			noise_large_reg <= (others=>'0');
			
		elsif (clk'event and clk='1') then			
			audf0_reg <= audf0_next;
			audc0_reg <= audc0_next;
			audf1_reg <= audf1_next;
			audc1_reg <= audc1_next;
			audf2_reg <= audf2_next;
			audc2_reg <= audc2_next;
			audf3_reg <= audf3_next;
			audc3_reg <= audc3_next;
			audctl_reg <= audctl_next;
			
			irqen_reg <= irqen_next;
			irqst_reg <= irqst_next;
			irq_n_reg <= irq_n_next;
			
			skctl_reg <= skctl_next;
			
			highpass0_reg <= highpass0_next;
			highpass1_reg <= highpass1_next;
			
			chan0_output_reg <= chan0_output_next;
			chan1_output_reg <= chan1_output_next;
			chan2_output_reg <= chan2_output_next;
			chan3_output_reg <= chan3_output_next;
			
			volume_channel_0_reg<= volume_channel_0_next;
			volume_channel_1_reg<= volume_channel_1_next;
			volume_channel_2_reg<= volume_channel_2_next;
			volume_channel_3_reg<= volume_channel_3_next;
			
			serin_reg <= serin_next;
			serin_shift_reg <= serin_shift_next;
			serin_bitcount_reg <= serin_bitcount_next;
			serout_shift_reg <= serout_shift_next;
			serout_bitcount_reg <= serout_bitcount_next;
			
			serout_holding_reg<=serout_holding_next;
			serout_holding_full_reg<=serout_holding_full_next;
			serout_active_reg <= serout_active_next;
			
			sio_out_reg <= sio_out_next;
			serial_out_reg <= serial_out_next;
			
			serial_ip_framing_reg <= serial_ip_framing_next;
			serial_ip_overrun_reg <= serial_ip_overrun_next;
			
			clock_reg <= clock_next;
			clock_sync_reg <= clock_sync_next;
			
			keyboard_overrun_reg <= keyboard_overrun_next;
			
			serin_clock_reg <= serin_clock_next;
			serin_clock_last_reg <= serin_clock_last_next;
			serout_clock_reg <= serout_clock_next;
			serout_clock_last_reg <= serout_clock_last_next;
			
			twotone_reg <= twotone_next;
			
			sio_in_reg <= sio_in_next;
			
			pot0_reg <= pot0_next;
			pot1_reg <= pot1_next;
			pot2_reg <= pot2_next;
			pot3_reg <= pot3_next;
			pot4_reg <= pot4_next;
			pot5_reg <= pot5_next;
			pot6_reg <= pot6_next;
			pot7_reg <= pot7_next;

			allpot_reg <= allpot_next;
			
			pot_counter_reg <= pot_counter_next;
			
			pot_reset_reg <= pot_reset_next;

			noise_4_reg <= noise_4_next;
			noise_5_reg <= noise_5_next;
			noise_large_reg <= noise_large_next;
		end if;
	end process;
	
	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>4)
		port map (addr_in=>addr, addr_decoded=>addr_decoded);
	
	-- clock selection
	process(enable_64,enable_15,enable_179,audctl_reg,audf0_pulse,audf2_pulse)
	begin
		audf0_enable <= enable_64;
		audf1_enable <= enable_64;
		audf2_enable <= enable_64;
		audf3_enable <= enable_64;		
		
		if (audctl_reg(0) = '1') then
			audf0_enable <= enable_15;
			audf1_enable <= enable_15;
			audf2_enable <= enable_15;
			audf3_enable <= enable_15;
		end if;

		if (audctl_reg(6) = '1') then
			audf0_enable <= enable_179;
		end if;
		
		if (audctl_reg(5) = '1') then
			audf2_enable <= enable_179;
		end if;
		
		if(audctl_reg(4) = '1') then
			audf1_enable <= audf0_pulse;
		end if;
		
		if(audctl_reg(3) = '1') then
			audf3_enable <= audf2_pulse;
		end if;
	end process;
	
	-- Instantiate timers
	timer0 : pokey_countdown_timer
		generic map (UNDERFLOW_DELAY=>3)
		port map(clk=>clk,enable=>audf0_enable,enable_underflow=>enable_179,reset_n=>reset_n,wr_en=>audf0_reload,data_in=>audf0_next,DATA_OUT=>audf0_pulse);
	timer1 : pokey_countdown_timer
		generic map (UNDERFLOW_DELAY=>3)
		port map(clk=>clk,enable=>audf1_enable,enable_underflow=>enable_179,reset_n=>reset_n,wr_en=>audf1_reload,data_in=>audf1_next,DATA_OUT=>audf1_pulse);
	timer2 : pokey_countdown_timer
		generic map (UNDERFLOW_DELAY=>3)
		port map(clk=>clk,enable=>audf2_enable,enable_underflow=>enable_179,reset_n=>reset_n,wr_en=>audf2_reload,data_in=>audf2_next,DATA_OUT=>audf2_pulse);
	timer3 : pokey_countdown_timer
		generic map (UNDERFLOW_DELAY=>3)
		port map(clk=>clk,enable=>audf3_enable,enable_underflow=>enable_179,reset_n=>reset_n,wr_en=>audf3_reload,data_in=>audf3_next,DATA_OUT=>audf3_pulse);		
		
	-- Timer reloading
	process (audctl_reg, audf0_pulse, audf1_pulse, audf2_pulse, audf3_pulse, stimer_write_delayed, async_serial_reset, twotone_reset)
	begin
		audf0_reload <= ((not(audctl_reg(4)) and audf0_pulse)) or (audctl_reg(4) and audf1_pulse) or stimer_write_delayed or twotone_reset;
		audf1_reload <= audf1_pulse or stimer_write_delayed or twotone_reset;
		audf2_reload <= ((not(audctl_reg(3)) and audf2_pulse)) or (audctl_reg(3) and audf3_pulse) or stimer_write_delayed or async_serial_reset;
		audf3_reload <= audf3_pulse or stimer_write_delayed or async_serial_reset;
	end process;
	
	-- Writes to registers
	process(data_in,wr_en,addr_decoded,audf0_reg,audc0_reg,audf1_reg,audc1_reg,audf2_reg,audc2_reg,audf3_reg,audc3_reg,audf0_enable,audf1_enable,audf2_enable,audf3_enable,audctl_reg, irqen_reg, skctl_reg, serout_holding_reg)
	begin
		audf0_next <= audf0_reg;
		audc0_next <= audc0_reg;
		audf1_next <= audf1_reg;
		audc1_next <= audc1_reg;
		audf2_next <= audf2_reg;
		audc2_next <= audc2_reg;
		audf3_next <= audf3_reg;
		audc3_next <= audc3_reg;
		audctl_next <= audctl_reg;		
		
		irqen_next <= irqen_reg;
		skctl_next <= skctl_reg;
		
		stimer_write <= '0';
		
		serout_holding_load <= '0';
		serout_holding_next <= serout_holding_reg;
		
		serial_reset <= '0';
		skrest_write <= '0';
		potgo_write <= '0';
		
		if (wr_en = '1') then
			if(addr_decoded(0) = '1') then
				audf0_next <= data_in;
			end if;
			
			if(addr_decoded(1) = '1') then
				audc0_next <= data_in;
			end if;
			
			if(addr_decoded(2) = '1') then
				audf1_next <= data_in;
			end if;

			if(addr_decoded(3) = '1') then
				audc1_next <= data_in;
			end if;
			
			if(addr_decoded(4) = '1') then
				audf2_next <= data_in;
			end if;

			if(addr_decoded(5) = '1') then
				audc2_next <= data_in;
			end if;
			
			if(addr_decoded(6) = '1') then
				audf3_next <= data_in;
			end if;		

			if(addr_decoded(7) = '1') then
				audc3_next <= data_in;
			end if;
			
			if(addr_decoded(8) = '1') then
				audctl_next <= data_in;
			end if;
			
			if (addr_decoded(9) = '1') then --STIMER
				stimer_write <= '1';
			end if;
			
			if (addr_decoded(10) = '1') then -- skrest - resets the serial input problems - overflow etc
				skrest_write <= '1';
			end if;

			if (addr_decoded(11) = '1') then -- POTGO - start POT scan
				potgo_write <= '1';
			end if;
			
			if (addr_decoded(13) = '1') then --SEROUT								
				serout_holding_next <= data_in;
				serout_holding_load <= '1';
			end if;
			
			if (addr_decoded(14) = '1') then --IRQEN
				irqen_next <= data_in;
			end if;

			if (addr_decoded(15) = '1') then --SKCTL
				skctl_next <= data_in;
				
				if (data_in(6 downto 4)="000") then
					serial_reset <= '1';
				end if;
			end if;	
	
		end if;
	end process;
	
	-- Read from registers
	process(addr_decoded,kbcode,RAND_OUT,IRQST_REG,key_held,shift_held,sio_in_reg,serin_reg,keyboard_overrun_reg, serial_ip_framing_reg, serial_ip_overrun_reg, waiting_for_start_bit, pot_in, pot0_reg, pot1_reg, pot2_reg, pot3_reg, pot4_reg, pot5_reg, pot6_reg, pot7_reg, allpot_reg)
	begin
		data_out <= X"FF";

		if(addr_decoded(0) = '1') then --POT0
			data_out <= pot0_reg;
		end if;

		if(addr_decoded(1) = '1') then --POT1
			data_out <= pot1_reg;
		end if;

		if(addr_decoded(2) = '1') then --POT2
			data_out <= pot2_reg;
		end if;

		if(addr_decoded(3) = '1') then --POT3
			data_out <= pot3_reg;
		end if;
		
		if(addr_decoded(4) = '1') then --POT4
			data_out <= pot4_reg;
		end if;

		if(addr_decoded(5) = '1') then --POT5
			data_out <= pot5_reg;
		end if;

		if(addr_decoded(6) = '1') then --POT6
			data_out <= pot6_reg;
		end if;

		if(addr_decoded(7) = '1') then --POT7
			data_out <= pot7_reg;
		end if;

		if(addr_decoded(8) = '1') then --ALLPOT
			data_out <= allpot_reg;
		end if;
		
		if(addr_decoded(9) = '1') then --KBCODE
			data_out <= kbcode;
		end if;
		
		if(addr_decoded(10) = '1') then -- RANDOM
			data_out <= RAND_OUT;
		end if;

		if (addr_decoded(13) = '1') then --SERIN			
			data_out <= serin_reg;
		end if;
		
		if (addr_decoded(14) = '1') then --IRQST - bits set to low when irq
			data_out <= IRQST_REG;
			--break_irq_n & other_key_irq_n & serial_ip_irq_n & serial_op_irq_n & serial_trans_irq_n & timer3_irq_n & timer_1_irq_n & timer_0_irq_n
		end if;		

		if (addr_decoded(15) = '1') then --SKSTAT
			data_out <= not(serial_ip_framing_reg)&not(keyboard_overrun_reg)&not(serial_ip_overrun_reg)&sio_in_reg&not(shift_held)&not(key_held)&waiting_for_start_bit&"1";
		end if;		
		
	end process;
	
	-- Fire interrupts
	process (irqen_reg, irqst_reg, audf0_pulse, audf1_pulse, audf3_pulse, other_key_irq, serial_ip_ready_interrupt, serout_active_reg, serial_op_needed_interrupt, break_irq)
	begin
		-- clear interrupts
		irqst_next <= irqst_reg or not(irqen_reg);
				
		irq_n_next <= '0';

		if ((irqst_reg or "0000"&not(irqen_reg(3))&"000") = X"FF") then
			irq_n_next <= '1';
		end if;
	
		-- set interrupts
		if (audf0_pulse = '1') then
			irqst_next(0) <= not(irqen_reg(0));
		end if;

		if (audf1_pulse = '1') then
			irqst_next(1) <= not(irqen_reg(1));
		end if;

		if (audf3_pulse = '1') then
			irqst_next(2) <= not(irqen_reg(2));
		end if;
		
		if (other_key_irq = '1') then
			irqst_next(6) <= not(irqen_reg(6));			
		end if;
		
		if (break_irq = '1') then
			irqst_next(7) <= not(irqen_reg(7));			
		end if;		
	
		if (serial_ip_ready_interrupt = '1') then
			irqst_next(5) <= not(irqen_reg(5));
		end if;
		
		irqst_next(3) <= serout_active_reg;
		
		if (serial_op_needed_interrupt = '1') then
			irqst_next(4) <= not(irqen_reg(4));
		end if;
		
	end process;
	
	-- Instantiate delay for stimer reload_request
	stimer_delay : delay_line
		generic map (count=>3)
		port map (clk=>clk, sync_reset=>'0',data_in=>stimer_write, enable=>enable_179, reset_n=>reset_n, data_out=>stimer_write_delayed);
		
	--stimer_write_delayed <= stimer_write;
	
	-- Instantiate audio noise filters
	pokey_noise_filter0 : pokey_noise_filter
		port map(clk=>clk,reset_n=>reset_n,noise_select=>audc0_reg(7 downto 5),pulse_in=>audf0_pulse,pulse_out=>audf0_pulse_noise,noise_4=>noise_4,noise_5=>noise_5,noise_large=>noise_large, sync_reset=>stimer_write_delayed);
	pokey_noise_filter1 : pokey_noise_filter
		port map(clk=>clk,reset_n=>reset_n,noise_select=>audc1_reg(7 downto 5),pulse_in=>audf1_pulse,pulse_out=>audf1_pulse_noise,noise_4=>noise_4_reg(0),noise_5=>noise_5_reg(0),noise_large=>noise_large_reg(0), sync_reset=>stimer_write_delayed);
	pokey_noise_filter2 : pokey_noise_filter
		port map(clk=>clk,reset_n=>reset_n,noise_select=>audc2_reg(7 downto 5),pulse_in=>audf2_pulse,pulse_out=>audf2_pulse_noise,noise_4=>noise_4_reg(1),noise_5=>noise_5_reg(1),noise_large=>noise_large_reg(1), sync_reset=>stimer_write_delayed);
	pokey_noise_filter3 : pokey_noise_filter
		port map(clk=>clk,reset_n=>reset_n,noise_select=>audc3_reg(7 downto 5),pulse_in=>audf3_pulse,pulse_out=>audf3_pulse_noise,noise_4=>noise_4_reg(2),noise_5=>noise_5_reg(2),noise_large=>noise_large_reg(2), sync_reset=>stimer_write_delayed);
	
	-- Audio output stage
	-- (toggling now handled in the noise filter - the subtlety on when to toggle and when to sample is important)
	chan0_output_next <= audf0_pulse_noise;
	chan1_output_next <= audf1_pulse_noise;
	chan2_output_next <= audf2_pulse_noise;
	chan3_output_next <= audf3_pulse_noise;
	
	-- High pass filters
	process(audctl_reg,audf2_pulse,audf3_pulse,chan0_output_reg, chan1_output_reg, chan2_output_reg, chan3_output_reg, highpass0_reg, highpass1_reg)
	begin
		highpass0_next <= highpass0_reg;
		highpass1_next <= highpass1_reg;
		
		if (audctl_reg(2) = '1') then
			if (audf2_pulse = '1') then
				highpass0_next <= chan0_output_reg;
			end if;
		else
			highpass0_next <= '1';
		end if;
		
		if (audctl_reg(1) = '1') then
			if (audf3_pulse = '1') then
				highpass1_next <= chan1_output_reg;
			end if;
		else
			highpass1_next <= '1';
		end if;
		
	end process;
	
	-- Instantiate key pokey clocks
	-- ~1.79MHz - from 25MHz/14
	-- ~64KHz - from 1.79MHz/28
	-- ~15KHz - from 1.79MHz/114
	--enable_179_div : enable_divider
	--	generic map (COUNT=>14)
	--	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>enable_179);		
		
	-- resetcount 6/33
	enable_64_div : syncreset_enable_divider
		generic map (COUNT=>28,RESETCOUNT=>6) -- 28-22
		port map(clk=>clk,syncreset=>initmode,reset_n=>reset_n,enable_in=>enable_179,enable_out=>enable_64);
		
	enable_15_div : syncreset_enable_divider
		generic map (COUNT=>114,RESETCOUNT=>33) -- 114-81
		port map(clk=>clk,syncreset=>initmode,reset_n=>reset_n,enable_in=>enable_179,enable_out=>enable_15);
		
	-- Instantiate pokey noise circuits (lfsr)
	initmode <= skctl_next(1) nor skctl_next(0);
	poly_17_19_lfsr : pokey_poly_17_9
		port map(clk=>clk,reset_n=>reset_n,init=>initmode,enable=>enable_179,select_9_17=>audctl_reg(7),bit_out=>noise_large,rand_out=>rand_out);
		
	poly_5_lfsr : pokey_poly_5
		port map(clk=>clk,reset_n=>reset_n,init=>initmode,enable=>enable_179,bit_out=>noise_5);
		
	poly_4_lfsr : pokey_poly_4
		port map(clk=>clk,reset_n=>reset_n,init=>initmode,enable=>enable_179,bit_out=>noise_4);

	-- Delay between feeding noise between channels
	process(noise_large_reg, noise_5_reg, noise_4_reg, noise_large, noise_5, noise_4, enable_179)
	begin
		noise_large_next <= noise_large_reg;
		noise_5_next <= noise_5_reg;
		noise_4_next <= noise_4_reg;

		if (enable_179='1') then
			noise_large_next <= noise_large_reg(1 downto 0)&noise_large;
			noise_5_next <= noise_5_reg(1 downto 0)&noise_5;
			noise_4_next <= noise_4_reg(1 downto 0)&noise_4;
		end if;
	end process;
	
	--AUDIO_LEFT <= "000"&count_reg(15 downto 3);
	process(chan0_output_reg, chan1_output_reg, chan2_output_reg, chan3_output_reg, audc0_reg, audc1_reg, audc2_reg, audc3_reg, highpass0_reg, highpass1_reg)
	begin
		volume_channel_0_next <= "0000";
		volume_channel_1_next <= "0000";
		volume_channel_2_next <= "0000";
		volume_channel_3_next <= "0000";
			
		if (((chan0_output_reg xor highpass0_reg) or audc0_reg(4)) = '1') then
			volume_channel_0_next <= audc0_reg(3 downto 0);
		end if;
		
		if (((chan1_output_reg xor highpass1_reg) or audc1_reg(4)) = '1') then
			volume_channel_1_next <= audc1_reg(3 downto 0);
		end if;
		
		if ((chan2_output_reg or audc2_reg(4)) = '1') then
			volume_channel_2_next <= audc2_reg(3 downto 0);
		end if;
		
		if ((chan3_output_reg or audc3_reg(4)) = '1') then
			volume_channel_3_next <= audc3_reg(3 downto 0);
		end if;
		
	end process;
	
	-- serial port output	
	-- urghhh (TODO: If timers are cleared with stimer_write, some clocks are still triggering. This workaround fixes the acid test. Investigate the proper fix)
        serout_sync_reset <= serial_reset or stimer_write_delayed;
	serout_clock_delay : delay_line
		generic map (count=>2)
		port map (clk=>clk, sync_reset=>serout_sync_reset,data_in=>serout_enable, enable=>enable_179, reset_n=>reset_n, data_out=>serout_enable_delayed);
		
	
	process(serout_enable_delayed, skctl_reg, serout_active_reg, serout_clock_last_reg,serout_clock_reg, serout_holding_load, serout_holding_reg, serout_holding_full_reg, serout_shift_reg, serout_bitcount_reg, serial_out_reg, twotone_reg, audf0_pulse, audf1_pulse, serial_reset)
	begin
		serout_clock_next <= serout_clock_reg;
		serout_clock_last_next <= serout_clock_reg;
	
		serout_shift_next <= serout_shift_reg;
		serout_bitcount_next <= serout_bitcount_reg;
		serout_holding_full_next <= serout_holding_full_reg;
		serout_active_next <= serout_active_reg;
		
		serial_out_next <= serial_out_reg; -- output from shift reg (if unchanged)
		sio_out_next <= serial_out_reg;		
	
		-- two tone output
		twotone_next <= twotone_reg;
		twotone_reset <= '0';
		
		if ((audf1_pulse or (audf0_pulse and serial_out_reg)) = '1') then
			twotone_next <= not(twotone_reg);
			twotone_reset <= skctl_reg(3);
		end if;
		
		if (skctl_reg(3) = '1') then
			sio_out_next <= twotone_reg;
		end if;
		
		serial_op_needed_interrupt <= '0';		
		
		-- generate clock from enable signals
		if (serout_enable_delayed = '1') then
			serout_clock_next <= not(serout_clock_reg);
		end if;
		
		-- output bits over sio
		if (serout_clock_last_reg = '0' and serout_clock_reg = '1') then			
			serout_shift_next <= '0'&serout_shift_reg(9 downto 1); -- next
			serial_out_next <= serout_shift_reg(1) or not(serout_active_reg); -- i.e. next serout_shift_reg(0)
				
			-- reload			
			if (serout_bitcount_reg = X"0") then
				if (serout_holding_full_reg='1') then -- unless, more to send in holding reg?
					serout_bitcount_next <= X"9"; -- 10 bits to send, 9 more after this
					serout_shift_next <= '1'&serout_holding_reg&'0';
					serial_out_next <= '0'; -- start bit (serout_shift_reg(0) after this cycle)
					serout_holding_full_next <= '0';					
					serial_op_needed_interrupt <= '1'; -- more data please!
					serout_active_next <= '1';
				else
					serout_active_next <= '0';
					serial_out_next <= '1'; -- remove blip! 
				end if;
			else
				serout_bitcount_next <= std_logic_vector(unsigned(serout_bitcount_reg)-1);
			end if;
		end if;

		-- force break
		if (skctl_reg(7) = '1') then
			serial_out_next <= '0';
		end if;
		
		-- register to load has been written too, update our state to reflect that it is full
		if (serout_holding_load = '1') then
			serout_holding_full_next <= '1';
		end if;
		
		if (serial_reset = '1') then
			twotone_next <= '0';
			serout_bitcount_next <= (others=>'0');
			serout_shift_next <= (others=>'0');
			serout_holding_full_next <= '0';
			serout_clock_next <= '0';
			serout_clock_last_next <= '0';
			serout_active_next <= '0';
		end if;
	end process;
	
	-- serial port input
	sio_in1_synchronizer : synchronizer
		port map (clk=>clk, raw=>sio_in1, sync=>sio_in1_reg);	
	sio_in2_synchronizer : synchronizer
		port map (clk=>clk, raw=>sio_in2, sync=>sio_in2_reg);	
	sio_in3_synchronizer : synchronizer
		port map (clk=>clk, raw=>sio_in3, sync=>sio_in3_reg);	
	sio_in_next <= sio_in1_reg and sio_in2_reg and sio_in3_reg;
		
	waiting_for_start_bit <= '1' when serin_bitcount_reg = X"9" else '0';
	process(serin_enable,serin_clock_last_reg,serin_clock_reg, sio_in_reg, serin_reg,serin_shift_reg, serin_bitcount_reg, serial_ip_overrun_reg, serial_ip_framing_reg, skrest_write, irqst_reg, skctl_reg, waiting_for_start_bit, serial_reset)
	begin
		serin_clock_next <= serin_clock_reg;
		serin_clock_last_next <= serin_clock_reg;
	
		serin_shift_next <= serin_shift_reg;
		serin_bitcount_next <= serin_bitcount_reg;
		serin_next <= serin_reg;
		
		serial_ip_overrun_next <= serial_ip_overrun_reg;
		serial_ip_framing_next <= serial_ip_framing_reg;
		serial_ip_ready_interrupt <= '0';
		
		async_serial_reset <= '0';
		
		-- generate clock from enable signals
		if (serin_enable = '1') then
			serin_clock_next <= not(serin_clock_reg);
		end if;
		
		-- resync clock on receipt of start bit
		if ((skctl_reg(4) and sio_in_reg and waiting_for_start_bit)= '1') then
			async_serial_reset <= '1';
			serin_clock_next <= '1';
		end if;
		
		-- receive bits into shift reg		
		if (serin_clock_last_reg='1' and serin_clock_reg='0') then -- failing edge					
			if (((waiting_for_start_bit and not(sio_in_reg)) or not(waiting_for_start_bit))='1') then				
				serin_shift_next <= sio_in_reg&serin_shift_reg(9 downto 1);
			
				if (serin_bitcount_reg = X"0") then -- full byte
					serin_next <= serin_shift_reg(9 downto 2); -- not shifted yet
					
					serin_bitcount_next <= X"9"; -- next... no disable for serial input, always happening.
					
					-- irq to alert new data avilable
					serial_ip_ready_interrupt <= '1';
					
					-- flag up overrun
					if (irqst_reg(5) = '0') then -- if interrupt bit not cleared yet...
						serial_ip_overrun_next <= '1';
					end if;				
					
					-- flag up framing problem (stop bit is 1 - pull from sio since reg not yet shifted)
					if (sio_in_reg='0') then
						serial_ip_framing_next <= '1';
					end if;
				else			
					serin_bitcount_next <= std_logic_vector(unsigned(serin_bitcount_reg)-1);
				end if;
			end if;
		end if;
		
		if (skrest_write = '1') then
			serial_ip_overrun_next <= '0';
			serial_ip_framing_next <= '0';
		end if;
		
		if (serial_reset = '1') then
			serin_clock_next <= '0';
			serin_bitcount_next <= X"9"; -- i.e. waiting for start bit
			serin_shift_next <= (others=>'0');			
		end if;		
	end process;
	
	-- serial clocks
	process(sio_clockin,skctl_reg,clock_reg,clock_sync_reg,audf1_pulse,audf2_pulse,audf3_pulse)
	begin
		clock_next <= sio_clockin;
		clock_sync_next <= clock_reg;
	
		serout_enable <= '0';
		serin_enable <= '0';
		clock_input <= '1'; -- when output, outputs channel 4
		
		case skctl_reg(6 downto 4) is
			when "000" =>
				serin_enable <= not(clock_sync_reg) and clock_reg;
				serout_enable <= not(clock_sync_reg) and clock_reg;
			when "001" =>
				serin_enable <= audf3_pulse;
				serout_enable <= not(clock_sync_reg) and clock_reg;
			when "010" =>
				serin_enable <= audf3_pulse;
				serout_enable <= audf3_pulse;
				clock_input <= '0';
			when "011" =>
				serin_enable <= audf3_pulse;
				serout_enable <= audf3_pulse;
			when "100" =>
				serin_enable <= not(clock_sync_reg) and clock_reg;
				serout_enable <= audf3_pulse;
			when "101" =>
				serin_enable <= audf3_pulse;
				serout_enable <= audf3_pulse;
			when "110" =>
				serin_enable <= audf3_pulse;
				serout_enable <= audf1_pulse;
				clock_input <= '0';
			when "111" =>			
				serin_enable <= audf3_pulse;
				serout_enable <= audf1_pulse;
			when others =>
				-- nop
		end case;
	end process;
	
	-- keyboard overrun (i.e. second key pressed before interrupt cleared)
	process(other_key_irq,keyboard_overrun_reg,skrest_write,irqst_reg)
	begin
		keyboard_overrun_next <= keyboard_overrun_reg;
		
		if (other_key_irq='1' and irqst_reg(6)='0') then
			keyboard_overrun_next <= '1';
		end if;
		
		if (skrest_write = '1') then
			keyboard_overrun_next <= '0';
		end if;
	end process;
	
	-- keyboard scan
	pokey_keyboard_scanner1 : pokey_keyboard_scanner
		port map (clk=>clk, reset_n=>reset_n, enable=>enable_15, keyboard_response=>keyboard_response, debounce_disable=>not(skctl_reg(0)), scan_enable=>skctl_reg(1), keyboard_scan=>keyboard_scan, key_held=>key_held, shift_held=>shift_held, keycode=>kbcode, other_key_irq=>other_key_irq, break_irq=>break_irq);

	-- POT scan
	process(potgo_write, pot_reset_reg, pot_counter_reg, pot_in, enable_15, enable_179, skctl_reg, pot0_reg, pot1_reg, pot2_reg, pot3_reg, pot4_reg, pot5_reg, pot6_reg, pot7_reg, allpot_reg)
	begin	
		pot0_next <= pot0_reg;
		pot1_next <= pot1_reg;
		pot2_next <= pot2_reg;
		pot3_next <= pot3_reg;
		pot4_next <= pot4_reg;
		pot5_next <= pot5_reg;
		pot6_next <= pot6_reg;
		pot7_next <= pot7_reg;

		allpot_next <= allpot_reg;
		
		pot_reset_next <= pot_reset_reg;
		
		pot_counter_next <= pot_counter_reg;
		
		if (((enable_15 and not(skctl_reg(2))) or (enable_179 and skctl_reg(2))) = '1') then
			pot_counter_next <= std_logic_vector(unsigned(pot_counter_reg) + 1);
			if (pot_counter_reg = X"E4") then
				pot_reset_next <= '1'; -- turn on pot dump transistors
				allpot_next <= (others=>'0');
			end if;
			
			if (pot_reset_reg = '0') then
				if (pot_in(0) = '0') then -- pot now high, latch
					pot0_next <= pot_counter_reg;
				end if;
				if (pot_in(1) = '0') then -- pot now high, latch
					pot1_next <= pot_counter_reg;
				end if;				
				if (pot_in(2) = '0') then -- pot now high, latch
					pot2_next <= pot_counter_reg;
				end if;
				if (pot_in(3) = '0') then -- pot now high, latch
					pot3_next <= pot_counter_reg;
				end if;
				if (pot_in(4) = '0') then -- pot now high, latch
					pot4_next <= pot_counter_reg;
				end if;
				if (pot_in(5) = '0') then -- pot now high, latch
					pot5_next <= pot_counter_reg;
				end if;
				if (pot_in(6) = '0') then -- pot now high, latch
					pot6_next <= pot_counter_reg;
				end if;
				if (pot_in(7) = '0') then -- pot now high, latch
					pot7_next <= pot_counter_reg;
				end if;

				allpot_next <= allpot_reg and not(pot_in);
			end if;			
		end if;
			
		if (potgo_write = '1') then
			pot_counter_next <= (others=>'0');
			pot_reset_next <= '0'; -- turn off pot dump transistors, so they start to get charged
			allpot_next <= (others=>'1');
		end if;		
	end process;
	
	-- Outputs
	irq_n_out <= irq_n_reg;	
	
	CHANNEL_0_OUT <= volume_channel_0_reg;
	CHANNEL_1_OUT <= volume_channel_1_reg;
	CHANNEL_2_OUT <= volume_channel_2_reg;
	CHANNEL_3_OUT <= volume_channel_3_reg;
	
	sio_out1 <= sio_out_reg;	
	sio_out2 <= sio_out_reg;	
	sio_out3 <= sio_out_reg;	
	
	sio_clockout <= audf3_pulse when clock_input='0' else 'Z';
	
	pot_reset <= pot_reset_reg;
		
END vhdl;


