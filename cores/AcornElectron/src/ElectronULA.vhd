--------------------------------------------------------------------------------
-- Copyright (c) 2015 David Banks
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    
-- \   \   \/    
--  \   \         
--  /   /         Filename  : ElectronFpga_core.vhd
-- /___/   /\     Timestamp : 28/07/2015
-- \   \  /  \ 
--  \___\/\___\ 
--
--Design Name: ElectronFpga_core


-- TODO:
-- Implement Cassette Out

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ElectronULA is
    port (
        clk_16M00 : in  std_logic;
        clk_33M33 : in  std_logic;
        clk_40M00 : in  std_logic;
        
        -- CPU Interface
        cpu_clken : in  std_logic;
        addr      : in  std_logic_vector(15 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        data_out  : out std_logic_vector(7 downto 0);
        R_W_n     : in  std_logic;
        RST_n     : in  std_logic;
        IRQ_n     : out std_logic;
        NMI_n     : in  std_logic;

        -- Rom Enable
        ROM_n     : out std_logic;
        
        -- Video
        red       : out std_logic_vector(2 downto 0);
        green     : out std_logic_vector(2 downto 0);
        blue      : out std_logic_vector(2 downto 0);
        vsync     : out std_logic;
        hsync     : out std_logic;

        -- Audio
        sound     : out std_logic;

        -- Keyboard
        kbd       : in  std_logic_vector(3 downto 0);

        -- Casette
        casIn     : in  std_logic;
        casOut    : out std_logic;

        -- MISC
        caps      : out std_logic;
        motor     : out std_logic;
        
        rom_latch : out std_logic_vector(3 downto 0);

        mode_init : in std_logic_vector(1 downto 0);
        
        contention: out std_logic        
        );
end;

architecture behavioral of ElectronULA is

  signal hsync_int      : std_logic;
  signal vsync_int      : std_logic;

  signal ram_we         : std_logic;
  signal ram_data       : std_logic_vector(7 downto 0);

  signal master_irq     : std_logic;

  signal power_on_reset : std_logic := '1';
  signal rtc_counter    : std_logic_vector(18 downto 0);
  signal general_counter: std_logic_vector(15 downto 0);
  signal sound_bit      : std_logic;
  signal isr_data       : std_logic_vector(7 downto 0);
  
  -- ULA Registers
  signal isr            : std_logic_vector(6 downto 2);
  signal ier            : std_logic_vector(6 downto 2);
  signal screen_base    : std_logic_vector(14 downto 6);
  signal data_shift     : std_logic_vector(7 downto 0);
  signal page_enable    : std_logic;
  signal page           : std_logic_vector(2 downto 0);
  signal counter        : std_logic_vector(7 downto 0);
  signal display_mode   : std_logic_vector(2 downto 0);
  signal comms_mode     : std_logic_vector(1 downto 0);
  
  type palette_type is array (0 to 7) of std_logic_vector (7 downto 0);  
  signal palette        : palette_type;

  signal hsync_start    : std_logic_vector(10 downto 0);
  signal hsync_end      : std_logic_vector(10 downto 0);
  signal h_active       : std_logic_vector(10 downto 0);
  signal h_total        : std_logic_vector(10 downto 0);
  signal h_count        : std_logic_vector(10 downto 0);
  signal h_count1       : std_logic_vector(10 downto 0);

  signal vsync_start    : std_logic_vector(9 downto 0);
  signal vsync_end      : std_logic_vector(9 downto 0);
  signal v_active_gph   : std_logic_vector(9 downto 0);
  signal v_active_txt   : std_logic_vector(9 downto 0);
  signal v_total        : std_logic_vector(9 downto 0);
  signal v_count        : std_logic_vector(9 downto 0);

  signal v_rtc          : std_logic_vector(9 downto 0);
  signal v_display      : std_logic_vector(9 downto 0);
  
  signal char_row       : std_logic_vector(3 downto 0);
  signal row_offset     : std_logic_vector(14 downto 0);
  signal col_offset     : std_logic_vector(9 downto 0);
  signal screen_addr    : std_logic_vector(14 downto 0);
  signal screen_data    : std_logic_vector(7 downto 0);
  
  -- Screen Mode Registers

  signal mode           : std_logic_vector(1 downto 0);

  -- the 256 byte page that the mode starts at
  signal mode_base      : std_logic_vector(7 downto 0);
  
  -- the number of bits per pixel (0 = 1BPP, 1 = 2BPP, 2=4BPP)
  signal mode_bpp       : std_logic_vector(1 downto 0);
  
   -- a '1' indicates a text mode (modes 3 and 6)
  signal mode_text      : std_logic;
  
  -- a '1' indicates a 40-col mode (modes 4, 5 and 6)
  signal mode_40        : std_logic;
  
  -- the number of bytes to increment row_offset when moving from one char row to the next
  signal mode_rowstep   : std_logic_vector(9 downto 0);
  
  signal display_intr   : std_logic;
  signal display_intr1  : std_logic;
  signal display_intr2  : std_logic;

  signal rtc_intr       : std_logic;
  signal rtc_intr1      : std_logic;
  signal rtc_intr2      : std_logic;

  signal clk_video      : std_logic;
  
  signal ctrl_caps      : std_logic;

  signal field          : std_logic;

  signal caps_int       : std_logic;
  signal motor_int      : std_logic;
  
  -- Supports changing the jumpers
  signal mode_init_copy : std_logic_vector(1 downto 0);

  -- Stable copies sampled once per frame
  signal screen_base1   : std_logic_vector(14 downto 6);
  signal mode_base1     : std_logic_vector(7 downto 0);

  -- Tape Interface
  signal cintone        : std_logic;
  signal cindat         : std_logic;
  signal databits       : std_logic_vector(3 downto 0);
  signal casIn1         : std_logic;
  signal casIn2         : std_logic;
  signal casIn3         : std_logic;
  signal ignore_next    : std_logic;
    
-- Helper function to cast an std_logic value to an integer
function sl2int (x: std_logic) return integer is
begin
    if x = '1' then
        return 1;
    else
        return 0;
    end if;
end;

-- Helper function to cast an std_logic_vector value to an integer
function slv2int (x: std_logic_vector) return integer is
begin
    return to_integer(unsigned(x));
end;
    
begin

    -- video timing constants
    -- mode 00 - RGB/s @ 50Hz non-interlaced
    -- mode 01 - RGB/s @ 50Hz interlaced
    -- mode 10 - SVGA  @ 50Hz
    -- mode 11 - SVGA  @ 60Hz
    
    clk_video    <= clk_40M00 when mode = "11" else
                    clk_33M33 when mode = "10" else
                    clk_16M00;

    hsync_start  <= std_logic_vector(to_unsigned(759, 11)) when mode = "11" else
                    std_logic_vector(to_unsigned(759, 11)) when mode = "10" else
                    std_logic_vector(to_unsigned(762, 11));    

    hsync_end    <= std_logic_vector(to_unsigned(887, 11)) when mode = "11" else
                    std_logic_vector(to_unsigned(887, 11)) when mode = "10" else
                    std_logic_vector(to_unsigned(837, 11));    
    
    h_total      <= std_logic_vector(to_unsigned(1055, 11)) when mode = "11" else
                    std_logic_vector(to_unsigned(1055, 11)) when mode = "10" else
                    std_logic_vector(to_unsigned(1023, 11));    
    
    h_active     <= std_logic_vector(to_unsigned(640, 11));

    vsync_start  <= std_logic_vector(to_unsigned(556, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(556, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(274, 10));    

    vsync_end    <= std_logic_vector(to_unsigned(560, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(560, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(277, 10));    

    v_total      <= std_logic_vector(to_unsigned(627, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(627, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(311, 10)) when field = '0' else
                    std_logic_vector(to_unsigned(312, 10));
                    
    v_active_gph <= std_logic_vector(to_unsigned(512, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(512, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(256, 10));

    v_active_txt <= std_logic_vector(to_unsigned(500, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(500, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(250, 10));

    v_display    <= std_logic_vector(to_unsigned(513, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(513, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(256, 10));

    v_rtc        <= std_logic_vector(to_unsigned(201, 10)) when mode = "11" else
                    std_logic_vector(to_unsigned(201, 10)) when mode = "10" else
                    std_logic_vector(to_unsigned(100, 10));
     
    ram : entity work.RAM_32K_DualPort port map(

      -- Port A is the 6502 port
        clka  => clk_16M00,
        wea   => ram_we,
        addra => addr(14 downto 0),
        dina  => data_in,
        douta => ram_data,

        -- Port B is the VGA Port
        clkb  => clk_video,
        web   => '0',
        addrb => screen_addr,
        dinb  => x"00",
        doutb => screen_data
    );

    sound <= sound_bit;
    
    -- FIXME: This should probably be gate with a clock enable
    ram_we <= '1' when addr(15) = '0' and R_W_n = '0' else '0';

    -- The external ROM is enabled:
    -- - When the address is C000-FBFF and FF00-FFFF (i.e. OS Rom)
    -- - When the address is 8000-BFFF and the ROM 10 or 11 is paged in (101x)
    ROM_n <= '0' when addr(15 downto 14) = "11" and addr(15 downto 8) /= x"FC" and addr(15 downto 8) /= x"FD" and addr(15 downto 8) /= x"FE" else
             '0' when addr(15 downto 14) = "10" and page_enable = '1' and page(2 downto 1) = "01" else
             '1';
      
    -- ULA Reads + RAM Reads + KBD Reads
    data_out <= ram_data              when addr(15) = '0' else
                "0000" & kbd          when addr(15 downto 14) = "10" and page_enable = '1' and page(2 downto 1) = "00" else
                isr_data              when addr(15 downto 8) = x"FE" and addr(3 downto 0) = x"0" else
                data_shift            when addr(15 downto 8) = x"FE" and addr(3 downto 0) = x"4" else
                x"F1"; -- todo FIXEME

    -- Register FEx0 is the Interrupt Status Register (Read Only)
    -- Bit 7 always reads as 1
    -- Bits 6..2 refect in interrups status regs
    -- Bit 1 is the power up reset bit, cleared by the first read after power up
    -- Bit 0 is the OR of bits 6..2
    master_irq <= (isr(6) and ier(6)) or 
                  (isr(5) and ier(5)) or
                  (isr(4) and ier(4)) or
                  (isr(3) and ier(3)) or
                  (isr(2) and ier(2));
    IRQ_n      <= not master_irq; 
    isr_data   <= '1' & isr(6 downto 2) & power_on_reset & master_irq;
    
    rom_latch  <= page_enable & page;
   
    process (clk_16M00, RST_n)
    begin
        if (RST_n = '0') then
           isr             <= (others => '0');
           ier             <= (others => '0');
           screen_base     <= (others => '0');
           data_shift      <= (others => '0');
           page_enable     <= '0';
           page            <= (others => '0');
           counter         <= (others => '0');
           comms_mode      <= "01";
           motor_int       <= '0';
           caps_int        <= '0';
           rtc_counter     <= (others => '0');
           general_counter <= (others => '0');
           sound_bit       <= '0';           
           mode            <= mode_init;
           mode_init_copy  <= mode_init;
           ctrl_caps       <= '0';
           cindat          <= '0';
           cintone         <= '0';
           
        elsif rising_edge(clk_16M00) then
            -- Detect control+caps 1...4 and change video format
            if (addr = x"9fff" and page_enable = '1' and page(2 downto 1) = "00") then
                if (kbd(2 downto 1) = "11") then
                    ctrl_caps <= '1';
                else
                    ctrl_caps <= '0';
                end if;
            end if;
            -- Detect "1" being pressed
            if (addr = x"afff" and page_enable = '1' and page(2 downto 1) = "00" and ctrl_caps = '1' and kbd(0) = '1') then
                mode <= "00";
            end if;
            -- Detect "2" being pressed
            if (addr = x"b7ff" and page_enable = '1' and page(2 downto 1) = "00" and ctrl_caps = '1' and kbd(0) = '1') then
                mode <= "01";
            end if;
            -- Detect "3" being pressed
            if (addr = x"bbff" and page_enable = '1' and page(2 downto 1) = "00" and ctrl_caps = '1' and kbd(0) = '1') then
                mode <= "10";
            end if;            
            -- Detect "4" being pressed
            if (addr = x"bdff" and page_enable = '1' and page(2 downto 1) = "00" and ctrl_caps = '1' and kbd(0) = '1') then
                mode <= "11";
            end if;
            -- Detect Jumpers being changed
            if (mode_init_copy /= mode_init) then
                mode <= mode_init;
                mode_init_copy <= mode_init;
            end if;
            -- Synchronize the display interrupt signal from the VGA clock domain
            display_intr1 <= display_intr;
            display_intr2 <= display_intr1;
            -- Generate the display end interrupt on the rising edge (line 256 of the screen)
            if (display_intr2 = '0' and display_intr1 = '1') then
                isr(2) <= '1';
            end if;
            -- Synchronize the rtc interrupt signal from the VGA clock domain
            rtc_intr1 <= rtc_intr;
            rtc_intr2 <= rtc_intr1;
            if (mode = "11") then
                -- For 60Hz frame rates we must synthesise a the 50Hz real time clock interrupt
                -- In theory the counter limit should be 319999, but there are additional
                -- rtc ticks if not rtc interrupt is received between two display interrupts
                -- hence the correction factor of 6/5. This comes from the probability
                -- of the there not being a 50Hz rtc interrupts between any two successive
                -- 60Hz display interrupts.
                if (rtc_counter = 383999) then
                    rtc_counter <= (others => '0');
                    isr(3) <= '1';
                else
                    rtc_counter <= rtc_counter + 1;
                end if;
            else
                -- Generate the rtc interrupt on the rising edge (line 100 of the screen)
                if (rtc_intr2 = '0' and rtc_intr1 = '1') then
                    isr(3) <= '1';
                end if;            
            end if;
            if (comms_mode = "00") then
                if (casIn2 = '0') then
                    general_counter <= (others => '0');
                else
                    general_counter <= general_counter + 1;
                end if;
            elsif (comms_mode = "01") then
                -- Sound Frequency = 1MHz / [16 * (S + 1)]
                if (general_counter = 0) then
                    general_counter <= counter & "00000000";
                    sound_bit <= not sound_bit;
                else
                    general_counter <= general_counter - 1;
                end if;            
            end if;
            
            
            -- Tape Interface Receive
            casIn1 <= casIn;
            casIn2 <= casIn1;
            casIn3 <= casIn2;
            if (comms_mode = "00" and motor_int = '1') then
                -- Only take actions on the falling edge of casIn
                -- On the falling edge, general_counter will contain length of
                -- the previous high pulse in 16MHz cycles.
                -- A 1200Hz pulse is 6666 cycles
                -- A 2400Hz pulse is 3333 cycles
                -- A threshold in between would be 5000 cycles.
                -- Ignore pulses shorter then say 500 cycles as these are
                -- probably just noise.

                if (casIn3 = '1' and casIn2 = '0' and general_counter > 500) then
                    -- a Pulse of length > 500 cycles has been detected

                    if (cindat = '0' and cintone = '0' and general_counter <= 5000) then
                        -- High Tone detected
                        cindat  <= '0';
                        cintone <= '1';
                        databits <= (others => '0');
                        -- Generate the high tone detect interrupt
                        isr(6) <= '1';

                    elsif (cindat = '0' and cintone = '1' and general_counter > 5000) then
                        -- Start bit detected
                        cindat  <= '1';
                        cintone <= '0';
                        databits <= (others => '0');
                        
                    elsif (cindat = '1' and ignore_next = '1') then
                        -- Ignoring the second pulse in a bit at 2400Hz
                        ignore_next <= '0';

                    elsif (cindat = '1' and databits < 9) then

                        if (databits < 8) then
                            if (general_counter > 5000) then
                                -- shift in a zero
                                data_shift <= '0' & data_shift(7 downto 1);
                            else
                                -- shift in a one
                                data_shift <= '1' & data_shift(7 downto 1);
                            end if;
                            -- Generate the receive data int as soon as the
                            -- last bit has been shifted in.
                            if (databits = 7) then
                                isr(4) <= '1';
                            end if;
                        end if;
                        -- Ignore the second pulse in a bit at 2400Hz
                        if (general_counter > 5000) then
                            ignore_next <= '0';
                        else
                            ignore_next <= '1';
                        end if;
                        -- Move on to the next data bit
                        databits <= databits + 1;
                    elsif (cindat = '1' and databits = 9) then                         
                        if (general_counter > 5000) then
                            -- Found next start bit...
                            cindat  <= '1';
                            cintone <= '0';
                            databits <= (others => '0');
                        else
                            -- Back in tone again
                            cindat  <= '0';
                            cintone <= '1';
                            databits <= (others => '0');
                            -- Generate the high tone detect interrupt
                            isr(6) <= '1';
                       end if;                           
                   end if;
                end if;
            else
                cindat      <= '0';
                cintone     <= '0';
                databits    <= (others => '0');
                ignore_next <= '0';
            end if;
            
            -- ULA Writes
            if (cpu_clken = '1') then
                if (addr(15 downto 8) = x"FE") then
                    if (R_W_n = '1') then
                        -- Clear the power on reset flag on the first read of the ISR (FEx0)
                        if (addr(3 downto 0) = x"0") then
                            power_on_reset <= '0';
                        end if;
                        -- Clear the RDFull interrupts on reading the data_shift register
                        if (addr(3 downto 0) = x"4") then
                            isr(4) <= '0';
                        end if;                    
                    else
                        case addr(3 downto 0) is
                        when x"0" =>
                            ier(6 downto 2) <= data_in(6 downto 2);
                        when x"1" =>
                        when x"2" =>
                            screen_base(8 downto 6) <= data_in(7 downto 5);
                        when x"3" =>
                            screen_base(14 downto 9) <= data_in(5 downto 0);
                        when x"4" =>
                            data_shift <= data_in;
                            -- Clear the TDEmpty interrupt on writing the
                            -- data_shift register
                            isr(5) <= '0';
                        when x"5" =>
                            if (data_in(6) = '1') then
                                -- Clear High Tone Detect IRQ
                                isr(6) <= '0';
                            end if;
                            if (data_in(5) = '1') then
                                -- Clear Real Time Clock IRQ
                                isr(3) <= '0';
                            end if;
                            if (data_in(4) = '1') then
                                -- Clear Display End IRQ
                                isr(2) <= '0';
                            end if;
                            if (page_enable = '1' and page(2) = '0') then
                                -- Roms 8-11 currently selected, so only selecting 8-15 will be honoured
                                if (data_in(3) = '1') then
                                    page_enable <= data_in(3);
                                    page <= data_in(2 downto 0);
                                end if;
                            else
                                -- Roms 0-7 or 12-15 currently selected, so anything goes
                                page_enable <= data_in(3);
                                page <= data_in(2 downto 0);                            
                            end if;
                        when x"6" =>
                            counter <= data_in;
                        when x"7" =>
                            caps_int     <= data_in(7);
                            motor_int    <= data_in(6);
                            case (data_in(5 downto 3)) is
                            when "000" =>
                                mode_base    <= x"30";
                                mode_bpp     <= "00";
                                mode_40      <= '0';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(633, 10)); -- 640 - 7
                            when "001" =>
                                mode_base    <= x"30";
                                mode_bpp     <= "01";
                                mode_40      <= '0';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(633, 10)); -- 640 - 7
                            when "010" =>
                                mode_base    <= x"30";
                                mode_bpp     <= "10";
                                mode_40      <= '0';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(633, 10)); -- 640 - 7
                            when "011" =>
                                mode_base    <= x"40";
                                mode_bpp     <= "00";
                                mode_40      <= '0';
                                mode_text    <= '1';
                                mode_rowstep <= std_logic_vector(to_unsigned(631, 10)); -- 640 - 9
                            when "100" =>
                                mode_base    <= x"58";
                                mode_bpp     <= "00";
                                mode_40      <= '1';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(313, 10)); -- 320 - 7
                            when "101" =>
                                mode_base    <= x"60";
                                mode_bpp     <= "01";
                                mode_40      <= '1';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(313, 10)); -- 320 - 7
                            when "110" =>
                                mode_base    <= x"60";
                                mode_bpp     <= "00";
                                mode_40      <= '1';
                                mode_text    <= '1';
                                mode_rowstep <= std_logic_vector(to_unsigned(311, 10)); -- 320 - 9
                            when "111" =>
                                -- mode 7 seems to default to mode 4
                                mode_base    <= x"58";
                                mode_bpp     <= "00";
                                mode_40      <= '1';
                                mode_text    <= '0';
                                mode_rowstep <= std_logic_vector(to_unsigned(313, 10)); -- 320 - 7
                            when others =>
                            end case;                            
                            comms_mode   <= data_in(2 downto 1);
                        when others =>
                            -- A '1' in the palatte data means disable the colour
                            -- Invert the stored palette, to make the palette logic simpler
                            palette(slv2int(addr(2 downto 0))) <= data_in xor "11111111";
                        end case;
                    end if;
                end if;          
            end if;
        end if;
    end process;

    -- SGVA timing at 60Hz with a 40.000MHz Pixel Clock
    -- Horizontal 800 + 40 + 128 + 88 = total 1056
    -- Vertical   600 +  1 +   4 + 23 = total 628
    -- Within the the 640x512 is centred so starts at 80,44
    -- Horizontal 640 + (80 + 40) + 128 + (88 + 80) = total 1056
    -- Vertical   512 + (44 +  1) +   4 + (23 + 44) = total 628

    -- RGBs timing at 50Hz with a 16.000MHz Pixel Clock
    -- Horizontal 640 + (96 + 26) +  75 + (91 + 96) = total 1024
    -- Vertical   256 + (16 +  2) +   3 + (19 + 16) = total 312
     
    process (clk_video)
    variable pixel : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk_video) then
            -- pipeline h_count by one cycle to compensate the register in the RAM
            h_count1 <= h_count;
            if (h_count = h_total) then
                h_count <= (others => '0');
                col_offset <= (others => '0');
                if (v_count = v_total) then
                    v_count <= (others => '0');
                    char_row <= (others => '0');
                    row_offset <= (others => '0');
                    screen_base1  <= screen_base;
                    mode_base1  <= mode_base;
                    if (mode = "01") then
                        -- Interlaced, so alternate odd and even fields
                        field <= not field;
                    else
                        -- Non-interlaced, so odd fields only
                        field <= '0';
                    end if;
                else
                    v_count <= v_count + 1;
                    if (v_count(0) = '1' or mode(1) = '0') then
                        if ((mode_text = '0' and char_row = 7) or (mode_text = '1' and char_row = 9)) then
                            char_row <= (others => '0');
                            row_offset <= row_offset + mode_rowstep;
                        else
                            char_row <= char_row + 1;
                            row_offset <= row_offset + 1;
                        end if;
                    end if;
                end if;
            else
                h_count <= h_count + 1;
                if ((mode_40 = '0' and h_count(2 downto 0) = "111") or
                    (mode_40 = '1' and h_count(3 downto 0) = "1111")) then
                    col_offset <= col_offset + 8;
                end if;
            end if;
            -- RGB Data
            if (h_count1 >= h_active or (mode_text = '0' and v_count >= v_active_gph) or (mode_text = '1' and v_count >= v_active_txt) or char_row >= 8) then
                -- blanking and border are always black
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
                contention <= '0';
            else
                -- Indicate possible memory contention on active scan lines
                contention <= not mode_40;
                -- rendering an actual pixel
                if (mode_bpp = 0) then
                    -- 1 bit per pixel, map to colours 0 and 8 for the palette lookup
                    if (mode_40 = '1') then
                        pixel := screen_data(7 - slv2int(h_count1(3 downto 1))) & "000";
                    else
                        pixel := screen_data(7 - slv2int(h_count1(2 downto 0))) & "000";
                    end if;
                elsif (mode_bpp = 1) then
                    -- 2 bits per pixel, map to colours 0, 2, 8, 10 for the palette lookup
                    if (mode_40 = '1') then
                        pixel := screen_data(7 - slv2int(h_count1(3 downto 2))) & "0" &
                                 screen_data(3 - slv2int(h_count1(3 downto 2))) & "0";
                    else
                        pixel := screen_data(7 - slv2int(h_count1(2 downto 1))) & "0" &
                                 screen_data(3 - slv2int(h_count1(2 downto 1))) & "0";
                    end if;
                else
                    -- 4 bits per pixel, map directly for the palette lookup
                    if (mode_40 = '1') then
                        pixel := screen_data(7 - sl2int(h_count1(3))) &
                                 screen_data(5 - sl2int(h_count1(3))) &
                                 screen_data(3 - sl2int(h_count1(3))) &
                                 screen_data(1 - sl2int(h_count1(3)));
                    else
                        pixel := screen_data(7 - sl2int(h_count1(2))) &
                                 screen_data(5 - sl2int(h_count1(2))) &
                                 screen_data(3 - sl2int(h_count1(2))) &
                                 screen_data(1 - sl2int(h_count1(2)));
                    end if;
                end if;
                -- Implement Color Palette
                case (pixel) is
                when "0000" =>
                    red   <= (others => palette(1)(0));
                    green <= (others => palette(1)(4));
                    blue  <= (others => palette(0)(4));
                when "0001" =>
                    red   <= (others => palette(7)(0));
                    green <= (others => palette(7)(4));
                    blue  <= (others => palette(6)(4));
                when "0010" =>
                    red   <= (others => palette(1)(1));
                    green <= (others => palette(1)(5));
                    blue  <= (others => palette(0)(5));
                when "0011" =>
                    red   <= (others => palette(7)(1));
                    green <= (others => palette(7)(5));
                    blue  <= (others => palette(6)(5));
                when "0100" =>
                    red   <= (others => palette(3)(0));
                    green <= (others => palette(3)(4));
                    blue  <= (others => palette(2)(4));
                when "0101" =>
                    red   <= (others => palette(5)(0));
                    green <= (others => palette(5)(4));
                    blue  <= (others => palette(4)(4));
                when "0110" =>
                    red   <= (others => palette(3)(1));
                    green <= (others => palette(3)(5));
                    blue  <= (others => palette(2)(5));
                when "0111" =>
                    red   <= (others => palette(5)(1));
                    green <= (others => palette(5)(5));
                    blue  <= (others => palette(4)(5));
                when "1000" =>
                    red   <= (others => palette(1)(2));
                    green <= (others => palette(0)(2));
                    blue  <= (others => palette(0)(6));
                when "1001" =>
                    red   <= (others => palette(7)(2));
                    green <= (others => palette(6)(2));
                    blue  <= (others => palette(6)(6));
                when "1010" =>
                    red   <= (others => palette(1)(3));
                    green <= (others => palette(0)(3));
                    blue  <= (others => palette(0)(7));
                when "1011" =>
                    red   <= (others => palette(7)(3));
                    green <= (others => palette(6)(3));
                    blue  <= (others => palette(6)(7));
                when "1100" =>
                    red   <= (others => palette(3)(2));
                    green <= (others => palette(2)(2));
                    blue  <= (others => palette(2)(6));
                when "1101" =>
                    red   <= (others => palette(5)(2));
                    green <= (others => palette(4)(2));
                    blue  <= (others => palette(4)(6));
                when "1110" =>
                    red   <= (others => palette(3)(3));
                    green <= (others => palette(2)(3));
                    blue  <= (others => palette(2)(7));
                when "1111" =>
                    red   <= (others => palette(5)(3));
                    green <= (others => palette(4)(3));
                    blue  <= (others => palette(4)(7));
                when others =>
                end case;
            end if;              
            -- Vertical Sync
            if (field = '0') then
                -- first field of interlaced scanning (or non interlaced)
                -- vsync starts at the begging of the line            
                if (h_count1 = 0) then
                    if (v_count = vsync_start) then
                        vsync_int <= '0';
                    elsif (v_count = vsync_end) then
                        vsync_int <= '1';
                    end if;
                end if;
            else
                -- second field of intelaced scanning
                -- vsync starts half way through the line
                if (h_count1 = ('0' & h_total(10 downto 1))) then
                    if (v_count = vsync_start) then 
                        vsync_int <= '0';
                    elsif (v_count = vsync_end) then
                        vsync_int <= '1';
                    end if;
                end if;
            end if;
            -- Horizontal Sync
            if (h_count1 = hsync_start) then
                hsync_int <= '0';
                if (v_count = v_display) then
                    display_intr <= '1';
                end if;
                if (v_count = v_rtc) then
                    rtc_intr <= '1';
                end if;
            elsif (h_count1 = hsync_end) then
                hsync_int    <= '1';
                display_intr <= '0';
                rtc_intr     <= '0';
            end if;
        end if;        
    end process;
    
    process (screen_base1, mode_base1, row_offset, col_offset)
        variable tmp: std_logic_vector(15 downto 0);
    begin
        tmp := ("0" & screen_base1 & "000000") + row_offset + col_offset;
        if (tmp(15) = '1') then
            tmp := tmp + (mode_base1 & "00000000");
        end if;
        screen_addr <= tmp(14 downto 0);
    end process;
    
    vsync <= '1'                     when mode(1) = '0' else vsync_int;
    hsync <= hsync_int and vsync_int when mode(1) = '0' else hsync_int;
    caps  <= caps_int;
    motor <= motor_int;
    
    casOut <= '0';

end behavioral;
