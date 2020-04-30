-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: cv_clock.vhd,v 1.3 2006/01/05 22:22:29 arnim Exp $
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
use ieee.numeric_std.all;

entity cv_clock is

  port (
    clk_i         : in  std_logic;
    clk_en_10m7_i : in  std_logic;
    reset_n_i     : in  std_logic;
    clk_en_3m58_o : out std_logic
  );

end cv_clock;


architecture rtl of cv_clock is

  signal clk_cnt_q : unsigned(1 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Process clk_cnt
  --
  -- Purpose:
  --   Implements the counter which is used to generate the clock enable
  --   for the 3.58 MHz clock.
  --
  clk_cnt: process (clk_i, reset_n_i)
  begin
    if reset_n_i = '0' then
      clk_cnt_q     <= (others => '0');

    elsif clk_i'event and clk_i = '1' then
      if clk_en_10m7_i = '1' then
        if clk_cnt_q = 0 then
          clk_cnt_q <= "10";
        else
          clk_cnt_q <= clk_cnt_q - 1;
        end if;
      end if;
    end if;
  end process clk_cnt;
  --
  -----------------------------------------------------------------------------

  clk_en_3m58_o <=   clk_en_10m7_i
                   when clk_cnt_q = 0 else
                     '0';
end rtl;
