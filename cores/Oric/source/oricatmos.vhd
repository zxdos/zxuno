--
-- ORIC ATMOS top level module
--
--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;

library unisim;
	use unisim.vcomponents.all;

entity ORIC is
port (
	I_RESET              : in    std_logic;

	-- Keyboard
	PS2CLK1              : in    std_logic;
	PS2DAT1              : in    std_logic;

	-- Audio out
	AUDIO_OUT           : out   std_logic;

	-- VGA out
	O_VIDEO_R           : out   std_logic_vector(2 downto 0); --Q
	O_VIDEO_G           : out   std_logic_vector(2 downto 0); --Q
	O_VIDEO_B           : out   std_logic_vector(2 downto 0); --Q
	O_HSYNC             : out   std_logic;
	O_VSYNC             : out   std_logic;
	VIDEO_SYNC          : out   std_logic;

	-- K7 connector
	K7_TAPEIN         : in    std_logic;
	K7_TAPEOUT        : out   std_logic;

--	K7_REMOTE         : out   std_logic;
--	K7_AUDIOOUT       : out   std_logic;

	-- PRINTER
--	PRT_DATA          : inout std_logic_vector(7 downto 0);
--	PRT_STR           : out   std_logic;  -- strobe
--	PRT_ACK           : in    std_logic;  -- ack

--	MAPn              : in    std_logic;
--	ROMDISn           : in    std_logic;
--	IRQn              : in    std_logic;
	---
--	CLK_EXT           : out   std_logic;  -- 1 MHZ
--	RW                : out   std_logic;
--	IO                : out   std_logic;
--	IOCONTROL         : in    std_logic;

    O_NTSC              : out   std_logic; --Q
    O_PAL               : out   std_logic; --Q

	-- Clk master
	CLK_50              : in    std_logic  -- MASTER CLK
);
end;

architecture RTL of ORIC is

	-- Resets
	signal loc_reset_n        : std_logic; --active low

	-- Internal clocks
	signal CLKFB              : std_logic := '0';
	signal clk24              : std_logic := '0';
	signal clk12              : std_logic := '0';
	signal clk6               : std_logic := '0';
	signal clk_aud            : std_logic := '0';
	signal clkout0            : std_logic := '0';
	signal clkout1            : std_logic := '0';
	signal clkout2            : std_logic := '0';
	signal clkout3            : std_logic := '0';
	signal clkout4            : std_logic := '0';
	signal clkout5            : std_logic := '0';
	signal pll_locked         : std_logic := '0';

	-- cpu
	signal CPU_ADDR           : std_logic_vector(23 downto 0);
	signal CPU_DI             : std_logic_vector( 7 downto 0);
	signal CPU_DO             : std_logic_vector( 7 downto 0);
	signal cpu_rw             : std_logic;
	signal cpu_irq            : std_logic;
	signal ad                 : std_logic_vector(15 downto 0);

	-- VIA
	signal via_pa_out_oe      : std_logic_vector( 7 downto 0);
	signal via_pa_in          : std_logic_vector( 7 downto 0);
	signal via_pa_out         : std_logic_vector( 7 downto 0);
--	signal via_ca2_out        : std_logic;
--	signal via_ca2_oe_l       : std_logic;
--	signal via_cb1_in         : std_logic;
	signal via_cb1_out        : std_logic;
	signal via_cb1_oe_l       : std_logic;
	signal via_cb2_out        : std_logic;
	signal via_cb2_oe_l       : std_logic;
	signal via_in             : std_logic_vector( 7 downto 0);
	signal via_out            : std_logic_vector( 7 downto 0);
	signal via_oe_l           : std_logic_vector( 7 downto 0);
	signal VIA_DO             : std_logic_vector( 7 downto 0);

	-- Keyboard
	signal KEY_ROW            : std_logic_vector( 7 downto 0);

	-- PSG
	signal psg_bdir           : std_logic; -- PSG read/write
	signal PSG_OUT            : std_logic_vector( 7 downto 0);

	-- ULA
	signal ula_phi2           : std_logic;
	signal ula_CSIOn          : std_logic;
	signal ula_CSIO           : std_logic;
	signal ula_CSROMn         : std_logic;
--	signal ula_CSRAMn         : std_logic;
	signal SRAM_DO            : std_logic_vector( 7 downto 0);
	signal ula_AD_SRAM        : std_logic_vector(15 downto 0);
	signal ula_CE_SRAM        : std_logic;
	signal ula_OE_SRAM        : std_logic;
	signal ula_WE_SRAM        : std_logic;
	signal ula_LE_SRAM        : std_logic;
	signal ula_CLK_4          : std_logic;
	signal ula_IOCONTROL      : std_logic;
	signal ula_VIDEO_R        : std_logic;
	signal ula_VIDEO_G        : std_logic;
	signal ula_VIDEO_B        : std_logic;
	signal ula_SYNC           : std_logic;

	signal ROM_DO             : std_logic_vector( 7 downto 0);

	-- VIDEO
	signal HSync              : std_logic;
	signal VSync              : std_logic;
	signal hs_int             : std_logic;
	signal vs_int             : std_logic;
	signal dummy              : std_logic_vector( 3 downto 0) := (others => '0');
	signal s_cmpblk_n_out     : std_logic;

	signal VideoR             : std_logic_vector(3 downto 0);
	signal VideoG             : std_logic_vector(3 downto 0);
	signal VideoB             : std_logic_vector(3 downto 0);

	signal red_s              : std_logic;
	signal grn_s              : std_logic;
	signal blu_s              : std_logic;

	signal clk_s              : std_logic;
	signal s_blank            : std_logic;

begin
	-----------------------------------------------
	-- generate all the system clocks required
	-----------------------------------------------
	inst_pll_base : PLL_BASE
	generic map (
		BANDWIDTH          => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED"
		COMPENSATION       => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRNOUS", "SOURCE_SYNCHRNOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		CLKIN_PERIOD       => 20.00, -- Clock period (ns) of input clock on CLKIN
		-- 1/12 || 2/25
		DIVCLK_DIVIDE      => 1,     -- Division factor for all clocks (1 to 52)
		CLKFBOUT_MULT      => 12,    -- Multiplication factor for all output clocks (1 to 64)
		CLKFBOUT_PHASE     => 0.0,   -- Phase shift (degrees) of all output clocks
		REF_JITTER         => 0.100, -- Input reference jitter (0.000 to 0.999 UI%)
		-- 120Mhz positive
		CLKOUT0_DIVIDE     => 5,     -- Division factor for CLKOUT0 (1 to 128)
		CLKOUT0_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT0 (0.01 to 0.99)
		CLKOUT0_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
		-- 120Mhz negative
		CLKOUT1_DIVIDE     => 5,     -- Division factor for CLKOUT1 (1 to 128)
		CLKOUT1_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT1 (0.01 to 0.99)
		CLKOUT1_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
		-- 24Mhz
		CLKOUT2_DIVIDE     => 25,    -- Division factor for CLKOUT2 (1 to 128)
		CLKOUT2_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT2 (0.01 to 0.99)
		CLKOUT2_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
		-- 24Mhz
		CLKOUT3_DIVIDE     => 25,    -- Division factor for CLKOUT3 (1 to 128)
		CLKOUT3_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT3 (0.01 to 0.99)
		CLKOUT3_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
		-- 12Mhz
		CLKOUT4_DIVIDE     => 50,    -- Division factor for CLKOUT4 (1 to 128)
		CLKOUT4_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT4 (0.01 to 0.99)
		CLKOUT4_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
		-- 6MHz
		CLKOUT5_DIVIDE     => 100,   -- Division factor for CLKOUT5 (1 to 128)
		CLKOUT5_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT5 (0.01 to 0.99)
		CLKOUT5_PHASE      => 0.0    -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
	)
	port map (
		CLKFBOUT => CLKFB,      -- General output feedback signal
		CLKOUT0  => clkout0,
		CLKOUT1  => clkout1,
		CLKOUT2  => clkout2,
		CLKOUT3  => clkout3,
		CLKOUT4  => clkout4,
		CLKOUT5  => clkout5,
		LOCKED   => pll_locked, -- Active high PLL lock signal
		CLKFBIN  => CLKFB,      -- Clock feedback input
		CLKIN    => CLK_50,     -- Clock input
		RST      => I_RESET     -- Asynchronous PLL reset
	);


	inst_buf3 : BUFG port map (I => clkout3, O => clk24);
	inst_buf4 : BUFG port map (I => clkout4, O => clk12);
	clk6 <= clkout5;

	------------------------------------------------

--	CLK_EXT <= ula_phi2;

	-- Reset
	loc_reset_n <= pll_locked;

	------------------------------------------------------------
	-- CPU 6502
	------------------------------------------------------------
	inst_cpu : entity work.T65
	port map (
		Mode    => "00",
		Res_n   => loc_reset_n,
		Enable  => '1',
		Clk     => ula_phi2,
		Rdy     => '1',
		Abort_n => '1',
		IRQ_n   => cpu_irq,
		NMI_n   => '1',
		SO_n    => '1',
		R_W_n   => cpu_rw,
		Sync    => open,
		EF      => open,
		MF      => open,
		XF      => open,
		ML_n    => open,
		VP_n    => open,
		VDA     => open,
		VPA     => open,
		A       => CPU_ADDR,
		DI      => CPU_DI,
		DO      => CPU_DO
	);

	inst_rom : entity work.rom_oa
	port map (
		clk  => clk24,
		ADDR => CPU_ADDR(13 downto 0),
		DATA => ROM_DO
	);

	------------------------------------------------------------
	-- STATIC RAM
	------------------------------------------------------------
	ad(15 downto 0)  <= ula_AD_SRAM when ula_phi2 = '0' else CPU_ADDR(15 downto 0);
--	ad(17 downto 16) <= "00";

	inst_ram : entity work.ram48k
	port map(
		clk  => clk24,
		cs   => ula_CE_SRAM,
		oe   => ula_OE_SRAM,
		we   => ula_WE_SRAM,
		addr => ad,
		di   => CPU_DO,
		do   => SRAM_DO
	);

	------------------------------------------------------------
	-- ULA
	------------------------------------------------------------
	inst_ula : entity work.ULA
	port map (
		RESETn     => loc_reset_n,
		CLK        => clk24,
		CLK_4      => ula_CLK_4,

		RW         => cpu_rw,
		ADDR       => CPU_ADDR(15 downto 0),
--		MAPn       => MAPn,
		MAPn       => '1',
		DB         => SRAM_DO,

		-- DRAM
--		AD_RAM     => open,
--		RASn       => open,
--		CASn       => open,
--		MUX        => open,
--		RW_RAM     => open,

		-- Address decoding
--		CSRAMn     => ula_CSRAMn,
		CSROMn     => ula_CSROMn,
		CSIOn      => ula_CSIOn,

		-- RAM
		SRAM_AD    => ula_AD_SRAM,
		SRAM_OE    => ula_OE_SRAM,
		SRAM_CE    => ula_CE_SRAM,
		SRAM_WE    => ula_WE_SRAM,
		LATCH_SRAM => ula_LE_SRAM,

		-- CPU Clock
		PHI2       => ula_PHI2,

		-- Video
		R          => ULA_VIDEO_R,
		G          => ULA_VIDEO_G,
		B          => ULA_VIDEO_B,
		SYNC       => ULA_SYNC,
		HSYNC      => hs_int,
		VSYNC      => vs_int
	);
   

	-----------------------------------------------------------------
	-- video scan converter required to display video on VGA hardware
	-----------------------------------------------------------------
	-- total resolution 354x312, active resolution 240x224, H 15625 Hz, V 50.08 Hz
	-- take note: the values below are relative to the CLK period not standard VGA clock period
	inst_scan_conv : entity work.VGA_SCANCONV
	generic map (
		-- mark active area of input video
		cstart      =>  65,  -- composite sync start
		clength     => 240,  -- composite sync length

		-- output video timing
		hA          =>  10,	-- h front porch
		hB          =>  46,	-- h sync
		hC          =>  24,	-- h back porch
		hD          => 240,	-- visible video

--		vA          =>  34,	-- v front porch (not used)
		vB          =>   2,	-- v sync
		vC          =>  20,	-- v back porch
		vD          => 224,	-- visible video

		hpad        =>  32,	-- H black border
		vpad        =>  32	-- V black border
	)
	port map (
		I_VIDEO(15 downto 12) => "0000",

		-- only 3 bit color
		I_VIDEO(11)           => ULA_VIDEO_R,
		I_VIDEO(10)           => ULA_VIDEO_R,
		I_VIDEO(9)            => ULA_VIDEO_R,
		I_VIDEO(8)            => ULA_VIDEO_R,

		I_VIDEO(7)            => ULA_VIDEO_G,
		I_VIDEO(6)            => ULA_VIDEO_G,
		I_VIDEO(5)            => ULA_VIDEO_G,
		I_VIDEO(4)            => ULA_VIDEO_G,

		I_VIDEO(3)            => ULA_VIDEO_B,
		I_VIDEO(2)            => ULA_VIDEO_B,
		I_VIDEO(1)            => ULA_VIDEO_B,
		I_VIDEO(0)            => ULA_VIDEO_B,
		I_HSYNC               => hs_int,
		I_VSYNC               => vs_int,

		-- for VGA output, feed these signals to VGA monitor
		O_VIDEO(15 downto 12)=> dummy,
		O_VIDEO(11 downto 8) => VideoR,
		O_VIDEO( 7 downto 4) => VideoG,
		O_VIDEO( 3 downto 0) => VideoB,
		O_HSYNC					=> HSync,
		O_VSYNC					=> VSync,
		O_CMPBLK_N				=> s_cmpblk_n_out,

		--
		CLK                   => clk6,
		CLK_x2                => clk12
	);

--Q
-- Para scandoubler descomentar esto y comentar las directas de la ULA
--	O_VIDEO_R <= VideoR(0) & VideoR(1) & VideoR(2) ;
--	O_VIDEO_G <= VideoG(0) & VideoG(1) & VideoG(2) ;
--	O_VIDEO_B <= VideoB(0) & VideoB(1) & VideoB(2) ;
--
--	O_HSYNC	<= HSync;
--	O_VSYNC	<= VSync;
----
	


-- Señales TV directas de la ULA	
	O_NTSC <= '0';
	O_PAL <= '1';

   O_HSYNC      <= ULA_SYNC;
   O_VSYNC      <= vs_int;
	O_VIDEO_R <= ULA_VIDEO_R & ULA_VIDEO_R & ULA_VIDEO_R;  
	O_VIDEO_G <= ULA_VIDEO_G & ULA_VIDEO_G & ULA_VIDEO_G;
	O_VIDEO_B <= ULA_VIDEO_B & ULA_VIDEO_B & ULA_VIDEO_B;
----
--fQ

	------------------------------------------------------------
	-- VIA
	------------------------------------------------------------
	ula_CSIO <= not ula_CSIOn;

	inst_via : entity work.M6522
	port map (
		I_RS          => CPU_ADDR(3 downto 0),
		I_DATA        => CPU_DO(7 downto 0),
		O_DATA        => VIA_DO,
		O_DATA_OE_L   => open,

		I_RW_L        => cpu_rw,
		I_CS1         => ula_CSIO,
		I_CS2_L       => ula_IOCONTROL,

		O_IRQ_L       => cpu_irq,   -- note, not open drain

		-- PORT A
		I_CA1         => '1',       -- PRT_ACK
		I_CA2         => '1',       -- psg_bdir
		O_CA2         => psg_bdir,  -- via_ca2_out
		O_CA2_OE_L    => open,

		I_PA          => via_pa_in,
		O_PA          => via_pa_out,
		O_PA_OE_L     => via_pa_out_oe,

		-- PORT B
		I_CB1         => K7_TAPEIN,
--		I_CB1         => '0',
		O_CB1         => via_cb1_out,
		O_CB1_OE_L    => via_cb1_oe_l,

		I_CB2         => '1',
		O_CB2         => via_cb2_out,
		O_CB2_OE_L    => via_cb2_oe_l,

		I_PB          => via_in,
		O_PB          => via_out,
		O_PB_OE_L     => via_oe_l,

		--
		RESET_L       => loc_reset_n,
		I_P2_H        => ula_phi2,
		ENA_4         => '1',
		CLK           => ula_CLK_4
	);

	------------------------------------------------------------
	-- KEYBOARD
	------------------------------------------------------------
	inst_key : entity work.keyboard
	port map(
		CLK		=> clk24,
		RESETn	=> loc_reset_n, -- active high reset

		PS2CLK	=> PS2CLK1,
		PS2DATA	=> PS2DAT1,

		COL		=> via_out(2 downto 0),
		ROWbit	=> KEY_ROW
	);

	-- Keyboard
	via_in <= x"F7" when (KEY_ROW or VIA_PA_OUT) = x"FF" else x"FF";

	------------------------------------------------------------
	-- PSG AY-3-8192
	------------------------------------------------------------
	inst_psg : entity work.YM2149
	port map (
		I_DA       => via_pa_out,
		O_DA       => via_pa_in,
		O_DA_OE_L  => open,
		-- control
		I_A9_L     => '0',
		I_A8       => '1',
		I_BDIR     => via_cb2_out,
		I_BC2      => '1',
		I_BC1      => psg_bdir,
		I_SEL_L    => '1',

		O_AUDIO    => PSG_OUT,
		-- port a
--		I_IOA      => x"00",
--		O_IOA      => open,
--		O_IOA_OE_L => open,
		-- port b
--		I_IOB      => x"00",
--		O_IOB      => open,
--		O_IOB_OE_L => open,

		RESET_L    => loc_reset_n,
		ENA        => '1',
		CLK        => ula_PHI2
	);

	------------------------------------------------------------
	-- Sigma Delta DAC
	------------------------------------------------------------
	inst_dac : entity work.DAC
	port map (
		clk_i  => clk24,
		resetn => loc_reset_n,
		dac_i  => PSG_OUT,
		dac_o  => AUDIO_OUT
	);

	------------------------------------------------------------
	-- Multiplex CPU , RAM/VIA , ROM
	------------------------------------------------------------
	ula_IOCONTROL <= '0';

	process
	begin
		wait until rising_edge(clk24);

		-- expansion port
		if    cpu_rw = '1' and ula_IOCONTROL = '1' and ula_CSIOn  = '0'                       then
			CPU_DI <= SRAM_DO;
		-- Via
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_CSIOn  = '0' and ula_LE_SRAM = '0' then
			CPU_DI <= VIA_DO;
		-- ROM
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_CSROMn = '0'                       then
			CPU_DI <= ROM_DO;
		-- Read data
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_phi2   = '1' and ula_LE_SRAM = '0' then
			cpu_di <= SRAM_DO;
		end if;
	end process;

	------------------------------------------------------------
	-- K7 PORT
	------------------------------------------------------------
	K7_TAPEOUT  <= via_out(7);
--	K7_REMOTE   <= via_out(6);
--	K7_AUDIOOUT <= AUDIO_OUT;

	------------------------------------------------------------
	-- PRINTER PORT
	------------------------------------------------------------
--	PRT_DATA    <= via_pa_out;
--	PRT_STR     <= via_out(4);
end RTL;
