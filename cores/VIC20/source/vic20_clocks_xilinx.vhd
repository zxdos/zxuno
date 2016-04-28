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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity VIC20_CLOCKS is
  port (
    I_CLK_REF         : in    std_logic;
    I_RESET_L         : in    std_logic;
    --
    O_CLK_REF         : out   std_logic;
    --
    O_ENA             : out   std_logic;
    O_CLK             : out   std_logic;
    O_RESET_L         : out   std_logic
    );
end;

architecture RTL of VIC20_CLOCKS is

  signal reset_dcm_h            : std_logic;
  signal clk_ref_ibuf           : std_logic;
  signal clk_dcm_op_0           : std_logic;
  signal clk_dcm_op_fx          : std_logic;
  signal clk_dcm_0_bufg         : std_logic;
  signal clk                    : std_logic;
  signal dcm_locked             : std_logic;
  signal delay_count            : std_logic_vector(7 downto 0) := (others => '0');
  signal div_cnt                : std_logic_vector(1 downto 0);

begin
  -- ref clk is 50MHz
  reset_dcm_h <= not I_RESET_L;
  --IBUFG0 : IBUFG port map (I=> I_CLK_REF, O => clk_ref_ibuf);

	dcm_inst : DCM_SP
	generic map (
		DLL_FREQUENCY_MODE    => "LOW",
		DUTY_CYCLE_CORRECTION => TRUE,
		CLKOUT_PHASE_SHIFT    => "NONE",
		PHASE_SHIFT           => 0,
		CLKFX_MULTIPLY        => 4,
		CLKFX_DIVIDE          => 23, --23
		CLKDV_DIVIDE          => 2.0,
		STARTUP_WAIT          => FALSE,
		CLKIN_PERIOD          => 20.0
	)
	port map (
		CLKIN    => I_CLK_REF,
		CLKFB    => clk_dcm_0_bufg,
		DSSEN    => '0',
		PSINCDEC => '0',
		PSEN     => '0',
		PSCLK    => '0',
		RST      => reset_dcm_h,
		CLK0     => clk_dcm_op_0,
		CLK90    => open,
		CLK180   => open,
		CLK270   => open,
		CLK2X    => open,
		CLK2X180 => open,
		CLKDV    => open,
		CLKFX    => clk_dcm_op_fx,
		CLKFX180 => open,
		LOCKED   => dcm_locked,
		PSDONE   => open
	);

  BUFG0 : BUFG port map (I=> clk_dcm_op_0,  O => clk_dcm_0_bufg);
  BUFG1 : BUFG port map (I=> clk_dcm_op_fx, O => clk);

  O_CLK     <= clk;
  O_CLK_REF <= clk_dcm_0_bufg;

  p_delay : process(I_RESET_L, clk)
  begin
    if (I_RESET_L = '0') then
      delay_count <= x"00"; -- longer delay for cpu
      O_RESET_L <= '0';
    elsif rising_edge(clk) then
      if (delay_count(7 downto 0) = (x"FF")) then
        delay_count <= (x"FF");
        O_RESET_L <= '1';
      else
        delay_count <= delay_count + "1";
        O_RESET_L <= '0';
      end if;
    end if;
  end process;

  p_clk_div : process(I_RESET_L, clk)
  begin
    if (I_RESET_L = '0') then
      div_cnt <= (others => '0');
    elsif rising_edge(clk) then
      div_cnt <= div_cnt + "1";
    end if;
  end process;

  p_assign_ena : process(div_cnt)
  begin
    O_ENA    <= div_cnt(0);
  end process;
end RTL;
