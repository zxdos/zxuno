library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity DE1_Toplevel is
	port
	(
		CLOCK_24		:	 in std_logic_vector(1 downto 0);
		CLOCK_27		:	 in std_logic_vector(1 downto 0);
		CLOCK_50		:	 in STD_LOGIC;
		EXT_CLOCK		:	 in STD_LOGIC;
		KEY		:	 in std_logic_vector(3 downto 0);
		SW		:	 in std_logic_vector(9 downto 0);
		HEX0		:	 out std_logic_vector(6 downto 0);
		HEX1		:	 out std_logic_vector(6 downto 0);
		HEX2		:	 out std_logic_vector(6 downto 0);
		HEX3		:	 out std_logic_vector(6 downto 0);
		LEDG		:	 out std_logic_vector(7 downto 0);
		LEDR		:	 out std_logic_vector(9 downto 0);
		UART_TXD		:	 out STD_LOGIC;
		UART_RXD		:	 in STD_LOGIC;
		DRAM_DQ		:	 inout std_logic_vector(15 downto 0);
		DRAM_ADDR		:	 out std_logic_vector(11 downto 0);
		DRAM_LDQM		:	 out STD_LOGIC;
		DRAM_UDQM		:	 out STD_LOGIC;
		DRAM_WE_N		:	 out STD_LOGIC;
		DRAM_CAS_N		:	 out STD_LOGIC;
		DRAM_RAS_N		:	 out STD_LOGIC;
		DRAM_CS_N		:	 out STD_LOGIC;
		DRAM_BA_0		:	 out STD_LOGIC;
		DRAM_BA_1		:	 out STD_LOGIC;
		DRAM_CLK		:	 out STD_LOGIC;
		DRAM_CKE		:	 out STD_LOGIC;
		FL_DQ		:	 inout std_logic_vector(7 downto 0);
		FL_ADDR		:	 out std_logic_vector(21 downto 0);
		FL_WE_N		:	 out STD_LOGIC;
		FL_RST_N		:	 out STD_LOGIC;
		FL_OE_N		:	 out STD_LOGIC;
		FL_CE_N		:	 out STD_LOGIC;
		SRAM_DQ		:	 inout std_logic_vector(15 downto 0);
		SRAM_ADDR		:	 out std_logic_vector(17 downto 0);
		SRAM_UB_N		:	 out STD_LOGIC;
		SRAM_LB_N		:	 out STD_LOGIC;
		SRAM_WE_N		:	 out STD_LOGIC;
		SRAM_CE_N		:	 out STD_LOGIC;
		SRAM_OE_N		:	 out STD_LOGIC;
		SD_DAT		:	 inout STD_LOGIC;	-- in
		SD_DAT3		:	 inout STD_LOGIC; -- out
		SD_CMD		:	 out STD_LOGIC;
		SD_CLK		:	 out STD_LOGIC;
		TDI		:	 in STD_LOGIC;
		TCK		:	 in STD_LOGIC;
		TCS		:	 in STD_LOGIC;
		TDO		:	 out STD_LOGIC;
		I2C_SDAT		:	 inout STD_LOGIC;
		I2C_SCLK		:	 out STD_LOGIC;
		PS2_DAT		:	 inout STD_LOGIC;
		PS2_CLK		:	 inout STD_LOGIC;
		VGA_HS		:	 out STD_LOGIC;
		VGA_VS		:	 out STD_LOGIC;
		VGA_R		:	 out unsigned(3 downto 0);
		VGA_G		:	 out unsigned(3 downto 0);
		VGA_B		:	 out unsigned(3 downto 0);
		AUD_ADCLRCK		:	 out STD_LOGIC;
		AUD_ADCDAT		:	 in STD_LOGIC;
		AUD_DACLRCK		:	 out STD_LOGIC;
		AUD_DACDAT		:	 out STD_LOGIC;
		AUD_BCLK		:	 inout STD_LOGIC;
		AUD_XCK		:	 out STD_LOGIC;
		GPIO_0		:	 inout std_logic_vector(35 downto 0);
		GPIO_1		:	 inout std_logic_vector(35 downto 0)
	);
END entity;

architecture rtl of DE1_Toplevel is

signal reset : std_logic;
signal clk42m      : std_logic;
signal memclk      : std_logic;
signal pll_locked : std_logic;

signal ps2m_clk_in : std_logic;
signal ps2m_clk_out : std_logic;
signal ps2m_dat_in : std_logic;
signal ps2m_dat_out : std_logic;

signal ps2k_clk_in : std_logic;
signal ps2k_clk_out : std_logic;
signal ps2k_dat_in : std_logic;
signal ps2k_dat_out : std_logic;

signal vga_red : std_logic_vector(7 downto 0);
signal vga_green : std_logic_vector(7 downto 0);
signal vga_blue : std_logic_vector(7 downto 0);
signal vga_window : std_logic;
signal vga_hsync : std_logic;
signal vga_vsync : std_logic;

signal audio_l : signed(15 downto 0);
signal audio_r : signed(15 downto 0);

signal hex : std_logic_vector(15 downto 0);

signal SOUND_L : std_logic_vector(15 downto 0);
signal SOUND_R : std_logic_vector(15 downto 0);
signal CmtIn : std_logic;

signal boot_req : std_logic;
signal boot_ack : std_logic;

alias PS2_MDAT : std_logic is GPIO_1(19);
alias PS2_MCLK : std_logic is GPIO_1(18);

COMPONENT SEG7_LUT
	PORT
	(
		oSEG		:	 OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		iDIG		:	 IN STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

begin

--	All bidir ports tri-stated
FL_DQ <= (others => 'Z');
SRAM_DQ <= (others => 'Z');
I2C_SDAT	<= 'Z';
GPIO_0 <= (others => 'Z');
GPIO_1 <= (others => 'Z');


-- PS2 keyboard & mouse
ps2m_dat_in<=PS2_MDAT;
PS2_MDAT <= '0' when ps2m_dat_out='0' else 'Z';
ps2m_clk_in<=PS2_MCLK;
PS2_MCLK <= '0' when ps2m_clk_out='0' else 'Z';

ps2k_dat_in<=PS2_DAT;
PS2_DAT <= '0' when ps2k_dat_out='0' else 'Z';
ps2k_clk_in<=PS2_CLK;
PS2_CLK <= '0' when ps2k_clk_out='0' else 'Z';


reset<=(not SW(0) xor KEY(0)) and pll_locked;

hexdigit0 : component SEG7_LUT
	port map (oSEG => HEX0, iDIG => hex(3 downto 0));
hexdigit1 : component SEG7_LUT
	port map (oSEG => HEX1, iDIG => hex(7 downto 4));
hexdigit2 : component SEG7_LUT
	port map (oSEG => HEX2, iDIG => hex(11 downto 8));
hexdigit3 : component SEG7_LUT
	port map (oSEG => HEX3, iDIG => hex(15 downto 12));

  U00 : entity work.pll
    port map(					-- for Altera DE1
      inclk0 => CLOCK_50,       -- 50 MHz external
      c0     => clk42m,         -- slow clock
      c1     => memclk,         -- fast clock
      c2     => DRAM_CLK        -- fast phase shifted for SDRAM
    );


myVgaMaster : entity work.video_vga_master
		generic map (
			clkDivBits => 4
		)
		port map (
			clk => memclk,
			clkDiv => X"4",	-- 100 Mhz / (3+1) = 25 Mhz

			hSync => vga_hsync,
			vSync => vga_vsync,

			-- Setup 640x480@60hz needs ~25 Mhz
			xSize => TO_UNSIGNED(800,12),
			ySize => TO_UNSIGNED(525,12),
			xSyncFr => TO_UNSIGNED(656,12),
			xSyncTo => TO_UNSIGNED(752,12),
			ySyncFr => TO_UNSIGNED(500,12),
			ySyncTo => TO_UNSIGNED(502,12)
		);

VGA_HS<=vga_hsync;
VGA_VS<=vga_vsync;

top : entity work.CtrlModule
	generic map(
		sysclk_frequency => 1260
	)
	port map(
		clk => memclk,
		reset_n => KEY(0),

		-- SD/MMC slot ports
		spi_clk => SD_CLK,
		spi_mosi => SD_CMD,
		spi_cs => SD_DAT3,
		spi_miso => SD_DAT,
		 
		txd => UART_TXD,
		rxd => UART_RXD,

		-- DIP Switches
		dipswitches(10) => LEDG(0),
		dipswitches(9 downto 0) => LEDR,
		
		-- PS/2
		ps2k_clk_in => ps2k_clk_in,
		ps2k_dat_in => ps2k_dat_in,
--		ps2k_clk_out => ps2k_clk_out,
--		ps2k_dat_out => ps2k_dat_out
		ps2m_clk_in => ps2m_clk_in,
		ps2m_dat_in => ps2m_dat_in,
		ps2m_clk_out => ps2m_clk_out,
		ps2m_dat_out => ps2m_dat_out,
		vga_hsync => vga_hsync,
		vga_vsync => vga_vsync,
		osd_window => VGA_B(3),
		osd_pixel => VGA_G(3),
		host_bootdata_req => boot_req,
		host_bootdata_ack => boot_ack,
		mouse_deltax => hex(15 downto 8),
		mouse_deltay=> hex(7 downto 0),
		mouse_idle => '1'
);

boot_req<=not boot_ack;

ps2k_clk_out<='1';
ps2k_dat_out<='1';

-- Audio
		
end architecture;
