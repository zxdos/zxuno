library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.Vcomponents.all;

entity DCMSID1 is
    port (CLKIN_IN  : in  std_logic;
          CLK0_OUT  : out std_logic;
          CLK0_OUT1 : out std_logic;
          CLK2X_OUT : out std_logic); 
end DCMSID1;

architecture BEHAVIORAL of DCMSID1 is
    signal CLKFX_BUF   : std_logic;
    signal CLKIN_IBUFG : std_logic;
    signal GND_BIT     : std_logic;
begin

    GND_BIT <= '0';
    CLKFX_BUFG_INST : BUFG
        port map (I => CLKFX_BUF, O => CLK0_OUT);
    
    DCM_INST : DCM
        generic map(CLK_FEEDBACK          => "NONE",
                    CLKDV_DIVIDE          => 4.0,
                    CLKFX_DIVIDE          => 12,
                    CLKFX_MULTIPLY        => 25,
                    CLKIN_DIVIDE_BY_2     => false,
                    CLKIN_PERIOD          => 65.1,
                    CLKOUT_PHASE_SHIFT    => "NONE",
                    DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
                    DFS_FREQUENCY_MODE    => "LOW",
                    DLL_FREQUENCY_MODE    => "LOW",
                    DUTY_CYCLE_CORRECTION => true,
                    FACTORY_JF            => x"C080",
                    PHASE_SHIFT           => 0,
                    STARTUP_WAIT          => false)
        port map (CLKFB    => GND_BIT,
                  CLKIN    => CLKIN_IN,
                  DSSEN    => GND_BIT,
                  PSCLK    => GND_BIT,
                  PSEN     => GND_BIT,
                  PSINCDEC => GND_BIT,
                  RST      => GND_BIT,
                  CLKDV    => open,
                  CLKFX    => CLKFX_BUF,
                  CLKFX180 => open,
                  CLK0     => open,
                  CLK2X    => CLK2X_OUT,
                  CLK2X180 => open,
                  CLK90    => open,
                  CLK180   => open,
                  CLK270   => open,
                  LOCKED   => open,
                  PSDONE   => open,
                  STATUS   => open);

end BEHAVIORAL;
