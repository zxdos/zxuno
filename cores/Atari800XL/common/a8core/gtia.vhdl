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

ENTITY gtia IS
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	MEMORY_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	ANTIC_FETCH : in std_logic;
	
	CPU_ENABLE_ORIGINAL : in std_logic; -- on cycle data is ready
	
	RESET_N : IN STD_LOGIC;
	
	PAL : IN STD_LOGIC;
	
	-- ANTIC interface
	COLOUR_CLOCK_ORIGINAL : in std_logic;
	COLOUR_CLOCK : in std_logic;
	COLOUR_CLOCK_HIGHRES : in std_logic;
	AN : IN STD_LOGIC_VECTOR(2 downto 0);
	
	-- keyboard interface
	CONSOL_IN : IN STD_LOGIC_VECTOR(3 downto 0);
	CONSOL_OUT : out STD_LOGIC_VECTOR(3 downto 0);
	
	-- keyboard interface
	TRIG : IN STD_LOGIC_VECTOR;
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- TO scandoubler...
	COLOUR_out : out std_logic_vector(7 downto 0);
	
	VSYNC : out std_logic;
	HSYNC : out std_logic;
	CSYNC : out std_logic;
	BLANK : out std_logic;
	BURST : out std_logic;
	START_OF_FIELD : out std_logic;
	ODD_LINE : out std_logic
);
END gtia;

ARCHITECTURE vhdl OF gtia IS
	COMPONENT complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
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
		ENABLE : IN STD_LOGIC; -- i.e. shift on this clock
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
	
	component gtia_player IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : in std_logic;
		
		COLOUR_ENABLE : IN STD_LOGIC;
		LIVE_POSITION : in std_logic_vector(7 downto 0);   -- counter ticks as display is drawn
		PLAYER_POSITION : in std_logic_vector(7 downto 0); -- requested position
		SIZE : in std_logic_vector(1 downto 0);
		bitmap : in std_logic_vector(7 downto 0);
		
		output : out std_logic
	);
	END component;
	
	component gtia_priority IS
	PORT 
	( 
		CLK : in std_logic;
		colour_enable : in std_logic;
		PRIOR : in std_logic_vector(7 downto 0);
		P0 : in std_logic;
		P1 : in std_logic;
		P2	: in std_logic;
		P3 : in std_logic;
		PF0 : in std_logic;
		PF1 : in std_logic;
		PF2 : in std_logic;
		PF3 : in std_logic;
		BK : in std_logic;
		
		P0_OUT : out std_logic;
		P1_OUT : out std_logic;
		P2_OUT : out std_logic;
		P3_OUT : out std_logic;
		PF0_OUT : out std_logic;
		PF1_OUT : out std_logic;
		PF2_OUT : out std_logic;
		PF3_OUT : out std_logic;
		BK_OUT : out std_logic
	);
	END component;	
	
	signal addr_decoded : std_logic_vector(31 downto 0);
	
	signal hposp0_raw_next : std_logic_vector(7 downto 0);
	signal hposp0_raw_reg : std_logic_vector(7 downto 0);
	signal hposp1_raw_next : std_logic_vector(7 downto 0);
	signal hposp1_raw_reg : std_logic_vector(7 downto 0);
	signal hposp2_raw_next : std_logic_vector(7 downto 0);
	signal hposp2_raw_reg : std_logic_vector(7 downto 0);
	signal hposp3_raw_next : std_logic_vector(7 downto 0);
	signal hposp3_raw_reg : std_logic_vector(7 downto 0);
	signal hposp0_delayed_reg : std_logic_vector(7 downto 0);
	signal hposp1_delayed_reg : std_logic_vector(7 downto 0);
	signal hposp2_delayed_reg : std_logic_vector(7 downto 0);
	signal hposp3_delayed_reg : std_logic_vector(7 downto 0);
	
	signal hposm0_raw_next : std_logic_vector(7 downto 0);
	signal hposm0_raw_reg : std_logic_vector(7 downto 0);
	signal hposm1_raw_next : std_logic_vector(7 downto 0);
	signal hposm1_raw_reg : std_logic_vector(7 downto 0);
	signal hposm2_raw_next : std_logic_vector(7 downto 0);
	signal hposm2_raw_reg : std_logic_vector(7 downto 0);
	signal hposm3_raw_next : std_logic_vector(7 downto 0);
	signal hposm3_raw_reg : std_logic_vector(7 downto 0);
	signal hposm0_delayed_reg : std_logic_vector(7 downto 0);
	signal hposm1_delayed_reg : std_logic_vector(7 downto 0);
	signal hposm2_delayed_reg : std_logic_vector(7 downto 0);
	signal hposm3_delayed_reg : std_logic_vector(7 downto 0);	
	
	signal sizep0_raw_next : std_logic_vector(1 downto 0);
	signal sizep0_raw_reg : std_logic_vector(1 downto 0);
	signal sizep1_raw_next : std_logic_vector(1 downto 0);
	signal sizep1_raw_reg : std_logic_vector(1 downto 0);
	signal sizep2_raw_next : std_logic_vector(1 downto 0);
	signal sizep2_raw_reg : std_logic_vector(1 downto 0);
	signal sizep3_raw_next : std_logic_vector(1 downto 0);
	signal sizep3_raw_reg : std_logic_vector(1 downto 0);

	signal sizem_raw_next : std_logic_vector(7 downto 0);
	signal sizem_raw_reg : std_logic_vector(7 downto 0);

	signal sizep0_delayed_reg : std_logic_vector(1 downto 0);
	signal sizep1_delayed_reg : std_logic_vector(1 downto 0);
	signal sizep2_delayed_reg : std_logic_vector(1 downto 0);
	signal sizep3_delayed_reg : std_logic_vector(1 downto 0);
	signal sizem_delayed_reg : std_logic_vector(7 downto 0);
	
	signal grafp0_next : std_logic_vector(7 downto 0);
	signal grafp0_reg : std_logic_vector(7 downto 0);
	signal grafp1_next : std_logic_vector(7 downto 0);
	signal grafp1_reg : std_logic_vector(7 downto 0);
	signal grafp2_next : std_logic_vector(7 downto 0);
	signal grafp2_reg : std_logic_vector(7 downto 0);
	signal grafp3_next : std_logic_vector(7 downto 0);
	signal grafp3_reg : std_logic_vector(7 downto 0);
	
	signal grafm_next : std_logic_vector(7 downto 0);
	signal grafm_reg : std_logic_vector(7 downto 0);

	signal grafm_reg10_extended : std_logic_vector(7 downto 0);
	signal grafm_reg32_extended : std_logic_vector(7 downto 0);
	signal grafm_reg54_extended : std_logic_vector(7 downto 0);
	signal grafm_reg76_extended : std_logic_vector(7 downto 0);

	signal colpm0_raw_next : std_logic_vector(7 downto 1);
	signal colpm0_raw_reg : std_logic_vector(7 downto 1);
	signal colpm1_raw_next : std_logic_vector(7 downto 1);
	signal colpm1_raw_reg : std_logic_vector(7 downto 1);
	signal colpm2_raw_next : std_logic_vector(7 downto 1);
	signal colpm2_raw_reg : std_logic_vector(7 downto 1);
	signal colpm3_raw_next : std_logic_vector(7 downto 1);
	signal colpm3_raw_reg : std_logic_vector(7 downto 1);
	signal colpm0_delayed_reg : std_logic_vector(7 downto 1);
	signal colpm1_delayed_reg : std_logic_vector(7 downto 1);
	signal colpm2_delayed_reg : std_logic_vector(7 downto 1);
	signal colpm3_delayed_reg : std_logic_vector(7 downto 1);
	
	signal colpf0_raw_next : std_logic_vector(7 downto 1);
	signal colpf0_raw_reg : std_logic_vector(7 downto 1);
	signal colpf1_raw_next : std_logic_vector(7 downto 1);
	signal colpf1_raw_reg : std_logic_vector(7 downto 1);
	signal colpf2_raw_next : std_logic_vector(7 downto 1);
	signal colpf2_raw_reg : std_logic_vector(7 downto 1);
	signal colpf3_raw_next : std_logic_vector(7 downto 1);
	signal colpf3_raw_reg : std_logic_vector(7 downto 1);
	signal colpf0_delayed_reg : std_logic_vector(7 downto 1);
	signal colpf1_delayed_reg : std_logic_vector(7 downto 1);
	signal colpf2_delayed_reg : std_logic_vector(7 downto 1);
	signal colpf3_delayed_reg : std_logic_vector(7 downto 1);
	
	signal colbk_raw_next : std_logic_vector(7 downto 1);
	signal colbk_raw_reg : std_logic_vector(7 downto 1);
	signal colbk_delayed_reg : std_logic_vector(7 downto 1);	
	
	signal prior_raw_next : std_logic_vector(7 downto 0);
	signal prior_raw_reg : std_logic_vector(7 downto 0);
	signal prior_delayed_reg : std_logic_vector(7 downto 0);
	signal prior_delayed2_reg : std_logic_vector(7 downto 6);
	
	signal vdelay_next : std_logic_vector(7 downto 0);
	signal vdelay_reg : std_logic_vector(7 downto 0);

	signal gractl_next : std_logic_vector(2 downto 0);
	signal gractl_reg : std_logic_vector(2 downto 0);
	
	signal consol_output_next : std_logic_vector(3 downto 0);
	signal consol_output_reg : std_logic_vector(3 downto 0);
	
	signal trig_next : std_logic_vector(3 downto 0);
	signal trig_reg : std_logic_vector(3 downto 0);
	
	-- collisions
	signal hitclr_write : std_logic;
	
	signal m0pf_next : std_logic_vector(3 downto 0);
	signal m0pf_reg : std_logic_vector(3 downto 0);
	signal m1pf_next : std_logic_vector(3 downto 0);
	signal m1pf_reg : std_logic_vector(3 downto 0);
	signal m2pf_next : std_logic_vector(3 downto 0);
	signal m2pf_reg : std_logic_vector(3 downto 0);
	signal m3pf_next : std_logic_vector(3 downto 0);
	signal m3pf_reg : std_logic_vector(3 downto 0);

	signal m0pl_next : std_logic_vector(3 downto 0);
	signal m0pl_reg : std_logic_vector(3 downto 0);
	signal m1pl_next : std_logic_vector(3 downto 0);
	signal m1pl_reg : std_logic_vector(3 downto 0);
	signal m2pl_next : std_logic_vector(3 downto 0);
	signal m2pl_reg : std_logic_vector(3 downto 0);
	signal m3pl_next : std_logic_vector(3 downto 0);
	signal m3pl_reg : std_logic_vector(3 downto 0);
	
	signal p0pf_next : std_logic_vector(3 downto 0);
	signal p0pf_reg : std_logic_vector(3 downto 0);
	signal p1pf_next : std_logic_vector(3 downto 0);
	signal p1pf_reg : std_logic_vector(3 downto 0);
	signal p2pf_next : std_logic_vector(3 downto 0);
	signal p2pf_reg : std_logic_vector(3 downto 0);
	signal p3pf_next : std_logic_vector(3 downto 0);
	signal p3pf_reg : std_logic_vector(3 downto 0);	
	
	signal p0pl_next : std_logic_vector(3 downto 0);
	signal p0pl_reg : std_logic_vector(3 downto 0);
	signal p1pl_next : std_logic_vector(3 downto 0);
	signal p1pl_reg : std_logic_vector(3 downto 0);
	signal p2pl_next : std_logic_vector(3 downto 0);
	signal p2pl_reg : std_logic_vector(3 downto 0);
	signal p3pl_next : std_logic_vector(3 downto 0);
	signal p3pl_reg : std_logic_vector(3 downto 0);		
	
	-- priority
	signal set_p0 : std_logic;
	signal set_p1 : std_logic;
	signal set_p2 : std_logic;
	signal set_p3 : std_logic;
	signal set_pf0 : std_logic;
	signal set_pf1 : std_logic;
	signal set_pf2 : std_logic;
	signal set_pf3 : std_logic;
	signal set_bk : std_logic;	
	
	-- ouput/sync
	signal COLOUR_NEXT : std_logic_vector(7 downto 0);
	signal COLOUR_REG : std_logic_vector(7 downto 0);
	signal HRCOLOUR_NEXT : std_logic_vector(7 downto 0);
	signal HRCOLOUR_REG : std_logic_vector(7 downto 0);
	
	signal vsync_next : std_logic;
	signal vsync_reg : std_logic;

	signal hsync_next : std_logic;
	signal hsync_reg : std_logic;
	
	signal csync_next : std_logic;
	signal csync_reg : std_logic;	
	
	signal hsync_start : std_logic;
	signal hsync_end : std_logic;

	signal csync_start : std_logic;
	signal csync_end : std_logic;	
	
	signal burst_next : std_logic;
	signal burst_reg : std_logic;
	
	signal burst_start : std_logic;
	signal burst_end : std_logic;
	
	signal hblank_next : std_logic;
	signal hblank_reg : std_logic;
	
	-- visible region (no collision detection outside this)
	signal visible_live : std_logic;
	
	-- antic input decode
	signal an_prev3_next : std_logic_vector(2 downto 0);
	signal an_prev3_reg : std_logic_vector(2 downto 0);	
	signal an_prev2_next : std_logic_vector(2 downto 0);
	signal an_prev2_reg : std_logic_vector(2 downto 0);	
	signal an_prev_next : std_logic_vector(2 downto 0);
	signal an_prev_reg : std_logic_vector(2 downto 0);
	
	signal active_bk_modify_next : std_logic_vector(7 downto 0);
	signal active_bk_modify_reg : std_logic_vector(7 downto 0);
	signal active_bk_valid_next : std_logic_vector(7 downto 0);
	signal active_bk_valid_reg : std_logic_vector(7 downto 0);
	signal active_bk_live : std_logic;
	signal active_pf0_live : std_logic;
	signal active_pf1_live : std_logic;
	signal active_pf2_live : std_logic;
	signal active_pf2_collision_live : std_logic;
	signal active_pf3_live : std_logic;
	signal active_pf3_collision_live : std_logic;
	signal active_pm0_live : std_logic;
	signal active_pm1_live : std_logic;
	signal active_pm2_live : std_logic;
	signal active_pm3_live : std_logic;
	
	signal active_p0_live : std_logic;
	signal active_p1_live : std_logic;
	signal active_p2_live : std_logic;
	signal active_p3_live : std_logic;
	signal active_m0_live : std_logic;
	signal active_m1_live : std_logic;
	signal active_m2_live : std_logic;
	signal active_m3_live : std_logic;
	
	signal active_hr_next : std_logic_vector(1 downto 0);
	signal active_hr_reg : std_logic_vector(1 downto 0);
	signal highres_next : std_logic;
	signal highres_reg : std_logic;
	
	-- horizontal position counter
	signal hpos_reg : std_logic_vector(7 downto 0);
	signal reset_counter : std_logic;
	signal counter_load_value : std_logic_vector(7 downto 0);
	
	-- sub colour clock highres mode	
	signal trigger_secondhalf : std_logic;
	
	-- pmg dma
	signal grafm_dma_load : std_logic;
	signal grafm_dma_next : std_logic_vector(7 downto 0);
	signal grafp0_dma_load : std_logic;
	signal grafp0_dma_next : std_logic_vector(7 downto 0);
	signal grafp1_dma_load : std_logic;
	signal grafp1_dma_next : std_logic_vector(7 downto 0);
	signal grafp2_dma_load : std_logic;
	signal grafp2_dma_next : std_logic_vector(7 downto 0);
	signal grafp3_dma_load : std_logic;
	signal grafp3_dma_next : std_logic_vector(7 downto 0);
	signal odd_scanline_next : std_logic;
	signal odd_scanline_reg : std_logic;
	
	signal pmg_dma_state_next : std_logic_vector(2 downto 0);
	signal pmg_dma_state_reg : std_logic_vector(2 downto 0);
	constant pmg_dma_missile : std_logic_vector(2 downto 0) := "000";
	constant pmg_dma_player0 : std_logic_vector(2 downto 0) := "001";
	constant pmg_dma_player1 : std_logic_vector(2 downto 0) := "010";
	constant pmg_dma_player2 : std_logic_vector(2 downto 0) := "011";
	constant pmg_dma_player3 : std_logic_vector(2 downto 0) := "100";
	constant pmg_dma_done    : std_logic_vector(2 downto 0) := "101";	
	constant pmg_dma_instruction : std_logic_vector(2 downto 0) := "110";	
	
begin
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			hposp0_raw_reg <= (others=>'0');
			hposp1_raw_reg <= (others=>'0');
			hposp2_raw_reg <= (others=>'0');
			hposp3_raw_reg <= (others=>'0');

			hposm0_raw_reg <= (others=>'0');
			hposm1_raw_reg <= (others=>'0');
			hposm2_raw_reg <= (others=>'0');
			hposm3_raw_reg <= (others=>'0');			

			sizep0_raw_reg <= (others=>'0');
			sizep1_raw_reg <= (others=>'0');
			sizep2_raw_reg <= (others=>'0');
			sizep3_raw_reg <= (others=>'0');

			sizem_raw_reg <= (others=>'0');
			
			grafp0_reg <= (others=>'0');
			grafp1_reg <= (others=>'0');
			grafp2_reg <= (others=>'0');
			grafp3_reg <= (others=>'0');

			grafm_reg <= (others=>'0');
			
			colpm0_raw_reg <= (others=>'0');
			colpm1_raw_reg <= (others=>'0');
			colpm2_raw_reg <= (others=>'0');
			colpm3_raw_reg <= (others=>'0');

			colpf0_raw_reg <= (others=>'0');
			colpf1_raw_reg <= (others=>'0');
			colpf2_raw_reg <= (others=>'0');
			colpf3_raw_reg <= (others=>'0');
			
			colbk_raw_reg <= (others=>'0');
			
			prior_raw_reg <= (others=>'0');
			
			vdelay_reg <= (others=>'0');
			
			gractl_reg <= (others=>'0');
			
			consol_output_reg <= (others=>'1');
			
			COLOUR_REG <= (OTHERS=>'0');
			HRCOLOUR_REG <= (OTHERS=>'0');
			
			csync_reg <= '0';
			vsync_reg <= '0';
			hsync_reg <= '0';
			burst_reg <= '0';
			hblank_reg <= '0';
			
			an_prev_reg <= (others=>'0');
			an_prev2_reg <= (others=>'0');
			an_prev3_reg <= (others=>'0');
			
			highres_reg <= '0';
			active_hr_reg <= (others=>'0');
			
			trig_reg <= (others=>'0');
			
			odd_scanline_reg <= '0';
			
			pmg_dma_state_reg <= pmg_dma_done;
			
			m0pf_reg <= (others=>'0');
			m1pf_reg <= (others=>'0');
			m2pf_reg <= (others=>'0');
			m3pf_reg <= (others=>'0');
			m0pl_reg <= (others=>'0');
			m1pl_reg <= (others=>'0');
			m2pl_reg <= (others=>'0');
			m3pl_reg <= (others=>'0');
			
			p0pf_reg <= (others=>'0');
			p1pf_reg <= (others=>'0');
			p2pf_reg <= (others=>'0');
			p3pf_reg <= (others=>'0');
			p0pl_reg <= (others=>'0');
			p1pl_reg <= (others=>'0');
			p2pl_reg <= (others=>'0');
			p3pl_reg <= (others=>'0');	
			
			active_bk_modify_reg <= (others=>'0');
			active_bk_valid_reg <= (others=>'0');
			
		elsif (clk'event and clk='1') then										
			hposp0_raw_reg <= hposp0_raw_next;
			hposp1_raw_reg <= hposp1_raw_next;
			hposp2_raw_reg <= hposp2_raw_next;
			hposp3_raw_reg <= hposp3_raw_next;

			hposm0_raw_reg <= hposm0_raw_next;
			hposm1_raw_reg <= hposm1_raw_next;
			hposm2_raw_reg <= hposm2_raw_next;
			hposm3_raw_reg <= hposm3_raw_next;			

			sizep0_raw_reg <= sizep0_raw_next;
			sizep1_raw_reg <= sizep1_raw_next;
			sizep2_raw_reg <= sizep2_raw_next;
			sizep3_raw_reg <= sizep3_raw_next;

			sizem_raw_reg <= sizem_raw_next;
			
			grafp0_reg <= grafp0_next;
			grafp1_reg <= grafp1_next;
			grafp2_reg <= grafp2_next;
			grafp3_reg <= grafp3_next;

			grafm_reg <= grafm_next;
			
			colpm0_raw_reg <= colpm0_raw_next;
			colpm1_raw_reg <= colpm1_raw_next;
			colpm2_raw_reg <= colpm2_raw_next;
			colpm3_raw_reg <= colpm3_raw_next;

			colpf0_raw_reg <= colpf0_raw_next;
			colpf1_raw_reg <= colpf1_raw_next;
			colpf2_raw_reg <= colpf2_raw_next;
			colpf3_raw_reg <= colpf3_raw_next;
			
			colbk_raw_reg <= colbk_raw_next;
			
			prior_raw_reg <= prior_raw_next;
			
			vdelay_reg <= vdelay_next;
			
			gractl_reg <= gractl_next;
			
			consol_output_reg <= consol_output_next;		

			COLOUR_REG <= colour_next;
			HRCOLOUR_REG <= hrcolour_next;
			
			csync_reg <= csync_next;
			vsync_reg <= vsync_next;
			hsync_reg <= hsync_next;
			burst_reg <= burst_next;
			hblank_reg <= hblank_next;
			
			an_prev_reg <= an_prev_next;
			an_prev2_reg <= an_prev2_next;
			an_prev3_reg <= an_prev3_next;
	
			highres_reg <= highres_next;
			active_hr_reg <= active_hr_next;
			
			trig_reg <= trig_next;
			
			odd_scanline_reg <= odd_scanline_next;
			
			pmg_dma_state_reg <= pmg_dma_state_next;
			
			m0pf_reg <= m0pf_next;
			m1pf_reg <= m1pf_next;
			m2pf_reg <= m2pf_next;
			m3pf_reg <= m3pf_next;
			m0pl_reg <= m0pl_next;
			m1pl_reg <= m1pl_next;
			m2pl_reg <= m2pl_next;
			m3pl_reg <= m3pl_next;
			
			p0pf_reg <= p0pf_next;
			p1pf_reg <= p1pf_next;
			p2pf_reg <= p2pf_next;
			p3pf_reg <= p3pf_next;
			p0pl_reg <= p0pl_next;
			p1pl_reg <= p1pl_next;
			p2pl_reg <= p2pl_next;
			p3pl_reg <= p3pl_next;
			
			active_bk_modify_reg <= active_bk_modify_next;
			active_bk_valid_reg <= active_bk_valid_next;
		end if;
	end process;
	
	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>5)
		port map (addr_in=>addr, addr_decoded=>addr_decoded);
		
	-- decode antic input
	process (AN, COLOUR_CLOCK, COLOUR_CLOCK_ORIGINAL, an_prev_reg, an_prev2_reg, an_prev3_reg, hblank_reg, vsync_reg, highres_reg, odd_scanline_reg, prior_delayed_reg, prior_delayed2_reg, hpos_reg, active_p0_live, active_p1_live, active_p2_live, active_p3_live, active_m0_live, active_m1_live, active_m2_live, active_m3_live, active_pf3_collision_live, active_bk_modify_reg, active_bk_modify_next, active_bk_valid_reg, active_hr_reg, visible_live)
	begin	
		hblank_next <= hblank_reg;
		reset_counter <= '0';
		counter_load_value <= (others=>'0');
		vsync_next <= vsync_reg;
		
		odd_scanline_next <= odd_scanline_reg;

		start_of_field <= '0';
			
		-- NB high res mode gives pf2 - which is or of the two pixels
		highres_next <= highres_reg;
		
		-- for gtia modes
		an_prev_next <= an_prev_reg;
		an_prev2_next <= an_prev2_reg;
		an_prev3_next <= an_prev3_reg;
		
		-- decoded AN
		visible_live <= '0';
		
		active_hr_next <= active_hr_reg;
		
		active_bk_modify_next <= active_bk_modify_reg;
		active_bk_valid_next <= active_bk_valid_reg;
		active_bk_live <= '0';
		active_pf0_live <= '0';
		active_pf1_live <= '0';
		active_pf2_live <= '0';
		active_pf2_collision_live <= '0';
		active_pf3_live <= '0';
		active_pf3_collision_live <= '0';
		active_pm0_live <= '0';
		active_pm1_live <= '0';
		active_pm2_live <= '0';
		active_pm3_live <= '0';
		
		if (COLOUR_CLOCK = '1') then	
			visible_live <= '1';
			vsync_next <= '0';
			hblank_next <= '0';
			an_prev_next <= an;
			an_prev2_next <= an_prev_reg;
			an_prev3_next <= an_prev2_reg;
			
			active_pm0_live <= active_p0_live or (active_m0_live and not(prior_delayed_reg(4)));
			active_pm1_live <= active_p1_live or (active_m1_live and not(prior_delayed_reg(4)));
			active_pm2_live <= active_p2_live or (active_m2_live and not(prior_delayed_reg(4)));
			active_pm3_live <= active_p3_live or (active_m3_live and not(prior_delayed_reg(4)));			
			
			active_bk_modify_next <= (others=>'0');
			active_bk_valid_next <= (others=>'1');
			
			active_hr_next <= (others=>'0');
		
			-- 000 background colour
			-- 001 vsync
			-- 01X hsync (low bit is high res mode - i.e. 2 pixels per colour clock)
			-- 1XX colour 0 to colour 3
			
			-- in gtia modes then we listen for 2 colour clocks to get one pixels
			-- 1ZY (giving signal ZYXV for 4 bit colour reg/luminance - unfortunately we only have 9 colour regs!)
			-- 1XV
			
			if (highres_reg = '1') then
				if (an(2) = '1') then
					active_hr_next <= AN(1 downto 0);				
				end if;
				
				active_bk_live <= not(an(2)) and not(an(1)) and not(an(0));
				active_pf0_live <= '0';
				active_pf1_live <= '0';
				active_pf2_live <= an(2);
				active_pf2_collision_live <= an(2) and (an(1) or an(0));
				active_pf3_collision_live <= '0';				
			else								
				-- gtia modes										
				case prior_delayed_reg(7 downto 6) is
					when "00" => 
						-- normal mode
						active_bk_live <= not(an(2)) and not(an(1)) and not(an(0));
						active_pf0_live <= an(2) and not(an(1)) and not(an(0));
						active_pf1_live <= an(2) and not(an(1)) and an(0);
						active_pf2_live <= an(2) and      an(1) and not(an(0));
						active_pf2_collision_live <= an(2) and      an(1) and not(an(0));
						active_pf3_collision_live <= an(2) and      an(1) and an(0);
					when "01" =>
						-- 1 colour/16 luminance
						-- no playfield collisions
						-- 5th player gets my luminance
						active_pf0_live <= '0';
						active_pf1_live <= '0';
						active_pf2_live <= '0';
						active_pf2_collision_live <= '0';
						active_pf3_collision_live <= '0';						
						active_bk_live <= '1';
						
						if (hpos_reg(0) = '1') then
							active_bk_modify_next(3 downto 0) <= an_prev_reg(1 downto 0)&an(1 downto 0);
						else
							active_bk_modify_next(3 downto 0) <= active_bk_modify_reg(3 downto 0);
						end if;
					when "10" => 
						-- 9 colour
						-- playfield collisions
						-- no missile/player collisions from 'playfield' data though		
						-- offset by 1 colour clock...
						if (hpos_reg(0) = '1') then
							active_bk_live <= '0';
							active_pf0_live <= '0';
							active_pf1_live <= '0';
							active_pf2_live <= '0';
							active_pf2_collision_live <= '0';
							active_pf3_collision_live <= '0';
														
							case an_prev_reg(1 downto 0)&an(1 downto 0) is
								when "0000" =>
									active_pm0_live <= '1';
								when "0001" =>
									active_pm1_live <= '1';
								when "0010" =>
									active_pm2_live <= '1';
								when "0011" =>								
									active_pm3_live <= '1';
								when "0100"|"1100" =>
									active_pf0_live <= an(2);
									active_bk_live <= not(an(2));
								when "0101"|"1101" =>
									active_pf1_live <= an(2);
									active_bk_live <= not(an(2));
								when "0110"|"1110" =>
									active_pf2_live <= an(2);
									active_pf2_collision_live <= an(2);
									active_bk_live <= not(an(2));
								when "0111"|"1111" =>								
									active_pf3_collision_live <= an(2);
									active_bk_live <= not(an(2));
								when others =>
									active_bk_live <= '1';
							end case;
						else
							active_bk_live <= '0';
							active_pf0_live <= '0';
							active_pf1_live <= '0';
							active_pf2_live <= '0';
							active_pf2_collision_live <= '0';
							active_pf3_collision_live <= '0';
														
							case an_prev2_reg(1 downto 0)&an_prev_reg(1 downto 0) is
								when "0000" =>
									active_pm0_live <= '1';
								when "0001" =>
									active_pm1_live <= '1';
								when "0010" =>
									active_pm2_live <= '1';
								when "0011" =>								
									active_pm3_live <= '1';
								when "0100"|"1100" =>
									active_pf0_live <= an_prev_reg(2);
									active_bk_live <= not(an_prev_reg(2));
								when "0101"|"1101" =>
									active_pf1_live <= an_prev_reg(2);
									active_bk_live <= not(an_prev_reg(2));
								when "0110"|"1110" =>
									active_pf2_live <= an_prev_reg(2);
									active_pf2_collision_live <= an_prev_reg(2);
									active_bk_live <= not(an_prev_reg(2));
								when "0111"|"1111" =>								
									active_pf3_collision_live <= an_prev_reg(2);
									active_bk_live <= not(an_prev_reg(2));
								when others =>
									active_bk_live <= '1';
							end case;									
						end if;
						
					when "11" =>
						-- 16 colour/1 luminance
						-- no playfield collisions
						-- 5th player gets our luminance
						active_bk_live <= '1';
						active_pf0_live <= '0';
						active_pf1_live <= '0';
						active_pf2_live <= '0';
						active_pf2_collision_live <= '0';
						active_pf3_collision_live <= '0';	
						if (hpos_reg(0) = '1') then
							active_bk_modify_next(7 downto 4) <= an_prev_reg(1 downto 0)&an(1 downto 0);
						else
							active_bk_modify_next(7 downto 4) <= active_bk_modify_reg(7 downto 4);
						end if;
						
						if (active_bk_modify_next(7 downto 4) = "0000") then
							active_bk_valid_next(3 downto 0) <= "0000";
						end if;
					when others =>
						-- nop
				end case;
			end if;
			
			if (prior_delayed_reg(4) = '1') then
				active_pf3_live <= active_pf3_collision_live or active_m0_live or active_m1_live or active_m2_live or active_m3_live;
			else
				active_pf3_live <= active_pf3_collision_live;
			end if;
			
			if (not (prior_delayed2_reg(7 downto 6) = "00")) then
				-- force off flip flop when in gtia mode
				highres_next <= '0';
			end if;
			
			-- hblank
			if (an_prev_reg(2 downto 1) = "01") then
				hblank_next <= '1';
				active_bk_live <= '0';
				active_pf0_live <= '0';
				active_pf1_live <= '0';
				active_pf2_live <= '0';
				active_pf2_collision_live <= '0';
				active_pf3_live <= '0';
				active_pf3_collision_live <= '0';
				highres_next <= an_prev_reg(0);
			
				if (COLOUR_CLOCK_ORIGINAL='1') then				
					if (hblank_reg = '0' and vsync_reg = '0') then
						reset_counter <= '1';
						counter_load_value <= X"E0"; -- 2 lower than antic
						odd_scanline_next <= not(odd_scanline_reg);
					end if;
				end if;
			end if;
			if (an(2 downto 1) = "01") then
				visible_live <= '0';
			end if;			
	
			-- vsync
			if (an_prev_reg = "001") then
				active_bk_live <= '0';
				active_pf0_live <= '0';
				active_pf1_live <= '0';
				active_pf2_live <= '0';
				active_pf2_collision_live <= '0';
				active_pf3_live <= '0';
				active_pf3_collision_live <= '0';
				
				vsync_next <= '1';

				odd_scanline_next <= '0';
				
				visible_live <= '0';

				start_of_field <= not(vsync_reg);
			end if;
			
			-- during vblank we reset our own counter - since Antic does not clear hblank_reg
			if (hpos_reg = X"E3" and COLOUR_CLOCK_ORIGINAL='1') then
				reset_counter <= '1';
				counter_load_value <= X"00";
			end if;

		end if;
	end process;
	
	-- hpos
	counter_hpos : simple_counter
		generic map (COUNT_WIDTH=>8)
		port map (clk=>clk, reset_n=>reset_n, increment=>COLOUR_CLOCK_ORIGINAL, load=>reset_counter, load_value=>counter_load_value, current_value=>hpos_reg);
	
	-- visible region
--	process(hpos_reg,vpos_reg)
--	begin		
--		visible_live <= '1';
--		
----		if (unsigned(vpos_reg) < to_unsigned(8,9)) then
----			visible_live <= '0';
----		end if;
----		
----		if (unsigned(vpos_reg) > to_unsigned(247,9)) then
----			visible_live <= '0';
----		end if;
----		
----		if (unsigned(hpos_reg) <= to_unsigned(34,8)) then
----			visible_live <= '0';
----		end if;
----		
----		if (unsigned(hpos_reg) > to_unsigned(221,8)) then
----			visible_live <= '0';
----		end if;		
--	end process;
	
	-- generate hsync and csync
	process(hpos_reg, hsync_reg, hsync_end, csync_reg, csync_end, burst_reg, burst_end, vsync_reg, vsync_next)
	begin
		hsync_start <= '0';
		hsync_next <= hsync_reg;

		csync_start <= '0';
		csync_next <= csync_reg;	
	
		burst_start <= '0';
		burst_next <= burst_reg;

		if (unsigned(hpos_reg) = X"D4") then
			csync_start <= vsync_reg;
			csync_next <= vsync_reg;
		end if;
	
		if (unsigned(hpos_reg) = X"0") then
			csync_start <= not(vsync_reg);
			csync_next <= not(vsync_reg);
						
			hsync_start <= '1';
			hsync_next <= '1';
		end if;

		if (unsigned(hpos_reg) = X"14" and vsync_reg = '0' ) then
			burst_start <= '1';
			burst_next <= '1';
		end if;
		
		if (hsync_end = '1') then
			hsync_next <= '0';
		end if;		
			
		if (csync_end = '1') then
			csync_next <= '0';
		end if;

		if (burst_end = '1') then
			burst_next <= '0';
		end if;
		
		if (vsync_next = '0' and vsync_reg = '1') then
			csync_next <= '0';
		end if;
	end process;

	hsync_delay : delay_line
		generic map (COUNT=>15)
		port map(clk=>clk,sync_reset=>'0',data_in=>hsync_start,enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hsync_end);	
		
	csync_delay : delay_line
		generic map (COUNT=>15)
		port map(clk=>clk,sync_reset=>'0',data_in=>csync_start,enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>csync_end);			

	burst_delay : delay_line
		generic map (COUNT=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>burst_start,enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>burst_end);	

	-- pmg dma
	process(CPU_ENABLE_ORIGINAL,antic_fetch,memory_data_in,hsync_start,pmg_dma_state_reg,gractl_reg,odd_scanline_reg,vdelay_reg,grafm_reg, visible_live,hpos_reg, hblank_reg)
	begin
		pmg_dma_state_next <= pmg_dma_state_reg;
		grafm_dma_load <= '0';
		grafm_dma_next <= grafm_reg;		
		grafp0_dma_load <= '0';
		grafp0_dma_next <= (others=>'0');
		grafp1_dma_load <= '0';
		grafp1_dma_next <= (others=>'0');
		grafp2_dma_load <= '0';
		grafp2_dma_next <= (others=>'0');
		grafp3_dma_load <= '0';
		grafp3_dma_next <= (others=>'0');
	
		-- pull pmg data from bus
		if (hpos_reg = X"E1") then
			pmg_dma_state_next <= pmg_dma_missile;
		end if;
		
		-- we start from the first antic fetch
		-- TODO - CPU enable does not identify next 'antic' cycle in turbo mode...
		case pmg_dma_state_reg is
			when pmg_dma_missile =>
				if (antic_fetch = '1' and cpu_enable_original = '1' and hblank_reg = '1' and visible_live = '0' and hpos_reg(7 downto 4) = "0000") then
					-- here we have the missile0					
					grafm_dma_load <= gractl_reg(0);
				
					if ((odd_scanline_reg or not(vdelay_reg(0))) = '1') then
						grafm_dma_next(1 downto 0) <= memory_data_in(1 downto 0);
					end if;
					if ((odd_scanline_reg or not(vdelay_reg(1))) = '1') then
						grafm_dma_next(3 downto 2) <= memory_data_in(3 downto 2);
					end if;
					if ((odd_scanline_reg or not(vdelay_reg(2))) = '1') then
						grafm_dma_next(5 downto 4) <= memory_data_in(5 downto 4);
					end if;
					if ((odd_scanline_reg or not(vdelay_reg(3))) = '1') then
						grafm_dma_next(7 downto 6) <= memory_data_in(7 downto 6);
					end if;
					
					pmg_dma_state_next <= pmg_dma_instruction;
				end if;
			when pmg_dma_instruction =>
				if (CPU_ENABLE_ORIGINAL = '1') then
					pmg_dma_state_next <= pmg_dma_player0;
				end if;			
			when pmg_dma_player0 =>
				if (CPU_ENABLE_ORIGINAL = '1') then
					-- here we have player0
					grafp0_dma_next <= memory_data_in;				
					grafp0_dma_load <= gractl_reg(1) and (odd_scanline_reg or not(vdelay_reg(4)));
					pmg_dma_state_next <= pmg_dma_player1;
				end if;
			when pmg_dma_player1 =>
				if (CPU_ENABLE_ORIGINAL = '1') then
					-- here we have player1
					grafp1_dma_next <= memory_data_in;
					grafp1_dma_load <= gractl_reg(1) and (odd_scanline_reg or not(vdelay_reg(5)));
					pmg_dma_state_next <= pmg_dma_player2;
				end if;
			when pmg_dma_player2 =>
				if (CPU_ENABLE_ORIGINAL = '1') then
					-- here we have player1
					grafp2_dma_next <= memory_data_in;
					grafp2_dma_load <= gractl_reg(1) and (odd_scanline_reg or not(vdelay_reg(6)));
					pmg_dma_state_next <= pmg_dma_player3;
				end if;				
			when pmg_dma_player3 =>
				if (CPU_ENABLE_ORIGINAL = '1') then
					-- here we have player1
					grafp3_dma_next <= memory_data_in;				
					grafp3_dma_load <= gractl_reg(1) and (odd_scanline_reg or not(vdelay_reg(7)));
					pmg_dma_state_next <= pmg_dma_done;
				end if;
			when others =>
				-- nop
		end case;
	end process;
		
	-- pmg display - same for all pmgs
	-- TODO: priority
	player0 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposp0_delayed_reg,size=>sizep0_delayed_reg(1 downto 0),bitmap=>grafp0_reg, output=>active_p0_live);	
	player1 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposp1_delayed_reg,size=>sizep1_delayed_reg(1 downto 0),bitmap=>grafp1_reg, output=>active_p1_live);	
	player2 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposp2_delayed_reg,size=>sizep2_delayed_reg(1 downto 0),bitmap=>grafp2_reg, output=>active_p2_live);	
	player3 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposp3_delayed_reg,size=>sizep3_delayed_reg(1 downto 0),bitmap=>grafp3_reg, output=>active_p3_live);				

	grafm_reg10_extended <= grafm_reg(1 downto 0)&"000000";
	grafm_reg32_extended <= grafm_reg(3 downto 2)&"000000";
	grafm_reg54_extended <= grafm_reg(5 downto 4)&"000000";
	grafm_reg76_extended <= grafm_reg(7 downto 6)&"000000";
	missile0 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposm0_delayed_reg,size=>sizem_delayed_reg(1 downto 0),bitmap=>grafm_reg10_extended, output=>active_m0_live);
	missile1 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposm1_delayed_reg,size=>sizem_delayed_reg(3 downto 2),bitmap=>grafm_reg32_extended, output=>active_m1_live);
	missile2 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposm2_delayed_reg,size=>sizem_delayed_reg(5 downto 4),bitmap=>grafm_reg54_extended, output=>active_m2_live);
	missile3 : gtia_player
		port map(clk=>clk,reset_n=>reset_n,colour_enable=>COLOUR_CLOCK_ORIGINAL,live_position=>hpos_reg,player_position=>hposm3_delayed_reg,size=>sizem_delayed_reg(7 downto 6),bitmap=>grafm_reg76_extended, output=>active_m3_live);
		
	-- calculate atari colour
	priority_rules : gtia_priority
		port map(clk=>clk, colour_enable=>colour_clock, prior=>prior_delayed_reg,p0=>active_pm0_live,p1=>active_pm1_live,p2=>active_pm2_live,p3=>active_pm3_live,pf0=>active_pf0_live,pf1=>active_pf1_live,pf2=>active_pf2_live,pf3=>active_pf3_live,bk=>active_bk_live,p0_out=>set_p0,p1_out=>set_p1,p2_out=>set_p2,p3_out=>set_p3,pf0_out=>set_pf0,pf1_out=>set_pf1,pf2_out=>set_pf2,pf3_out=>set_pf3,bk_out=>set_bk);	

	trigger_secondhalf <= colour_clock_HIGHRES and not colour_clock;
	process(set_p0,set_p1,set_p2,set_p3,set_pf0,set_pf1,set_pf2,set_pf3,set_bk,highres_reg, active_hr_reg, colbk_delayed_reg, colpf0_delayed_reg, colpf1_delayed_reg, colpf2_delayed_reg, colpf3_delayed_reg, colpm0_delayed_reg, colpm1_delayed_reg, colpm2_delayed_reg, colpm3_delayed_reg, trigger_secondhalf, colour_clock, COLOUR_REG, hrcolour_reg, visible_live, active_bk_modify_next, active_bk_valid_next)
	begin
		colour_next <= colour_reg;
		hrcolour_next <= hrcolour_reg;
		
		if (trigger_secondhalf = '1') then
			if (highres_reg = '1') then
				colour_next <= hrcolour_reg;
			end if;
		end if;		
		
		if (colour_clock = '1') then 
			colour_next <= 
				(
				((colbk_delayed_reg&'0' or active_bk_modify_next) and active_bk_valid_next and (set_bk &set_bk &set_bk &set_bk &set_bk &set_bk &set_bk& set_bk)) or
				(colpf0_delayed_reg&'0' and (set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0) ) or
				(colpf1_delayed_reg&'0' and (set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1) ) or
				(colpf2_delayed_reg&'0' and (set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2) ) or
				((colpf3_delayed_reg&'0' or active_bk_modify_next) and (set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3) ) or
				(colpm0_delayed_reg&'0' and (set_p0 &set_p0 &set_p0 &set_p0 &set_p0 &set_p0 &set_p0& set_p0)) or
				(colpm1_delayed_reg&'0' and (set_p1 &set_p1 &set_p1 &set_p1 &set_p1 &set_p1 &set_p1& set_p1)) or
				(colpm2_delayed_reg&'0' and (set_p2 &set_p2 &set_p2 &set_p2 &set_p2 &set_p2 &set_p2& set_p2)) or
				(colpm3_delayed_reg&'0' and (set_p3 &set_p3 &set_p3 &set_p3 &set_p3 &set_p3 &set_p3& set_p3))
				);
			hrcolour_next <= -- SAME FIXME
				(
				((colbk_delayed_reg&'0' or active_bk_modify_next) and active_bk_valid_next and (set_bk &set_bk &set_bk &set_bk &set_bk &set_bk &set_bk& set_bk)) or
				(colpf0_delayed_reg&'0' and (set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0&set_pf0) ) or
				(colpf1_delayed_reg&'0' and (set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1&set_pf1) ) or
				(colpf2_delayed_reg&'0' and (set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2&set_pf2) ) or
				((colpf3_delayed_reg&'0' or active_bk_modify_next) and (set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3&set_pf3) ) or
				(colpm0_delayed_reg&'0' and (set_p0 &set_p0 &set_p0 &set_p0 &set_p0 &set_p0 &set_p0& set_p0)) or
				(colpm1_delayed_reg&'0' and (set_p1 &set_p1 &set_p1 &set_p1 &set_p1 &set_p1 &set_p1& set_p1)) or
				(colpm2_delayed_reg&'0' and (set_p2 &set_p2 &set_p2 &set_p2 &set_p2 &set_p2 &set_p2& set_p2)) or
				(colpm3_delayed_reg&'0' and (set_p3 &set_p3 &set_p3 &set_p3 &set_p3 &set_p3 &set_p3& set_p3))
				);
						
			-- finally high-res mode overrides the luma
			if (set_bk = '0' and highres_reg = '1') then
			
				if (active_hr_reg(1) = '1') then
					colour_next(3 downto 0) <= colpf1_delayed_reg(3 downto 1)&'0';						
				end if;
				
				if (active_hr_reg(0) = '1') then						
					hrcolour_next(3 downto 0) <= colpf1_delayed_reg(3 downto 1)&'0';
				end if;
			end if;				
			
			if (visible_live = '0') then
				colour_next <= X"00";
				hrcolour_next <= X"00";
			end if;			
		end if;
	end process;

	-- collision detection
	process (colour_clock, m0pf_reg,m1pf_reg,m2pf_reg,m3pf_reg,m0pl_reg,m1pl_reg,m2pl_reg,m3pl_reg,p0pf_reg,p1pf_reg,p2pf_reg,p3pf_reg,p0pl_reg,p1pl_reg,p2pl_reg,p3pl_reg,hitclr_write,active_pf0_live,active_pf1_live,active_pf2_collision_live,active_pf3_collision_live,active_p0_live,active_p1_live,active_p2_live,active_p3_live,active_m0_live,active_m1_live,active_m2_live,active_m3_live, visible_live)
	begin
		m0pf_next <= m0pf_reg;
		m1pf_next <= m1pf_reg;
		m2pf_next <= m2pf_reg;
		m3pf_next <= m3pf_reg;
		m0pl_next <= m0pl_reg;
		m1pl_next <= m1pl_reg;
		m2pl_next <= m2pl_reg;
		m3pl_next <= m3pl_reg;
		
		p0pf_next <= p0pf_reg;
		p1pf_next <= p1pf_reg;
		p2pf_next <= p2pf_reg;
		p3pf_next <= p3pf_reg;
		p0pl_next <= p0pl_reg;
		p1pl_next <= p1pl_reg;
		p2pl_next <= p2pl_reg;
		p3pl_next <= p3pl_reg;	
		
		if (hitclr_write = '1') then
			m0pf_next <= (others=>'0');
			m1pf_next <= (others=>'0');
			m2pf_next <= (others=>'0');
			m3pf_next <= (others=>'0');
			m0pl_next <= (others=>'0');
			m1pl_next <= (others=>'0');
			m2pl_next <= (others=>'0');
			m3pl_next <= (others=>'0');
			
			p0pf_next <= (others=>'0');
			p1pf_next <= (others=>'0');
			p2pf_next <= (others=>'0');
			p3pf_next <= (others=>'0');
			p0pl_next <= (others=>'0');
			p1pl_next <= (others=>'0');
			p2pl_next <= (others=>'0');
			p3pl_next <= (others=>'0');
		else
			if (visible_live = '1' and colour_clock = '1') then
				m0pl_next <= m0pl_reg or (active_m0_live&active_m0_live&active_m0_live&active_m0_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				m1pl_next <= m1pl_reg or (active_m1_live&active_m1_live&active_m1_live&active_m1_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				m2pl_next <= m2pl_reg or (active_m2_live&active_m2_live&active_m2_live&active_m2_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				m3pl_next <= m3pl_reg or (active_m3_live&active_m3_live&active_m3_live&active_m3_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);

				m0pf_next <= m0pf_reg or (active_m0_live&active_m0_live&active_m0_live&active_m0_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				m1pf_next <= m1pf_reg or (active_m1_live&active_m1_live&active_m1_live&active_m1_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				m2pf_next <= m2pf_reg or (active_m2_live&active_m2_live&active_m2_live&active_m2_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				m3pf_next <= m3pf_reg or (active_m3_live&active_m3_live&active_m3_live&active_m3_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				
				p0pl_next <= p0pl_reg or (active_p0_live&active_p0_live&active_p0_live&'0'        and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				p1pl_next <= p1pl_reg or (active_p1_live&active_p1_live&'0'       &active_p1_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				p2pl_next <= p2pl_reg or (active_p2_live&'0'       &active_p2_live&active_p2_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);
				p3pl_next <= p3pl_reg or ('0'       &active_p3_live&active_p3_live&active_p3_live and active_p3_live&active_p2_live&active_p1_live&active_p0_live);	
				
				p0pf_next <= p0pf_reg or (active_p0_live&active_p0_live&active_p0_live&active_p0_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				p1pf_next <= p1pf_reg or (active_p1_live&active_p1_live&active_p1_live&active_p1_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				p2pf_next <= p2pf_reg or (active_p2_live&active_p2_live&active_p2_live&active_p2_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);
				p3pf_next <= p3pf_reg or (active_p3_live&active_p3_live&active_p3_live&active_p3_live and active_pf3_collision_live&active_pf2_collision_live&active_pf1_live&active_pf0_live);			
			end if;
		end if;
		
	end process;

	-- Writes to registers
	process(cpu_data_in,wr_en,addr_decoded,hposp0_raw_reg,hposp1_raw_reg,hposp2_raw_reg,hposp3_raw_reg,hposm0_raw_reg,hposm1_raw_reg,hposm2_raw_reg,hposm3_raw_reg,sizep0_raw_reg,sizep1_raw_reg,sizep2_raw_reg,sizep3_raw_reg,sizem_raw_reg,grafp0_reg,grafp1_reg,grafp2_reg,grafp3_reg, grafm_reg, colpm0_raw_reg, colpm1_raw_reg, colpm2_raw_reg, colpm3_raw_reg, colpf0_raw_reg, colpf1_raw_reg,colpf2_raw_reg, colpf3_raw_reg, colbk_raw_reg, prior_raw_reg, vdelay_reg, gractl_reg, consol_output_reg, grafm_dma_load, grafm_dma_next, grafp0_dma_load, grafp0_dma_next, grafp1_dma_load, grafp1_dma_next, grafp2_dma_load, grafp2_dma_next, grafp3_dma_load, grafp3_dma_next)
	begin
		hposp0_raw_next <= hposp0_raw_reg;
		hposp1_raw_next <= hposp1_raw_reg;
		hposp2_raw_next <= hposp2_raw_reg;
		hposp3_raw_next <= hposp3_raw_reg;

		hposm0_raw_next <= hposm0_raw_reg;
		hposm1_raw_next <= hposm1_raw_reg;
		hposm2_raw_next <= hposm2_raw_reg;
		hposm3_raw_next <= hposm3_raw_reg;			

		sizep0_raw_next <= sizep0_raw_reg;
		sizep1_raw_next <= sizep1_raw_reg;
		sizep2_raw_next <= sizep2_raw_reg;
		sizep3_raw_next <= sizep3_raw_reg;

		sizem_raw_next <= sizem_raw_reg;
		
		grafp0_next <= grafp0_reg;
		grafp1_next <= grafp1_reg;
		grafp2_next <= grafp2_reg;
		grafp3_next <= grafp3_reg;

		grafm_next <= grafm_reg;
		
		colpm0_raw_next <= colpm0_raw_reg;
		colpm1_raw_next <= colpm1_raw_reg;
		colpm2_raw_next <= colpm2_raw_reg;
		colpm3_raw_next <= colpm3_raw_reg;

		colpf0_raw_next <= colpf0_raw_reg;
		colpf1_raw_next <= colpf1_raw_reg;
		colpf2_raw_next <= colpf2_raw_reg;
		colpf3_raw_next <= colpf3_raw_reg;
		
		colbk_raw_next <= colbk_raw_reg;
		
		prior_raw_next <= prior_raw_reg;
		
		vdelay_next <= vdelay_reg;
		
		gractl_next <= gractl_reg;
		
		consol_output_next <= consol_output_reg;	
		
		hitclr_write <= '0';
		
		if (grafm_dma_load = '1') then
			grafm_next <= grafm_dma_next;
		end if;

		if (grafp0_dma_load = '1') then
			grafp0_next <= grafp0_dma_next;
		end if;

		if (grafp1_dma_load = '1') then
			grafp1_next <= grafp1_dma_next;
		end if;

		if (grafp2_dma_load = '1') then
			grafp2_next <= grafp2_dma_next;
		end if;

		if (grafp3_dma_load = '1') then
			grafp3_next <= grafp3_dma_next;
		end if;
		
		if (wr_en = '1') then
			if(addr_decoded(0) = '1') then
				hposp0_raw_next <= cpu_data_in;
			end if;	

			if(addr_decoded(1) = '1') then
				hposp1_raw_next <= cpu_data_in;
			end if;		
			
			if(addr_decoded(2) = '1') then
				hposp2_raw_next <= cpu_data_in;
			end if;

			if(addr_decoded(3) = '1') then
				hposp3_raw_next <= cpu_data_in;
			end if;	
			
			if(addr_decoded(4) = '1') then
				hposm0_raw_next <= cpu_data_in;
			end if;	

			if(addr_decoded(5) = '1') then
				hposm1_raw_next <= cpu_data_in;
			end if;		
			
			if(addr_decoded(6) = '1') then
				hposm2_raw_next <= cpu_data_in;
			end if;

			if(addr_decoded(7) = '1') then
				hposm3_raw_next <= cpu_data_in;
			end if;
			
			if(addr_decoded(8) = '1') then
				sizep0_raw_next <= cpu_data_in(1 downto 0);
			end if;	

			if(addr_decoded(9) = '1') then
				sizep1_raw_next <= cpu_data_in(1 downto 0);
			end if;		
			
			if(addr_decoded(10) = '1') then
				sizep2_raw_next <= cpu_data_in(1 downto 0);
			end if;

			if(addr_decoded(11) = '1') then
				sizep3_raw_next <= cpu_data_in(1 downto 0);
			end if;
			
			if(addr_decoded(12) = '1') then
				sizem_raw_next <= cpu_data_in;
			end if;	

			if(addr_decoded(13) = '1') then
				grafp0_next <= cpu_data_in;
			end if;		
			
			if(addr_decoded(14) = '1') then
				grafp1_next <= cpu_data_in;
			end if;

			if(addr_decoded(15) = '1') then
				grafp2_next <= cpu_data_in;
			end if;			
			
			if(addr_decoded(16) = '1') then
				grafp3_next <= cpu_data_in;
			end if;	

			if(addr_decoded(17) = '1') then
				grafm_next <= cpu_data_in;
			end if;		
			
			if(addr_decoded(18) = '1') then
				colpm0_raw_next <= cpu_data_in(7 downto 1);
			end if;

			if(addr_decoded(19) = '1') then
				colpm1_raw_next <= cpu_data_in(7 downto 1);
			end if;

			if(addr_decoded(20) = '1') then
				colpm2_raw_next <= cpu_data_in(7 downto 1);
			end if;	

			if(addr_decoded(21) = '1') then
				colpm3_raw_next <= cpu_data_in(7 downto 1);
			end if;		
			
			if(addr_decoded(22) = '1') then
				colpf0_raw_next <= cpu_data_in(7 downto 1);
			end if;

			if(addr_decoded(23) = '1') then
				colpf1_raw_next <= cpu_data_in(7 downto 1);
			end if;									

			if(addr_decoded(24) = '1') then
				colpf2_raw_next <= cpu_data_in(7 downto 1);
			end if;	

			if(addr_decoded(25) = '1') then
				colpf3_raw_next <= cpu_data_in(7 downto 1);
			end if;		
			
			if(addr_decoded(26) = '1') then
				colbk_raw_next <= cpu_data_in(7 downto 1);
			end if;

			if(addr_decoded(27) = '1') then
				prior_raw_next <= cpu_data_in;
			end if;	
			
			if(addr_decoded(28) = '1') then
				vdelay_next <= cpu_data_in;
			end if;	

			if(addr_decoded(29) = '1') then
				gractl_next <= cpu_data_in(2 downto 0);
			end if;		
			
			if(addr_decoded(30) = '1') then
				-- clear the collision regs
				hitclr_write <= '1';
			end if;

			if(addr_decoded(31) = '1') then
				consol_output_next <= cpu_data_in(3 downto 0);
			end if;				
			
		end if;
	end process;
	
	-- delays...
		-- TODO - needs more attention ... 
		-- The prior behaviour here in real hardware is all over the place...
		-- THESE CAN TAKE MUCH LESS SPACE - only need to store per CPU cycle, not per colour clock original
	prior_short_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>6)
		port map(clk=>clk,sync_reset=>'0',data_in=>prior_raw_reg(5 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>prior_delayed_reg(5 downto 0));

	prior_long_delay : wide_delay_line
		generic map (COUNT=>3, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>prior_raw_reg(7 downto 6),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>prior_delayed_reg(7 downto 6));

	prior_longer_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>prior_raw_reg(7 downto 6),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>prior_delayed2_reg(7 downto 6));		
		
	colbk_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colbk_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colbk_delayed_reg(7 downto 1));	

	colpm0_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpm0_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpm0_delayed_reg(7 downto 1));		
	colpm1_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpm1_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpm1_delayed_reg(7 downto 1));		
	colpm2_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpm2_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpm2_delayed_reg(7 downto 1));		
	colpm3_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpm3_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpm3_delayed_reg(7 downto 1));		

	colpf0_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpf0_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpf0_delayed_reg(7 downto 1));		
	colpf1_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpf1_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpf1_delayed_reg(7 downto 1));		
	colpf2_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpf2_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpf2_delayed_reg(7 downto 1));		
	colpf3_delay : wide_delay_line
		generic map (COUNT=>2, WIDTH=>7)
		port map(clk=>clk,sync_reset=>'0',data_in=>colpf3_raw_reg(7 downto 1),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>colpf3_delayed_reg(7 downto 1));				

	hposp0_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposp0_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposp0_delayed_reg(7 downto 0));		
	hposp1_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposp1_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposp1_delayed_reg(7 downto 0));		
	hposp2_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposp2_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposp2_delayed_reg(7 downto 0));		
	hposp3_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposp3_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposp3_delayed_reg(7 downto 0));				

	hposm0_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposm0_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposm0_delayed_reg(7 downto 0));		
	hposm1_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposm1_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposm1_delayed_reg(7 downto 0));		
	hposm2_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposm2_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposm2_delayed_reg(7 downto 0));		
	hposm3_delay : wide_delay_line
		generic map (COUNT=>5, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>hposm3_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>hposm3_delayed_reg(7 downto 0));				
		
	sizep0_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>sizep0_raw_reg(1 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>sizep0_delayed_reg(1 downto 0));		
	sizep1_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>sizep1_raw_reg(1 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>sizep1_delayed_reg(1 downto 0));		
	sizep2_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>sizep2_raw_reg(1 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>sizep2_delayed_reg(1 downto 0));		
	sizep3_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>2)
		port map(clk=>clk,sync_reset=>'0',data_in=>sizep3_raw_reg(1 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>sizep3_delayed_reg(1 downto 0));		
	sizem_delay : wide_delay_line
		generic map (COUNT=>4, WIDTH=>8)
		port map(clk=>clk,sync_reset=>'0',data_in=>sizem_raw_reg(7 downto 0),enable=>COLOUR_CLOCK_ORIGINAL,reset_n=>reset_n,data_out=>sizem_delayed_reg(7 downto 0));				
		
	-- joystick
	process(trig_reg, trig, gractl_reg)
	begin	
		trig_next <= trig;
		
		if (gractl_reg(2) = '1') then
			trig_next <= trig_reg and trig;
		end if;
	end process;
	
	-- Read from registers		
	process(addr_decoded, CONSOL_IN, consol_output_reg, trig_reg, m0pf_reg,m1pf_reg,m2pf_reg,m3pf_reg,m0pl_reg,m1pl_reg,m2pl_reg,m3pl_reg,p0pf_reg,p1pf_reg,p2pf_reg,p3pf_reg,p0pl_reg,p1pl_reg,p2pl_reg,p3pl_reg, pal)
	begin
		data_out <= X"0F";

		if (addr_decoded(0) = '1') then
			data_out <= "0000"&m0pf_reg;
		end if;

		if (addr_decoded(1) = '1') then
			data_out <= "0000"&m1pf_reg;
		end if;
		
		if (addr_decoded(2) = '1') then
			data_out <= "0000"&m2pf_reg;
		end if;

		if (addr_decoded(3) = '1') then
			data_out <= "0000"&m3pf_reg;
		end if;

		if (addr_decoded(4) = '1') then
			data_out <= "0000"&p0pf_reg;
		end if;

		if (addr_decoded(5) = '1') then
			data_out <= "0000"&p1pf_reg;
		end if;
		
		if (addr_decoded(6) = '1') then
			data_out <= "0000"&p2pf_reg;
		end if;

		if (addr_decoded(7) = '1') then
			data_out <= "0000"&p3pf_reg;
		end if;
		
		if (addr_decoded(8) = '1') then
			data_out <= "0000"&m0pl_reg;
		end if;

		if (addr_decoded(9) = '1') then
			data_out <= "0000"&m1pl_reg;
		end if;
		
		if (addr_decoded(10) = '1') then
			data_out <= "0000"&m2pl_reg;
		end if;

		if (addr_decoded(11) = '1') then
			data_out <= "0000"&m3pl_reg;
		end if;		

		if (addr_decoded(12) = '1') then
			data_out <= "0000"&p0pl_reg;
		end if;

		if (addr_decoded(13) = '1') then
			data_out <= "0000"&p1pl_reg;
		end if;
		
		if (addr_decoded(14) = '1') then
			data_out <= "0000"&p2pl_reg;
		end if;

		if (addr_decoded(15) = '1') then
			data_out <= "0000"&p3pl_reg;
		end if;		
		
		if (addr_decoded(16) = '1') then
			data_out <= "0000000"&trig_reg(0);
		end if;

		if (addr_decoded(17) = '1') then
			data_out <= "0000000"&trig_reg(1);
		end if;

		if (addr_decoded(18) = '1') then
			data_out <= "0000000"&trig_reg(3);
		end if;
		
		if (addr_decoded(19) = '1') then
			data_out <= "0000000"&trig_reg(3);
		end if;
		
		if (addr_decoded(20) = '1') then
			data_out <= "0000"&not(pal&pal&pal)&'1';
		end if;

		if (addr_decoded(31) = '1') then
			data_out <= "0000"&(not(CONSOL_IN) and (not consol_output_reg));
		end if;
		
	end process;
	
	-- output	
	colour_out <= colour_reg;
	
	vsync<=vsync_reg;
	hsync<=hsync_reg;
	csync<=csync_reg xor vsync_reg;
	blank<=hblank_reg or vsync_reg;
	burst<=burst_reg;
	odd_line<=odd_scanline_reg;
	
	consol_out <= consol_output_reg;

end vhdl;


