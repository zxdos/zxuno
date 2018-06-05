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
USE ieee.math_real.ceil;
USE ieee.math_real.log2;
use IEEE.STD_LOGIC_MISC.all;

ENTITY antic IS
GENERIC
(
	cycle_length : integer := 32 -- or 32...
);
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	RESET_N : IN STD_LOGIC;
	
	MEMORY_READY_ANTIC : IN STD_LOGIC;
	MEMORY_READY_CPU : IN STD_LOGIC;
	MEMORY_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	ANTIC_ENABLE_179 : IN std_logic;
	
	PAL : IN STD_LOGIC;
	
	lightpen : in std_logic;
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	NMI_N_OUT : OUT std_logic;
	ANTIC_READY : OUT std_logic; -- taken low by wsync writes
	
	-- GTIA interface
	AN : OUT STD_LOGIC_VECTOR(2 downto 0);
	COLOUR_CLOCK_ORIGINAL_OUT : out std_logic;
	COLOUR_CLOCK_OUT : out std_logic;
	HIGHRES_COLOUR_CLOCK_OUT : out std_logic; -- 2x to allow for half pixel modes
	
	-- DMA fetch
	dma_fetch_out : out std_logic;
	dma_address_out : out std_logic_vector(15 downto 0);
	
	-- refresh
	refresh_out : out std_logic; -- used by sdram
	
	-- for debugging
	dma_clock_out : out std_logic;
	hcount_out : out std_logic_vector(7 downto 0);
	vcount_out : out std_logic_vector(8 downto 0)
);
END antic;

ARCHITECTURE vhdl OF antic IS
	COMPONENT complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;
	
	COMPONENT antic_dma_clock IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_n : IN STD_LOGIC;
		enable_dma : IN STD_LOGIC;
		
		playfield_start : in std_logic;
		playfield_end : in std_logic;
		vblank : in std_logic;
		
		slow_dma : in std_logic;
		medium_dma : in std_logic;
		fast_dma : in std_logic;
				
		dma_clock_out_0 : out std_logic;
		dma_clock_out_1 : out std_logic;
		dma_clock_out_2 : out std_logic;
		dma_clock_out_3 : out std_logic
	);
	END component;
	
	component antic_counter IS
	generic
	(
		STORE_WIDTH : natural := 1;
		COUNT_WIDTH : natural := 1
	);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_n : IN STD_LOGIC;
		increment : in std_logic;
		load : IN STD_LOGIC;
		load_value : in std_logic_vector(STORE_WIDTH-1 downto 0);

		current_value : out std_logic_vector(STORE_WIDTH-1 downto 0)
	);
	END component;
	
	component simple_counter IS
	generic
	(
		COUNT_WIDTH : natural := 1
	);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_n : IN STD_LOGIC;
		increment : in std_logic;
		load : IN STD_LOGIC;
		load_value : in std_logic_vector(COUNT_WIDTH-1 downto 0);

		current_value : out std_logic_vector(COUNT_WIDTH-1 downto 0)
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
		
	component wide_delay_line IS
	generic(COUNT : natural := 1; WIDTH : natural :=1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		SYNC_RESET : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC_VECTOR(WIDTH-1 downto 0);
		ENABLE : IN STD_LOGIC; -- i.e. shift on this clock
		RESET_N : IN STD_LOGIC;
		
		DATA_OUT : OUT STD_LOGIC_VECTOR(WIDTH-1 downto 0)
	);
	END component;	

	component reg_file IS
	generic
	(
		BYTES : natural := 1;
		WIDTH : natural := 1
	);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		ADDR : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
		DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		WR_EN : IN STD_LOGIC;
		
		DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
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
	
	signal addr_decoded : std_logic_vector(15 downto 0);
	
	signal enable_dma : std_logic;
	signal dma_clock_character_name : std_logic;
	signal dma_clock_character_inc : std_logic;
	signal dma_clock_bitmap_data : std_logic;
	signal dma_clock_character_data : std_logic;
	
	signal wsync_next : std_logic;
	signal wsync_reg : std_logic;
	signal wsync_reset : std_logic;
	signal wsync_write : std_logic;
	signal wsync_delayed_write : std_logic;
	
	signal nmi_next : std_logic;
	signal nmi_reg : std_logic;
	
	signal nmi_shiftreg_next : std_logic_vector(15 downto 0);
	signal nmi_shiftreg_reg : std_logic_vector(15 downto 0);
	
	signal nmist_next : std_logic_vector(7 downto 5); -- dli/vbi/reset
	signal nmist_reg : std_logic_vector(7 downto 5);
	
	signal nmist_reset : std_logic;
	
	signal nmien_raw_next : std_logic_vector(7 downto 6); -- dli/vbi (reset always active)
	signal nmien_raw_reg : std_logic_vector(7 downto 6);
	signal nmien_delayed_reg : std_logic_vector(7 downto 6);
	
	signal dli_nmi_next : std_logic;
	signal vbi_nmi_next : std_logic;
	signal dli_nmi_reg : std_logic;
	signal vbi_nmi_reg : std_logic;
	
	signal nmi_reset : std_logic;
	--signal nmi_pending_next : std_logic; -- looks like on t65 the nmi_n is blocked by rdy being low, but not on real hardware?? XXX verify
	--signal nmi_pending_reg : std_logic;
	
	signal playfield_dma_start : std_logic;
	signal playfield_dma_end : std_logic;
	signal playfield_display_active_next : std_logic;
	signal playfield_display_active_reg : std_logic;
	
	signal dmactl_raw_next : std_logic_vector(6 downto 0);
	signal dmactl_raw_reg : std_logic_vector(6 downto 0);
	signal dmactl_delayed_reg : std_logic_vector(6 downto 0);
	signal dmactl_delayed_enabled : std_logic;

	signal playfield_dma_enabled : std_logic;
	
	signal chactl_next : std_logic_vector(2 downto 0);
	signal chactl_reg : std_logic_vector(2 downto 0);
	
	-- dma is only allowed during certain portions of the display
	signal allow_real_dma_next : std_logic;
	signal allow_real_dma_reg : std_logic;
	
	-- dma fetch handling
	-- dma is scheduled one cycle before it happens, so that registers can directly drive output	
	signal dma_fetch_next : std_logic;
	signal dma_fetch_reg : std_logic;
	signal dma_address_next : std_logic_vector(15 downto 0);
	signal dma_address_reg : std_logic_vector(15 downto 0);

	signal dma_cache_next : std_logic_vector(7 downto 0);
	signal dma_cache_reg : std_logic_vector(7 downto 0);
	signal dma_cache_ready_next : std_logic;
	signal dma_cache_ready_reg : std_logic;
	
	constant dma_fetch_line_buffer : std_logic_vector(2 downto 0) := "000";
	constant dma_fetch_shiftreg : std_logic_vector(2 downto 0) := "001";
	constant dma_fetch_null : std_logic_vector(2 downto 0) := "010";
	constant dma_fetch_instruction : std_logic_vector(2 downto 0) := "011";
	constant dma_fetch_list_low : std_logic_vector(2 downto 0) := "100";
	constant dma_fetch_list_high : std_logic_vector(2 downto 0) := "101";
	signal dma_fetch_destination_next : std_logic_vector(2 downto 0);
	signal dma_fetch_destination_reg : std_logic_vector(2 downto 0);
	signal dma_fetch_request : std_logic;
	
	signal display_list_address_low_temp_next : std_logic_vector(7 downto 0);
	signal display_list_address_low_temp_reg : std_logic_vector(7 downto 0);
	
	signal character_next : std_logic_vector(7 downto 0);
	signal character_reg : std_logic_vector(7 downto 0);
	signal displayed_character_next : std_logic_vector(7 downto 0);
	signal displayed_character_reg : std_logic_vector(7 downto 0);

	-- instruction decode
	signal instruction_next : std_logic_vector(7 downto 0);
	signal instruction_reg : std_logic_vector(7 downto 0);
	
	signal first_line_of_instruction_next : std_logic;
	signal first_line_of_instruction_reg: std_logic;

	signal last_line_of_instruction_live : std_logic;
	signal last_line_of_instruction_next : std_logic;
	signal last_line_of_instruction_reg: std_logic;
	
	signal force_final_row : std_logic;
	
	signal instruction_blank_reg : std_logic;
	signal instruction_blank_next : std_logic;

	--type dma_speed_type is (no_dma,slow_dma,medium_dma,fast_dma);
	--signal dma_speed_next : dma_speed_type;
	--signal dma_speed_reg : dma_speed_type;
	constant no_dma : std_logic_vector(1 downto 0) := "00";
	constant slow_dma : std_logic_vector(1 downto 0) := "01";
	constant medium_dma : std_logic_vector(1 downto 0) := "10";
	constant fast_dma : std_logic_vector(1 downto 0) := "11";
	signal dma_speed_next : std_logic_vector(1 downto 0);
	signal dma_speed_reg : std_logic_vector(1 downto 0);
	signal slow_dma_s,medium_dma_s,fast_dma_s : std_logic; -- remove me XXX
	
	--type instruction_type is (mode_character, mode_bitmap, mode_jvb, mode_jump, mode_blank);
	--signal instruction_type_next : instruction_type;
	--signal instruction_type_reg : instruction_type;
	constant mode_character : std_logic_vector(2 downto 0) := "000";
	constant mode_bitmap : std_logic_vector(2 downto 0) := "001";
	constant mode_jvb : std_logic_vector(2 downto 0) := "010";
	constant mode_jump : std_logic_vector(2 downto 0) := "011";
	constant mode_blank : std_logic_vector(2 downto 0) := "100";
	signal instruction_type_next : std_logic_vector(2 downto 0);
	signal instruction_type_reg : std_logic_vector(2 downto 0);
	
	signal two_part_instruction_next : std_logic;
	signal two_part_instruction_reg : std_logic;

		-- e.g. if instruction is 8 lines long then the final row is 7
	signal instruction_final_row_next : std_logic_vector(3 downto 0);
	signal instruction_final_row_reg : std_logic_vector(3 downto 0);
		
	--type shift_rate_type is (slow_shift,medium_shift,fast_shift);
	--signal shift_rate_next : shift_rate_type;
	--signal shift_rate_reg : shift_rate_type;
	constant slow_shift : std_logic_vector(1 downto 0) := "00";
	constant medium_shift : std_logic_vector(1 downto 0) := "01";
	constant fast_shift : std_logic_vector(1 downto 0) := "10";
	signal shift_rate_next : std_logic_vector(1 downto 0);
	signal shift_rate_reg : std_logic_vector(1 downto 0);
	
	signal shift_twobit_next : std_logic; -- Provide AN0 and AN1, or just AN0
	signal shift_twobit_reg : std_logic;
	
	signal twopixel_next : std_logic; -- GTIA should interpret output as two pixels
	signal twopixel_reg : std_logic;	
	
	signal single_colour_character_next : std_logic; -- for antic 6/7 where high two bits of character code determine colour
	signal single_colour_character_reg : std_logic;

	signal multi_colour_character_next : std_logic; -- for antic 4/5 where 2 bits + 1 bit of of character code determin colour
	signal multi_colour_character_reg : std_logic;
	
	signal twoline_character_next : std_logic; -- for antic 5/7
	signal twoline_character_reg : std_logic;
	
	signal map_background_next : std_logic; -- background,pf0,pf1,pf2 graphics modes or background,pf0 modes
	signal map_background_reg : std_logic;
	
	signal dli_enabled_next : std_logic;
	signal dli_enabled_reg : std_logic;
	
	signal descenders_next : std_logic; -- for mode 3
	signal descenders_reg : std_logic;
		
	-- Shift register used to output to AN2-AN0	
	-- Can either be loaded from memory or from the line buffer
	signal display_shift_next : std_logic_vector(7 downto 0);
	signal display_shift_reg : std_logic_vector(7 downto 0);
	
	signal delay_display_shift_next : std_logic_vector(24 downto 0);
	signal delay_display_shift_reg : std_logic_vector(24 downto 0);
	
	signal data_live : std_logic_vector(1 downto 0); -- helper for chatctl
	
	signal load_display_shift_from_memory : std_logic;
	signal load_display_shift_from_line_buffer : std_logic;
	
	signal enable_shift : std_logic;
	signal shiftclock_next : std_logic_vector(3 downto 0);
	signal shiftclock_reg : std_logic_vector(3 downto 0);
	
	signal playfield_reset : std_logic;
	signal playfield_load : std_logic;
	
	-- position in frame	
	signal hcount_next : std_logic_vector(7 downto 0);
	signal hcount_reg : std_logic_vector(7 downto 0);
	
	signal vcount_next : std_logic_vector(8 downto 0);
	signal vcount_reg : std_logic_vector(8 downto 0);
	
	signal vblank_next : std_logic;
	signal vblank_reg : std_logic;
	signal vsync_next : std_logic;
	signal vsync_reg : std_logic;
	
	signal hblank_next : std_logic;
	signal hblank_reg : std_logic;
	
	signal playfield_dma_start_cycle : std_logic_vector(7 downto 0);
	signal playfield_dma_end_cycle : std_logic_vector(7 downto 0);
	signal playfield_display_start_cycle : std_logic_vector(7 downto 0);
	signal playfield_display_end_cycle : std_logic_vector(7 downto 0);
	
	signal hcount_reset : std_logic;
	signal vcount_reset : std_logic;
	signal vcount_increment : std_logic;
	
	-- scrolling	
	signal hscrol_reg : std_logic_vector(3 downto 0);
	signal hscrol_next : std_logic_vector(3 downto 0);

	signal vscrol_raw_reg : std_logic_vector(3 downto 0);
	signal vscrol_raw_next : std_logic_vector(3 downto 0);
	signal vscrol_delayed_reg : std_logic_vector(3 downto 0);
	
	signal vscrol_enabled_reg : std_logic;
	signal vscrol_enabled_next : std_logic;
	signal vscrol_last_enabled_reg : std_logic;
	signal vscrol_last_enabled_next : std_logic;
	
	signal update_row_count : std_logic;
	
	signal hscrol_enabled_reg : std_logic;
	signal hscrol_enabled_next : std_logic;

	-- refresh
	signal refresh_pending_next : std_logic;
	signal refresh_pending_reg : std_logic;

	signal refresh_fetch_next : std_logic;
	signal refresh_fetch_reg : std_logic;
	
	-- Counter signals
	signal increment_display_list_address : std_logic;
	signal load_display_list_address : std_logic;
	signal display_list_address_next : std_logic_vector(15 downto 0);
	signal display_list_address_reg : std_logic_vector(15 downto 0);
	signal load_display_list_address_cpu : std_logic;
	signal load_display_list_address_dma : std_logic;
	signal display_list_address_next_cpu : std_logic_vector(15 downto 0);
	signal display_list_address_next_dma : std_logic_vector(15 downto 0);	

	signal increment_memory_scan_address : std_logic;
	signal load_memory_scan_address : std_logic;
	signal memory_scan_address_next : std_logic_vector(15 downto 0);
	signal memory_scan_address_reg : std_logic_vector(15 downto 0);

	signal increment_line_buffer_address : std_logic;
	signal load_line_buffer_address : std_logic;
	signal line_buffer_address_next : std_logic_vector(7 downto 0);
	signal line_buffer_address_reg : std_logic_vector(7 downto 0);

	signal increment_row_count : std_logic;
	signal load_row_count : std_logic;
	signal row_count_next : std_logic_vector(3 downto 0);
	signal row_count_reg : std_logic_vector(3 downto 0);

	signal increment_refresh_count : std_logic;
	signal load_refresh_count : std_logic;
	signal refresh_count_next : std_logic_vector(3 downto 0);
	signal refresh_count_reg : std_logic_vector(3 downto 0);
	
	signal pmbase_reg : std_logic_vector(7 downto 2);
	signal pmbase_next : std_logic_vector(7 downto 2);

	signal chbase_raw_reg : std_logic_vector(7 downto 1);
	signal chbase_raw_next : std_logic_vector(7 downto 1);
	signal chbase_delayed_reg : std_logic_vector(7 downto 1);
	
	signal line_buffer_write : std_logic;
	signal line_buffer_data_in : std_logic_vector(7 downto 0);
	signal line_buffer_data_out : std_logic_vector(7 downto 0);
	
	-- output registers
	signal an_current : std_logic_vector(2 downto 0); -- live unregistered calculation of next output (not gated by cc)
	signal an_prev_next : std_logic_vector(2 downto 0); -- previous - for hscrol
	signal an_prev_reg : std_logic_vector(2 downto 0);  -- previous - for hscrol
	signal an_next : std_logic_vector(2 downto 0);
	signal an_reg : std_logic_vector(2 downto 0);
	
	-- light pendin
	signal penv_next : std_logic_vector(7 downto 0);
	signal penv_reg : std_logic_vector(7 downto 0);
	signal penh_next : std_logic_vector(7 downto 0);
	signal penh_reg : std_logic_vector(7 downto 0);
	
	-- high res modes
	signal colour_clock_8x : std_logic;
	signal colour_clock_4x : std_logic;
	signal colour_clock_2x : std_logic;
	signal colour_clock_1x : std_logic;
	signal colour_clock_half_x : std_logic;
	signal colour_clock_selected : std_logic;
	signal colour_clock_selected_highres : std_logic;
	
	constant cycle_length_bits: integer := integer(ceil(log2(real(cycle_length))));
	signal colour_clock_count_next : std_logic_vector(cycle_length_bits-1 downto 0);
	signal colour_clock_count_reg : std_logic_vector(cycle_length_bits-1 downto 0);
	signal colour_clock_count_reg_topthree : std_logic_vector(2 downto 0);
	
	signal memory_ready_both : std_logic;
	
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			nmi_reg <= '0';
			wsync_reg <= '0';
			vcount_reg <= (others=>'0');
			--hcount_reg <= X"01";
			hcount_reg <= X"00";
			dmactl_raw_reg <= (others=>'0');
			chactl_reg <= (others=>'0');
			vblank_reg <= '0';			
			vsync_reg <= '0';
			pmbase_reg <= (others=>'0');
			allow_real_dma_reg <= '0';
			display_shift_reg <= (others=>'0');
			chbase_raw_reg <= (others=>'0');
			
			instruction_reg <= (others=>'0');
			first_line_of_instruction_reg <= '0';
			last_line_of_instruction_reg <= '0';
			dma_speed_reg <= no_dma;
			instruction_type_reg <= mode_blank;
			instruction_final_row_reg <= (others=>'0');
			shift_rate_reg <= slow_shift;
			shift_twobit_reg <= '0';
			twopixel_reg <= '0';
			single_colour_character_reg <= '0';
			multi_colour_character_reg <= '0';
			twoline_character_reg <= '0';
			map_background_reg <= '0';
			dli_enabled_reg <= '0';
			two_part_instruction_reg <= '0';
			descenders_reg <='0';
			
			hscrol_reg <= (others=>'0');
			vscrol_raw_reg <= (others=>'0');			
			vscrol_enabled_reg <= '0';
			vscrol_last_enabled_reg <= '0';
			hscrol_enabled_reg <= '0';
			
			shiftclock_reg <= (others=>'0');
			
			hblank_reg <= '0';
			
			an_reg <= (others=>'0');
			an_prev_reg <= (others=>'0');
			
			dma_fetch_reg <= '0';
			dma_address_reg <= (others=>'0');			
			dma_cache_reg <= (others=>'0');
			dma_cache_ready_reg <= '0';
			dma_fetch_destination_reg <= dma_fetch_null;
			
			playfield_display_active_reg <= '0';
			
			instruction_blank_reg <= '0';
			
			display_list_address_low_temp_reg <= (others=>'0');
			
			character_reg <= (others=>'0');
			displayed_character_reg <= (others=>'0');
			
			refresh_pending_reg <= '0';
			refresh_fetch_reg <= '0';
			
			--nmi_pending_reg <= '0';
			
			dli_nmi_reg <= '0';
			vbi_nmi_reg <= '0';
			nmien_raw_reg <= (others=>'0');
			
			delay_display_shift_reg <= (others=>'0');
			
			nmi_shiftreg_reg <= (others=>'1');
			
			penh_reg <= (others=>'0');
			penv_reg <= (others=>'0');
			
			colour_clock_count_reg <= (others=>'0');
			
		elsif (clk'event and clk='1') then			
			nmi_reg <= nmi_next;
			wsync_reg <= wsync_next;
			vcount_reg <= vcount_next;
			hcount_reg <= hcount_next;
			nmist_reg <= nmist_next;
			dmactl_raw_reg <= dmactl_raw_next;
			chactl_reg <= chactl_next;
			vblank_reg <= vblank_next;
			vsync_reg <= vsync_next;
			pmbase_reg <= pmbase_next;
			allow_real_dma_reg <= allow_real_dma_next;
			display_shift_reg <= display_shift_next;
			chbase_raw_reg <= chbase_raw_next;
			
			instruction_reg <= instruction_next;
			first_line_of_instruction_reg <= first_line_of_instruction_next;
			last_line_of_instruction_reg <= last_line_of_instruction_next;
			dma_speed_reg <= dma_speed_next;
			instruction_type_reg <= instruction_type_next;
			instruction_final_row_reg <= instruction_final_row_next;
			shift_rate_reg <= shift_rate_next;
			shift_twobit_reg <= shift_twobit_next;
			twopixel_reg <= twopixel_next;
			single_colour_character_reg <= single_colour_character_next;
			multi_colour_character_reg <= multi_colour_character_next;
			twoline_character_reg <= twoline_character_next;
			map_background_reg <= map_background_next;
			dli_enabled_reg <= dli_enabled_next;
			two_part_instruction_reg <= two_part_instruction_next;
			descenders_reg <= descenders_next;
			
			hscrol_reg <= hscrol_next;
			vscrol_raw_reg <= vscrol_raw_next;	
			vscrol_enabled_reg <= vscrol_enabled_next;
			vscrol_last_enabled_reg <= vscrol_last_enabled_next;
			hscrol_enabled_reg <= hscrol_enabled_next;
			
			shiftclock_reg <= shiftclock_next;
			
			hblank_reg <= hblank_next;
			
			an_reg <= an_next;
			an_prev_reg <= an_prev_next;
			
			dma_fetch_reg <= dma_fetch_next;
			dma_address_reg <= dma_address_next;
			dma_cache_reg <= dma_cache_next;
			dma_cache_ready_reg <= dma_cache_ready_next;
			dma_fetch_destination_reg <= dma_fetch_destination_next;
			
			playfield_display_active_reg <= playfield_display_active_next;
			
			instruction_blank_reg <= instruction_blank_next;
			
			display_list_address_low_temp_reg <= display_list_address_low_temp_next;
			
			character_reg <= character_next;
			displayed_character_reg <= displayed_character_next;
			
			refresh_pending_reg <= refresh_pending_next;
			refresh_fetch_reg <= refresh_fetch_next;
						
			dli_nmi_reg <= dli_nmi_next;
			vbi_nmi_reg <= vbi_nmi_next;
			nmien_raw_reg <= nmien_raw_next;
			
			delay_display_shift_reg <= delay_display_shift_next;
			
			nmi_shiftreg_reg <= nmi_shiftreg_next;
			
			penh_reg <= penh_next;
			penv_reg <= penv_next;
			
			colour_clock_count_reg <= colour_clock_count_next;
		end if;
	end process;
	
	-- Colour clock (3.57MHz for PAL)
	-- TODO - allow double for 640 pixel width and quadruple for 1280 pixel width)
	-- TODO - allow other clocks for driving VGA (mostly higher dot clock + line doubling (buffer between antic and gtia??))

        colour_clock_count_reg_topthree <= colour_clock_count_reg(cycle_length_bits-1 downto cycle_length_bits-3);
	process(colour_clock_count_reg, colour_clock_count_reg_topthree, ANTIC_ENABLE_179)		
	begin
		colour_clock_half_x <= '0';
		colour_clock_1x<='0';
		colour_clock_2x<='0';
		colour_clock_4x<='0';
		colour_clock_8x<='0';
	
		colour_clock_count_next <= std_logic_vector(unsigned(colour_clock_count_reg) + 1);
		
		if (ANTIC_ENABLE_179 = '1') then -- resync...
			colour_clock_count_next <= std_logic_vector(to_unsigned(1,cycle_length_bits));
		end if;

		colour_clock_8x <= '1';
		
		if (or_reduce(colour_clock_count_reg( cycle_length_bits-4 downto 0)) = '0') then
			case colour_clock_count_reg_topthree is
			when "000" =>
				colour_clock_half_x <= '1';
				colour_clock_1x <= '1';
				colour_clock_2x <= '1';
				colour_clock_4x <= '1';
			when "001" =>
				colour_clock_4x <= '1';
			when "010" =>
				colour_clock_2x <= '1';			
				colour_clock_4x <= '1';			
			when "011" =>
				colour_clock_4x <= '1';
			when "100" =>			
				colour_clock_1x <= '1';
				colour_clock_2x <= '1';
				colour_clock_4x <= '1';
			when "101" =>
				colour_clock_4x <= '1';
			when "110" =>
				colour_clock_2x <= '1';			
				colour_clock_4x <= '1';			
			when "111" =>
				colour_clock_4x <= '1';			
			when others =>
				-- nop
			end case;
		end if;
	end process;
	
	process(colour_clock_half_x,colour_clock_1x,colour_clock_2x, colour_clock_4x, colour_clock_8x, dmactl_delayed_reg)
	begin
		enable_dma <= colour_clock_half_x;
		colour_clock_selected <= colour_clock_1x;
		colour_clock_selected_highres <= colour_clock_2x;		
		dmactl_delayed_enabled <= '0';
		
		case dmactl_delayed_reg(6 downto 5) is
		when "01" =>
			dmactl_delayed_enabled <= '1';
		when "10" =>
			enable_dma <= colour_clock_1x;
			colour_clock_selected <= colour_clock_2x;		
			colour_clock_selected_highres <= colour_clock_4x;
			dmactl_delayed_enabled <= '1';
		when "11" =>
			enable_dma <= colour_clock_2x;
			colour_clock_selected <= colour_clock_4x;
			colour_clock_selected_highres <= colour_clock_8x;
			dmactl_delayed_enabled <= '1';
		when others =>
			--nop
		end case;		
	end process;	
		
	-- Counters (memory address for data, memory address for display list)
	antic_counter_memory_scan : antic_counter
		generic map (STORE_WIDTH=>16, COUNT_WIDTH=>12)
		port map (clk=>clk, reset_n=>reset_n, increment=>increment_memory_scan_address, load=>load_memory_scan_address, load_value=>memory_scan_address_next, current_value=>memory_scan_address_reg);
		
	load_display_list_address <= load_display_list_address_cpu or load_display_list_address_dma;
	display_list_address_next <= display_list_address_next_cpu when load_display_list_address_cpu='1' else display_list_address_next_dma;
	antic_counter_display_list : antic_counter
		generic map (STORE_WIDTH=>16, COUNT_WIDTH=>10)
		port map (clk=>clk, reset_n=>reset_n, increment=>increment_display_list_address, load=>load_display_list_address, load_value=>display_list_address_next, current_value=>display_list_address_reg);
	antic_counter_line_buffer : simple_counter
		generic map (COUNT_WIDTH=>8)
		port map (clk=>clk, reset_n=>reset_n, increment=>increment_line_buffer_address, load=>load_line_buffer_address, load_value=>line_buffer_address_next, current_value=>line_buffer_address_reg);
	antic_counter_row_count : simple_counter
		generic map (COUNT_WIDTH=>4)
		port map (clk=>clk, reset_n=>reset_n, increment=>increment_row_count, load=>load_row_count, load_value=>row_count_next, current_value=>row_count_reg);
	antic_counter_refresh_count : simple_counter
		generic map (COUNT_WIDTH=>4)
		port map (clk=>clk, reset_n=>reset_n, increment=>increment_refresh_count, load=>load_refresh_count, load_value=>refresh_count_next, current_value=>refresh_count_reg);
	
	-- Count position on screen
	-- horizontal
	process(hcount_reg, colour_clock_1x, colour_clock_half_x, hcount_reset)
	begin
		hcount_next <= hcount_reg;		
		if (colour_clock_1x = '1') then
			hcount_next <= std_logic_vector(unsigned(hcount_reg)+1);
			
			if (colour_clock_half_x = '1') then
				hcount_next(0) <= '1';
			end if;
		end if;
		
		if (hcount_reset = '1') then
			hcount_next <= (others=>'0');
		end if;
	end process;
	
	-- vertical
	process(vcount_reg, vcount_increment, vcount_reset, colour_clock_1x)
	begin
		vcount_next <= vcount_reg;
		
		if (colour_clock_1x = '1') then		
			if (vcount_increment = '1') then
				vcount_next <= std_logic_vector(unsigned(vcount_reg)+1);
			end if;
			
			if (vcount_reset = '1') then
				vcount_next <= (others=>'0');
			end if;
		end if;
	end process;	
	
	-- Actions done based on vertical position		
	process(vcount_reg, vblank_reg, vsync_reg, colour_clock_1x,vcount_increment,pal)
	begin
		vblank_next <= vblank_reg;
		vsync_next <= vsync_reg;
		vcount_reset <= '0';
	
		if (colour_clock_1x='1') then
			case vcount_reg is
				when '0'&X"08" => 
					vblank_next <= '0';
				when '0'&X"F8" =>
					vblank_next <= '1';
				--when '1'&X"05" => (changed for testing galaxian!)
				--	vblank_next <= '1';					
-- PAL
				when '1'&X"13" =>
					vsync_next <= pal;
				when '1'&X"16" =>
					vsync_next <= '0';
				when '1'&X"38" =>
					vcount_reset <= '1'; -- Blip at 9c..., then wrap
-- NTSC
				when '0'&X"FF" =>
					vsync_next <= not(pal);
				when '1'&X"02" =>
					vsync_next <= '0';
				when '1'&X"06" =>
					vcount_reset <= not(pal); -- Blip at 9c..., then wrap
				when others =>
					-- nothing
			end case;
		end if;
	end process;
	
	-- Calculate playfield start/end
	process(hscrol_enabled_reg, dmactl_delayed_reg, hscrol_reg)
	begin		
		playfield_dma_start_cycle <= (others=>'1');
		playfield_dma_end_cycle <= (others=>'1');
		playfield_display_start_cycle <= (others=>'1');
		playfield_display_end_cycle <= (others=>'1');

		playfield_dma_enabled <= dmactl_delayed_reg(1) or dmactl_delayed_reg(0); -- TODO, more work needed here
		
		-- DMA clock start/end
		-- wide=3, normal=2, narrow=1
		-- Playfield start is at (in colour clocks):
		-- 68 + hscrol&FE - width*16
		-- i.e. for width=3 and hscrol=0 -> 68+0-48 = 20 (10 in cycles)
		-- i.e. for width=2 and hscrol=0 -> 68+0-32 = 36 (18 in cycles)
		-- i.e. for width=1 and hscrol=0 -> 68+0-16 = 52 (26 in cycles)
		-- MUST BE A NICE EASY WAY TO GET THIS - expect offset is wrong... 
		-- e.g. if its 64 then we may be able to do something like base&width&
		-- Playfield end is at (in colour clocks):
		-- 164 + hscrol&FE + width*16
		-- i.e. for width=3 and hscrol=0 -> 164+0+48 = 212 (106 in cycles)
		-- i.e. for width=2 and hscrol=0 -> 164+0+32 = 192 (96 in cycles)
		-- i.e. for width=1 and hscrol=0 -> 164+0+16 = 180 (92 in cycles)
		
		-- hscrol interfers with playfield dma width (for dma purposes only!)
		if (hscrol_enabled_reg='1') then
			case dmactl_delayed_reg(1 downto 0) is
				when "10"|"11" => -- normal and wide - both treated as wide due to hscrol
					playfield_dma_start_cycle <= X"1"&hscrol_reg(3 downto 1)&'1'; -- 20  (10 in machine cycles)
					playfield_dma_end_cycle   <= X"D"&hscrol_reg(3 downto 1)&'0'; -- 212 (106 in machine cycles)
				when "01" => -- narrow - traated as normal due to hscrol
					playfield_dma_start_cycle <= X"2"&hscrol_reg(3 downto 1)&'1'; -- 36  (18 in machine cycles)
					playfield_dma_end_cycle <=   X"C"&hscrol_reg(3 downto 1)&'0'; -- 196 (98 in machine cycles)
				when others =>
					-- nothing
			end case;
		else
			case dmactl_delayed_reg(1 downto 0) is
				when "11" => -- wide
					playfield_dma_start_cycle <= X"11";
					playfield_dma_end_cycle   <= X"D0";
				when "10" => -- normal
					playfield_dma_start_cycle <= X"21";
					playfield_dma_end_cycle   <= X"C0";
				when "01" => -- narrow
					playfield_dma_start_cycle <= X"31";
					playfield_dma_end_cycle <=   X"B0";
				when others =>
					-- nothing
			end case;		
		end if;

		-- background colour outside this area...
		-- TODO - review these locations - should be clear due to garbage!
		case dmactl_delayed_reg(1 downto 0) is
			when "11" => -- wide
				playfield_display_start_cycle <= X"2B"; -- TODO work out correct noise on left for large hscrol
				if (hscrol_reg > X"C") then
					playfield_display_start_cycle <= X"2F"; -- TODO work out correct noise on left for large hscrol				
				end if;
				playfield_display_end_cycle   <= X"DD"; -- last two colour clocks are corrupt (ie dc to dd), then there are two missing...
			when "10" => -- normal
				playfield_display_start_cycle <= X"2F";
				playfield_display_end_cycle   <= X"CF";
			when "01" => -- narrow
				playfield_display_start_cycle <= X"3F";
				playfield_display_end_cycle <=   X"BF";
			when others =>
				-- nothing
		end case;				
	end process;
	
	-- Actions done based on horizontal position - notably dma!
	process (dmactl_delayed_enabled, hcount_reg, vcount_reg, vblank_reg, hblank_reg, dmactl_delayed_reg, playfield_dma_start_cycle, playfield_dma_end_cycle, playfield_display_start_cycle, playfield_display_end_cycle, instruction_final_row_reg, display_list_address_reg, pmbase_reg, first_line_of_instruction_reg, last_line_of_instruction_live, last_line_of_instruction_reg, instruction_type_reg, dma_clock_character_name, dma_clock_character_data, dma_clock_bitmap_data, allow_real_dma_reg, row_count_reg, dma_address_reg, memory_scan_address_reg, chbase_delayed_reg, line_buffer_data_out, enable_dma, colour_clock_1x, two_part_instruction_reg, dma_fetch_destination_reg, playfield_display_active_reg, character_reg, dma_clock_character_inc, single_colour_character_reg, twoline_character_reg, instruction_reg, dli_enabled_reg, refresh_fetch_next, chactl_reg, vscrol_enabled_reg, vscrol_last_enabled_reg,twopixel_reg,dli_nmi_reg,vbi_nmi_reg,displayed_character_reg, playfield_dma_enabled)
	begin
		allow_real_dma_next <= allow_real_dma_reg;

		playfield_dma_start <= '0';
		playfield_dma_end <= '0';
		playfield_display_active_next <= playfield_display_active_reg;
		
		dma_fetch_request <= '0';
		dma_address_next <= dma_address_reg;
		dma_fetch_destination_next <= dma_fetch_destination_reg;
		
		first_line_of_instruction_next <= first_line_of_instruction_reg;
		last_line_of_instruction_next <= last_line_of_instruction_reg;
		
		load_display_shift_from_line_buffer <= '0';
				
		increment_memory_scan_address <= '0';
		
		line_buffer_address_next <= (others=>'0');
		load_line_buffer_address <= '0';
		increment_line_buffer_address <= '0';
		
		playfield_load <= '0';
		
		hblank_next <= hblank_reg;
		hcount_reset <= '0';
		
		vcount_increment <= '0';
		
		character_next <= character_reg;
		displayed_character_next <= displayed_character_reg;
		
		dli_nmi_next <= dli_nmi_reg;
		vbi_nmi_next <= vbi_nmi_reg;
		wsync_reset <= '0';
		
		load_refresh_count <= '0';
		refresh_count_next <= (others=>'0');
		
		update_row_count <= '0'; 
		vscrol_last_enabled_next <= vscrol_last_enabled_reg;
	
		if (colour_clock_1x = '1') then	
			-- Playfield start/end
			if (unsigned(hcount_reg) = (unsigned(playfield_dma_start_cycle))) then
				playfield_dma_start <= '1';				
				load_line_buffer_address <= '1';
			end if;
			
			if (unsigned(hcount_reg) = (unsigned(playfield_dma_end_cycle))) then
				playfield_dma_end <= '1';
			end if;	
			
			if (hcount_reg = playfield_display_start_cycle) then
				playfield_display_active_next <= '1';				
			end if;
			
			if (hcount_reg = playfield_display_end_cycle) then
				playfield_display_active_next <= '0';
			end if;	

			if (dma_clock_character_data = '1') then -- Final cycle of this is cycle 114 (0 based) - aka cycle 0... Which clashes with pmg dma.
				if (dmactl_delayed_enabled='1' and instruction_type_reg = mode_character) then -- Sooo only enable, never disable
					dma_fetch_request <= '1';
				end if;				

				if (twoline_character_reg='1') then
					if (single_colour_character_reg='1') then
						dma_address_next <= chbase_delayed_reg(7 downto 1)&character_reg(5 downto 0)&(row_count_reg(3 downto 1)xor chactl_reg(2)&chactl_reg(2)&chactl_reg(2));
					else
						dma_address_next <= chbase_delayed_reg(7 downto 2)&character_reg(6 downto 0)&(row_count_reg(3 downto 1)xor chactl_reg(2)&chactl_reg(2)&chactl_reg(2));
					end if;
				else
					if (single_colour_character_reg='1') then
						dma_address_next <= chbase_delayed_reg(7 downto 1)&character_reg(5 downto 0)&(row_count_reg(2 downto 0)xor chactl_reg(2)&chactl_reg(2)&chactl_reg(2));
					else
						dma_address_next <= chbase_delayed_reg(7 downto 2)&character_reg(6 downto 0)&(row_count_reg(2 downto 0)xor chactl_reg(2)&chactl_reg(2)&chactl_reg(2));
					end if;
				end if;

				displayed_character_next <= character_reg;
				
				-- TODO
				-- Logic depends on mode - e.g. some 128 char, some 64 char etc. Line count is complex, depends on vscrol etc.				
				dma_fetch_destination_next <= dma_fetch_shiftreg;
				
				load_display_shift_from_line_buffer <= to_std_logic(instruction_type_reg = mode_bitmap);								
				increment_line_buffer_address <= '1';
			end if;						
		
			case hcount_reg is 		
				when X"00" => -- missile DMA, if missile or player DMA enabled					
					dma_fetch_request <= dmactl_delayed_reg(2) or dmactl_delayed_reg(3);
					dma_fetch_destination_next <= dma_fetch_null;									
					if (dmactl_delayed_reg(4) = '1') then -- single line resolution
						dma_address_next <= pmbase_reg(7 downto 3)&"011"&vcount_reg(7 downto 0);
					else
						dma_address_next <= pmbase_reg(7 downto 2)&"011"&vcount_reg(7 downto 1);
					end if;
					
				when X"02" => -- display list dma if enabled
					first_line_of_instruction_next <= '0';
					
					if (instruction_type_reg = mode_jvb) then
						-- suppress when waiting for vblank
						first_line_of_instruction_next <= first_line_of_instruction_reg or vblank_reg;
					else				
						if (last_line_of_instruction_reg = '1') then -- set on previous line at cycle 108
							dma_fetch_request <= dmactl_delayed_enabled;
							dma_address_next <= display_list_address_reg;
							dma_fetch_destination_next <= dma_fetch_instruction;									
							
							first_line_of_instruction_next <= '1';						
							
							vscrol_last_enabled_next <= vscrol_enabled_reg;
						end if;
					end if;					
				
				when X"05" =>				
					update_row_count <= '1'; -- done after instruction fetch...
					
				when X"04"|X"06"|X"08"|X"0A" =>  -- player DMA, if enabled
					dma_fetch_request <= dmactl_delayed_reg(3);
					dma_fetch_destination_next <= dma_fetch_null;	
					if (dmactl_delayed_reg(4) = '1') then -- single line resolution
						dma_address_next <= pmbase_reg(7 downto 3)&std_logic_vector(unsigned(hcount_reg(3 downto 1))+2)&vcount_reg(7 downto 0);
					else
						dma_address_next <= pmbase_reg(7 downto 2)&std_logic_vector(unsigned(hcount_reg(3 downto 1))+2)&vcount_reg(7 downto 1);
					end if;
					
				when X"0C" => -- lms lower byte dma if display list dma enabled?;
					dma_fetch_request <= dmactl_delayed_enabled and first_line_of_instruction_reg and two_part_instruction_reg;
					dma_address_next <= display_list_address_reg;				
					dma_fetch_destination_next <= dma_fetch_list_low;
				
				when X"0E" => -- lms upper byte dma if display list dma enabled?
					dma_fetch_request <= dmactl_delayed_enabled and first_line_of_instruction_reg and two_part_instruction_reg;
					dma_address_next <= display_list_address_reg;				
					dma_fetch_destination_next <= dma_fetch_list_high;
					
					if (instruction_type_reg = mode_jvb) then
						-- turn off this extra dma for jvb mode, re-enabled by vblank_reg
						first_line_of_instruction_next <= '0';
					end if;
					
					dli_nmi_next <= dli_enabled_reg and last_line_of_instruction_live and not vblank_reg;
					if (vcount_reg = '0'&X"F8") then
						vbi_nmi_next <= '1';
					end if;
					
				when X"12" =>
					dli_nmi_next <= '0';
					vbi_nmi_next <= '0';

				when X"21" =>
					hblank_next <= '0';					
					
				when X"24" => 
					playfield_load <= '1'; -- start the shift register
					
				when X"31" => -- start refresh					
					load_refresh_count <= '1';
					refresh_count_next <= (others=>'0');
				
				when X"D2" => -- cycle 105 - reset wsync so we process from 105 on
					wsync_reset <= '1';				
			
				when X"D4" => -- Force playfield DMA into virtual mode (cycle 105)
					allow_real_dma_next <= '0';				
					load_refresh_count <= '1';
					refresh_count_next <= "1001";
					
				when X"D8" => -- vscrol value checked at cycle 108
					last_line_of_instruction_next <= last_line_of_instruction_live;
				
				when X"DE" => -- Increment vcount immediately before cycle 111 (again the 4 offset as seen in hscrol...)
					vcount_increment <= '1';
										
				when X"DD" =>
					hblank_next <= '1';					
					
				when X"E3" => -- Wrap hcount after 227 (i.e. 0 to 227)
					hcount_reset <= '1';
					allow_real_dma_next <= not(vblank_reg);
				when others =>
					-- nothing
			end case;	
			
			-- Playfield DMA
			if (instruction_type_reg = mode_character and dma_clock_character_name = '1') then -- for character name
				dma_fetch_request <= dmactl_delayed_enabled and first_line_of_instruction_reg and playfield_dma_enabled;
				dma_address_next <= memory_scan_address_reg;
				dma_fetch_destination_next <= dma_fetch_line_buffer;
				increment_memory_scan_address <= first_line_of_instruction_reg;
			end if;					
			
			if (instruction_type_reg = mode_character and dma_clock_character_inc = '1') then -- next character
				character_next <= line_buffer_data_out;
				increment_line_buffer_address <= '1';
			end if;
			
			if (instruction_type_reg = mode_bitmap and dma_clock_bitmap_data = '1' and first_line_of_instruction_reg='1') then -- bitmap data			
				dma_fetch_request <= dmactl_delayed_enabled and playfield_dma_enabled;
				dma_address_next <= memory_scan_address_reg;
				dma_fetch_destination_next <= dma_fetch_line_buffer;
				increment_memory_scan_address <= '1';		
			end if;
			
			if (vblank_reg = '1') then
				dma_fetch_request <= '0';
			end if;
			
			if (refresh_fetch_next = '1') then
				dma_address_next <= (others=>'0');
			end if;
		
		end if;
	end process;
	
	-- refresh handling
	process(hcount_reg,refresh_count_reg,colour_clock_1x,dma_fetch_next,refresh_pending_reg, refresh_fetch_reg, allow_real_dma_next)
	begin
		increment_refresh_count <= '0';
		refresh_pending_next <= refresh_pending_reg;
		refresh_fetch_next <= refresh_fetch_reg;
		
		if (colour_clock_1x = '1' and hcount_reg(0) = '0') then
			refresh_fetch_next <= '0';
		
			-- do pending refresh once we have a spare cycle
			if (refresh_pending_reg='1' and (dma_fetch_next='0' or allow_real_dma_next='0')) then
				refresh_fetch_next <= '1';		
				refresh_pending_next <= '0';
			end if;
		
			-- do scheduled refresh - if block, enable pending one
			if (hcount_reg(2 downto 1) = "01" and unsigned(refresh_count_reg)<9) then
				increment_refresh_count <= '1';
				refresh_fetch_next <= not(dma_fetch_next);
				refresh_pending_next <= dma_fetch_next;
			end if;
		end if;
	end process;
	
	process(refresh_fetch_next)
	begin
	end process;
	
	-- nmi handling
	-- edge senstive, single cycle is enough (unless cpu disabled or  clashes)
	-- antic asserts for 2 old cycles - if we stick to that then in turbo mode it fixes most nmi bugs, in normal mode they still exist...	which is the goal.	

	nmien_delay : wide_delay_line
		generic map (COUNT=>cycle_length,WIDTH=>2)
		port map (clk=>clk,sync_reset=>'0',data_in=>nmien_raw_reg(7 downto 6),enable=>'1',reset_n=>reset_n,data_out=>nmien_delayed_reg(7 downto 6));
		
	nmi_next <= not((dli_nmi_reg and nmien_delayed_reg(7)) or (vbi_nmi_reg and nmien_delayed_reg(6)));
	
	process(nmist_reg, vbi_nmi_reg, dli_nmi_reg, vbi_nmi_next, dli_nmi_next, nmist_reset)
	begin	
		nmist_next(5) <= '0';
		nmist_next(6) <= ((nmist_reg(6) and not(nmist_reset)) or vbi_nmi_reg or vbi_nmi_next) and not(dli_nmi_reg or dli_nmi_next); -- auto clear vbi flat on dli!
		nmist_next(7) <= ((nmist_reg(7) and not(nmist_reset))or dli_nmi_reg or dli_nmi_next) and not(vbi_nmi_reg or vbi_nmi_next); -- auto clear dli flag on vbi!
	end process;
	
	-- dma clock	
	process(dma_speed_reg) -- XXX TODO - remove this process!
	begin
		slow_dma_s <= '0';
		medium_dma_s <= '0';
		fast_dma_s <= '0';
		
		case dma_speed_reg is
			when no_dma =>
				-- nothing
			when slow_dma =>
				slow_dma_s <= '1';
			when medium_dma =>
				medium_dma_s <= '1';
			when fast_dma =>
				fast_dma_s <= '1';
			when others =>
				-- nothing
		end case;
	end process;
	
	antic_dma_clock1 : antic_dma_clock
		port map (clk=>clk, reset_n=>reset_n,enable_dma=>enable_dma, playfield_start=>playfield_dma_start,playfield_end=>playfield_dma_end,vblank=>vblank_reg,slow_dma=>slow_dma_s,medium_dma=>medium_dma_s,fast_dma=>fast_dma_s,dma_clock_out_0=>dma_clock_character_name,dma_clock_out_1=>dma_clock_character_inc,dma_clock_out_2=>dma_clock_bitmap_data,dma_clock_out_3=>dma_clock_character_data);

	-- line buffer
	reg_file1 : reg_file
		generic map (BYTES=>48, WIDTH=>6) -- TODO:reset after 63, not 64?
		port map (clk=>clk,addr=>line_buffer_address_reg(5 downto 0),data_in=>line_buffer_data_in,wr_en=>line_buffer_write, data_out=>line_buffer_data_out);		
		--generic map (BYTES=>192, WIDTH=>8) -- TODO:reset after 63, not 64?
		--port map (clk=>clk,addr=>line_buffer_address_reg,data_in=>line_buffer_data_in,wr_en=>line_buffer_write, data_out=>line_buffer_data_out);
		
	-- vertical scrolling
	-- load row count from vscrol must be done at time of instruction load
	-- vscrol adjustment to affect dli should be done by cycle 5 - i.e. dli 'last line'
	-- vscrol adjustment to affect actual last line should be done by cycle 108 - because...
	vscrol_delay : wide_delay_line
		generic map (COUNT=>cycle_length,WIDTH=>4)
		port map (clk=>clk,sync_reset=>'0',data_in=>vscrol_raw_reg(3 downto 0),enable=>'1',reset_n=>reset_n,data_out=>vscrol_delayed_reg(3 downto 0));		
	
	process(vblank_reg, vscrol_delayed_reg, vscrol_enabled_reg, vscrol_last_enabled_reg, first_line_of_instruction_reg, row_count_reg, instruction_final_row_reg, update_row_count, force_final_row)
	begin								
		load_row_count <= '0';
		row_count_next <= (others=>'0');
		increment_row_count <= '0';
		
		last_line_of_instruction_live <= '0';		
		
		if (update_row_count = '1') then							
			if (vscrol_enabled_reg='1' and vscrol_last_enabled_reg='0') then -- vscrol - first line
				row_count_next <= vscrol_delayed_reg;
			end if;
		
			if (first_line_of_instruction_reg = '1') then
				load_row_count <= '1';
			else
				increment_row_count <= '1';
			end if;
		end if;
		
		if (vscrol_enabled_reg='0' and vscrol_last_enabled_reg='1') then -- vscrol - last line
			if (row_count_reg = vscrol_delayed_reg) then -- TODO, review
				last_line_of_instruction_live <= '1';
			end if;
		else -- normal
			if (row_count_reg = instruction_final_row_reg) then
				last_line_of_instruction_live <= '1';
			end if;
		end if;
		
		if (vblank_reg = '1' or force_final_row = '1') then
			last_line_of_instruction_live <= '1';
		end if;
						
	end process;
	
	-- chbase 2 cycle delay
	chbase_delay : wide_delay_line
		generic map (COUNT=>cycle_length*2,WIDTH=>7)
		port map (clk=>clk,sync_reset=>'0',data_in=>chbase_raw_reg(7 downto 1),enable=>'1',reset_n=>reset_n,data_out=>chbase_delayed_reg(7 downto 1));
		
	-- decode instruction	
	process(instruction_reg)
	begin
		dma_speed_next <= no_dma;
		instruction_type_next <= mode_blank;
		shift_rate_next <= slow_shift;
		shift_twobit_next <= '0';
		twopixel_next <= '0';
		single_colour_character_next <= '0';		
		multi_colour_character_next <= '0';		
		twoline_character_next <= '0';
		map_background_next <= '0';
		instruction_final_row_next <= (others=>'0');
		two_part_instruction_next <= instruction_reg(6);
		instruction_blank_next <= '0';
		vscrol_enabled_next <= instruction_reg(5);
		hscrol_enabled_next <= instruction_reg(4);
		dli_enabled_next <= instruction_reg(7);
		descenders_next <= '0';		
		force_final_row <= '0';
		
		case instruction_reg(3 downto 0) is 			
			when X"0" =>
				instruction_type_next <= mode_blank;
				instruction_final_row_next <= '0'&instruction_reg(6 downto 4);
				two_part_instruction_next <= '0';
				instruction_blank_next <= '1';
				vscrol_enabled_next <= '0';
				hscrol_enabled_next <= '0';
				
			when X"1" =>
				instruction_type_next <= mode_jump;
				instruction_final_row_next <= (others=>'0');
				instruction_blank_next <= '1';
				vscrol_enabled_next <= '0';
				hscrol_enabled_next <= '0';
				two_part_instruction_next <= '1';
				
				if (instruction_reg(6) = '1') then
					instruction_type_next <= mode_jvb;
					force_final_row <= '1';
				end if;
				
			when X"2" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"7";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '1';
				
			when X"3" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"9";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '1';
				descenders_next <= '1';
				
			when X"4" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"7";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';
				multi_colour_character_next <= '1';
				
			when X"5" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"F";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';	
				twoline_character_next <= '1';		
				multi_colour_character_next <= '1';
				
			when X"6" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"7";
				
				dma_speed_next <= medium_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '0';
				twopixel_next <= '0';
				single_colour_character_next <= '1';
				
			when X"7" =>
				instruction_type_next <= mode_character;
				instruction_final_row_next <= X"F";
				
				dma_speed_next <= medium_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '0';
				twopixel_next <= '0';
				single_colour_character_next <= '1';
				twoline_character_next <= '1';
				
			when X"8" =>					
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"7";
				
				dma_speed_next <= slow_dma;
				shift_rate_next <= slow_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"9" =>					
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"3";
				
				dma_speed_next <= slow_dma;
				shift_rate_next <= medium_shift;
				shift_twobit_next <= '0';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"A" =>
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"3";
				
				dma_speed_next <= medium_dma;
				shift_rate_next <= medium_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"B" =>					
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"1";
				
				dma_speed_next <= medium_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '0';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"C" =>					
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"0";
				
				dma_speed_next <= medium_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '0';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"D" =>
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"1";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"E" =>
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"0";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '0';
				map_background_next <= '1';
				
			when X"F" =>
				instruction_type_next <= mode_bitmap;
				instruction_final_row_next <= X"0";
				
				dma_speed_next <= fast_dma;
				shift_rate_next <= fast_shift;
				shift_twobit_next <= '1';
				twopixel_next <= '1';
			when others =>
				-- nothing
				
		end case;
	end process;

	-- dma fetching
	-- dma fetch - cache response until needed
	-- we allow two colour clocks for each fetch...
	process(memory_data_in,memory_ready_both,hcount_reg,dma_fetch_reg,dma_address_reg,dma_fetch_destination_reg,dma_cache_ready_reg,dma_cache_reg,dma_fetch_request,vblank_reg, instruction_type_reg, instruction_reg, display_list_address_reg, memory_scan_address_reg, enable_dma, display_list_address_low_temp_reg)
	begin	
		instruction_next <= instruction_reg;
		
		display_list_address_next_dma <= display_list_address_reg;
		load_display_list_address_dma <= '0';
		memory_scan_address_next <= memory_scan_address_reg;
		load_memory_scan_address <= '0';
		increment_display_list_address <= '0';
		
		load_display_shift_from_memory <= '0';
		display_list_address_low_temp_next <= display_list_address_low_temp_reg;		
		
		line_buffer_data_in <= (others=>'0');
		line_buffer_write <= '0';

		dma_cache_next <= dma_cache_reg;
		dma_cache_ready_next <= dma_cache_ready_reg;
		dma_fetch_next <= dma_fetch_request or dma_fetch_reg;

		if (dma_fetch_reg = '1' and memory_ready_both = '1') then
			dma_cache_next <= memory_data_in;
			dma_cache_ready_next <= '1';
			dma_fetch_next <= '0';
		end if;
		
		if (vblank_reg = '1' and instruction_type_reg = mode_jvb) then
			instruction_next <= (others=>'0');
		end if;
	
		if (dma_cache_ready_reg='1' and hcount_reg(0)='0') then
		--if (dma_cache_ready_reg='1') then
			case dma_fetch_destination_reg is 
				when dma_fetch_line_buffer =>
					line_buffer_data_in <= dma_cache_reg;					
					line_buffer_write <= '1';
				when dma_fetch_shiftreg =>
					load_display_shift_from_memory <= '1';
				when dma_fetch_null =>
					-- nothing (C/G/MTIA listens to bus)
				when dma_fetch_instruction =>
					instruction_next <= dma_cache_reg;
					
					increment_display_list_address <= '1';
					
				when dma_fetch_list_low =>
					if (instruction_type_reg = mode_jump or instruction_type_reg = mode_jvb) then
						--display_list_address_next_dma(7 downto 0) <= dma_cache_reg; Changing this so soon messes up next dma cycle
						display_list_address_low_temp_next <= dma_cache_reg;
						increment_display_list_address <= '1';
					else
						increment_display_list_address <= '1';
						memory_scan_address_next(7 downto 0) <= dma_cache_reg;
						load_memory_scan_address <= '1';
					end if;
				when dma_fetch_list_high =>
					if (instruction_type_reg = mode_jump or instruction_type_reg = mode_jvb) then
						 display_list_address_next_dma <= dma_cache_reg&display_list_address_low_temp_reg;
						 load_display_list_address_dma <= '1';
					else
						increment_display_list_address <= '1';
						memory_scan_address_next(15 downto 8) <= dma_cache_reg;
						load_memory_scan_address <= '1';
					end if;
				
				when others =>
					-- nothing
				
			end case;

			dma_cache_ready_next <= '0';
		end if;
	end process;
	
	-- shift reg clock
	playfield_reset <= hblank_reg;
	
	process(colour_clock_selected, shift_rate_reg, shiftclock_reg, playfield_reset, playfield_load, hscrol_reg, hscrol_enabled_reg)
	begin
		shiftclock_next <= shiftclock_reg;
		enable_shift <= '0';
	
		if (colour_clock_selected = '1') then
		
			shiftclock_next <= shiftclock_reg(2 downto 0)&shiftclock_reg(3);
			
			if (playfield_load='1') then
				shiftclock_next <= "1000";
			end if;
			
			if (playfield_reset='1') then
				shiftclock_next <= "0000";
			end if;			
			
			--shiftclock_next(0) <= shiftclock_reg(1);
			--shiftclock_next(1) <= shiftclock_reg(2);
			--shiftclock_next(2) <= shiftclock_reg(3) nor playfield_load;
			--shiftclock_next(3) <= shiftclock_reg(0) nor playfield_reset;						
			case shift_rate_reg is
				when slow_shift =>
					enable_shift <= (shiftclock_reg(0) and not(hscrol_reg(1) and hscrol_enabled_reg)) or (shiftclock_reg(2) and hscrol_reg(1) and hscrol_enabled_reg);
				when medium_shift =>
					enable_shift <= shiftclock_reg(2) or shiftclock_reg(0);
				when fast_shift =>			
					enable_shift <= (shiftclock_reg(3) or shiftclock_reg(2)) or (shiftclock_reg(1) or shiftclock_reg(0));
				when others =>
					-- nothing
			end case;			
		end if;
	end process;

	-- shift reg
	process (enable_shift, shift_twobit_reg, display_shift_reg, load_display_shift_from_memory, load_display_shift_from_line_buffer, dma_cache_reg, line_buffer_data_out)
	begin
		display_shift_next <= display_shift_reg;
		
		if (enable_shift = '1') then
			if (shift_twobit_reg = '1') then
				display_shift_next <= display_shift_reg(5 downto 0)&"00";
			else
				display_shift_next <= display_shift_reg(6 downto 0)&"0";
			end if;			
		end if;
		
		if (load_display_shift_from_memory = '1') then
			display_shift_next(7 downto 0) <= dma_cache_reg;
		end if;

		if (load_display_shift_from_line_buffer = '1') then
			display_shift_next(7 downto 0) <= line_buffer_data_out;
		end if;
		
	end process;
	
	-- delay shift reg output for n cycles, so we can match AN with antic output
	process(colour_clock_selected, display_shift_reg, delay_display_shift_reg, displayed_character_reg, instruction_type_reg)
	begin
		delay_display_shift_next <= delay_display_shift_reg;
		
		if (colour_clock_selected = '1') then
			-- TODO - RAM accesses are now processed in the 2nd colour clock
			-- This is too late for character modes, so delay needs adjusting...
			if (instruction_type_reg=mode_character) then	
				delay_display_shift_next <= displayed_character_reg(7 downto 5)&"00"&delay_display_shift_reg(24 downto 22)&display_shift_reg(7 downto 6)&delay_display_shift_reg(19 downto 5);
			else
				delay_display_shift_next <= displayed_character_reg(7 downto 5)&display_shift_reg(7 downto 6)&delay_display_shift_reg(24 downto 5);
			end if;
		end if;
		
	end process;
	
	-- ANO-2
	-- XXX - clean up!	
	-- first process - AN with no blanking	
	process(data_live,delay_display_shift_reg, shift_twobit_reg, twopixel_reg, instruction_blank_reg, playfield_display_active_reg, single_colour_character_reg, multi_colour_character_reg, chactl_reg, instruction_type_reg, map_background_reg, descenders_reg, row_count_reg)
	begin
		an_current <= (others=>'0');
		data_live <= (others=>'0');
		if (shift_twobit_reg = '1') then				
			an_current(0) <= delay_display_shift_reg(0);
			an_current(1) <= delay_display_shift_reg(1);
			an_current(2) <= '1';
			
			if (instruction_type_reg = mode_character) then							
				data_live(0) <= delay_display_shift_reg(0);
				data_live(1) <= delay_display_shift_reg(1);
								
				if (descenders_reg = '1') then					
					if (delay_display_shift_reg(3 downto 2) = "11") then
						if (unsigned(row_count_reg)<2) then
							data_live(1 downto 0) <= "00";
						end if;
					else
						if (unsigned(row_count_reg)>=8) then
							data_live(1 downto 0) <= "00";
						end if;
					end if;
				end if;	
			
				if (delay_display_shift_reg(4)='1') then -- inverse/hidden
					if (chactl_reg(1)='1') then
						an_current(0) <= not(data_live(0) and not(chactl_reg(0)));
						an_current(1) <= not(data_live(1) and not(chactl_reg(0)));
					else
						an_current(0) <= data_live(0) and not(chactl_reg(0));
						an_current(1) <= data_live(1) and not(chactl_reg(0));					
					end if;
				else
					an_current(0) <= data_live(0);
					an_current(1) <= data_live(1);				
				end if;
			end if;		

			if (multi_colour_character_reg = '1') then
				case delay_display_shift_reg(1 downto 0) is
					when "00" =>
						an_current <= "000";
					when "01" =>
						an_current <= "100";			
					when "10" =>
						an_current <= "101";			
					when "11" =>
						an_current <= "11"&delay_display_shift_reg(4);										
					when others =>
						-- nop
				end case;				
			end if;
			
			if (map_background_reg='1') then
				case delay_display_shift_reg(1 downto 0) is
					when "00" =>
						an_current <= "000";
					when "01" =>
						an_current <= "100";			
					when "10" =>
						an_current <= "101";			
					when "11" =>
						an_current <= "110";										
					when others =>
						-- nop
				end case;
			end if;
		else
			if (single_colour_character_reg = '1') then
				-- i.e. antic 6,7
				if (delay_display_shift_reg(1) = '1') then
					an_current(0) <= delay_display_shift_reg(3);
					an_current(1) <= delay_display_shift_reg(4);
					an_current(2) <= '1';					
				else
					an_current(0) <= '0';
					an_current(1) <= '0';
					an_current(2) <= '0';
				end if;			
			end if;
			
			if (map_background_reg='1') then
				if (delay_display_shift_reg(1)='1') then
					an_current <= "100";
				else
					an_current <= "000";										
				end if;
			end if;				
		end if;		
	end process;
	
	process(colour_clock_selected, an_current, an_prev_reg)
	begin
		an_prev_next <= an_prev_reg;
		
		if (colour_clock_selected = '1') then
			an_prev_next <= an_current;
		end if;
	end process;
	
	process(colour_clock_selected, an_current, an_reg, an_prev_reg, hscrol_reg, hscrol_enabled_reg, vsync_reg, vblank_reg, hblank_reg, playfield_display_active_reg, instruction_blank_reg, twopixel_reg, playfield_dma_enabled)
	begin
		an_next <= an_reg;
	
		if (colour_clock_selected = '1') then	
			an_next <= an_current;
			
			if (hscrol_reg(0)='1' and hscrol_enabled_reg='1') then
				an_next <= an_prev_reg;
			end if;
			
			if ((not(playfield_display_active_reg) or instruction_blank_reg or vblank_reg or not(playfield_dma_enabled)) = '1') then
				an_next <= "000";
			end if;
			
			if (vblank_reg = '1' or hblank_reg = '1') then				
				an_next(0) <= vsync_reg or twopixel_reg;
				an_next(1) <= not(vsync_reg);
				an_next(2) <= not(hblank_reg) and twopixel_reg and playfield_dma_enabled;
			end if;			

--			if (hblank_reg = '1') then
--				an_next(0)<=twopixel_reg;
--				an_next(1)<='1';
--				an_next(2)<='0';
--			end if;
--
--			if(vblank_reg = '1' and hblank_reg = '0') then
--				an_next(0)<=twopixel_reg;
--				an_next(1)<='1';
--				an_next(2)<=twopixel_reg and (dmactl_delayed_reg(1) or dmactl_delayed_reg(0)); --playfield_display_active_reg?
--			end if;
--
--			if(vsync_reg='1') then
--				an_next(0)<='1';
--				an_next(1)<='0';
--			end if;
			
			-- TODO this is too simplistic:
			-- Antic should provide GTIA with the 'visible region using code 002 for vblank and hblank
			-- + odd behaviour seen during high res bug

		end if;
		
	end process;
	
	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>4)
		port map (addr_in=>addr, addr_decoded=>addr_decoded);

	-- wsync write takes 1 cycle to assert rdy
	-- TODO - revisit antic delays in terms of cpu cycles
	wsync_delay : delay_line
		generic map (COUNT=>cycle_length+cycle_length/2)
		--generic map (COUNT=>cycle_length+cycle_length-2) -- TODO
		port map (clk=>clk,sync_reset=>'0',data_in=>wsync_write,enable=>'1',reset_n=>reset_n,data_out=>wsync_delayed_write);

	-- dmactl takes 1 cycle to be applied - NO IT DOES NOT - TODO FIXME
	--dmactl_delay : wide_delay_line
	--	generic map (COUNT=>cycle_length,WIDTH=>6)
	--	port map (clk=>clk,sync_reset=>'0',data_in=>dmactl_raw_reg(5 downto 0),enable=>'1',reset_n=>reset_n,data_out=>dmactl_delayed_reg(5 downto 0));
	dmactl_delayed_reg <= dmactl_raw_next;
	--dmactl_delayed_reg <= dmactl_raw_reg;
		
	-- Writes to registers
	process(cpu_data_in,wr_en,addr_decoded,nmien_raw_reg,dmactl_raw_reg,chactl_reg,hscrol_reg,display_list_address_reg,chbase_raw_reg,pmbase_reg,vscrol_raw_reg, wsync_reg, wsync_delayed_write, wsync_reset)
	begin		
		nmien_raw_next <= nmien_raw_reg;
		dmactl_raw_next <= dmactl_raw_reg;
		chactl_next <= chactl_reg;
		hscrol_next <= hscrol_reg;
		vscrol_raw_next <= vscrol_raw_reg;
		chbase_raw_next <= chbase_raw_reg;
		pmbase_next <= pmbase_reg;
		wsync_next <= (wsync_delayed_write or wsync_reg) and not(wsync_reset);
		nmist_reset <= '0';
		wsync_write <= '0';
		
		load_display_list_address_cpu <= '0';
		display_list_address_next_cpu <= display_list_address_reg;
	
		if (wr_en = '1') then
			if(addr_decoded(0) = '1') then
				dmactl_raw_next <= cpu_data_in(6 downto 0);
			end if;	

			if(addr_decoded(1) = '1') then
				chactl_next <= cpu_data_in(2 downto 0);
			end if;	
			
			if(addr_decoded(2) = '1') then
				display_list_address_next_cpu(7 downto 0) <= cpu_data_in;
				load_display_list_address_cpu <= '1';
			end if;		
			
			if(addr_decoded(3) = '1') then
				display_list_address_next_cpu(15 downto 8) <= cpu_data_in;
				load_display_list_address_cpu <= '1';
			end if;

			if(addr_decoded(4) = '1') then
				hscrol_next <= cpu_data_in(3 downto 0);
			end if;	

			if(addr_decoded(5) = '1') then
				vscrol_raw_next <= cpu_data_in(3 downto 0);
			end if;
			
			if(addr_decoded(7) = '1') then
				pmbase_next <= cpu_data_in(7 downto 2);
			end if;		
			
			if(addr_decoded(9) = '1') then
				chbase_raw_next <= cpu_data_in(7 downto 1);
			end if;		

			if(addr_decoded(10) = '1') then
				wsync_write <= '1';
			end if;		
	
			if(addr_decoded(14) = '1') then
				nmien_raw_next <= cpu_data_in(7 downto 6);
			end if;
		
			if(addr_decoded(15) = '1') then
				nmist_reset <= '1';
			end if;		
		end if;
	end process;
	
	-- Read from registers
	process(addr_decoded,hcount_reg,vcount_reg,nmist_reg,penv_reg,penh_reg)
	begin
		data_out <= X"FF";

		if (addr_decoded(8) = '1') then -- HCOUNT :-)
			data_out <= hcount_reg; -- bonus points for the one who spots this in code:-)
		end if;
		
		if(addr_decoded(11) = '1') then --VCOUNT
			data_out <= vcount_reg(8 downto 1);
		end if;
		
		if (addr_decoded(12) = '1') then -- PENH
			data_out <= penh_reg;
		end if;
		
		if (addr_decoded(13) = '1') then -- PENV
			data_out <= penv_reg;
		end if;

		if(addr_decoded(15) = '1') then --NMIST
			data_out <= nmist_reg&"00000";
		end if;
		
	end process;
	
	-- nmi delay
	nmi_shiftreg_next <= nmi_reg&nmi_shiftreg_reg(15 downto 1);
	
	-- light pen
	process(lightpen,hcount_reg,vcount_reg,penv_reg,penh_reg)
	begin
		penv_next <= penv_reg;
		penh_next <= penh_reg;
		
		if (lightpen = '0') then
			penv_next <= vcount_reg(8 downto 1);
			penh_next <= hcount_reg;
		end if;
	end process;
	
	-- Use CPU data if virtual dma
	MEMORY_READY_both <= MEMORY_READY_ANTIC when allow_real_dma_reg='1' else MEMORY_READY_CPU;
	
	-- output
	nmi_n_out <= nmi_shiftreg_reg(0);
	
	dma_clock_out<=dma_clock_character_name;
	
	AN <= an_reg;
	
	antic_ready <= not(wsync_reg);
	
	dma_fetch_out <= allow_real_dma_reg and dma_fetch_reg;
	dma_address_out <= dma_address_reg;
	
	refresh_out <= refresh_fetch_reg;
	
	COLOUR_CLOCK_ORIGINAL_OUT <= colour_clock_1x;
	COLOUR_CLOCK_OUT <= colour_clock_selected;
	HIGHRES_COLOUR_CLOCK_OUT <= colour_clock_selected_highres;

	vcount_out <= vcount_reg;
	hcount_out <= hcount_reg;
	
END vhdl;

