-- Mod by Quest 2016
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
-- version 001 initial release

-- ps2 interface returns keyboard press/release scan codes
-- these are mapped into a small ram which is harassed by the
-- VIA chip in the same way as the original keyboard.
--
-- Restore key mapped to PgUp
--
-- all cursor keys are directly mapped
--
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity VIC20_PS2_IF is
  port (
    I_PS2_CLK       : in    std_logic;
    I_PS2_DATA      : in    std_logic;

    I_COL           : in    std_logic_vector(7 downto 0);
    O_ROW           : out   std_logic_vector(7 downto 0);
    O_RESTORE       : out   std_logic;

    I_ENA_1MHZ      : in    std_logic;
    I_P2_H          : in    std_logic; -- high for phase 2 clock  ____----__
    RESET_L         : in    std_logic;
    ENA_4           : in    std_logic; -- 4x system clock (4HZ)   _-_-_-_-_-
    CLK             : in    std_logic;
	 scanSW	:	out	std_logic_vector(6 downto 0) 
    );
end;

architecture RTL of VIC20_PS2_IF is

  component ps2kbd
      port(
          Rst_n     : in  std_logic;
          Clk       : in  std_logic;
          Ena       : in  std_logic;
          Tick1us   : in  std_logic;
          PS2_Clk   : in  std_logic;
          PS2_Data  : in  std_logic;
          Press     : out std_logic;
          Release   : out std_logic;
          Reset     : out std_logic;
          ScanE0    : out std_logic;
          ScanCode  : out std_logic_vector(7 downto 0));
  end component;

  signal tick_1us       : std_logic;
  signal kbd_press      : std_logic;
  signal kbd_release    : std_logic;
  signal kbd_reset      : std_logic;
  signal kbd_press_s    : std_logic;
  signal kbd_release_s  : std_logic;
  signal kbd_scancode   : std_logic_vector(7 downto 0);
  signal kbd_scanE0     : std_logic;

  signal left_cursor    : std_logic;
  signal up_cursor      : std_logic;

  signal via_col_addr   : std_logic_vector(3 downto 0);
  signal rowcol         : std_logic_vector(7 downto 0);
  signal row_mask       : std_logic_vector(7 downto 0);

  signal ram_w_addr     : std_logic_vector(3 downto 0);
  signal ram_r_addr     : std_logic_vector(3 downto 0);
  signal ram_we         : std_ulogic;
  signal ram_din        : std_logic_vector(7 downto 0);
  signal ram_dout       : std_logic_vector(7 downto 0);

  signal reset_cnt      : std_logic_vector(4 downto 0);

  signal tag            : std_logic_vector(7 downto 0);
  
  signal VIDEO: std_logic := '0';
--  signal SCANL: std_logic := '0';
  signal CTRL	: std_logic;
  signal ALT	: std_logic;
  signal EXP8K	: std_logic;
  -- non-xilinx ram
  --type slv_array8 is array (natural range <>) of std_logic_vector(7 downto 0);
  --shared variable  ram  : slv_array8(7 downto 0) := (others => (others => '0'));

begin

 -- VIC-20 / C64 Standard:
 --
 -- |  <-  1!  2"  3#  4$  5%  6&  7'  8(  9)  0   +   -  GBP HOME DEL |  | F1 |
 -- | CTRL   q   w   e   r   t   y   u   i   o   p   @   *  ^~ RESTORE |  | F3 |
 --| RUN LOCK a   s   d   f   g   h   j   k   l   :[  ;]  =   RETURN  |   | F5 |
 --| C=  SHIFT  z   x   c   v   b   n   m   ,<  .>  /?  SHIFT DWN RGT |   | F7 |
 ---------------|_______________SPACE_______________|------------------


  tick_1us <= I_ENA_1MHZ;

  -- Keyboard decoder
  u_kbd : ps2kbd
        port map(
            Rst_n    => RESET_L,
            Clk      => CLK,
            Ena      => ENA_4,
            Tick1us  => tick_1us,
            PS2_Clk  => I_PS2_CLK,
            PS2_Data => I_PS2_DATA,
            Press    => kbd_press,
            Release  => kbd_release,
            Reset    => kbd_reset,
            ScanE0   => kbd_scanE0,
            ScanCode => kbd_scancode
            );

  p_decode_scancode : process
  begin
    -- hopefully the tools will build a rom for this
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      -- rowcol is valid for lots of clocks, but kbd_press_t1 / release are single
      -- clock strobes. must sync these to p2_h
      if (kbd_press = '1') then
        kbd_press_s <= '1';
      elsif (I_P2_H = '0') then
        kbd_press_s <= '0';
      end if;

      if (kbd_release = '1') then
        kbd_release_s <= '1';
      elsif (I_P2_H = '0') then
        kbd_release_s <= '0';
      end if;

      -- top bit low for keypress
      if (kbd_scanE0 = '0') then
        rowcol <= x"ff";
        case kbd_scancode is
          --                     row/col       vic             ps2
          when x"16" => rowcol <= x"00";--      1               1
          when x"0E" => rowcol <= x"01";--      left_arr        `
          when x"0D" => rowcol <= x"02";--      control         tab
          when x"76" => rowcol <= x"03";--      runstop         esc
          when x"29" => rowcol <= x"04";--      space           space
          when x"14" => rowcol <= x"05";--      cbm             left_ctrl
          when x"15" => rowcol <= x"06";--      q               q
          when x"1E" => rowcol <= x"07";--      2               2
          when x"26" => rowcol <= x"10";--      3               3
          when x"1D" => rowcol <= x"11";--      w               w
          when x"1C" => rowcol <= x"12";--      a               a
          when x"12" => rowcol <= x"13";--      left_shift      left_shift
          when x"1A" => rowcol <= x"14";--      z               z
          when x"1B" => rowcol <= x"15";--      s               s
          when x"24" => rowcol <= x"16";--      e               e
          when x"25" => rowcol <= x"17";--      4               4
          when x"2E" => rowcol <= x"20";--      5               5
          when x"2D" => rowcol <= x"21";--      r               r
          when x"23" => rowcol <= x"22";--      d               d
          when x"22" => rowcol <= x"23";--      x               x
          when x"21" => rowcol <= x"24";--      c               c
          when x"2B" => rowcol <= x"25";--      f               f
          when x"2C" => rowcol <= x"26";--      t               t
          when x"36" => rowcol <= x"27";--      6               6
          when x"3D" => rowcol <= x"30";--      7               7
          when x"35" => rowcol <= x"31";--      y               y
          when x"34" => rowcol <= x"32";--      g               g
          when x"2A" => rowcol <= x"33";--      v               v
          when x"32" => rowcol <= x"34";--      b               b
          when x"33" => rowcol <= x"35";--      h               h
          when x"3C" => rowcol <= x"36";--      u               u
          when x"3E" => rowcol <= x"37";--      8               8
          when x"46" => rowcol <= x"40";--      9               9
          when x"43" => rowcol <= x"41";--      i               i
          when x"3B" => rowcol <= x"42";--      j               j
          when x"31" => rowcol <= x"43";--      n               n
          when x"3A" => rowcol <= x"44";--      m               m
          when x"42" => rowcol <= x"45";--      k               k
          when x"44" => rowcol <= x"46";--      o               o
          when x"45" => rowcol <= x"47";--      0               0
          when x"4E" => rowcol <= x"50";--      +               -
          when x"4D" => rowcol <= x"51";--      p               p
          when x"4B" => rowcol <= x"52";--      l               l
          when x"41" => rowcol <= x"53";--      ,               ,
          when x"49" => rowcol <= x"54";--      .               .
          when x"4C" => rowcol <= x"55";--      :               ;
          when x"54" => rowcol <= x"56";--      @               [
          when x"55" => rowcol <= x"57";--      -               =
          when x"5B" => rowcol <= x"61";--      *               ]
          when x"52" => rowcol <= x"62";--      ;               '
          when x"4A" => rowcol <= x"63";--      /               /
          when x"59" => rowcol <= x"64";--      right_shift     right_shift
          when x"5D" => rowcol <= x"65";--      =               \   (#)
          when x"66" => rowcol <= x"70";--      del             backspace
          when x"5A" => rowcol <= x"71";--      return          return
          when x"05" => rowcol <= x"74";--      f1              f1
          when x"04" => rowcol <= x"75";--      f3              f3
          when x"03" => rowcol <= x"76";--      f5              f5
          when x"83" => rowcol <= x"77";--      f7              f7									
 		 		 
          when others => rowcol <= x"FF";
        end case;
      else
        rowcol <= x"ff";
        case kbd_scancode is
          when x"70" => rowcol <= x"60";--      gbp             insert
          when x"71" => rowcol <= x"66";--      up_arr          del
          when x"6C" => rowcol <= x"67";--      home            home
          when x"74" => rowcol <= x"72";--      right           right_cursor
          when x"72" => rowcol <= x"73";--      down            down_cursor
          when x"6B" => rowcol <= x"72";--      cbm right       left_cursor
          when x"75" => rowcol <= x"73";--      cbm down        up_cursor
			 
          when others => rowcol <= x"FF";
        end case;
      end if;
    end if;
  end process;

  p_direct_key_maps : process(RESET_L, CLK)
  begin
    if (RESET_L = '0') then
      O_RESTORE <= '1';
      left_cursor <= '0';
      up_cursor   <= '0';
    elsif rising_edge(CLK) then
      if (ENA_4 = '1') then
        if (kbd_reset = '1') then

          O_RESTORE <= '1';
          left_cursor <= '0';
          up_cursor   <= '0';

        elsif (kbd_press = '1') or (kbd_release = '1') then
          if (kbd_scanE0 = '1') then
            if (kbd_scancode = x"7D") then        -- page up
              O_RESTORE <= not kbd_press;
            end if;

            if (kbd_scancode =  x"6B") then       -- left_cursor
              left_cursor <= kbd_press;
            end if;

            if (kbd_scancode =  x"75") then       -- up_cursor
              up_cursor <= kbd_press;
            end if;			
			 else --q E0

			   if (kbd_scancode =  x"01") then       -- F9, rom/game cart1 active
					scanSW(4 downto 1) <= kbd_press & "001"; --enable cart1, disable others reset
				end if;
				
			   if (kbd_scancode =  x"09") then       -- F10, rom/game cart2 active
					scanSW(4 downto 1) <= kbd_press & "010"; --enable cart2, disable others reset
            end if;	
				
			   if (kbd_scancode =  x"78") then       -- F11, rom/game cart3 active
					scanSW(4 downto 1) <= kbd_press & "100"; --enable cart3, disable others and reset
            end if;					
				
				if (kbd_scancode =  x"07") then       -- F12 cold reset
					scanSW(5 downto 1) <= '0' & kbd_press & "000"; --disable carts and reset to basic (EXPANDED 16k)						
				end if;
				
				if (kbd_scancode =  x"77") then       -- bloq num cold reset
					scanSW(5 downto 1) <= '1' & kbd_press & "000"; --disable carts and reset to unexpanded VIC20						
            end if;				
				
			   if (kbd_scancode =  x"7E") then       -- Sroll Lock VGA/RGB
							if (VIDEO = '0' and kbd_press = '0') then
								scanSW(0) <= '1';
								VIDEO <= '1';
							elsif (VIDEO = '1' and kbd_press = '0') then
								scanSW(0) <= '0';
								VIDEO <= '0';
							end if;	
            end if;	

			   if (kbd_scancode =  x"11") then --ALT
					ALT <= kbd_press;
				end if;
				
			   if (kbd_scancode =  x"14") then --CTRL
					CTRL <= kbd_press;
				end if;
				
			   if (kbd_scancode =  x"66" and ALT = '1' and CTRL = '1') then --Master reset
					scanSW(6) <= kbd_press;
				end if;				
			 
          end if;
        end if;
      end if;
    end if;
  end process;

  p_expand_row : process(rowcol)
  begin
    row_mask <= x"01";
    case rowcol(6 downto 4) is
      when "000" => row_mask <= x"01";
      when "001" => row_mask <= x"02";
      when "010" => row_mask <= x"04";
      when "011" => row_mask <= x"08";
      when "100" => row_mask <= x"10";
      when "101" => row_mask <= x"20";
      when "110" => row_mask <= x"40";
      when "111" => row_mask <= x"80";
      when others => null;
    end case;
  end process;

  p_reset_cnt : process(RESET_L, CLK)
  begin
    if (RESET_L = '0') then
      reset_cnt <= "10000";
    elsif rising_edge(CLK) then
    -- counter used to reset ram
      if (ENA_4 = '1') then
        if (kbd_reset = '1') then
          reset_cnt <= "10000";
        elsif (reset_cnt(4) = '1') then
          reset_cnt <= reset_cnt + "1";
        end if;
      end if;
    end if;
  end process;

  p_keybd_write : process(kbd_press_s, kbd_release_s, rowcol,
                          kbd_reset, reset_cnt, ram_dout, row_mask, I_P2_H, ENA_4)
    variable we : boolean;
  begin
    -- valid key ?
    we := ((kbd_press_s = '1') or (kbd_release_s = '1')) and (rowcol(7) = '0');

    if (reset_cnt(4) = '1') then
      ram_w_addr <= reset_cnt(3 downto 0);
      ram_din    <= x"00";
      ram_we     <= '1';
    else
      ram_w_addr <= rowcol(3 downto 0);

      if (kbd_press_s = '1') then
        ram_din  <= ram_dout or      row_mask; -- pressed
      else
        ram_din  <= ram_dout and not row_mask; -- released
      end if;

      ram_we <= '0';
      if we and (I_P2_H = '0') and (ENA_4 = '1') then
        ram_we <= '1';
      end if;
    end if;

  end process;

  keybd_ram : for i in 0 to 7 generate
  begin
    inst: RAM16X1D
      port map (
        a0    => ram_w_addr(0),
        a1    => ram_w_addr(1),
        a2    => ram_w_addr(2),
        a3    => ram_w_addr(3),
        dpra0 => ram_r_addr(0),
        dpra1 => ram_r_addr(1),
        dpra2 => ram_r_addr(2),
        dpra3 => ram_r_addr(3),
        wclk  => CLK,
        we    => ram_we,
        d     => ram_din(i),
        dpo   => ram_dout(i)
        );
  end generate;

  -- NON XILINX RAM
  --p_ram_w : process
    --variable ram_addr : integer := 0;
  --begin
    --wait until rising_edge(CLK_4);
    --if (ram_we = '1') then
      --ram_addr := to_integer(unsigned(ram_w_addr(2 downto 0)));
      --ram(ram_addr) := ram_din;
    --end if;
  --end process;

  --p_ram_r : process(CLK_4,ram_r_addr)
    --variable ram_addr : integer := 0;
  --begin
    --ram_addr := to_integer(unsigned(ram_r_addr(2 downto 0)));
    --ram_dout <= ram(ram_addr);
  --end process;
  -- END OF NON XILINX RAM

  p_tag : process(RESET_L, CLK)
    variable addr : integer := 0;
  begin
    if (RESET_L = '0') then
      tag <= x"00";
    elsif rising_edge(CLK) then
      if (ram_we = '1') then -- ram_we already has the ena_4 gate
        addr := to_integer(unsigned(ram_w_addr(2 downto 0)));
        if (ram_din = x"00") then -- no keys pressed
          tag(addr) <= '0';
        else
          tag(addr) <= '1';
        end if;
      end if;
    end if;
  end process;

  -- the via can access the ram when p2_h = '1'
  p_ram_read_mux : process(I_P2_H, via_col_addr, rowcol)
  begin
    if (I_P2_H = '1') then
      ram_r_addr <= via_col_addr;
    else
      ram_r_addr <= rowcol(3 downto 0); -- write r/m/w
    end if;
  end process;

  p_via_out_reg : process
    variable force_cbm_key : std_logic;
  begin
    wait until rising_edge(CLK);
    if (ENA_4 = '1') then
      force_cbm_key := up_cursor or left_cursor;
      if (I_P2_H = '1') then
        if (I_COL = x"00") then -- any pressed?
          if (tag = x"00") then
            O_ROW <= x"FF"; -- none
          else
            O_ROW <= x"00"; -- all pressed !
          end if;
        elsif (via_col_addr(2 downto 0) = "101") then -- col 5
          O_ROW <= not (ram_dout or ("0000000" & force_cbm_key));
        else
          O_ROW <= not ram_dout; -- keyboard switches are active low
        end if;
      end if;
    end if;
  end process;

  -- VIA interface
  p_via_col : process(I_COL)
  begin
    via_col_addr <= x"F";
    case I_COL is
      when x"FE" => via_col_addr <= x"0";
      when x"FD" => via_col_addr <= x"1";
      when x"FB" => via_col_addr <= x"2";
      when x"F7" => via_col_addr <= x"3";
      when x"EF" => via_col_addr <= x"4";
      when x"DF" => via_col_addr <= x"5";
      when x"BF" => via_col_addr <= x"6";
      when x"7F" => via_col_addr <= x"7";
      when others => null;
    end case;
  end process;

end architecture RTL;
