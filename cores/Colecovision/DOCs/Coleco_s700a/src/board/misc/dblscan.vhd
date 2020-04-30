--
-- Adapted for FPGA Colecovision by A. Laeuger, 26-Feb-2006
--
-- Based on
--
-- A simulation model of Pacman hardware
-- VHDL conversion by MikeJ - October 2002
--
-- FPGA PACMAN video scan doubler
--
-- based on a design by Tatsuyuki Satoh
--
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
-- Email pacman@fpgaarcade.com
--
-- Revision list
--
-- version 002 initial release
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity DBLSCAN is
  port (
    COL_IN        : in  std_logic_vector(3 downto 0);

    HSYNC_IN      : in  std_logic;
    VSYNC_IN      : in  std_logic;

    COL_OUT       : out std_logic_vector(3 downto 0);

    HSYNC_OUT     : out std_logic;
    VSYNC_OUT     : out std_logic;
    BLANK_OUT     : out std_logic;
    --  NOTE CLOCKS MUST BE PHASE LOCKED !!
    CLK_6         : in  std_logic; -- input pixel clock (6MHz)
    CLK_EN_6M     : in  std_logic;
    CLK_12        : in  std_logic; -- output clock      (12MHz)
    CLK_EN_12M    : in  std_logic
  );
end;

architecture RTL of DBLSCAN is

  component dpram
    generic (
      addr_width_g : integer := 8;
      data_width_g : integer := 8
    );
    port (
      clk_a_i  : in  std_logic;
      we_i     : in  std_logic;
      addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
      data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
      data_a_o : out std_logic_vector(data_width_g-1 downto 0);
      clk_b_i  : in  std_logic;
      addr_b_i : in  std_logic_vector(addr_width_g-1 downto 0);
      data_b_o : out std_logic_vector(data_width_g-1 downto 0)
    );
  end component;

  --
  -- input timing
  --
  signal hsync_in_t1 : std_logic;
  signal vsync_in_t1 : std_logic;
  signal hpos_i : std_logic_vector(8 downto 0) := (others => '0');    -- input capture postion
  signal ibank : std_logic;
  signal we_a : std_logic;
  signal we_b : std_logic;
  signal rgb_in  : std_logic_vector(3 downto 0);
  --
  -- output timing
  --
  signal hpos_o : std_logic_vector(8 downto 0) := (others => '0');
  signal ohs : std_logic;
  signal ohs_t1 : std_logic;
  signal ovs : std_logic;
  signal ovs_t1 : std_logic;
  signal obank : std_logic;
  signal obank_t1 : std_logic;
  --
  signal vs_cnt : std_logic_vector(2 downto 0);
  signal rgb_out_a : std_logic_vector(3 downto 0);
  signal rgb_out_b : std_logic_vector(3 downto 0);
begin

  p_input_timing : process
    variable rising_h : boolean;
    variable rising_v : boolean;
  begin
    wait until rising_edge (CLK_6);
    if CLK_EN_6M = '1' then
      hsync_in_t1 <= HSYNC_IN;
      vsync_in_t1 <= VSYNC_IN;

      rising_h := (HSYNC_IN = '1') and (hsync_in_t1 = '0');
      rising_v := (VSYNC_IN = '1') and (vsync_in_t1 = '0');

      if rising_v then
        ibank <= '0';
      elsif rising_h then
        ibank <= not ibank;
      end if;

      if rising_h then
        hpos_i <= (others => '0');
      else
        hpos_i <= hpos_i + "1";
      end if;
    end if;

  end process;

  we_a <=     ibank and CLK_EN_6M;
  we_b <= not ibank and CLK_EN_6M;
  rgb_in <= COL_IN;

  u_ram_a : dpram
    generic map (
      addr_width_g => 9,
      data_width_g => 4
    )
    port map (
      clk_a_i  => CLK_6,
      we_i     => we_a,
      addr_a_i => hpos_i,
      data_a_i => rgb_in,
      data_a_o => open,
      clk_b_i  => CLK_12,
      addr_b_i => hpos_o,
      data_b_o => rgb_out_a
    );
  u_ram_b : dpram
    generic map (
      addr_width_g => 9,
      data_width_g => 4
    )
    port map (
      clk_a_i  => CLK_6,
      we_i     => we_b,
      addr_a_i => hpos_i,
      data_a_i => rgb_in,
      data_a_o => open,
      clk_b_i  => CLK_12,
      addr_b_i => hpos_o,
      data_b_o => rgb_out_b
    );


  p_output_timing : process
    variable rising_h : boolean;
  begin
    wait until rising_edge (CLK_12);
    if CLK_EN_12M = '1' then
      rising_h := ((ohs = '1') and (ohs_t1 = '0'));

      if rising_h or (hpos_o = "101010101") then
        hpos_o <= (others => '0');
      else
        hpos_o <= hpos_o + "1";
      end if;

      if (ovs = '1') and (ovs_t1 = '0') then -- rising_v
        obank <= '0';
        vs_cnt <= "000";
      elsif rising_h then
        obank <= not obank;
        if (vs_cnt(2) = '0') then
          vs_cnt <= vs_cnt + "1";
        end if;
      end if;

      ohs <= HSYNC_IN; -- reg on clk_12
      ohs_t1 <= ohs;

      ovs <= VSYNC_IN; -- reg on clk_12
      ovs_t1 <= ovs;
    end if;
  end process;

  p_op : process
  begin
    wait until rising_edge (CLK_12);
    if CLK_EN_12M = '1' then

      HSYNC_OUT <= '0';
      if (hpos_o < 8) then
        HSYNC_OUT <= '1';
      end if;

      BLANK_OUT <= '0';
      if hpos_o < 56 or hpos_o > 295 then
        BLANK_OUT <= '1';
      end if;

      obank_t1 <= obank;
      if (obank_t1 = '1') then
        COL_OUT <= rgb_out_b;
      else
        COL_OUT <= rgb_out_a;
      end if;

      VSYNC_OUT <= not vs_cnt(2);
    end if;
  end process;

end architecture RTL;
