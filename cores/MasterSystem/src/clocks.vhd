------------------------------------------------------------------------------
-- Input Clock   Input Freq (MHz)   Input Jitter (UI)
------------------------------------------------------------------------------
-- primary          50.000            0.010
-- Generador relojes PLL para el in de 50Mhz del ZX-UNO

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clock is
port
 (-- Clock in ports
  clk_in           : in     std_logic;
  sel_pclock : in std_logic;
  sel_cpu : in std_logic;
  -- Clock out ports
  clk8          : out    std_logic;
  clk16          : out    std_logic;
  clk_cpu          : out    std_logic;
--  clk32  : out    std_logic;
  pclock : out std_logic;
  cpu_pclock : out std_logic
 );
end clock;

architecture behavioral of clock is
  -- Input clock buffering / unused connectors
  signal clkin1      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal clkout0          : std_logic;
  signal clkout1          : std_logic;
  signal clkout2          : std_logic;
  signal clkout3          : std_logic;
  signal clkout4_unused   : std_logic;
  signal clkout5_unused   : std_logic;
  -- Unused status signals
  signal locked_unused    : std_logic;
  
  signal clk357 : std_logic;

begin

  -- Input buffering
  --------------------------------------
  clkin1_buf : IBUFG
  port map
   (O => clkin1,
    I => clk_in);


  -- Clocking primitive
  --------------------------------------
  -- Instantiation of the PLL primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  pll_base_inst : PLL_BASE
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "SYSTEM_SYNCHRONOUS",
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT        => 16,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 100, --25 = 32Mhz, --100 = 8Mhz --1120 = 7,12Mhz (/2 = 3,57)
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT1_DIVIDE       => 50, --50 = 16MHz
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKOUT2_DIVIDE       => 25, --27 ~29.5Mhz Z80     --100 = 8mhz    --50 = 16mhz   --32 = 25Mhz
    CLKOUT2_PHASE        => 0.000,
    CLKOUT2_DUTY_CYCLE   => 0.500,
--    CLKOUT3_DIVIDE       => 112, --25 = 32Mhz for HDMI clock
--    CLKOUT3_PHASE        => 0.000,
--    CLKOUT3_DUTY_CYCLE   => 0.500,
    CLKIN_PERIOD         => 20.0,
    REF_JITTER           => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfbout,
    CLKOUT0             => clkout0,
    CLKOUT1             => clkout1,
    CLKOUT2             => clkout2,
    CLKOUT3             => clkout3,
    CLKOUT4             => clkout4_unused,
    CLKOUT5             => clkout5_unused,
    LOCKED              => locked_unused,
    RST                 => '0',
    -- Input clock control
    CLKFBIN             => clkfbout_buf,
    CLKIN               => clkin1);

  -- Output buffering
  -------------------------------------
  clkf_buf : BUFG
  port map
   (O => clkfbout_buf,
    I => clkfbout);


  clkout1_buf : BUFG
  port map
   (O   => clk8,
    I   => clkout0);

  clkout2_buf : BUFG
  port map
   (O   => clk16,
    I   => clkout1);

  clkout3_buf : BUFG
  port map
   (O   => clk_cpu,
    I   => clkout2);

--  clkout4_buf : BUFG
--  port map
--   (O   => clk32,
--    I   => clkout3);
	 
	pclock_sel : BUFGMUX --muxer del relojes 16 / 8 para el pixel clock del scandoubler on/off
	port map
	(O => pclock,
	 I0 => clkout0, --el de 8
	 I1 => clkout1, --el de 16
	 S => sel_pclock);
	 
	 
	pclock_sel_cpu : BUFGMUX --muxer del relojes 32 / 8 para el cambio de cpu (32 = loader/SD)
	port map
	(O => cpu_pclock,
	 I0 => clkout1, 
	 I1 => clkout2, --el de 32
	 S => sel_cpu);	 

--	process (clkout3)
--	 begin
--		if rising_edge(clkout3) then
--			clk357 <= not clk357;
--		end if;
--	end process;

end behavioral;
