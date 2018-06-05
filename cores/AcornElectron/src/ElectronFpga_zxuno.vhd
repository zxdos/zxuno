--------------------------------------------------------------------------------
-- Copyright (c) 2015 David Banks
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    
-- \   \   \/    
--  \   \         
--  /   /         Filename  : ElectronFpga.vhf
-- /___/   /\     Timestamp : 28/07/2015
-- \   \  /  \ 
--  \___\/\___\ 
--
--Design Name: ElectronFpga
--Device: Spartan6 LX9

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ElectronFpga is
    port (
        clk50      : in    std_logic;
        ps2_clk        : in    std_logic;
        ps2_data       : in    std_logic;
        ERST           : in    std_logic;
        red            : inout std_logic_vector (2 downto 0);
        green          : inout std_logic_vector (2 downto 0);
        blue           : inout std_logic_vector (2 downto 0);
        vsync          : inout std_logic;
        hsync          : inout std_logic;
        dred           : out   std_logic_vector (2 downto 0);
        dgreen         : out   std_logic_vector (2 downto 0);
        dblue          : out   std_logic_vector (2 downto 0);
        dvsync         : out   std_logic;
        dhsync         : out   std_logic;
        audiol         : out   std_logic;
        audioR         : out   std_logic;
        casIn          : in    std_logic;
        casOut         : out   std_logic;
        LED1           : out   std_logic;
        SDMISO         : in    std_logic;
        SDSS           : out   std_logic;
        SDCLK          : out   std_logic;
        SDMOSI         : out   std_logic
     );
end;

architecture behavioral of ElectronFpga is

    signal clk_16M00  : std_logic;
    signal clk_33M33  : std_logic;
    signal clk_40M00  : std_logic;
    signal ERSTn      : std_logic;     
    signal pwrup_RSTn : std_logic;
    signal reset_ctr  : std_logic_vector (7 downto 0) := (others => '0');
    
begin

    dred <= red;
    dgreen <= green;
    dblue <= blue;
    dvsync <= vsync;
    dhsync <= hsync;

 relojes_electron: entity work.relojes
  port map
   (-- Clock in ports
    CLK_IN1 => clk50,
    -- Clock out ports
    CLK_OUT1 => clk_40M00,
    CLK_OUT2 => clk_16M00,
    CLK_OUT3 => clk_33M33
	 );
	 
    inst_ElectronFpga_core : entity work.ElectronFpga_core
     port map (
        clk_16M00         => clk_16M00,
        clk_33M33         => clk_33M33,
        clk_40M00         => clk_40M00,
        ps2_clk           => ps2_clk,
        ps2_data          => ps2_data,
        ERSTn             => ERSTn,
        red               => red,
        green             => green,
        blue              => blue,
        vsync             => vsync,
        hsync             => hsync,
        audiol            => audiol,
        audioR            => audioR,
        casIn             => casIn,
        casOut            => casOut,
        LED1              => LED1,
        SDMISO            => SDMISO,
        SDSS              => SDSS,
        SDCLK             => SDCLK,
        SDMOSI            => SDMOSI
    );  
    
    ERSTn      <= pwrup_RSTn and not ERST;

    -- This internal counter forces power up reset to happen
    -- This is needed by the GODIL to initialize some of the registers
    ResetProcess : process (clk_16M00)
    begin
        if rising_edge(clk_16M00) then
            if (pwrup_RSTn = '0') then
                reset_ctr <= reset_ctr + 1;
            end if;
        end if;
    end process;
    pwrup_RSTn <= reset_ctr(7);
    
end behavioral;
