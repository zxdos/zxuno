-- BBC Micro for Papilio Duo
--
-- Copyright (c) 2011 Mike Stirling
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- BBC B Micro
--
--
-- (C) 2011 Mike Stirling
--
-- 2015 port to ZX-UNO by Quest

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity bbc_micro is
    generic (
       UseT65Core    : boolean := true;
       UseAlanDCore  : boolean := false
       );
     port (clk50      : in    std_logic;
           ps2_clk        : in    std_logic;
           ps2_data       : in    std_logic;
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
           audioL         : out   std_logic;
           audioR         : out   std_logic;
           RAMWRn         : out   std_logic;
           SRAM_ADDR      : out   std_logic_vector (18 downto 0);
           SRAM_DATA      : inout std_logic_vector (7 downto 0);
           SDMISO         : in    std_logic;
           SDSS           : out   std_logic;
           SDCLK          : out   std_logic;
           SDMOSI         : out   std_logic;
           LED1           : out   std_logic;
			  NTSC           : out   std_logic; 
			  PAL            : out   std_logic 			  

    );
end entity;

architecture rtl of bbc_micro is

-------------
-- Signals
-------------

-- Master clock - 32 MHz
signal clock        :   std_logic;
signal hard_reset_n :   std_logic;
signal reset_n      :   std_logic;
signal CLOCK_24     :   std_logic;

-- Clock enable counter
-- CPU and video cycles are interleaved.  The CPU runs at 2 MHz (every 16th
-- cycle) and the video subsystem is enabled on every odd cycle.
signal clken_counter    :   unsigned(4 downto 0);
signal cpu_cycle        :   std_logic; -- Qualifies all 2 MHz cycles
signal cpu_cycle_mask   :   std_logic_vector(1 downto 0); -- Set to mask CPU cycles until 1 MHz cycle is complete
signal cpu_clken        :   std_logic; -- 2 MHz cycles in which the CPU is enabled

-- IO cycles are out of phase with the CPU
signal vid_clken        :   std_logic; -- 16 MHz video cycles
signal mhz4_clken       :   std_logic; -- Used by 6522
signal mhz2_clken       :   std_logic; -- Used for latching CPU address for clock stretch
signal mhz1_clken       :   std_logic; -- 1 MHz bus and associated peripherals, 6522 phase 2

-- SAA5050 needs a 6 MHz clock enable relative to a 24 MHz clock
signal ttxt_clken_counter   :   unsigned(1 downto 0);
signal ttxt_clken       :   std_logic;

-- CPU signals
signal cpu_mode         :   std_logic_vector(1 downto 0);
signal cpu_ready        :   std_logic;
signal cpu_abort_n      :   std_logic;
signal cpu_irq_n        :   std_logic;
signal cpu_nmi_n        :   std_logic;
signal cpu_so_n         :   std_logic;
signal cpu_r_nw         :   std_logic;
signal cpu_sync         :   std_logic;
signal cpu_ef           :   std_logic;
signal cpu_mf           :   std_logic;
signal cpu_xf           :   std_logic;
signal cpu_ml_n         :   std_logic;
signal cpu_vp_n         :   std_logic;
signal cpu_vda          :   std_logic;
signal cpu_vpa          :   std_logic;
signal cpu_a            :   std_logic_vector(23 downto 0);
signal cpu_di           :   std_logic_vector(7 downto 0);
signal cpu_do           :   std_logic_vector(7 downto 0);
signal cpu_addr_us      :   unsigned (15 downto 0);
signal cpu_dout_us      :   unsigned (7 downto 0);

-- CRTC signals
signal crtc_clken       :   std_logic;
signal crtc_do          :   std_logic_vector(7 downto 0);
signal crtc_vsync       :   std_logic;
signal crtc_hsync       :   std_logic;
signal crtc_de          :   std_logic;
signal crtc_cursor      :   std_logic;
constant crtc_lpstb       :   std_logic := '0'; --q signal
signal crtc_ma          :   std_logic_vector(13 downto 0);
signal crtc_ra          :   std_logic_vector(4 downto 0);

-- Decoded display address after address translation for hardware
-- scrolling
signal display_a        :   std_logic_vector(14 downto 0);

-- "VIDPROC" signals
signal vidproc_invert_n :   std_logic;
signal vidproc_disen    :   std_logic;
signal r_in             :   std_logic;
signal g_in             :   std_logic;
signal b_in             :   std_logic;
signal r_out            :   std_logic;
signal g_out            :   std_logic;
signal b_out            :   std_logic;

-- Scandoubler signals (Mist)
signal vga0_r           :   std_logic_vector(1 downto 0);
signal vga0_g           :   std_logic_vector(1 downto 0);
signal vga0_b           :   std_logic_vector(1 downto 0);
signal vga0_hs          :   std_logic;
signal vga0_vs          :   std_logic;
signal vga0_mode        :   std_logic;
-- Scandoubler signals (RGB2VGA)
signal vga_clock        :   std_logic;
signal vga1_r           :   std_logic_vector(1 downto 0);
signal vga1_g           :   std_logic_vector(1 downto 0);
signal vga1_b           :   std_logic_vector(1 downto 0);
signal vga1_hs          :   std_logic;
signal vga1_vs          :   std_logic;
signal vga1_mode        :   std_logic;
signal rgbi_out         :   std_logic_vector(3 downto 0);

signal DIP : std_logic_vector(1 downto 0); --q

-- SAA5050 signals
signal ttxt_glr         :   std_logic;
signal ttxt_dew         :   std_logic;
signal ttxt_crs         :   std_logic;
signal ttxt_lose        :   std_logic;
signal ttxt_r           :   std_logic;
signal ttxt_g           :   std_logic;
signal ttxt_b           :   std_logic;
signal ttxt_y           :   std_logic;

-- System VIA signals
signal sys_via_do       :   std_logic_vector(7 downto 0);
signal sys_via_do_oe_n  :   std_logic;
signal sys_via_irq_n    :   std_logic;
signal sys_via_ca1_in   :   std_logic := '0';
signal sys_via_ca2_in   :   std_logic := '0';
signal sys_via_ca2_out  :   std_logic;
signal sys_via_ca2_oe_n :   std_logic;
signal sys_via_pa_in    :   std_logic_vector(7 downto 0);
signal sys_via_pa_out   :   std_logic_vector(7 downto 0);
signal sys_via_pa_oe_n  :   std_logic_vector(7 downto 0);
signal sys_via_cb1_in   :   std_logic := '0';
signal sys_via_cb1_out  :   std_logic;
signal sys_via_cb1_oe_n :   std_logic;
signal sys_via_cb2_in   :   std_logic := '0';
signal sys_via_cb2_out  :   std_logic;
signal sys_via_cb2_oe_n :   std_logic;
signal sys_via_pb_in    :   std_logic_vector(7 downto 0);
signal sys_via_pb_out   :   std_logic_vector(7 downto 0);
signal sys_via_pb_oe_n  :   std_logic_vector(7 downto 0);

-- User VIA signals
signal user_via_do      :   std_logic_vector(7 downto 0);
signal user_via_do_oe_n :   std_logic;
signal user_via_irq_n   :   std_logic;
signal user_via_ca1_in  :   std_logic := '0';
constant user_via_ca2_in  :   std_logic := '0'; --q signal
signal user_via_ca2_out :   std_logic;
signal user_via_ca2_oe_n    :   std_logic;
signal user_via_pa_in   :   std_logic_vector(7 downto 0);
signal user_via_pa_out  :   std_logic_vector(7 downto 0);
signal user_via_pa_oe_n :   std_logic_vector(7 downto 0);
signal user_via_cb1_in  :   std_logic := '0';
signal user_via_cb1_out :   std_logic;
signal user_via_cb1_oe_n    :   std_logic;
signal user_via_cb2_in  :   std_logic := '0';
signal user_via_cb2_out :   std_logic;
signal user_via_cb2_oe_n    :   std_logic;
signal user_via_pb_in   :   std_logic_vector(7 downto 0);
signal user_via_pb_out  :   std_logic_vector(7 downto 0);
signal user_via_pb_oe_n :   std_logic_vector(7 downto 0);

-- IC32 latch on System VIA
signal ic32             :   std_logic_vector(7 downto 0);
signal sound_enable_n   :   std_logic;
--signal speech_read_n    :   std_logic;
--signal speech_write_n   :   std_logic;
signal keyb_enable_n    :   std_logic;
signal disp_addr_offs   :   std_logic_vector(1 downto 0);
signal caps_lock_led_n  :   std_logic;
signal shift_lock_led_n :   std_logic;

-- Keyboard
signal keyb_column      :   std_logic_vector(3 downto 0);
signal keyb_row         :   std_logic_vector(2 downto 0);
signal keyb_out         :   std_logic;
signal keyb_int         :   std_logic;
signal keyb_break       :   std_logic;

-- Sound generator
signal sound_ready      :   std_logic;
signal sound_di         :   std_logic_vector(7 downto 0);
signal sound_ao         :   signed(7 downto 0);
signal audio            :   std_logic;
signal pcm_inl          :   std_logic_vector(15 downto 0);
signal pcm_inr          :   std_logic_vector(15 downto 0);

-- Memory enables
signal ram_enable       :   std_logic;      -- 0x0000
signal rom_enable       :   std_logic;      -- 0x8000 (BASIC/sideways ROMs)
signal mos_enable       :   std_logic;      -- 0xC000

-- IO region enables
signal io_fred          :   std_logic;      -- 0xFC00 (1 MHz bus)
signal io_jim           :   std_logic;      -- 0xFD00 (1 MHz bus)
signal io_sheila        :   std_logic;      -- 0xFE00 (System peripherals)

-- SHIELA
signal crtc_enable      :   std_logic;      -- 0xFE00-FE07
signal acia_enable      :   std_logic;      -- 0xFE08-FE0F
signal serproc_enable   :   std_logic;      -- 0xFE10-FE1F
signal vidproc_enable   :   std_logic;      -- 0xFE20-FE2F
signal romsel_enable    :   std_logic;      -- 0xFE30-FE3F
signal sys_via_enable   :   std_logic;      -- 0xFE40-FE5F
signal user_via_enable  :   std_logic;      -- 0xFE60-FE7F
--signal fddc_enable      :   std_logic;      -- 0xFE80-FE9F
--signal adlc_enable      :   std_logic;      -- 0xFEA0-FEBF (Econet)
signal adc_enable       :   std_logic;      -- 0xFEC0-FEDF
--signal tube_enable      :   std_logic;      -- 0xFEE0-FEFF

-- ROM select latch
signal romsel           :   std_logic_vector(3 downto 0);

signal mhz1_enable      :   std_logic;      -- Set for access to any 1 MHz peripheral

-- Flash
signal  FL_ADDR     :   std_logic_vector(15 downto 0);
signal  FL_DQ       :   std_logic_vector(7 downto 0);

signal sdclk_int : std_logic;

signal RAMWRn_int : std_logic;

signal scanSW : std_logic_vector(2 downto 0); --q
signal scanNext : std_logic;
signal scanReg : std_logic;

signal poweron_reset:	unsigned(7 downto 0) := "00000000";
signal scandoubler_ctrl: std_logic_vector(1 downto 0);
signal ram_we_n: std_logic;
signal ram_a:	std_logic_vector(18 downto 0);

begin

    dred <= red;
    dgreen <= green;
    dblue <= blue;
    dvsync <= vsync;
    dhsync <= hsync;

    -------------------------
    -- COMPONENT INSTANCES
    -------------------------
	NTSC <= '0';
	PAL <= '1';	

 relojes_bbc: entity work.relojes
  port map
   (-- Clock in ports
    CLK_IN1 => clk50,
    -- Clock out ports
    CLK_OUT1 => clock, --32
    CLK_OUT2 => CLOCK_24 --24
	 );


    rom : entity work.rom_image port map(
        clk_i               => clock,
        addr_i              => FL_ADDR,
        data_o              => FL_DQ
    );

    -- 6502 CPU
    GenT65Core: if UseT65Core generate
    cpu : entity work.T65 port map (
        cpu_mode,
        reset_n,
        cpu_clken,
        clock,
        cpu_ready,
        cpu_abort_n,
        cpu_irq_n,
        cpu_nmi_n,
        cpu_so_n,
        cpu_r_nw,
        cpu_sync,
        cpu_ef,
        cpu_mf,
        cpu_xf,
        cpu_ml_n,
        cpu_vp_n,
        cpu_vda,
        cpu_vpa,
        cpu_a,
        cpu_di,
        cpu_do );
    end generate;    
    
    GenAlanDCore: if UseAlanDCore generate
        inst_r65c02: entity work.r65c02 port map (
            reset    => reset_n,
            clk      => clock,
            enable   => cpu_clken,
            nmi_n    => cpu_nmi_n,
            irq_n    => cpu_irq_n,
            di       => unsigned(cpu_di),
            do       => cpu_dout_us,
            addr     => cpu_addr_us,
            nwe      => cpu_r_nw,
            sync     => cpu_sync,
            sync_irq => open,
            Regs     => open            
        );
        cpu_do <= std_logic_vector(cpu_dout_us);
        cpu_a(15 downto 0) <= std_logic_vector(cpu_addr_us);
        cpu_a(23 downto 16) <= (others => '0');
    end generate;

    crtc : entity work.mc6845 port map (
        clock,
        crtc_clken,
        reset_n,
        crtc_enable,
        cpu_r_nw,
        cpu_a(0),
        cpu_do,
        crtc_do,
        crtc_vsync,
        crtc_hsync,
        crtc_de,
        crtc_cursor,
        crtc_lpstb,
        crtc_ma,
        crtc_ra );

    video_ula : entity work.vidproc port map (
        clock,
        vid_clken,
        reset_n,
        crtc_clken,
        vidproc_enable,
        cpu_a(0),
        cpu_do,
        SRAM_DATA(7 downto 0),
        vidproc_invert_n,
        vidproc_disen,
        crtc_cursor,
        r_in, g_in, b_in,
        r_out, g_out, b_out
        );

    teletext : entity work.saa5050 port map (
        CLOCK_24, -- This runs at 6 MHz, which we can't derive from the 32 MHz clock
        ttxt_clken,
        reset_n,
        clock, -- Data input is synchronised from the bus clock domain
        vid_clken,
        SRAM_DATA(6 downto 0),
        ttxt_glr,
        ttxt_dew,
        ttxt_crs,
        ttxt_lose,
        ttxt_r, ttxt_g, ttxt_b, ttxt_y
        );

    -- System VIA
    system_via : entity work.m6522 port map (
        cpu_a(3 downto 0),
        cpu_do,
        sys_via_do,
        sys_via_do_oe_n,
        cpu_r_nw,
        sys_via_enable,
        '0', -- nCS2
        sys_via_irq_n,
        sys_via_ca1_in,
        sys_via_ca2_in,
        sys_via_ca2_out,
        sys_via_ca2_oe_n,
        sys_via_pa_in,
        sys_via_pa_out,
        sys_via_pa_oe_n,
        sys_via_cb1_in,
        sys_via_cb1_out,
        sys_via_cb1_oe_n,
        sys_via_cb2_in,
        sys_via_cb2_out,
        sys_via_cb2_oe_n,
        sys_via_pb_in,
        sys_via_pb_out,
        sys_via_pb_oe_n,
        mhz1_clken,
        hard_reset_n, -- System VIA is reset by power on reset only
        mhz4_clken,
        clock
        );
        
    -- User VIA
    user_via : entity work.m6522 port map (
        cpu_a(3 downto 0),
        cpu_do,
        user_via_do,
        user_via_do_oe_n,
        cpu_r_nw,
        user_via_enable,
        '0', -- nCS2
        user_via_irq_n,
        user_via_ca1_in,
        user_via_ca2_in,
        user_via_ca2_out,
        user_via_ca2_oe_n,
        user_via_pa_in,
        user_via_pa_out,
        user_via_pa_oe_n,
        user_via_cb1_in,
        user_via_cb1_out,
        user_via_cb1_oe_n,
        user_via_cb2_in,
        user_via_cb2_out,
        user_via_cb2_oe_n,
        user_via_pb_in,
        user_via_pb_out,
        user_via_pb_oe_n,
        mhz1_clken,
        reset_n,
        mhz4_clken,
        clock
        );

    -- Keyboard
    keyb : entity work.keyboard port map (
        clock, hard_reset_n, mhz1_clken,
        ps2_clk, ps2_data,
        keyb_enable_n,
        keyb_column,
        keyb_row,
        keyb_out,
        keyb_int,
        keyb_break,
        -- TODO: Add DIP Switches
        "00000000",
		  scanSW
        );

    -- Sound generator (and drive logic for I2S codec)
    sound : entity work.sn76489_top port map (
        clock, mhz4_clken,
        reset_n, '0', sound_enable_n,
        sound_ready, sound_di,
        sound_ao
        );

	dac : entity work.pwm_sddac PORT MAP(
		clk_i => clock,
		reset => '0',
		dac_i => std_logic_vector(128+sound_ao), --added 128 to lower volume and avoid distortion
		dac_o => audio
	);

    -- TODO: Add DAC
    audioL <= audio;
    audioR <= audio;


    -- Keyboard and System VIA are reset by external reset switch or PLL being out of lock
--    hard_reset_n <= not ERST;

    -- Rest of system is reset by all of the above plus the keyboard BREAK key
    reset_n <= hard_reset_n and not keyb_break;

    -- Clock enable generation - 32 MHz clock split into 32 cycles
    -- CPU is on 0 and 16 (but can be masked by 1 MHz bus accesses)
    -- Video is on all odd cycles (16 MHz)
    -- 1 MHz cycles are on cycle 31 (1 MHz)
    vid_clken <= clken_counter(0); -- 1,3,5...
    mhz4_clken <= clken_counter(0) and clken_counter(1) and clken_counter(2); -- 7/15/23/31
    mhz2_clken <= mhz4_clken and clken_counter(3); -- 15/31
    mhz1_clken <= mhz2_clken and clken_counter(4); -- 31
    cpu_cycle <= not (clken_counter(0) or clken_counter(1) or clken_counter(2) or clken_counter(3)); -- 0/16
    cpu_clken <= cpu_cycle and not cpu_cycle_mask(1) and not cpu_cycle_mask(0);

    clk_gen: process(clock,reset_n)
    begin
        if reset_n = '0' then
            clken_counter <= (others => '0');
        elsif rising_edge(clock) then
            clken_counter <= clken_counter + 1;
        end if;
    end process;

    cycle_stretch: process(clock,reset_n,mhz2_clken)
    begin
        if reset_n = '0' then
            cpu_cycle_mask <= "00";
        elsif rising_edge(clock) and mhz2_clken = '1' then
            if mhz1_enable = '1' and cpu_cycle_mask = "00" then
                -- Block CPU cycles until 1 MHz cycle has completed
                if mhz1_clken = '0' then
                    cpu_cycle_mask <= "01";
                else
                    cpu_cycle_mask <= "10";
                end if;
            end if;
            if cpu_cycle_mask /= "00" then
                cpu_cycle_mask <= cpu_cycle_mask - 1;
            end if;
        end if;
    end process;

    ttxt_clk_gen: process(CLOCK_24,reset_n)
    begin
        if reset_n = '0' then
            ttxt_clken_counter <= (others => '0');
        elsif rising_edge(CLOCK_24) then
            ttxt_clken_counter <= ttxt_clken_counter + 1;
        end if;
    end process;

    -- 6 MHz clock enable for SAA5050
    --ttxt_clken <= '1' when ttxt_clken_counter = 0 else '0';
	  ttxt_clken <= not ttxt_clken_counter(0); --q

    -- CPU configuration and fixed signals
    cpu_mode <= "00"; -- 6502
    cpu_ready <= '1';
    cpu_abort_n <= '1';
    cpu_nmi_n <= '1';
    cpu_so_n <= '1';

    -- Address decoding
    -- 0x0000 = 32 KB SRAM
    -- 0x8000 = 16 KB BASIC/Sideways ROMs
    -- 0xC000 = 16 KB MOS ROM
    --
    -- IO regions are mapped into a hole in the MOS.  There are three regions:
    -- 0xFC00 = FRED
    -- 0xFD00 = JIM
    -- 0xFE00 = SHEILA
    ram_enable <= not cpu_a(15);
    rom_enable <= cpu_a(15) and not cpu_a(14);
    mos_enable <= cpu_a(15) and cpu_a(14) and not (io_fred or io_jim or io_sheila);
    io_fred <= '1' when cpu_a(15 downto 8) = "11111100" else '0';
    io_jim <= '1' when cpu_a(15 downto 8) = "11111101" else '0';
    io_sheila <= '1' when cpu_a(15 downto 8) = "11111110" else '0';
    -- The following IO regions are accessed at 1 MHz and hence will stall the
    -- CPU accordingly
    mhz1_enable <= io_fred or io_jim or
        adc_enable or sys_via_enable or user_via_enable or
        serproc_enable or acia_enable or crtc_enable;

    -- SHEILA address demux
    -- All the system peripherals are mapped into this page as follows:
    -- 0xFE00 - 0xFE07 = MC6845 CRTC
    -- 0xFE08 - 0xFE0F = MC6850 ACIA (Serial/Tape)
    -- 0xFE10 - 0xFE1F = Serial ULA
    -- 0xFE20 - 0xFE2F = Video ULA
    -- 0xFE30 - 0xFE3F = Paged ROM select latch
    -- 0xFE40 - 0xFE5F = System VIA (6522)
    -- 0xFE60 - 0xFE7F = User VIA (6522)
    -- 0xFE80 - 0xFE9F = 8271 Floppy disc controller
    -- 0xFEA0 - 0xFEBF = 68B54 ADLC for Econet
    -- 0xFEC0 - 0xFEDF = uPD7002 ADC
    -- 0xFEE0 - 0xFEFF = Tube ULA
    process(cpu_a,io_sheila)
    begin
        -- All regions normally de-selected
        crtc_enable <= '0';
        acia_enable <= '0';
        serproc_enable <= '0';
        vidproc_enable <= '0';
        romsel_enable <= '0';
        sys_via_enable <= '0';
        user_via_enable <= '0';
--        fddc_enable <= '0';
--        adlc_enable <= '0';
        adc_enable <= '0';
--        tube_enable <= '0';

        if io_sheila = '1' then
            case cpu_a(7 downto 5) is
                when "000" =>
                    -- 0xFE00
                    if cpu_a(4) = '0' then
                        if cpu_a(3) = '0' then
                            -- 0xFE00
                            crtc_enable <= '1';
                        else
                            -- 0xFE08
                            acia_enable <= '1';
                        end if;
                    else
                        -- 0xFE10
                        serproc_enable <= '1';
                    end if;
                when "001" =>
                    -- 0xFE20
                    if cpu_a(4) = '0' then
                        -- 0xFE20
                        vidproc_enable <= '1';
                    else
                        -- 0xFE30
                        romsel_enable <= '1';
                    end if;
                when "010" => sys_via_enable <= '1';    -- 0xFE40
                when "011" => user_via_enable <= '1';   -- 0xFE60
--                when "100" => fddc_enable <= '1';       -- 0xFE80
--                when "101" => adlc_enable <= '1';       -- 0xFEA0
                when "110" => adc_enable <= '1';        -- 0xFEC0
--                when "111" => tube_enable <= '1';       -- 0xFEE0
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- CPU data bus mux and interrupts
    cpu_di <=
        SRAM_DATA(7 downto 0) when ram_enable = '1' else
        FL_DQ       when rom_enable = '1' else
        FL_DQ       when mos_enable = '1' else
        crtc_do     when crtc_enable = '1' else
        "00000010"  when acia_enable = '1' else
        sys_via_do  when sys_via_enable = '1' else
        user_via_do when user_via_enable = '1' else
        "11111110"  when io_sheila = '1' else
        "11111111"  when io_fred = '1' or io_jim = '1' else
        (others => '0'); -- un-decoded locations are pulled down by RP1
    cpu_irq_n <= sys_via_irq_n and user_via_irq_n;

    -- ROMs are in external flash and split into 16K slots (since this also suits other
    -- computers that might be run on the same board).
    -- The first 8 slots are allocated for use here, and the first 4 are decoded as
    -- the sideways ROMs.  Slot 7 is used for the MOS.

    FL_ADDR(15) <= mos_enable;
    FL_ADDR(14) <= romsel(0);
    FL_ADDR(13 downto 0) <= cpu_a(13 downto 0);

    -- Synchronous outputs to SRAM
    process(clock,reset_n)
    variable ram_write : std_logic;
    begin
        ram_write := ram_enable and not cpu_r_nw;

        if reset_n = '0' then
            RAMWRn_int <= '1';
            SRAM_DATA(7 downto 0) <= (others => 'Z');
        elsif rising_edge(clock) then
            -- Default to inputs
            SRAM_DATA(7 downto 0) <= (others => 'Z');

            -- Register SRAM signals to outputs (clock must be at least 2x CPU clock)
            if vid_clken = '1' then
                -- Fetch data from previous CPU cycle
                RAMWRn_int <= not ram_write;
                --SRAM_ADDR <= "000" & cpu_a(15 downto 0);
                RAM_A <= "000" & cpu_a(15 downto 0);
                if ram_write = '1' then
                    SRAM_DATA(7 downto 0) <= cpu_do;
                end if;
            else
                -- Fetch data from previous display cycle
                RAMWRn_int <= '1';
              --  SRAM_ADDR <= "0000" & display_a;
                RAM_A <= "0000" & display_a;
            end if;
        end if;
    end process;
 --   RAMWRn <= RAMWRn_int or (not clock);
    ram_we_n <= RAMWRn_int or (not clock);

    -- Address translation logic for calculation of display address
    process(crtc_ma,crtc_ra,disp_addr_offs)
    variable aa : unsigned(3 downto 0);
    begin
        if crtc_ma(12) = '0' then
            -- No adjustment
            aa := unsigned(crtc_ma(11 downto 8));
        else
            -- Address adjusted according to screen mode to compensate for
            -- wrap at 0x8000.
            case disp_addr_offs is
            when "00" =>
                -- Mode 3 - restart at 0x4000
                aa := unsigned(crtc_ma(11 downto 8)) + 8;
            when "01" =>
                -- Mode 6 - restart at 0x6000
                aa := unsigned(crtc_ma(11 downto 8)) + 12;
            when "10" =>
                -- Mode 0,1,2 - restart at 0x3000
                aa := unsigned(crtc_ma(11 downto 8)) + 6;
            when "11" =>
                -- Mode 4,5 - restart at 0x5800
                aa := unsigned(crtc_ma(11 downto 8)) + 11;
            when others =>
                null;
            end case;
        end if;

        if crtc_ma(13) = '0' then
            -- HI RES
            display_a <= std_logic_vector(aa(3 downto 0)) & crtc_ma(7 downto 0) & crtc_ra(2 downto 0);
        else
            -- TTX VDU
            display_a <= std_logic(aa(3)) & "1111" & crtc_ma(9 downto 0);
        end if;
    end process;

    -- VIDPROC
    vidproc_invert_n <= '1';
    vidproc_disen <= crtc_de and not crtc_ra(3); -- DISEN is masked off by RA(3) for MODEs 3 and 6
    r_in <= ttxt_r;
    g_in <= ttxt_g;
    b_in <= ttxt_b;

    -- SAA5050
    ttxt_glr <= not crtc_hsync;
    ttxt_dew <= crtc_vsync;
    ttxt_crs <= not crtc_ra(0);
    ttxt_lose <= crtc_de;

    -- CRTC drives video out (CSYNC on HSYNC output, VSYNC high) --q scandoubler
--    hsync <= not (crtc_hsync or crtc_vsync); --q xor
--    vsync <= '1';
--    red <= r_out & r_out & r_out;
--    green <= g_out & g_out & g_out;
--    blue <= b_out & b_out & b_out;

    -- Connections to System VIA
    -- ADC
    sys_via_cb1_in <= '1'; -- /EOC
    -- CRTC
    sys_via_ca1_in <= crtc_vsync;
    sys_via_cb2_in <= crtc_lpstb;
    -- Keyboard
    sys_via_ca2_in <= keyb_int;
    sys_via_pa_in(7) <= keyb_out;
    sys_via_pa_in(6 downto 0) <= sys_via_pa_out(6 downto 0); -- Must loop back output pins or keyboard won't work
    keyb_column <= sys_via_pa_out(3 downto 0);
    keyb_row <= sys_via_pa_out(6 downto 4);
    -- Sound
    sound_di <= sys_via_pa_out;
    -- Others (idle until missing bits implemented)
    sys_via_pb_in(7 downto 4) <= (others => '1');

    -- Connections to User VIA (user port is output on green LEDs)
    user_via_ca1_in <= '1'; -- Pulled up

    -- MMBEEB

    -- SDCLK is driven from either PB1 or CB1 depending on the SR Mode
    sdclk_int     <= user_via_pb_out(1) when user_via_pb_oe_n(1) = '0' else
                     user_via_cb1_out   when user_via_cb1_oe_n = '0' else                     
                     '1';
    
    SDCLK           <= sdclk_int;
    user_via_cb1_in <= sdclk_int;
    
    -- SDMOSI is always driven from PB0
    SDMOSI        <= user_via_pb_out(0) when user_via_pb_oe_n(0) = '0' else
                     '1';
    
    -- SDMISO is always read from CB2
    user_via_cb2_in <= SDMISO; -- SDI
    
    -- SDSS is hardwired to 0 (always selected) as there is only one slave attached
    SDSS          <= '0';         

 
    user_via_pb_in <= user_via_pb_out;

    -- ROM select latch
    process(clock,reset_n)
    begin
        if reset_n = '0' then
            romsel <= (others => '0');
        elsif rising_edge(clock) then
            if romsel_enable = '1' and cpu_r_nw = '0' then
                romsel <= cpu_do(3 downto 0);
            end if;
        end if;
    end process;

    -- IC32 latch
    sound_enable_n <= ic32(0);
--    speech_write_n <= ic32(1);
--    speech_read_n <= ic32(2);
    keyb_enable_n <= ic32(3);
    disp_addr_offs <= ic32(5 downto 4);
    caps_lock_led_n <= ic32(6);
    shift_lock_led_n <= ic32(7);

    process(clock,reset_n)
    variable bit_num : integer;
    begin
--        bit_num := to_integer(unsigned(sys_via_pb_out(2 downto 0)));

        if reset_n = '0' then
            ic32 <= (others => '0');
        elsif rising_edge(clock) then
				bit_num := to_integer(unsigned(sys_via_pb_out(2 downto 0)));
            ic32(bit_num) <= sys_via_pb_out(3);
        end if;
    end process;
	 
  DIP(0) <= scandoubler_ctrl(0) xor scanSW(0); -- vga / rgb (via SRAM init or ScrollLock
  DIP(1) <= '0';
	 
-----------------------------------------------
-- Scan Doubler from the MIST project
-----------------------------------------------

	inst_mist_scandoubler: entity work.mist_scandoubler port map (
		clk => clock,
		clk_16 => clock,
		clk_16_en => vid_clken,
		scanlines => scanSW(1), --scanlines "-" numpad
		hs_in => not crtc_hsync,
		vs_in => not crtc_vsync,
		r_in => r_out,
		g_in => g_out,
		b_in => b_out,
		hs_out => vga0_hs,
		vs_out => vga0_vs,
		r_out => vga0_r,
		g_out => vga0_g,
		b_out => vga0_b,
		is15k => open 
	);
    vga0_mode <= DIP(0);


-----------------------------------------------
-- Scan Doubler from RGB2VGA project
-----------------------------------------------

--	inst_rgb2vga_dcm: entity work.rgb2vga_dcm port map (
--		CLKIN_IN => clock,
--		CLKFX_OUT => vga_clock
--	);
--
--	inst_rgb2vga: entity work.rgb2vga port map (
--		clock => clock,
--		clken => vid_clken,
--		clk25 => vga_clock,
--		rgbi_in => r_out & g_out & b_out & '0',
--		hSync_in => crtc_hsync,
--		vSync_in => crtc_vsync,
--		rgbi_out => rgbi_out,
--		hSync_out => vga1_hs,
--		vSync_out => vga1_vs
--	);
--    vga1_r <= rgbi_out(3) & rgbi_out(3);
--    vga1_g <= rgbi_out(2) & rgbi_out(2);
--    vga1_b <= rgbi_out(1) & rgbi_out(1);
--    
--    vga1_mode <= DIP(1);

-----------------------------------------------
-- RGBHV Multiplexor
-----------------------------------------------

    -- CRTC drives video out (CSYNC on HSYNC output, VSYNC high)
    hsync <= vga0_hs when vga0_mode = '1' else
--             vga1_hs when vga1_mode = '1' else
             not (crtc_hsync or crtc_vsync);

    vsync <= vga0_vs when vga0_mode = '1' else
--             vga1_vs when vga1_mode = '1' else
             '1';
             
    red   <= vga0_r(1) & vga0_r(0) & "0" when vga0_mode = '1' else
--             vga1_r(1) & vga1_r(0) & "0" when vga1_mode = '1' else
             r_out & r_out & r_out;
             
    green <= vga0_g(1) & vga0_g(0) & "0" when vga0_mode = '1' else
--             vga1_g(1) & vga1_g(0) & "0" when vga1_mode = '1' else
             g_out & g_out & g_out;
             
    blue  <= vga0_b(1) & vga0_b(0) & "0" when vga0_mode = '1' else
--             vga1_b(1) & vga1_b(0) & "0" when vga1_mode = '1' else
             b_out & b_out & b_out;
	 

   -- Keyboard LEDs
   -- LED1 <= not caps_lock_led_n;
	
LED1 <= not sdclk_int; --SD Led
	 
	--- RESET int / SCANDLBLCTRL REG ZXUNO
	 
	process (clock)
	  begin
		if rising_edge(clock) then
		  if (poweron_reset < 126) then
            scandoubler_ctrl <= sram_data(1 downto 0);
		  end if;
		  if poweron_reset < 254 then
				poweron_reset <= poweron_reset + 1;
		  end if;
		end if;
	end process;	 
	
	hard_reset_n <= '0' when poweron_reset < 254 else  '1';
	
	sram_addr <= "0001000111111010101" when poweron_reset < 254 else ram_a; --0x8FD5 SRAM (SCANDBLCTRL REG)
	RAMWRn <= '1' when poweron_reset < 254 else ram_we_n;
	
	--- endRESET int
	
------------multiboot---------------

	multiboot: entity work.multiboot
	port map(
		clk_icap		      => CLOCK_24,
		REBOOT				=> scanSW(2) --mreset key combo
	);	

end architecture;
