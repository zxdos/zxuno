--
-- A simulation model of VIC20 hardware
-- Copyright (c) MikeJ - March 2003
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email vic20@fpgaarcade.com
--
--
-- Revision list
--
-- version 002 spartan3e release
-- version 001 initial release
--
--
-- A model of the 6561 PAL VIC chip
--
-- Fully functional and tested against a real chip.
--
-- POTX/Y not implemented
-- light pen may not be correct

-- The noise generator is not 100% accurate. I am fairly sure it is a LFSR
-- of length 18 or 19, however I have not found the taps which reproduce the
-- waveform of a real device.

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

--library UNISIM;
  --use UNISIM.Vcomponents.all;

-- 6561 PAL Video Interface Chip model

entity VIC20_VIC is
  generic (
    K_OFFSET          : in    std_logic_vector(4 downto 0) := "10000"
    );
  port (
    I_RW_L            : in    std_logic;

    I_ADDR            : in    std_logic_vector(13 downto 0);
    O_ADDR            : out   std_logic_vector(13 downto 0);

    I_DATA            : in    std_logic_vector(11 downto 0);
    O_DATA            : out   std_logic_vector( 7 downto 0);
    O_DATA_OE_L       : out   std_logic;
    --
    O_AUDIO           : out   std_logic_vector(3 downto 0);

    O_VIDEO_R         : out   std_logic_vector(2 downto 0);
    O_VIDEO_G         : out   std_logic_vector(2 downto 0);
    O_VIDEO_B         : out   std_logic_vector(2 downto 0);

    O_HSYNC           : out   std_logic;
    O_VSYNC           : out   std_logic;
    O_COMP_SYNC_L     : out   std_logic;
    --
    --
    I_LIGHT_PEN       : in    std_logic;
    I_POTX            : in    std_logic;
    I_POTY            : in    std_logic;

    O_ENA_1MHZ        : out   std_logic; -- 1.1 MHz strobe
    O_P2_H            : out   std_logic; -- 2.2 MHz cpu access
    ENA_4             : in    std_logic; -- 4.436 MHz clock enable
    CLK               : in    std_logic
    );
end;

architecture RTL of VIC20_VIC is

  -- clocks per line must be divisable by 4
  constant CLOCKS_PER_LINE_M1 : std_logic_vector(8 downto 0) := "100011011"; -- 284 -1
  constant TOTAL_LINES_M1     : std_logic_vector(8 downto 0) := "100110111"; -- 312 -1
  constant H_START_M1         : std_logic_vector(8 downto 0) := "000101011"; -- 44 -1
--  constant H_START_M1         : std_logic_vector(8 downto 0) := "000101001"; -- 42 -1
  constant H_END_M1           : std_logic_vector(8 downto 0) := "100001111"; -- 272 -1
  constant V_START            : std_logic_vector(8 downto 0) := "000011100"; -- 28
  -- video size 228 pixels by 284 lines

  -- close to original                               RGB
  constant col0 : std_logic_vector(11 downto 0) := x"000";  -- 0 - 0000   Black
  constant col1 : std_logic_vector(11 downto 0) := x"FFF";  -- 1 - 0001   White
  constant col2 : std_logic_vector(11 downto 0) := x"B11";  -- 2 - 0010   Red
  constant col3 : std_logic_vector(11 downto 0) := x"5ED";  -- 3 - 0011   Cyan
  constant col4 : std_logic_vector(11 downto 0) := x"C3D";  -- 4 - 0100   Purple
  constant col5 : std_logic_vector(11 downto 0) := x"4E3";  -- 5 - 0101   Green
  constant col6 : std_logic_vector(11 downto 0) := x"33C";  -- 6 - 0110   Blue
  constant col7 : std_logic_vector(11 downto 0) := x"DE2";  -- 7 - 0111   Yellow
  constant col8 : std_logic_vector(11 downto 0) := x"C60";  -- 8 - 1000   Orange
  constant col9 : std_logic_vector(11 downto 0) := x"EB8";  -- 9 - 1001   Light orange
  constant colA : std_logic_vector(11 downto 0) := x"E99";  --10 - 1010   Pink
  constant colB : std_logic_vector(11 downto 0) := x"AFF";  --11 - 1011   Light cyan
  constant colC : std_logic_vector(11 downto 0) := x"EAE";  --12 - 1100   Light purple
  constant colD : std_logic_vector(11 downto 0) := x"AFA";  --13 - 1101   Light green
  constant colE : std_logic_vector(11 downto 0) := x"A9E";  --14 - 1110   Light blue
  constant colF : std_logic_vector(11 downto 0) := x"FFA";  --15 - 1111   Light yellow
  -- 'Pure' colours
  --constant col0 : std_logic_vector(11 downto 0) := x"000";  -- 0 - 0000   Black
  --constant col1 : std_logic_vector(11 downto 0) := x"FFF";  -- 1 - 0001   White
  --constant col2 : std_logic_vector(11 downto 0) := x"F00";  -- 2 - 0010   Red
  --constant col3 : std_logic_vector(11 downto 0) := x"0FF";  -- 3 - 0011   Cyan
  --constant col4 : std_logic_vector(11 downto 0) := x"606";  -- 4 - 0100   Purple
  --constant col5 : std_logic_vector(11 downto 0) := x"0A0";  -- 5 - 0101   Green
  --constant col6 : std_logic_vector(11 downto 0) := x"00F";  -- 6 - 0110   Blue
  --constant col7 : std_logic_vector(11 downto 0) := x"DD0";  -- 7 - 0111   Yellow
  --constant col8 : std_logic_vector(11 downto 0) := x"CA0";  -- 8 - 1000   Orange
  --constant col9 : std_logic_vector(11 downto 0) := x"FA0";  -- 9 - 1001   Light orange
  --constant colA : std_logic_vector(11 downto 0) := x"F88";  --10 - 1010   Pink
  --constant colB : std_logic_vector(11 downto 0) := x"0FF";  --11 - 1011   Light cyan
  --constant colC : std_logic_vector(11 downto 0) := x"F0F";  --12 - 1100   Light purple
  --constant colD : std_logic_vector(11 downto 0) := x"0F0";  --13 - 1101   Light green
  --constant colE : std_logic_vector(11 downto 0) := x"0AF";  --14 - 1110   Light blue
  --constant colF : std_logic_vector(11 downto 0) := x"FF0";  --15 - 1111   Light yellow

  signal ena_1mhz_int     : std_logic;
  signal p2_h_int         : std_logic;
  signal cs               : std_logic;
  -- cpu if
  signal r_interlaced     : std_logic := '0'; -- 6561 does not support
  signal r_x_offset       : std_logic_vector(6 downto 0) :=  "0001100"; -- 12
  signal r_y_offset       : std_logic_vector(7 downto 0) := "00100110"; -- 38
  signal r_num_cols       : std_logic_vector(6 downto 0) :=  "0010110"; -- 22
  signal r_num_rows       : std_logic_vector(5 downto 0) :=   "010111"; -- 23
  signal r_charsize       : std_logic := '0';
  signal r_screen_mem     : std_logic_vector(4 downto 0) := "11111";
  signal r_char_mem       : std_logic_vector(3 downto 0) := "0000";
  signal r_x_lightpen     : std_logic_vector(7 downto 0) := "00000000";
  signal r_y_lightpen     : std_logic_vector(7 downto 0) := "00000000";
  signal r_base_sound     : std_logic_vector(7 downto 0) := "00000000";
  signal r_alto_sound     : std_logic_vector(7 downto 0) := "00000000";
  signal r_soprano_sound  : std_logic_vector(7 downto 0) := "00000000";
  signal r_noise_sound    : std_logic_vector(7 downto 0) := "00000000";
  signal r_amplitude      : std_logic_vector(3 downto 0) := "0000";
  signal r_aux_colour     : std_logic_vector(3 downto 0) := "0000";
  signal r_border_colour  : std_logic_vector(2 downto 0) := "011";
  signal r_reverse_mode   : std_logic := '1'; -- 1 is off
  signal r_backgnd_colour : std_logic_vector(3 downto 0) := "0001";

  -- timing
  signal hcnt             : std_logic_vector(8 downto 0) := "000000000";
  signal vcnt             : std_logic_vector(8 downto 0) := "000000000";

  signal do_hsync         : boolean;
  signal hblank           : std_logic;
  signal vblank           : std_logic := '1';
  signal hsync            : std_logic;
  signal vsync            : std_logic;

  signal start_h          : boolean;
  signal h_char_cnt       : std_logic_vector(9 downto 0);
  signal h_char_last      : std_logic;
  signal start_v          : boolean;
  signal v_char_cnt       : std_logic_vector(10 downto 0);
  signal v_char_last      : boolean;

  signal matrix_cnt       : std_logic_vector(13 downto 0);
  signal last_matrix_cnt  : std_logic_vector(13 downto 0);
  signal din_reg_cell     : std_logic_vector(11 downto 0);
  signal din_reg_char     : std_logic_vector(11 downto 0);
  signal char_load        : std_logic;
  signal doing_cell       : std_logic;

  signal op_cnt           : std_logic_vector(3 downto 0) := (others => '0');
  signal op_reg           : std_logic_vector(7 downto 0);

  signal op_multi         : std_logic;
  signal op_col           : std_logic_vector(2 downto 0);

  signal col_mux_sel      : std_logic_vector(3 downto 0);
  signal col_rgb          : std_logic_vector(11 downto 0);

  signal bit_sel          : std_logic;
  signal bit_sel_m        : std_logic_vector(1 downto 0);
  signal bit_sel_final    : std_logic_vector(1 downto 0);

  signal light_pen_in_t1  : std_logic;
  signal light_pen_in_t2  : std_logic;

  -- audio
  signal audio_div        : std_logic_vector(9 downto 0):= (others => '0');
  signal audio_div_t1     : std_logic_vector(9 downto 0);
  signal audio_div_256    : boolean;
  signal audio_div_128    : boolean;
  signal audio_div_64     : boolean;
  signal audio_div_16     : boolean;

  signal base_sg          : std_logic;
  signal base_sg_freq     : std_logic_vector(6 downto 0);
  signal base_sg_cnt      : std_logic_vector(6 downto 0) := (others => '0');

  signal alto_sg          : std_logic;
  signal alto_sg_freq     : std_logic_vector(6 downto 0);
  signal alto_sg_cnt      : std_logic_vector(6 downto 0) := (others => '0');

  signal soprano_sg       : std_logic;
  signal soprano_sg_freq  : std_logic_vector(6 downto 0);
  signal soprano_sg_cnt   : std_logic_vector(6 downto 0) := (others => '0');

  signal noise_sg         : std_logic;
  signal noise_sg_freq    : std_logic_vector(6 downto 0);
  signal noise_sg_cnt     : std_logic_vector(6 downto 0) := (others => '0');
  signal noise_gen        : std_logic_vector(18 downto 0) := (others => '0');

  signal audio_wav        : std_logic_vector(3 downto 0);
  signal audio_mul_out    : std_logic_vector(7 downto 0);

begin

  p_strobe_gen : process(hcnt)
  begin

    ena_1mhz_int <= '0';
    if (hcnt(1 downto 0) = "01") then
      ena_1mhz_int <= '1';
    end if;

    p2_h_int     <= not hcnt(1);
  end process;
  O_ENA_1MHZ <= ena_1mhz_int;
  O_P2_H <= p2_h_int; -- vic access when P2_H = '0'

  p_chip_sel : process(p2_h_int, I_ADDR)
  begin
    cs <= '0';
    if (p2_h_int = '1') then -- cpu access
      if (I_ADDR(13 downto 8) = "010000") then
        cs <= '1';
      end if;
    end if;
  end process;

  p_oe : process(cs, I_RW_L)
  begin
    O_DATA_OE_L <= '1';
    if (I_RW_L = '1') and (cs = '1') then -- cpu read access
      O_DATA_OE_L <= '0';
    end if;
  end process;
  --
  -- registers
  --
  p_reg_write : process
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      if (I_RW_L = '0') and (cs = '1') then -- cpu read access
         --the data sheet claims the registers alias
        case I_ADDR(3 downto 0) is
          when x"0" => r_interlaced             <= I_DATA(7);
                       r_x_offset               <= I_DATA(6 downto 0);

          when x"1" => r_y_offset               <= I_DATA(7 downto 0);

          when x"2" => r_screen_mem(0)          <= I_DATA(7);
                       r_num_cols               <= I_DATA(6 downto 0);

          when x"3" => r_num_rows               <= I_DATA(6 downto 1);
                       r_charsize               <= I_DATA(0);

          when x"5" => r_screen_mem(4 downto 1) <= I_DATA(7 downto 4);
                       r_char_mem(3 downto 0)   <= I_DATA(3 downto 0);

          when x"A" => r_base_sound             <= I_DATA(7 downto 0);
          when x"B" => r_alto_sound             <= I_DATA(7 downto 0);
          when x"C" => r_soprano_sound          <= I_DATA(7 downto 0);
          when x"D" => r_noise_sound            <= I_DATA(7 downto 0);
          when x"E" => r_aux_colour             <= I_DATA(7 downto 4);
                       r_amplitude              <= I_DATA(3 downto 0);
          when x"F" => r_backgnd_colour         <= I_DATA(7 downto 4);
                       r_reverse_mode           <= I_DATA(3);
                       r_border_colour          <= I_DATA(2 downto 0);
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_reg_read : process
  begin
    wait until rising_edge(CLK); -- we have time for one clock
    if (ENA_4 = '1') then
      case I_ADDR(3 downto 0) is
        when x"0" => O_DATA(7)              <= r_interlaced;
                     O_DATA(6 downto 0)     <= r_x_offset;

        when x"1" => O_DATA(7 downto 0)     <= r_y_offset;

        when x"2" => O_DATA(7)              <= r_screen_mem(0);
                     O_DATA(6 downto 0)     <= r_num_cols;

        when x"3" => O_DATA(7)              <= vcnt(0);
                     O_DATA(6 downto 1)     <= r_num_rows;
                     O_DATA(0)              <= r_charsize;

        when x"4" => O_DATA(7 downto 0)     <= vcnt(8 downto 1);

        when x"5" => O_DATA(7 downto 4)     <= r_screen_mem(4 downto 1);
                     O_DATA(3 downto 0)     <= r_char_mem(3 downto 0);


        when x"6" => O_DATA(7 downto 0)     <= r_x_lightpen;
        when x"7" => O_DATA(7 downto 0)     <= r_y_lightpen;
        when x"8" => O_DATA(7 downto 0)     <= x"00"; -- pot x
        when x"9" => O_DATA(7 downto 0)     <= x"00"; -- pot y

        when x"A" => O_DATA(7 downto 0)     <= r_base_sound;
        when x"B" => O_DATA(7 downto 0)     <= r_alto_sound;
        when x"C" => O_DATA(7 downto 0)     <= r_soprano_sound;
        when x"D" => O_DATA(7 downto 0)     <= r_noise_sound;

        when x"E" => O_DATA(7 downto 4)     <= r_aux_colour;
                     O_DATA(3 downto 0)     <= r_amplitude;

        when x"F" => O_DATA(7 downto 4)     <= r_backgnd_colour;
                     O_DATA(3)              <= r_reverse_mode;
                     O_DATA(2 downto 0)     <= r_border_colour;
        when others => null;
      end case;
    end if;
  end process;
  --
  -- video timing
  --
  -- 312 lines per frame
  --
  -- hsync blank picture blank
  -- 20    24    228     12     total 284 clock
  p_hvcnt : process
    variable hcarry,vcarry : boolean;
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      if (hcnt = CLOCKS_PER_LINE_M1) then
        hcnt <= "000000000";
      else
        hcnt <= hcnt +"1";
      end if;

      if do_hsync then
        if (vcnt = TOTAL_LINES_M1) then
          vcnt <= "000000000";
        else
          vcnt <= vcnt +"1";
        end if;
      end if;
    end if;
  end process;

  p_sync_comb : process(hcnt, vcnt)
  begin
    vsync <= '0';
    if (vcnt(8 downto 2) = "0000000") then
      vsync <= '1';
    end if;

    do_hsync <= (hcnt = CLOCKS_PER_LINE_M1);
  end process;

  p_sync : process
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      if (hcnt = H_END_M1) then
        hblank <= '1';
      elsif (hcnt = H_START_M1) then
        hblank <= '0';
      end if;

      if do_hsync then
        hsync <= '1';
      elsif (hcnt = "0000010011") then -- 20 -1
        hsync <= '0';
      end if;

      if do_hsync then
        if (vcnt = TOTAL_LINES_M1) then
          vblank <= '1';
        elsif (vcnt = V_START) then
          vblank <= '0';
        end if;
      end if;
    end if;
  end process;

  p_comp_sync : process(hsync, vsync)
  begin
    O_HSYNC <= hsync;
    O_VSYNC <= vsync;
    O_COMP_SYNC_L <= (not vsync) and (not hsync);
  end process;

  --
  -- addr
  --
  p_matrix_address : process
    variable cell_addr : std_logic_vector(13 downto 0);
    variable char_addr : std_logic_vector(13 downto 0);
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      -- counter used for video matrix address

      if (vsync = '1') then
        last_matrix_cnt(13 downto 9) <= r_screen_mem;
        last_matrix_cnt( 8 downto 0) <= (others => '0'); -- top left;

      elsif (h_char_last = '1') and v_char_last then
        last_matrix_cnt <= matrix_cnt;
      end if;

      if (hsync = '1') then
        matrix_cnt <= last_matrix_cnt;
      elsif (char_load = '1') then
        matrix_cnt <= matrix_cnt + "1";
       end if;

      -- address

      if (hcnt(1 downto 0) = "01") then
        if (h_char_cnt(2) = '0') then
          -- if cell fetch
          doing_cell <= '1';
          O_ADDR(13 downto 0) <= matrix_cnt;
        else
          -- if char fetch
          doing_cell <= '0';

          -- experiments show this is the correct behaviour

          if (r_charsize = '0') then
            cell_addr := ("000" & din_reg_cell(7 downto 0) & v_char_cnt(2 downto 0));
          else
            cell_addr := ("00"  & din_reg_cell(7 downto 0) & v_char_cnt(3 downto 0));
          end if;

          char_addr := (r_char_mem & "0000000000") + cell_addr;
          O_ADDR(13 downto 0) <= char_addr;
        end if;
      end if;

      if (hcnt(1 downto 0) = "11") then
        if (doing_cell = '1') then
          din_reg_cell <= I_DATA;
        else
          din_reg_char <= I_DATA;
        end if;
      end if;
    end if;
  end process;

  --
  -- video gen
  --
  p_offset_comp : process(hcnt, r_x_offset, vcnt, r_y_offset)
  begin
    -- nasty fudge factor to centre the piccy.
    start_h <= (hcnt = ((r_x_offset & "00") + K_OFFSET)); -- looks about right, fiddle at will
    start_v <= (vcnt = (r_y_offset & '0'));
  end process;

  p_char_cnt : process
    variable h_end : boolean;
    variable v_end : boolean;
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      h_end := (h_char_cnt(8 downto 0) = (r_num_cols(5 downto 0) & "000"));

      h_char_last <= '0';
      if start_h then
        h_char_cnt <= "1000000000";
      elsif (h_char_cnt(9) = '1') then -- active

        --if h_end then --or (hblank = '1') then -- hblank removed to ensure we still get a picture with daft offset values
        if h_end or do_hsync then
          h_char_cnt <= (others => '0');
          h_char_last <= '1';
        else
          h_char_cnt <= h_char_cnt + "1";
        end if;
      end if;

      if (r_charsize = '0') then
        v_end := (v_char_cnt(8 downto 0) = (r_num_rows(5 downto 0) & "000"));
      else
        v_end := (v_char_cnt(9 downto 0) = (r_num_rows(5 downto 0) & "0000"));
      end if;

      if v_end or (vblank = '1') then
        v_char_cnt <= (others => '0');
      else
        if start_h then
          if start_v then
            v_char_cnt <= "10000000000";
          elsif (v_char_cnt(10) = '1') then -- active
            v_char_cnt <= v_char_cnt + "1";
          end if;
        end if;
      end if;

      if (r_charsize = '0') then
        v_char_last <= (v_char_cnt(2 downto 0) = "111");
      else
        v_char_last <= (v_char_cnt(3 downto 0) = "1111");
      end if;
    end if;
  end process;

  p_char_load : process(h_char_cnt, v_char_cnt)
  begin
    char_load <= '0';
    if ((h_char_cnt(9) = '1') and (v_char_cnt(10) = '1')) then
      if (h_char_cnt(2 downto 0) = "111") then
        char_load <= '1';
      end if;
    end if;
  end process;

  p_char_gen : process
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      -- this would be better as a shift register, but to keep it simple ..
      -- op_cnt(3) is used as character_matrix_active (0 = border)
      if (char_load = '1') then
        op_cnt(3 downto 0) <= "1000";
        --buffer character
        op_reg   <= din_reg_char(7 downto 0);
        op_multi <= din_reg_cell(11);
        op_col   <= din_reg_cell(10 downto 8);
      elsif (op_cnt(3) = '1') then
        op_cnt <= op_cnt + "1";
      end if;
    end if;
  end process;

  p_char_sel : process(op_cnt, op_reg)
  begin
    -- yuk, a mux. Hang the expense.
    bit_sel <= '0';
    case op_cnt(2 downto 0) is
      when "000" => bit_sel <= op_reg(7);
      when "001" => bit_sel <= op_reg(6);
      when "010" => bit_sel <= op_reg(5);
      when "011" => bit_sel <= op_reg(4);
      when "100" => bit_sel <= op_reg(3);
      when "101" => bit_sel <= op_reg(2);
      when "110" => bit_sel <= op_reg(1);
      when "111" => bit_sel <= op_reg(0);
      when others => null;
    end case;

    bit_sel_m <= "00";
    case op_cnt(2 downto 0) is
      when "000" => bit_sel_m <= op_reg(7 downto 6);
      when "001" => bit_sel_m <= op_reg(7 downto 6);
      when "010" => bit_sel_m <= op_reg(5 downto 4);
      when "011" => bit_sel_m <= op_reg(5 downto 4);
      when "100" => bit_sel_m <= op_reg(3 downto 2);
      when "101" => bit_sel_m <= op_reg(3 downto 2);
      when "110" => bit_sel_m <= op_reg(1 downto 0);
      when "111" => bit_sel_m <= op_reg(1 downto 0);
      when others => null;
    end case;

  end process;

  p_char_decode : process(op_cnt, op_multi, bit_sel, bit_sel_m, r_reverse_mode)
  begin
    -- bit_sel_m codes
    -- 00 background colour
    -- 01 border colour
    -- 10 forground colour
    -- 11 aux colour
    bit_sel_final <= "00";
    if (op_cnt(3) = '0') then
      -- border
      bit_sel_final <= "01";
    else
      if (op_multi = '1') then
        bit_sel_final <= bit_sel_m;
      else
        bit_sel_final(1) <= bit_sel xor (not r_reverse_mode);
        bit_sel_final(0) <= '0';
      end if;
    end if;
  end process;

  P_char_colour_mux : process(bit_sel_final, r_backgnd_colour, r_border_colour,
                              op_col, r_aux_colour)
  begin
    col_mux_sel <= "0000";
      -- character matrix
    case bit_sel_final is
      when "00" => col_mux_sel <= r_backgnd_colour;
      when "01" => col_mux_sel <= ('0' & r_border_colour);
      when "10" => col_mux_sel <= ('0' & op_col);
      when "11" => col_mux_sel <= r_aux_colour;
      when others => null;
    end case;
  end process;

  p_colour_mux : process(col_mux_sel)
  begin
    col_rgb <= x"000";
    case col_mux_sel is
      when x"0" => col_rgb <= col0;
      when x"1" => col_rgb <= col1;
      when x"2" => col_rgb <= col2;
      when x"3" => col_rgb <= col3;
      when x"4" => col_rgb <= col4;
      when x"5" => col_rgb <= col5;
      when x"6" => col_rgb <= col6;
      when x"7" => col_rgb <= col7;
      when x"8" => col_rgb <= col8;
      when x"9" => col_rgb <= col9;
      when x"A" => col_rgb <= colA;
      when x"B" => col_rgb <= colB;
      when x"C" => col_rgb <= colC;
      when x"D" => col_rgb <= colD;
      when x"E" => col_rgb <= colE;
      when x"F" => col_rgb <= colF;
      when others => null;
    end case;
  end process;

  p_video_out_mux : process
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      if (hblank = '1') or (vblank = '1') then
        -- blanking
        O_VIDEO_R <= "000";
        O_VIDEO_G <= "000";
        O_VIDEO_B <= "000";
      else
        O_VIDEO_R <= col_rgb(11 downto 9);
        O_VIDEO_G <= col_rgb( 7 downto 5);
        O_VIDEO_B <= col_rgb( 3 downto 1);
      end if;
   end if;
  end process;


  p_lightpen : process
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
    -- no idea if this is correct !!

      light_pen_in_t1 <= I_LIGHT_PEN;
      light_pen_in_t2 <= light_pen_in_t1;

      if (light_pen_in_t2 = '1') and (light_pen_in_t1 = '0') then --  neg edge
        r_x_lightpen <= hcnt(8 downto 1); -- ??
        r_y_lightpen <= vcnt(8 downto 1); -- ??
      end if;
    end if;
  end process;
  --
  -- AUDIO
  --
  p_sound_div : process
  begin
  -- bass       freq f=Phi2/256/(128-(($900a+1)&127))
  -- alto       freq f=Phi2/128/(128-(($900b+1)&127))
  -- soprano    freq f=Phi2/64/(128-(($900c+1) &127))
  -- noise      freq f=Phi2/32/(128-(($900d+1) &127)) -- not true about the divider !
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then

      audio_div <= audio_div + "1";
      audio_div_t1 <= audio_div;
      -- /256 /4 (phi = clk4 /4) *2 as toggling output
      audio_div_256 <= (audio_div(8) = '1') and (audio_div_t1(8) = '0');
      audio_div_128 <= (audio_div(7) = '1') and (audio_div_t1(7) = '0');
      audio_div_64  <= (audio_div(6) = '1') and (audio_div_t1(6) = '0');
      audio_div_16  <= (audio_div(4) = '1') and (audio_div_t1(4) = '0');
    end if;
  end process;

  p_sound_gen : process
    variable noise_zero : std_ulogic;
    variable wav : std_logic;
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      base_sg_freq    <= "1111111" - r_base_sound(6 downto 0);
      alto_sg_freq    <= "1111111" - r_alto_sound(6 downto 0);
      soprano_sg_freq <= "1111111" - r_soprano_sound(6 downto 0);
      noise_sg_freq   <= "1111111" - r_noise_sound(6 downto 0);

      if audio_div_256 then
        if (base_sg_cnt = "0000000") then
          base_sg_cnt <= base_sg_freq(6 downto 0) - "1"; -- note wrap around for 0 case
          base_sg <= not base_sg;
        else
          base_sg_cnt <= base_sg_cnt - "1";
        end if;
      end if;

      if audio_div_128 then
        if (alto_sg_cnt = "0000000") then
          alto_sg_cnt <= alto_sg_freq(6 downto 0) - "1";
          alto_sg <= not alto_sg;
        else
          alto_sg_cnt <= alto_sg_cnt - "1";
        end if;
      end if;

      if audio_div_64 then
        if (soprano_sg_cnt = "0000000") then
          soprano_sg_cnt <= soprano_sg_freq(6 downto 0) - "1";
          soprano_sg <= not soprano_sg;
        else
          soprano_sg_cnt <= soprano_sg_cnt - "1";
        end if;
      end if;

      -- noise gen
      noise_zero := '0';
      if (noise_gen = "0000000000000000000") then
        noise_zero := '1';
      end if;

      if audio_div_16 then
        if (noise_sg_cnt = "0000000") then
          noise_sg_cnt <= noise_sg_freq(6 downto 0) - "1";

          noise_gen(18 downto 2) <= noise_gen(17 downto 1);
          noise_gen(1)           <= noise_gen(0) xor noise_zero;
          noise_gen(0)           <= noise_gen(0) xor noise_gen(1) xor
                                    noise_gen(4) xor noise_gen(18);

          noise_sg <= noise_gen(9);
        else
          noise_sg_cnt <= noise_sg_cnt - "1";
        end if;
      end if;

      -- 'mixer'
      wav := (r_base_sound(7)    and base_sg   ) or
             (r_alto_sound(7)    and alto_sg   ) or
             (r_soprano_sound(7) and soprano_sg) or
             (r_noise_sound(7)   and noise_sg  );

      O_AUDIO(3 downto 0) <= "0000";
      if (wav = '1') then
        O_AUDIO(3 downto 0) <= r_amplitude;
      end if;
    end if;
  end process;

end architecture RTL;
