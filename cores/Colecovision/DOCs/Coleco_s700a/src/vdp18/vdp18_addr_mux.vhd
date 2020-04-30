-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_addr_mux.vhd,v 1.10 2006/06/18 10:47:01 arnim Exp $
--
-- Address Multiplexer / Generator
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

use work.vdp18_pack.access_t;
use work.vdp18_pack.opmode_t;
use work.vdp18_pack.hv_t;

entity vdp18_addr_mux is

  port (
    access_type_i : in  access_t;
    opmode_i      : in  opmode_t;
    num_line_i    : in  hv_t;
    reg_ntb_i     : in  std_logic_vector(0 to  3);
    reg_ctb_i     : in  std_logic_vector(0 to  7);
    reg_pgb_i     : in  std_logic_vector(0 to  2);
    reg_satb_i    : in  std_logic_vector(0 to  6);
    reg_spgb_i    : in  std_logic_vector(0 to  2);
    reg_size1_i   : in  boolean;
    cpu_vram_a_i  : in  std_logic_vector(0 to 13);
    pat_table_i   : in  std_logic_vector(0 to  9);
    pat_name_i    : in  std_logic_vector(0 to  7);
    spr_num_i     : in  std_logic_vector(0 to  4);
    spr_line_i    : in  std_logic_vector(0 to  3);
    spr_name_i    : in  std_logic_vector(0 to  7);
    vram_a_o      : out std_logic_vector(0 to 13)
  );

end vdp18_addr_mux;


use work.vdp18_pack.all;

architecture rtl of vdp18_addr_mux is

begin

  -----------------------------------------------------------------------------
  -- Process mux
  --
  -- Purpose:
  --   Generates the VRAM address based on the current access type.
  --
  mux: process (access_type_i, opmode_i,
                num_line_i,
                reg_ntb_i, reg_ctb_i, reg_pgb_i,
                reg_satb_i, reg_spgb_i,
                reg_size1_i,
                cpu_vram_a_i,
                pat_table_i, pat_name_i,
                spr_num_i, spr_name_i,
                spr_line_i)
    variable num_line_v : std_logic_vector(num_line_i'range);
  begin
    -- default assignment
    vram_a_o   <= (others => '0');
    num_line_v := std_logic_vector(num_line_i);

    case access_type_i is
      -- CPU Access -----------------------------------------------------------
      when AC_CPU =>
        vram_a_o <= cpu_vram_a_i;

      -- Pattern Name Table Access --------------------------------------------
      when AC_PNT =>
        vram_a_o(0 to  3) <= reg_ntb_i;
        vram_a_o(4 to 13) <= pat_table_i;

      -- Pattern Color Table Access -------------------------------------------
      when AC_PCT =>
        case opmode_i is
          when OPMODE_GRAPH1 =>
            vram_a_o( 0 to  7) <= reg_ctb_i;
            vram_a_o( 8)       <= '0';
            vram_a_o( 9 to 13) <= pat_name_i(0 to 4);

          when OPMODE_GRAPH2 =>
            vram_a_o( 0)       <= reg_ctb_i(0);
            vram_a_o( 1 to  2) <= num_line_v(1 to 2) and
                                  -- remaining bits in CTB mask color
                                  -- lookups
                                  (reg_ctb_i(1) & reg_ctb_i(2));
            vram_a_o( 3 to 10) <= pat_name_i and
                                  -- remaining bits in CTB mask color
                                  -- lookups
                                  (reg_ctb_i(3) & reg_ctb_i(4) &
                                   reg_ctb_i(5) & reg_ctb_i(6) &
                                   reg_ctb_i(7) & "111");
            vram_a_o(11 to 13) <= num_line_v(6 to 8);

          when others =>
            null;
        end case;

      -- Pattern Generator Table Access ---------------------------------------
      when AC_PGT =>
        case opmode_i is
          when OPMODE_TEXTM  |
               OPMODE_GRAPH1 =>
            vram_a_o( 0 to  2) <= reg_pgb_i;
            vram_a_o( 3 to 10) <= pat_name_i;
            vram_a_o(11 to 13) <= num_line_v(6 to 8);

          when OPMODE_MULTIC =>
            vram_a_o( 0 to  2) <= reg_pgb_i;
            vram_a_o( 3 to 10) <= pat_name_i;
            vram_a_o(11 to 13) <= num_line_v(4 to 6);

          when OPMODE_GRAPH2 =>
            vram_a_o( 0)       <= reg_pgb_i(0);
            vram_a_o( 1 to  2) <= num_line_v(1 to 2) and
                                  -- remaining bits in PGB mask pattern
                                  -- lookups
                                  (reg_pgb_i(1) & reg_pgb_i(2)); 
            vram_a_o( 3 to 10) <= pat_name_i and
                                  -- remaining bits in CTB mask pattern
                                  -- lookups
                                  (reg_ctb_i(3) & reg_ctb_i(4) &
                                   reg_ctb_i(5) & reg_ctb_i(6) &
                                   reg_ctb_i(7) & "111");
            vram_a_o(11 to 13) <= num_line_v(6 to 8);

          when others =>
            null;
        end case;

      -- Sprite Test ----------------------------------------------------------
      when AC_STST |
           AC_SATY =>
        vram_a_o( 0 to  6) <= reg_satb_i;
        vram_a_o( 7 to 11) <= spr_num_i;
        vram_a_o(12 to 13) <= "00";

      -- Sprite Attribute Table: X --------------------------------------------
      when AC_SATX =>
        vram_a_o( 0 to  6) <= reg_satb_i;
        vram_a_o( 7 to 11) <= spr_num_i;
        vram_a_o(12 to 13) <= "01";

      -- Sprite Attribute Table: Name -----------------------------------------
      when AC_SATN =>
        vram_a_o( 0 to  6) <= reg_satb_i;
        vram_a_o( 7 to 11) <= spr_num_i;
        vram_a_o(12 to 13) <= "10";

      -- Sprite Attribute Table: Color ----------------------------------------
      when AC_SATC =>
        vram_a_o( 0 to  6) <= reg_satb_i;
        vram_a_o( 7 to 11) <= spr_num_i;
        vram_a_o(12 to 13) <= "11";

      -- Sprite Pattern, Upper Part -------------------------------------------
      when AC_SPTH =>
        vram_a_o( 0 to  2)   <= reg_spgb_i;
        if not reg_size1_i then
          -- 8x8 sprite
          vram_a_o( 3 to 10) <= spr_name_i;
          vram_a_o(11 to 13) <= spr_line_i(1 to 3);
        else
          -- 16x16 sprite
          vram_a_o( 3 to  8) <= spr_name_i(0 to 5);
          vram_a_o( 9)       <= '0';
          vram_a_o(10 to 13) <= spr_line_i;
        end if;

      -- Sprite Pattern, Lower Part -------------------------------------------
      when AC_SPTL =>
        vram_a_o( 0 to  2) <= reg_spgb_i;
        vram_a_o( 3 to  8) <= spr_name_i(0 to 5);
        vram_a_o( 9)       <= '1';
        vram_a_o(10 to 13) <= spr_line_i;

      when others =>
        null;

    end case;

  end process mux;
  --
  -----------------------------------------------------------------------------

end rtl;
