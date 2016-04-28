--------------------------------------------------------------------------------
-- Copyright (c) 2009 Alan Daly.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    
-- \   \   \/    
--  \   \         
--  /   /         Filename  : Atomic_top.vhf
-- /___/   /\     Timestamp : 02/03/2013 06:17:50
-- \   \  /  \ 
--  \___\/\___\ 
--
--Design Name: Atomic_top
--Device: spartan3A
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Atomic_core is
    generic (
       CImplSDDOS       : boolean;
       CImplGraphicsExt : boolean;
       CImplSoftChar    : boolean;
       CImplSID         : boolean;
       CImplVGA80x40    : boolean;
       CImplHWScrolling : boolean;
       CImplMouse       : boolean;
       CImplUart        : boolean;
       CImplDoubleVideo : boolean;
       MainClockSpeed   : integer;
       DefaultBaud      : integer
    );
    port (clk_vga : in    std_logic;
        clk_16M00 : in    std_logic;
        clk_32M00 : in    std_logic;
        ps2_clk   : in    std_logic;
        ps2_data  : in    std_logic;
        ps2_mouse_clk   : inout    std_logic;
        ps2_mouse_data  : inout    std_logic;
        ERSTn     : in    std_logic;
        IRSTn     : out   std_logic;
        red       : out   std_logic_vector (2 downto 0);
        green     : out   std_logic_vector (2 downto 0);
        blue      : out   std_logic_vector (2 downto 0);
        vsync     : out   std_logic;
        hsync     : out   std_logic;
        RamCE     : out   std_logic;
        RomCE     : out   std_logic;
        phi2      : out   std_logic;
        ExternWE  : out   std_logic;
        ExternA   : out   std_logic_vector (16 downto 0);
        ExternDin : out   std_logic_vector (7 downto 0);
        ExternDout: in    std_logic_vector (7 downto 0);
        audiol    : out   std_logic;
        audioR    : out   std_logic;
        SDMISO    : in    std_logic;
        SDSS      : out   std_logic;
        SDCLK     : out   std_logic;
        SDMOSI    : out   std_logic;
        uart_RxD  : in    std_logic;
        uart_TxD  : out   std_logic;
        LED1      : out   std_logic;        
        LED2      : out   std_logic;
        charSet   : in    std_logic;
        Joystick1 : in    std_logic_vector (7 downto 0) := (others => '1')
--      ;  Joystick2 : in    std_logic_vector (7 downto 0) := (others => '1')
        );
end Atomic_core;

architecture BEHAVIORAL of Atomic_core is
    
-------------------------------------------------
-- cpu signals names
-------------------------------------------------
    signal cpu_R_W_n         : std_logic;
    signal cpu_addr          : std_logic_vector (15 downto 0);
    signal cpu_din           : std_logic_vector (7 downto 0);
    signal cpu_dout          : std_logic_vector (7 downto 0);
    signal cpu_IRQ_n         : std_logic;
--cpu clock and enables
    signal clken_counter     : std_logic_vector (3 downto 0);
    signal cpu_cycle         : std_logic;
    signal cpu_clken         : std_logic;
    signal not_cpu_R_W_n     : std_logic;
    signal phi               : std_logic;
---------------------------------------------------
-- VDG signals names
---------------------------------------------------
    signal RSTn              : std_logic;
    signal vdg_fs_n          : std_logic;
    signal vdg_an_g          : std_logic;
    signal vdg_gm            : std_logic_vector(2 downto 0);
    signal vdg_css           : std_logic;
    -- VGA output
    signal vdg_red           : std_logic;
    signal vdg_green1        : std_logic;
    signal vdg_green0        : std_logic;
    signal vdg_blue          : std_logic;
    signal vdg_hsync         : std_logic;
    signal vdg_vsync         : std_logic;
    signal vdg_hblank        : std_logic;
    signal vdg_vblank        : std_logic;
----------------------------------------------------
-- enables
----------------------------------------------------
    signal mc6522_enable     : std_logic;
    signal i8255_enable      : std_logic;
    signal extern_rom_enable : std_logic;
    signal extern_ram_enable : std_logic;
    signal video_ram_enable  : std_logic;
    signal reg_enable        : std_logic;
    signal sid_enable        : std_logic;
    signal uart_enable       : std_logic;
    signal gated_we          : std_logic;
    signal video_ram_we      : std_logic;
    signal reg_we            : std_logic;
    signal sid_we            : std_logic;
    signal uart_we           : std_logic;
----------------------------------------------------
-- ram/roms
----------------------------------------------------
    signal extern_data       : std_logic_vector(7 downto 0);
    signal godil_data        : std_logic_vector(7 downto 0);
----------------------------------------------------
--
----------------------------------------------------
    signal via4_clken        : std_logic;
    signal via1_clken        : std_logic;
    signal mc6522_data       : std_logic_vector(7 downto 0);
    signal mc6522_irq        : std_logic;
    signal mc6522_ca1        : std_logic;
    signal mc6522_ca2        : std_logic;
    signal mc6522_cb1        : std_logic;
    signal mc6522_cb2        : std_logic;
    signal mc6522_porta      : std_logic_vector(7 downto 0);
    signal mc6522_portb      : std_logic_vector(7 downto 0);

    signal i8255_pa_data  : std_logic_vector(7 downto 0);
    signal i8255_pb_data  : std_logic_vector(7 downto 0);
    signal i8255_pb_idata : std_logic_vector(7 downto 0);
    signal i8255_pc_data  : std_logic_vector(7 downto 0);
    signal i8255_pc_idata : std_logic_vector(7 downto 0);
    signal i8255_data     : std_logic_vector(7 downto 0);
    signal i8255_rd       : std_logic;

    signal inpurps2dat : std_logic;
    signal inpurps2clk : std_logic;
    signal ps2dataout  : std_logic_vector(5 downto 0);
    signal key_shift   : std_logic;
    signal key_ctrl    : std_logic;
    signal key_repeat  : std_logic;
    signal key_break   : std_logic;
    signal key_escape  : std_logic;
    signal key_turbo   : std_logic_vector(1 downto 0);

    signal sid_audio  : std_logic;

    signal spi_enable : std_logic;
    signal spi_data   : std_logic_vector (7 downto 0);

    signal uart_escape : std_logic;
    signal uart_break : std_logic;

    signal extern_reg_enable : std_logic;
     
--------------------------------------------------------------------
--                   here it begin :)
--------------------------------------------------------------------
begin

---------------------------------------------------------------------
--
---------------------------------------------------------------------
    cpu : entity work.T65 port map (
   		Mode           => "00",
		Abort_n        => '1',
		SO_n           => '1',
        Res_n          => RSTn,
        Enable         => cpu_clken,
        Clk            => clk_16M00,
        Rdy            => '1',
        IRQ_n          => cpu_IRQ_n,
        NMI_n          => '1',
        R_W_n          => cpu_R_W_n,
        Sync           => open,
        A(23 downto 16) => open,
        A(15 downto 0) => cpu_addr(15 downto 0),
        DI(7 downto 0) => cpu_din(7 downto 0),
        DO(7 downto 0) => cpu_dout(7 downto 0));
---------------------------------------------------------------------
--
---------------------------------------------------------------------                           
    Inst_AtomGodilVideo : entity work.AtomGodilVideo
        generic map (
           CImplGraphicsExt => CImplGraphicsExt,
           CImplSoftChar    => CImplSoftChar,
           CImplSID         => CImplSID,
           CImplVGA80x40    => CImplVGA80x40,
           CImplHWScrolling => CImplHWScrolling,
           CImplMouse       => CImplMouse,
           CImplUart        => CImplUart,
           CImplDoubleVideo => CImplDoubleVideo,
           MainClockSpeed   => MainClockSpeed,
           DefaultBaud      => DefaultBaud
        )     
        port map (
            clock_vga => clk_vga,
            clock_main => clk_16M00,
            clock_sid_32Mhz => clk_32M00,
            clock_sid_dac => clk_32M00,
            reset => not RSTn,
            reset_vid => '0',
            din => cpu_dout,
            dout => godil_data,
            addr => cpu_addr(12 downto 0),
            CSS => vdg_css,
            AG => vdg_an_g,
            GM => vdg_gm,
            nFS => vdg_fs_n,
            ram_we => video_ram_we,
            reg_cs => reg_enable,
            reg_we => reg_we,
            sid_cs => sid_enable,
            sid_we => sid_we,
            sid_audio => sid_audio,
            PS2_CLK => ps2_mouse_clk,
            PS2_DATA => ps2_mouse_data,            
            uart_cs => uart_enable,
            uart_we => uart_we,
            uart_RxD => uart_RxD,
            uart_TxD => uart_TxD,
            uart_escape => uart_escape,
            uart_break => uart_break,
            final_red => vdg_red,
            final_green1 => vdg_green1,
            final_green0 => vdg_green0,
            final_blue => vdg_blue,
            final_vsync => vdg_vsync,
            final_hsync => vdg_hsync,
            charSet => charSet
            );
---------------------------------------------------------------------
--
---------------------------------------------------------------------                   
    pia : entity work.I82C55 port map(
        I_ADDR => cpu_addr(1 downto 0),  -- A1-A0
        I_DATA => cpu_dout(7 downto 0),  -- D7-D0
        O_DATA => i8255_data,
        CS_H   => i8255_enable,
        WR_L   => cpu_R_W_n,
        O_PA   => i8255_pa_data,
        I_PB   => i8255_pb_idata,
        I_PC   => i8255_pc_idata(7 downto 4),
        O_PC   => i8255_pc_data(3 downto 0),
        RESET  => RSTn,
        ENA    => cpu_clken,
        CLK    => clk_16M00);
---------------------------------------------------------------------
--
---------------------------------------------------------------------                           
    input : entity work.keyboard port map(
        CLOCK      => clk_16M00,
        nRESET     => ERSTn,
        CLKEN_1MHZ => cpu_clken,
        PS2_CLK    => inpurps2clk,
        PS2_DATA   => inpurps2dat,
        KEYOUT     => ps2dataout,
        ROW        => i8255_pa_data(3 downto 0),
        ESC_IN     => uart_escape,
        BREAK_IN   => uart_break,
        SHIFT_OUT  => key_shift,
        CTRL_OUT   => key_ctrl,
        REPEAT_OUT => key_repeat,
        BREAK_OUT  => key_break,
        TURBO      => key_turbo,
        ESC_OUT    => key_escape,
        Joystick1  => Joystick1
--      ,  Joystick2  => Joystick2
        );
      
---------------------------------------------------------------------
--  
---------------------------------------------------------------------
    via : entity work.M6522 port map(
        I_RS    => cpu_addr(3 downto 0),
        I_DATA  => cpu_dout(7 downto 0),
        O_DATA  => mc6522_data(7 downto 0),
        I_RW_L  => cpu_R_W_n,
        I_CS1   => mc6522_enable,
        I_CS2_L => '0',
        O_IRQ_L => mc6522_irq,
        I_CA1   => mc6522_ca1,
        I_CA2   => mc6522_ca2,
        O_CA2   => mc6522_ca2,
        I_PA    => mc6522_porta(7 downto 0),
        O_PA    => mc6522_porta(7 downto 0),
        I_CB1   => mc6522_cb1,
        O_CB1   => mc6522_cb1,
        I_CB2   => mc6522_cb2,
        O_CB2   => mc6522_cb2,
        I_PB    => mc6522_portb(7 downto 0),
        O_PB    => mc6522_portb(7 downto 0),
        RESET_L => RSTn,
        I_P2_H  => via1_clken,
        ENA_4   => via4_clken,
        CLK     => clk_16M00);                                      

    Inst_spi: if (CImplSDDOS) generate
        Inst_spi_comp : entity work.SPI_Port
            port map (
                nRST    => RSTn,
                clk     => clk_16M00,
                enable  => spi_enable,
                nwe     => cpu_R_W_n,
                address => cpu_addr(2 downto 0),
                datain  => cpu_dout(7 downto 0),
                dataout => spi_data,
                MISO    => SDMISO,
                MOSI    => SDMOSI,
                NSS     => SDSS,
                SPICLK  => SDCLK
            );
    end generate;

---------------------------------------------------------------------
--
---------------------------------------------------------------------

    gated_we      <= not_cpu_R_W_n;
    uart_we       <= gated_we;
    video_ram_we  <= gated_we and video_ram_enable;
    reg_we        <= gated_we;
    sid_we        <= gated_we;

    RSTn          <= ERSTn and key_break;
    IRSTn         <= RSTn;

    mc6522_ca1    <= '1';
    inpurps2clk   <= ps2_clk;
    inpurps2dat   <= ps2_data;
    not_cpu_R_W_n <= not cpu_R_W_n;
    cpu_IRQ_n     <= mc6522_irq;

    
    audiol        <= sid_audio;
    audioR        <= i8255_pc_data(2);

    i8255_pc_idata <= vdg_fs_n & key_repeat & "11" & i8255_pc_data (3 downto 0);
    i8255_pb_idata <= key_shift & key_ctrl & ps2dataout;
    
    vdg_gm        <= i8255_pa_data(7 downto 5) when RSTn='1' else "000";
    vdg_an_g      <= i8255_pa_data(4)  when RSTn='1' else '0';
    vdg_css       <= i8255_pc_data(3) when RSTn='1' else '0';
    red(2 downto 0)   <= vdg_red & vdg_red & vdg_red;
    green(2 downto 0) <= vdg_green1 & vdg_green0 & vdg_green0;
    blue(2 downto 0)  <= vdg_blue & vdg_blue & vdg_blue;
    vsync             <= vdg_vsync;
    hsync             <= vdg_hsync;

-- enables
    process(cpu_addr)
    begin
        -- All regions normally de-selected
        mc6522_enable     <= '0';
        i8255_enable      <= '0';
        extern_ram_enable <= '0';
        extern_rom_enable <= '0';
        video_ram_enable  <= '0';
        sid_enable        <= '0'; 
        spi_enable        <= '0'; 
        reg_enable        <= '0';
        uart_enable       <= '0';
        extern_reg_enable <= '0';
        
        case cpu_addr(15 downto 12) is
            when x"0" => extern_ram_enable <= '1';  -- 0x0000 -- 0x03ff is RAM
            when x"1" => extern_ram_enable <= '1';
            when x"2" => extern_ram_enable <= '1';
            when x"3" => extern_ram_enable <= '1';
            when x"4" => extern_ram_enable <= '1';
            when x"5" => extern_ram_enable <= '1';
            when x"6" => extern_ram_enable <= '1';
            when x"7" => extern_ram_enable <= '1';
            when x"8" => video_ram_enable  <= '1';  -- 0x8000 -- 0x9fff is RAM
            when x"9" => video_ram_enable  <= '1';
            when x"A" => extern_rom_enable <= '1';
            when x"B" =>
                if cpu_addr(11 downto 8) = "0000" then     -- 0xb000 8255 PIA  
                    i8255_enable <= '1';
                elsif cpu_addr(11 downto 8) = "1000" then  -- 0xb800 6522 VIA (optional)
                    mc6522_enable <= '1';
                elsif cpu_addr(11 downto 10) = "01" then
                    spi_enable <= '1';  -- 0xb400-0xb7ff SPI
                elsif cpu_addr(11 downto 4) = "11011011" then
                    uart_enable <= '1';  -- 0xbdb0-0xbdbf UART
                elsif cpu_addr(11 downto 5) = "1101110" then
                    sid_enable <= '1';  -- 0xbdc0-0xbddf SID
                elsif cpu_addr(11 downto 5) = "1101111" then
                    reg_enable <= '1';  -- 0xbde0-0xbdff GODIL Registers
                elsif cpu_addr(11 downto 4) = "11111111" then
                    extern_reg_enable <= '1';  -- 0xbff0-0xbfff RomLatch
                end if;
                
            when x"C"   => extern_rom_enable <= '1';
            when x"D"   => extern_rom_enable <= '1';
            when x"E"   => extern_rom_enable <= '1';
            when x"F"   => extern_rom_enable <= '1';
            when others => null;
        end case;

    end process;

    cpu_din <=
        extern_data     when extern_ram_enable = '1'               else
        godil_data      when video_ram_enable = '1'                else
        i8255_data      when i8255_enable = '1'                    else
        mc6522_data     when mc6522_enable = '1'                   else
        godil_data      when sid_enable = '1'  and CImplSID        else
        godil_data      when uart_enable = '1' and CImplUart       else
        godil_data      when reg_enable = '1'                      else -- TODO add CImpl constraint
        spi_data        when spi_enable = '1'  and CImplSDDOS      else
        extern_data     when spi_enable = '1'  and not CImplSDDOS  else
        extern_data     when extern_rom_enable = '1'               else
        extern_data     when extern_reg_enable = '1'               else
        x"f1";          -- un-decoded locations
        
    ExternWE        <= not_cpu_R_W_n;
    RamCE           <= extern_ram_enable;			
    RomCE           <= extern_rom_enable;			
    ExternA         <= '0' & cpu_addr(15 downto 0);
    ExternDin       <= cpu_dout(7 downto 0);
    extern_data     <= ExternDout;
    
--------------------------------------------------------
-- clock enable generator
--------------------------------------------------------
    clk_gen : process(clk_16M00, RSTn)
    begin
        if RSTn = '0' then
            clken_counter <= (others => '0');
            cpu_clken <= '0';
            phi <= '0';
            phi2 <= '0';
        elsif rising_edge(clk_16M00) then
            clken_counter <= clken_counter + 1;
            case (key_turbo) is
                when "01" =>
                    -- 2MHz
                    -- cpu_clken active on cycle 0, 8
                    -- address/data changes on cycle 1, 9
                    -- phi2 active on cycle 2..5, 10..13
                    cpu_clken <= clken_counter(0) and clken_counter(1) and clken_counter(2);  -- on cycles 0, 8
                    phi <= not clken_counter(2);
                    via1_clken <= clken_counter(0) and clken_counter(1) and clken_counter(2);
                    via4_clken <= clken_counter(0);
                when "10" =>
                    -- 4MHz
                    -- cpu_clken active on cycle 0, 4, 8, 12
                    -- address/data changes on cycle 1, 5, 9, 13
                    -- phi2 active on cycle 2..3, 6..7 10..11 14..15
                    cpu_clken <= clken_counter(0) and clken_counter(1);
                    phi <= not clken_counter(1);
                    via1_clken <= clken_counter(0) and clken_counter(1);
                    via4_clken <= '1';
                when "11" =>
                    -- 8MHz
                    -- cpu_clken active on cycle 0, 2, 4, 6, 8, 10, 12, 14
                    -- address/data changes on cycle 1, 3, 5, 7, 9, 11, 13, 15
                    -- phi2 active on cycle 1, 3, 5, 7, 9, 11, 13, 15
                    -- NOTE: this case is not ideal, because no matter how you time phi2, one or other
                    -- edge will change at the same time as address/data changes.
                    -- (1) Address Setup at start of write cycle
                    -- (2) Data hold and end of write cycle
                    -- For now we will optimise for (2)
                    cpu_clken <= clken_counter(0);
                    phi <= clken_counter(0); -- not negated, see note above
                    via1_clken <= clken_counter(0);
                    via4_clken <= '1';
                when others =>
                    -- 1MHz
                    -- cpu_clken active on cycle 0
                    -- address/data changes on cycle 1
                    -- phi2 active on cycle 2..9
                    cpu_clken <= clken_counter(0) and clken_counter(1) and clken_counter(2) and clken_counter(3);
                    phi <= not clken_counter(3);
                    via1_clken <= clken_counter(0) and clken_counter(1) and clken_counter(2) and clken_counter(3);
                    via4_clken <= clken_counter(0) and clken_counter(1);
            end case;
            -- delay by 1 cycle so address and data will be stable for 62.5ns before phi2
            phi2 <= phi;
        end if;
    end process;
        
    LED1 <= '0';
    LED2 <= '0';
 
end BEHAVIORAL;


