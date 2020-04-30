-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_clk_gen.vhd,v 1.8 2006/06/18 10:47:01 arnim Exp $
--
-- Clock Generator
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

library ieee;
use ieee.std_logic_1164.all;

entity vdp18_clk_gen is

  port (
    clk_i         : in  std_logic;
    clk_en_10m7_i : in  std_logic;
    reset_i       : in  boolean;
    clk_en_5m37_o : out boolean;
    clk_en_3m58_o : out boolean;
    clk_en_2m68_o : out boolean
  );

end vdp18_clk_gen;


library ieee;
use ieee.numeric_std.all;

architecture rtl of vdp18_clk_gen is

  signal cnt_q         : unsigned(3 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --   Implements the sequential elements.
  --   * clock counter
  --
  seq: process (clk_i, reset_i)
    variable cnt_v : integer range -256 to 255;
  begin
    if reset_i then
      cnt_q     <= (others => '0');

    elsif clk_i'event and clk_i = '1' then
      if clk_en_10m7_i = '1' then
        if cnt_q = 11 then
          -- wrap after counting 12 clocks
          cnt_q <= (others => '0');
        else
          cnt_q <= cnt_q + 1;
        end if;
      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process clk_en
  --
  -- Purpose:
  --   Generates the derived clock enable signals.
  --
  clk_en: process (clk_en_10m7_i,
                   cnt_q)
    variable cnt_v : integer range -256 to 255;
  begin
    cnt_v := to_integer(cnt_q);

    -- 5.37 MHz clock enable --------------------------------------------------
    if clk_en_10m7_i = '1' then
      case cnt_v is
        when 1 | 3 | 5 | 7 | 9 | 11 =>
          clk_en_5m37_o <= true;
        when others =>
          clk_en_5m37_o <= false;
      end case;
    else
      clk_en_5m37_o     <= false;
    end if;

    -- 3.58 MHz clock enable --------------------------------------------------
    if clk_en_10m7_i = '1' then
      case cnt_v is
        when 2 | 5 | 8 | 11 =>
          clk_en_3m58_o <= true;
        when others =>
          clk_en_3m58_o <= false;
      end case;
    else
      clk_en_3m58_o     <= false;
    end if;

    -- 2.68 MHz clock enable --------------------------------------------------
    if clk_en_10m7_i = '1' then
      case cnt_v is
        when 3 | 7 | 11 =>
          clk_en_2m68_o <= true;
        when others =>
          clk_en_2m68_o <= false;
      end case;
    else
      clk_en_2m68_o     <= false;
    end if;

  end process clk_en;
  --
  -----------------------------------------------------------------------------

end rtl;
