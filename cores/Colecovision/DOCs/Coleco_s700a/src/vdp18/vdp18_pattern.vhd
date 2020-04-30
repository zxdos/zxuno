-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_pattern.vhd,v 1.8 2006/06/18 10:47:06 arnim Exp $
--
-- Pattern Generation Controller
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

use work.vdp18_pack.opmode_t;
use work.vdp18_pack.access_t;
use work.vdp18_pack.hv_t;

entity vdp18_pattern is

  port (
    clk_i         : in  std_logic;
    clk_en_5m37_i : in  boolean;
    clk_en_acc_i  : in  boolean;
    reset_i       : in  boolean;
    opmode_i      : in  opmode_t;
    access_type_i : in  access_t;
    num_line_i    : in  hv_t;
    vram_d_i      : in  std_logic_vector(0 to 7);
    vert_inc_i    : in  boolean;
    vsync_n_i     : in  std_logic;
    reg_col1_i    : in  std_logic_vector(0 to 3);
    reg_col0_i    : in  std_logic_vector(0 to 3);
    pat_table_o   : out std_logic_vector(0 to 9);
    pat_name_o    : out std_logic_vector(0 to 7);
    pat_col_o     : out std_logic_vector(0 to 3)
  );

end vdp18_pattern;


library ieee;
use ieee.numeric_std.all;

use work.vdp18_pack.all;

architecture rtl of vdp18_pattern is

  signal pat_cnt_q    : unsigned(0 to 9);
  signal pat_name_q,
         pat_tmp_q,
         pat_shift_q,
         pat_col_q    : std_logic_vector(0 to 7);

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --  Implements the sequential elements:
  --    * pattern shift register
  --    * pattern color register
  --    * pattern counter
  --
  seq: process (clk_i, reset_i)
  begin
    if reset_i then
      pat_cnt_q   <= (others => '0');
      pat_name_q  <= (others => '0');
      pat_tmp_q   <= (others => '0');
      pat_shift_q <= (others => '0');
      pat_col_q   <= (others => '0');

    elsif clk_i'event and clk_i = '1' then
      if clk_en_5m37_i then
        -- shift pattern with every pixel clock
        pat_shift_q(0 to 6) <= pat_shift_q(1 to 7);
      end if;

      if clk_en_acc_i then
        -- determine register update based on current access type -------------
        case access_type_i is
          when AC_PNT =>
            -- store pattern name
            pat_name_q    <= vram_d_i;
            -- increment pattern counter
            pat_cnt_q     <= pat_cnt_q + 1;

          when AC_PCT =>
            -- store pattern color in temporary register
            pat_tmp_q     <= vram_d_i;

          when AC_PGT =>
            if opmode_i = OPMODE_MULTIC then
              -- set shift register to constant value
              -- this value generates 4 bits of color1
              -- followed by 4 bits of color0
              pat_shift_q <= "11110000";
              -- set pattern color from pattern generator memory
              pat_col_q   <= vram_d_i;
            else
              -- all other modes:
              -- store pattern line in shift register
              pat_shift_q <= vram_d_i;
              -- move pattern color from temporary register to color register
              pat_col_q   <= pat_tmp_q;
            end if;

          when others =>
            null;

        end case;

      end if;

      if vert_inc_i then
        -- redo patterns of if there are more lines inside this pattern
        if num_line_i(0) = '0' then
          case opmode_i is
            when OPMODE_TEXTM =>
              if num_line_i(6 to 8) /= "111" then
                pat_cnt_q <= pat_cnt_q - 40;
              end if;

            when OPMODE_GRAPH1 |
                 OPMODE_GRAPH2 |
                 OPMODE_MULTIC =>
              if num_line_i(6 to 8) /= "111" then
                pat_cnt_q <= pat_cnt_q - 32;
              end if;
          end case;
        end if;
      end if;

      if vsync_n_i = '0' then
        -- reset pattern counter at end of active display area
        pat_cnt_q <= (others => '0');
      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process col_gen
  --
  -- Purpose:
  --   Generates the color of the current pattern pixel.
  --
  col_gen: process (opmode_i,
                    pat_shift_q,
                    pat_col_q,
                    reg_col1_i,
                    reg_col0_i)
    variable pix_v : std_logic;
  begin
    -- default assignment
    pat_col_o <= "0000";
    pix_v     := pat_shift_q(0);

    case opmode_i is
      -- Text Mode ------------------------------------------------------------
      when OPMODE_TEXTM =>
        if pix_v = '1' then
          pat_col_o <= reg_col1_i;
        else
          pat_col_o <= reg_col0_i;
        end if;

      -- Graphics I, II and Multicolor Mode -----------------------------------
      when OPMODE_GRAPH1 |
           OPMODE_GRAPH2 |
           OPMODE_MULTIC   =>
        if pix_v = '1' then
          pat_col_o <= pat_col_q(0 to 3);
        else
          pat_col_o <= pat_col_q(4 to 7);
        end if;

      when others =>
        null;

    end case;
  end process col_gen;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output Mapping
  -----------------------------------------------------------------------------
  pat_table_o <= std_logic_vector(pat_cnt_q);
  pat_name_o  <= pat_name_q;

end rtl;
