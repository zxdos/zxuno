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
-- version 001 initial release

use std.textio.ALL;
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;


entity VIC20_TB is
end;

architecture Sim of VIC20_TB is

  signal clk_50         : std_logic;
  signal reset_h        : std_logic;

  signal ps2_clk        : std_logic;
  signal ps2_data       : std_logic;
  signal o_video_r      : std_logic_vector(3 downto 0);
  signal o_video_g      : std_logic_vector(3 downto 0);
  signal o_video_b      : std_logic_vector(3 downto 0);
  signal o_hsync        : std_logic;
  signal o_vsync        : std_logic;
  signal o_tmds         : std_logic_vector(3 downto 0);
  signal o_tmdsb        : std_logic_vector(3 downto 0);
  
--  signal flash_addr     : std_logic_vector(23 downto 0);
--  signal flash_data     : std_logic_vector( 7 downto 0);
--  signal flash_data_int : std_logic_vector( 7 downto 0);
--  signal flash_ce_l     : std_logic;
--  signal flash_oe_l     : std_logic;

  constant CLKPERIOD_50 : time := 20 ns;

  procedure PS2Byte(Byte : in std_logic_vector(7 downto 0);
                  signal Clk : out std_logic;
                  signal Data : out std_logic) is
  begin
      for i in 0 to 10 loop
          if i = 0 then
              Data <= '0';
          elsif i = 9 then
              Data <= not Byte(0) xor
                          Byte(1) xor
                          Byte(2) xor
                          Byte(3) xor
                          Byte(4) xor
                          Byte(5) xor
                          Byte(6) xor
                          Byte(7);
          elsif i = 10 then
              Data <= '1';
          else
              Data <= Byte(i - 1);
          end if;
          wait for 20 us;
          Clk <= '0';
          wait for 20 us;
          Clk <= '1';
      end loop;
  end;

begin
  u0 : entity work.VIC20
    port map (
--      O_STRATAFLASH_ADDR    => flash_addr,
--      B_STRATAFLASH_DATA    => flash_data,
--      O_STRATAFLASH_CE_L    => flash_ce_l,
--      O_STRATAFLASH_OE_L    => flash_oe_l,
--      O_STRATAFLASH_WE_L    => open,
--      O_STRATAFLASH_BYTE    => open,
--      -- disable other onboard devices
--      O_LCD_RW              => open,
--      O_LCD_E               => open,
--      O_SPI_ROM_CS          => open,
--      O_SPI_ADC_CONV        => open,
--      O_SPI_DAC_CS          => open,
--      O_PLATFORMFLASH_OE    => open,
      --
      I_PS2_CLK             => ps2_clk,
      I_PS2_DATA            => ps2_data,
      --
      O_VIDEO_R             => o_video_r,
      O_VIDEO_G             => o_video_g,
      O_VIDEO_B             => o_video_b,
      O_HSYNC               => o_hsync,
      O_VSYNC               => o_vsync,
      --
	   TMDS                  => o_tmds,
	   TMDSB                 => o_tmdsb,
	   --
      O_AUDIO_L             => open,
      O_AUDIO_R             => open,
      --
      I_RESET               => reset_h,
      I_CLK_REF             => clk_50
      );

  p_clk_50  : process
  begin
    CLK_50 <= '0';
    wait for CLKPERIOD_50 / 2;
    CLK_50 <= '1';
    wait for CLKPERIOD_50 - (CLKPERIOD_50 / 2);
  end process;

  p_rst : process
  begin
    reset_h <= '1';
    wait for 100 ns;
    reset_h <= '0';
    wait;
  end process;
  -- if you have a cart ....

  --u1 : entity work.cart
    --port map (
      --ADDR => flash_addr(12 downto 0),
      --DATA => flash_data_int
      --);
--  flash_data_int <= (others => 'H');
--
--  p_flash_oe : process(flash_oe_l, flash_ce_l, flash_data_int)
--  begin
--    flash_data <= transport (others => 'Z') after 75 ns;
--    if (flash_oe_l = '0') and (flash_ce_l = '0') then
--      flash_data <= transport flash_data_int after 75 ns;
--    end if;
--  end process;


  ps2_clk   <= 'H';
  ps2_data  <= 'H';

  p_keyboard : process
  begin
      wait for 20 ms;
      PS2Byte(x"05", ps2_clk, ps2_data); -- F1
      wait;
  end process;

end Sim;

