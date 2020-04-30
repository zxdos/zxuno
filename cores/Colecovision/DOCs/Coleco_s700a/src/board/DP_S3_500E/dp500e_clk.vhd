-------------------------------------------------------------------------------
--
-- Clock generator for Zefant-XS3 board.
--
-- $Id: zefant-xs3_clk.vhd,v 1.3 2006/06/13 20:18:33 arnim Exp $
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
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
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------
-- Generate clock   85.7 Mhz
-- 50Mhz * 12 /7

library ieee;
use ieee.std_logic_1164.all;

entity cv_clk is

  port (
    clkin_i    : in  std_logic;
    locked_o   : out std_logic;
    clk_21m3_o : out std_logic
  );

end cv_clk;


library unisim;
use unisim.vcomponents.all;

architecture struct of cv_clk is

  signal clkin_ibuf_s : std_logic;
  signal clkfx_s,
         clk_85m4_s   : std_logic;
  signal clk_42m7_q   : std_logic;
  signal clk_21m3_q   : std_logic;
  signal locked_s     : std_logic;
  signal gnd_s        : std_logic;

begin

  gnd_s <= '0';

  dcm_b : dcm
    generic map (
      CLKIN_PERIOD   => 20.0,
      CLKFX_MULTIPLY => 12,
      CLKFX_DIVIDE   => 7,
      CLK_FEEDBACK   => "None"
    )
    port map (
      CLKIN          => clkin_ibuf_s,
      CLKFB          => gnd_s,
      RST            => gnd_s,
      PSEN           => gnd_s,
      PSINCDEC       => gnd_s,
      PSCLK          => gnd_s,
      CLK0           => open,
      CLK90          => open,
      CLK180         => open,
      CLK270         => open,
      CLK2X          => open,
      CLK2X180       => open,
      CLKDV          => open,
      CLKFX          => clkfx_s,
      CLKFX180       => open,
      STATUS         => open,
      LOCKED         => locked_s,
      PSDONE         => open
    );
  locked_o <= locked_s;

  clkin_ibuf_b : IBUFG
    port map (
      I => clkin_i,
      O => clkin_ibuf_s
    );

  clkfx_bufg_b : BUFG
    port map (
      I => clkfx_s,
      O => clk_85m4_s
    );

  -----------------------------------------------------------------------------
  -- Process clk_div
  --
  -- Purpose:
  --   Divides the 85.32 MHz clock by 4 to generate the main 21.33 MHz clock.
  --
  clk_div: process (clk_85m4_s, locked_s)
  begin
    if locked_s = '0' then
      clk_42m7_q <= '0';
      clk_21m3_q <= '0';
    elsif clk_85m4_s'event and clk_85m4_s = '1' then
      clk_42m7_q <= not clk_42m7_q;
      if clk_42m7_q = '1' then
        clk_21m3_q <= not clk_21m3_q;
      end if;
    end if;
  end process clk_div;
  --
  -----------------------------------------------------------------------------

  clk21m3_bufg_b : BUFG
    port map (
      I => clk_21m3_q,
      O => clk_21m3_o
    );

end struct;
