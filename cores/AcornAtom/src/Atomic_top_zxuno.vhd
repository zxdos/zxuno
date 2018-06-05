--------------------------------------------------------------------------------
-- Copyright (c) 2015 David Banks
--
-- based on work by Alan Daly. Copyright(c) 2009. All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    
-- \   \   \/    
--  \   \         
--  /   /         Filename  : Atomic_top_zxuno.vhf
-- /___/   /\     Timestamp : 19/04/2015
-- \   \  /  \ 
--  \___\/\___\ 
--
--Design Name: Atomic_top_zxuno
--Device: Spartan6 LX9

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Atomic_top_zxuno is
    port (CLK50       : in    std_logic; --Q
           ps2_clk        : in    std_logic;
           ps2_data       : in    std_logic;
           ps2_mouse_clk  : inout std_logic;
           ps2_mouse_data : inout std_logic;
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
           RAMWRn         : out   std_logic;
           SRAM_ADDR      : out   std_logic_vector (18 downto 0); --Q --20
           SRAM_DATA      : inout std_logic_vector (7 downto 0);
           SDMISO         : in    std_logic;
           SDSS           : out   std_logic;
           SDCLK          : out   std_logic;
           SDMOSI         : out   std_logic;
           LED1           : out   std_logic;
           charSet        : in    std_logic;
           JOYSTICK1      : in    std_logic_vector (7 downto 0)
           );
end Atomic_top_zxuno;

architecture behavioral of Atomic_top_zxuno is

    signal clk_vga    : std_logic;
    signal clk_16M00  : std_logic;
    signal clk_32M00  : std_logic; --Q	 
    signal IRSTn      : std_logic;
    signal ERSTn      : std_logic;     
    signal phi2       : std_logic;

    signal RamCE      : std_logic;
    signal RamWR      : std_logic;
    signal RomCE      : std_logic;
    signal RomDout    : std_logic_vector (7 downto 0);
    signal ExternWE   : std_logic;
    signal ExternA    : std_logic_vector (16 downto 0);
    signal ExternDin  : std_logic_vector (7 downto 0);
    signal ExternDout : std_logic_vector (7 downto 0);
    
    signal nARD       : std_logic;
    signal nAWR       : std_logic;
    signal AVRA0      : std_logic;
    signal AVRInt     : std_logic;
    signal AVRDataIn  : std_logic_vector (7 downto 0);
    signal AVRDataOut : std_logic_vector (7 downto 0);

    signal PL8Data    : std_logic_vector (7 downto 0);
    signal PL8Enable  : std_logic;

    signal LED1n      : std_logic;
    signal LED2n      : std_logic;

    signal SelectBFFE : std_logic;
    signal SelectBFFF : std_logic;
    
    signal RegBFFE    : std_logic_vector (7 downto 0);
    signal RegBFFF    : std_logic_vector (7 downto 0);

    signal WriteProt  : std_logic;                     -- Write protects #A000, #C000-#FFFF
    signal OSInRam    : std_logic;                     -- #C000-#FFFF in RAM
    signal ExRamBank  : std_logic_vector (1 downto 0); -- #4000-#7FFF bank select
    signal RomLatch   : std_logic_vector (3 downto 0); -- #A000-#AFFF bank select

    signal ioport     : std_logic_vector (7 downto 0);

    signal pwrup_RSTn : std_logic;
    signal reset_ctr  : std_logic_vector (7 downto 0) := (others => '0');


----Q	 
	component atom_clocks
	port
	 (-- Clock in ports
	  CLK_IN1           : in     std_logic;
	  -- Clock out ports
	  CLK_OUT1          : out    std_logic;
	  CLK_OUT2          : out    std_logic;
	  CLK_OUT3          : out    std_logic
	 );
	end component;
----	 
    
begin

    dred <= red;
    dgreen <= green;
    dblue <= blue;
    dvsync <= vsync;
    dhsync <= hsync;

----Q
atom_top_clocks : atom_clocks
  port map
   (-- Clock in ports
    CLK_IN1            => CLK50,
    -- Clock out ports
    CLK_OUT1           => clk_32M00,
    CLK_OUT2           => clk_vga,
    CLK_OUT3           => clk_16M00);
	 
-----	 
    
    inst_Atomic_core : entity work.Atomic_core
    generic map (
        CImplSDDOS        => false,
        CImplGraphicsExt  => true,
        CImplSoftChar     => true,
        CImplSID          => true,
        CImplVGA80x40     => true,
        CImplHWScrolling  => true,
        CImplMouse        => false,
        CImplUart         => false,
        CImplDoubleVideo  => false,
        MainClockSpeed    => 16000000,
        DefaultBaud       => 115200          
     )
     port map (
        clk_vga           => clk_vga,
        clk_16M00         => clk_16M00,
        clk_32M00         => clk_32M00,
        ps2_clk           => ps2_clk,
        ps2_data          => ps2_data,
        ps2_mouse_clk     => ps2_mouse_clk,
        ps2_mouse_data    => ps2_mouse_data,
        ERSTn             => ERSTn,
        IRSTn             => IRSTn,
        red               => red(2 downto 0),
        green             => green(2 downto 0),
        blue              => blue(2 downto 0),
        vsync             => vsync,
        hsync             => hsync,
        RamCE             => open,
        RomCE             => open,
        phi2              => phi2,
        ExternWE          => ExternWE,
        ExternA           => ExternA,
        ExternDin         => ExternDin,
        ExternDout        => ExternDout,        
        audiol            => audiol,
        audioR            => audioR,
        SDMISO            => '0',
        SDSS              => open,
        SDCLK             => open,
        SDMOSI            => open,
        uart_RxD          => '0', --Q
        uart_TxD          => open, --Q
        LED1              => open,
        LED2              => open,
        charSet           => charSet,
        Joystick1         => JOYSTICK1
    );  

    Inst_AVR8: entity work.AVR8 port map(
        clk16M            => clk_16M00,
        nrst              => IRSTn,
        portain           => AVRDataOut,
        portaout          => AVRDataIn,

        portbin(0)        => '0',
        portbin(1)        => '0',
        portbin(2)        => '0',
        portbin(3)        => '0',
        portbin(4)        => AVRInt,
        portbin(5)        => '0',
        portbin(6)        => '0',
        portbin(7)        => '0',
        
        portbout(0)       => nARD,
        portbout(1)       => nAWR,
        portbout(2)       => open,
        portbout(3)       => AVRA0,
        portbout(4)       => open,
        portbout(5)       => open,
        portbout(6)       => LED1n,
        portbout(7)       => LED2n,

        portdin           => (others => '0'),
        portdout(0)       => open,
        portdout(1)       => open,
        portdout(2)       => open,
        portdout(3)       => open,
        portdout(4)       => SDSS,
        portdout(5)       => open,
        portdout(6)       => open,
        portdout(7)       => open,

        -- FUDLR
        portein           => ioport,
        porteout          => open,
                
        spi_mosio         => SDMOSI,
        spi_scko          => SDCLK,
        spi_misoi         => SDMISO
     
        ,rxd               => '0', --Q
         txd               => open --Q

    );
    
    ioport <= "111" & Joystick1(5) & Joystick1(0) & Joystick1(1) & Joystick1(2) & Joystick1(3);
    
    Inst_AtomPL8: entity work.AtomPL8 port map(
        clk               => clk_16M00,
        enable            => PL8Enable,
        nRST              => IRSTn,
        RW                => not ExternWE,
        Addr              => ExternA(2 downto 0),
        DataIn            => ExternDin,
        DataOut           => PL8Data,
        AVRDataIn         => AVRDataIn,
        AVRDataOut        => AVRDataOut,
        nARD              => nARD,
        nAWR              => nAWR,
        AVRA0             => AVRA0,
        AVRINTOut         => AVRInt,
        AtomIORDOut       => open,
        AtomIOWROut       => open
    );

    rom_c000_ffff : entity work.InternalROM port map(
        CLK               => clk_16M00,
        ADDR              => ExternA,
        DATA              => RomDout
    );
    
    ERSTn      <= pwrup_RSTn and not ERST;

    RomCE      <= '1' when ExternA(15 downto 14) = "11" and OsInRam = '0' else
                  '0';

    RamCE      <= '1' when ExternA(15 downto 14) = "11" and OsInRam = '1' else
                  '1' when ExternA(15 downto 12) = "1010"                 else
                  '1' when ExternA(15) = '0'                              else
                  '0';

    RamWR      <= '0' when ExternA(15) = '1' and WriteProt = '1' else ExternWE;
    
    RAMWRn     <= not (RamWR and RamCE and phi2);
    SRAM_DATA  <= ExternDin when RamWR = '1' and RamCE = '1' else "ZZZZZZZZ";

----Q
    SRAM_ADDR  <= "010" & ExRamBank & ExternA(13 downto 0) when ExternA(15 downto 14) = "01"   else
                  "011" & RomLatch  & ExternA(11 downto 0) when ExternA(15 downto 12) = "1010" else
                  "00"  & ExternA;
----

    PL8Enable  <= '1' when ExternA(15 downto 8) = "10110100" else '0';
    
    ExternDout <= PL8Data  when PL8Enable  = '1' else
                  RomDout  when RomCE      = '1' else
                  RegBFFE  when SelectBFFE = '1' else 
                  RegBFFF  when SelectBFFF = '1' else 
                  SRAM_DATA;

    -------------------------------------------------
    -- BFFE and BFFF registers
    --
    -- See http://stardot.org.uk/forums/viewtopic.php?f=44&t=9341
    --
    -- The following are currently un-implemented:
    --
    -- - BFFE bit 6 (turbo mode)
    --   as F1..F4 already allow 1/2/4/8MHz to be selected
    --
    -- - BFFE bit 3 (#C000-#FFFF bank select)
    --   as there is insufficient space for a second ROM bank
    --   unless switch from the SoftAVR to the real AVR
    --
    -------------------------------------------------
    SelectBFFE <= '1' when ExternA(15 downto 0) = "1011111111111110" else '0';
    SelectBFFF <= '1' when ExternA(15 downto 0) = "1011111111111111" else '0';
    
    RomLatchProcess : process (ERSTn, IRSTn, clk_16M00)
    begin
        if ERSTn = '0' OR IRSTn = '0' then
            RegBFFE(3 downto 0) <= "0000";
            RegBFFF(7 downto 0) <= "00000000";
        elsif rising_edge(clk_16M00) then
            if SelectBFFE = '1' and ExternWE = '1' then
                RegBFFE <= ExternDin;
            end if;
            if SelectBFFF = '1' and ExternWE = '1' then
                RegBFFF <= ExternDin;
            end if;
        end if;
    end process;

    WriteProt  <= RegBFFE(7);
    OSInRam    <= RegBFFE(2);
    ExRamBank  <= RegBFFE(1 downto 0);
    RomLatch   <= RegBFFF(3 downto 0);
     
    LED1       <= not LED1n;

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