-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_sprite.vhd,v 1.11 2006/06/18 10:47:06 arnim Exp $
--
-- Sprite Generation Controller
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

use work.vdp18_pack.hv_t;
use work.vdp18_pack.access_t;

entity vdp18_sprite is

  port (
    clk_i         : in  std_logic;
    clk_en_5m37_i : in  boolean;
    clk_en_acc_i  : in  boolean;
    reset_i       : in  boolean;
    access_type_i : in  access_t;
    num_pix_i     : in  hv_t;
    num_line_i    : in  hv_t;
    vram_d_i      : in  std_logic_vector(0 to 7);
    vert_inc_i    : in  boolean;
    reg_size1_i   : in  boolean;
    reg_mag1_i    : in  boolean;
    spr_5th_o     : out boolean;
    spr_5th_num_o : out std_logic_vector(0 to 4);
    stop_sprite_o : out boolean;
    spr_coll_o    : out boolean;
    spr_num_o     : out std_logic_vector(0 to 4);
    spr_line_o    : out std_logic_vector(0 to 3);
    spr_name_o    : out std_logic_vector(0 to 7);
    spr0_col_o    : out std_logic_vector(0 to 3);
    spr1_col_o    : out std_logic_vector(0 to 3);
    spr2_col_o    : out std_logic_vector(0 to 3);
    spr3_col_o    : out std_logic_vector(0 to 3)
  );

end vdp18_sprite;


library ieee;
use ieee.numeric_std.all;

use work.vdp18_pack.all;

architecture rtl of vdp18_sprite is

  subtype sprite_number_t  is unsigned(0 to 4);
  type    sprite_numbers_t is array (natural range 0 to 3) of sprite_number_t;
  signal  sprite_numbers_q : sprite_numbers_t;

  signal  sprite_num_q     : unsigned(0 to 4);
  signal  sprite_idx_q     : unsigned(0 to 2);
  signal  sprite_name_q    : std_logic_vector(0 to 7);

  subtype sprite_x_pos_t   is unsigned(0 to 7);
  type    sprite_xpos_t    is array (natural range 0 to 3) of sprite_x_pos_t;
  signal  sprite_xpos_q    : sprite_xpos_t;
  type    sprite_ec_t      is array (natural range 0 to 3) of std_logic;
  signal  sprite_ec_q      : sprite_ec_t;
  type    sprite_xtog_t    is array (natural range 0 to 3) of std_logic;
  signal  sprite_xtog_q    : sprite_xtog_t;

  subtype sprite_col_t     is std_logic_vector(0 to 3);
  type    sprite_cols_t    is array (natural range 0 to 3) of sprite_col_t;
  signal  sprite_cols_q    : sprite_cols_t;

  subtype sprite_pat_t     is std_logic_vector(0 to 15);
  type    sprite_pats_t    is array (natural range 0 to 3) of sprite_pat_t;
  signal  sprite_pats_q    : sprite_pats_t;

  signal  sprite_line_s,
          sprite_line_q    : std_logic_vector(0 to 3);
  signal  sprite_visible_s : boolean;

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --  Implements the sequential elements.
  --
  seq: process (clk_i, reset_i)
    variable sprite_idx_inc_v,
             sprite_idx_dec_v  : unsigned(sprite_idx_q'range);
    variable sprite_idx_v      : natural range 0 to 3;
  begin
    if reset_i then
      sprite_numbers_q <= (others => (others => '0'));
      sprite_num_q     <= (others => '0');
      sprite_idx_q     <= (others => '0');
      sprite_line_q    <= (others => '0');
      sprite_name_q    <= (others => '0');
      sprite_cols_q    <= (others => (others => '0'));
      sprite_xpos_q    <= (others => (others => '0'));
      sprite_ec_q      <= (others => '0');
      sprite_xtog_q    <= (others => '0');
      sprite_pats_q    <= (others => (others => '0'));

    elsif clk_i'event and clk_i = '1' then
      -- sprite index will be incremented during sprite tests
      sprite_idx_inc_v  := sprite_idx_q + 1;
      -- sprite index will be decremented at end of sprite pattern data
      sprite_idx_dec_v  := sprite_idx_q - 1;
      -- just save typing
      sprite_idx_v      := to_integer(sprite_idx_q(1 to 2));

      if clk_en_5m37_i then
        -- pre-decrement index counter when sprite reading starts
        if num_pix_i = hv_sprite_start_c and sprite_idx_q > 0 then
          sprite_idx_q <= sprite_idx_dec_v;
        end if;

        -----------------------------------------------------------------------
        -- X position counters
        -----------------------------------------------------------------------
        for idx in 0 to 3 loop
          if num_pix_i(0) = '0'                                       or
             (sprite_ec_q(idx) = '1' and num_pix_i(0 to 3) = "1111") then
            if    sprite_xpos_q(idx) /= 0 then
              -- decrement counter until 0
              sprite_xpos_q(idx) <= sprite_xpos_q(idx) - 1;
            else
              -- toggle magnification flag
              sprite_xtog_q(idx) <= not sprite_xtog_q(idx);
            end if;
          end if;
        end loop;

        -----------------------------------------------------------------------
        -- Sprite pattern shift registers
        -----------------------------------------------------------------------
        for idx in 0 to 3 loop
          if sprite_xpos_q(idx) = 0 then  -- x counter elapsed
            -- decide when to shift pattern information
            -- case 1: pixel number is >= 0
            --         => active display area
            -- case 2: early clock bit is set and pixel number is between
            --         -32 and 0
            --   shift if
            --     magnification not enbled
            --       or
            --     magnification enabled and toggle marker true
            if (num_pix_i(0) = '0'                                   or
                (sprite_ec_q(idx) = '1' and num_pix_i(0 to 3) = "1111")) and
               (sprite_xtog_q(idx) = '1' or not reg_mag1_i)              then
              --
              -- shift pattern left and fill vacated position with
              -- transparent information
              sprite_pats_q(idx)(0 to 14) <= sprite_pats_q(idx)(1 to 15);
              sprite_pats_q(idx)(15)      <= '0';
            end if;
          end if;

          -- clear pattern at end of visible display
          -- this removes "left-overs" when a sprite overlaps the right border
          if num_pix_i = "011111111" then
            sprite_pats_q(idx) <= (others => '0');
          end if;
        end loop;
      end if;


      if    vert_inc_i then
        -- reset sprite num counter and sprite index counter
        sprite_num_q   <= (others => '0');
        sprite_idx_q   <= (others => '0');

      elsif clk_en_acc_i then
        case access_type_i is
          when AC_STST =>
            -- increment sprite number counter
            sprite_num_q      <= sprite_num_q + 1;

            if sprite_visible_s then
              if sprite_idx_q < 4 then
                -- store sprite number
                sprite_numbers_q(sprite_idx_v) <= sprite_num_q;
                -- and increment index counter
                sprite_idx_q  <= sprite_idx_inc_v;
              end if;
            end if;

          when AC_SATY =>
            -- store sprite line
            sprite_line_q <= sprite_line_s;

          when AC_SATX =>
            -- save x position
            sprite_xpos_q(sprite_idx_v) <= unsigned(vram_d_i);
            -- reset toggle flag for magnified sprites
            sprite_xtog_q(sprite_idx_v) <= '0';

          when AC_SATN =>
            -- save sprite name
            sprite_name_q <= vram_d_i;

          when AC_SATC =>
            -- save sprite color
            sprite_cols_q(sprite_idx_v)   <= vram_d_i(4 to 7);
            -- and save early clock bit
            sprite_ec_q(sprite_idx_v)     <= vram_d_i(0);

          when AC_SPTH =>
            -- save upper pattern data
            sprite_pats_q(sprite_idx_v)(0 to  7)
              <= vram_d_i;
            -- set lower part to transparent
            sprite_pats_q(sprite_idx_v)(8 to 15)
              <= (others => '0');

            if not reg_size1_i then
              -- decrement index counter in 8-bit mode
              sprite_idx_q <= sprite_idx_dec_v;
            end if;

          when AC_SPTL =>
            -- save lower pattern data
            sprite_pats_q(sprite_idx_v)(8 to 15) <= vram_d_i;

            -- always decrement index counter
            sprite_idx_q <= sprite_idx_dec_v;

          when others =>
            null;
        end case;

      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process calc_vert
  --
  -- Purpose:
  --   Calculates the displayed line of the sprite and determines whether it
  --   is visible on the current line or not.
  --
  calc_vert: process (clk_en_acc_i, access_type_i,
                      vram_d_i,
                      num_pix_i, num_line_i,
                      sprite_num_q, sprite_idx_q,
                      reg_size1_i, reg_mag1_i)
    variable sprite_line_v : signed(0 to 8);
    variable vram_d_v      : signed(0 to 8);
  begin
    -- default assignments
    sprite_visible_s <= false;
    stop_sprite_o    <= false;

    vram_d_v         := resize(signed(vram_d_i), 9);
    -- determine if y information from VRAM should be treated
    -- as a signed or unsigned number
    if vram_d_v < -31 then
      -- treat as unsigned number
      vram_d_v(0)    := '0';
    end if;

    sprite_line_v    := num_line_i - vram_d_v;
    if reg_mag1_i then
      -- unmagnify line number
      sprite_line_v  := shift_right(sprite_line_v, 1);
    end if;

    -- check result bounds
    if sprite_line_v >= 0 then
      if reg_size1_i then
        -- double sized sprite: 16 data lines
        if sprite_line_v < 16 then
          sprite_visible_s <= true;
        end if;
      else
        -- standard sized sprite: 8 data lines
        if sprite_line_v < 8 then
          sprite_visible_s <= true;
        end if;
      end if;
    end if;

    -- finally: line number of current sprite
    sprite_line_s <= std_logic_vector(sprite_line_v(5 to 8));

    if clk_en_acc_i then
      -- determine when to stop sprite scanning
      if access_type_i = AC_STST then
        if vram_d_v = 208 then
          -- stop upon Y position 208
          stop_sprite_o <= true;
        end if;

        if sprite_idx_q = 4 then
          -- stop when all sprite positions have been vacated
          stop_sprite_o <= true;
        end if;

        if sprite_num_q = 31 then
          -- stop when all sprites have been read
          stop_sprite_o <= true;
        end if;
      end if;

      -- stop sprite reading when last active sprite has been processed
      if sprite_idx_q = 0                                and
         ( access_type_i = AC_SPTL                   or
          (access_type_i = AC_SPTH and not reg_size1_i)) then
        stop_sprite_o <= true;
      end if;
    end if;

    -- stop sprite reading when no sprite is active on current line
    if num_pix_i = hv_sprite_start_c and sprite_idx_q = 0 then
      stop_sprite_o <= true;
    end if;
  end process calc_vert;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process fifth
  --
  -- Purpose:
  --   Detects the fifth sprite.
  --
  fifth: process (clk_en_acc_i, access_type_i,
                  sprite_visible_s,
                  sprite_idx_q,
                  sprite_num_q)
  begin
    -- default assignments
    spr_5th_o         <= false;
    spr_5th_num_o     <= (others => '0');

    if clk_en_acc_i and access_type_i = AC_STST then
      if sprite_visible_s and sprite_idx_q = 4 then
        spr_5th_o     <= true;
        spr_5th_num_o <= std_logic_vector(sprite_num_q);
      end if;
    end if;
  end process fifth;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process col_mux
  --
  -- Purpose:
  --   Implements the color multiplexers.
  --
  col_mux: process (sprite_cols_q,
                    sprite_pats_q,
                    sprite_xpos_q)
    variable num_spr_pix_v : unsigned(0 to 2);
  begin
    -- default assignments
    -- sprite colors are set to transparent
    spr0_col_o    <= (others => '0');
    spr1_col_o    <= (others => '0');
    spr2_col_o    <= (others => '0');
    spr3_col_o    <= (others => '0');
    num_spr_pix_v := (others => '0');

    if sprite_xpos_q(0) = 0 and sprite_pats_q(0)(0) = '1' then
      spr0_col_o    <= sprite_cols_q(0);
      num_spr_pix_v := num_spr_pix_v + 1;
    end if;
    if sprite_xpos_q(1) = 0 and sprite_pats_q(1)(0) = '1' then
      spr1_col_o    <= sprite_cols_q(1);
      num_spr_pix_v := num_spr_pix_v + 1;
    end if;
    if sprite_xpos_q(2) = 0 and sprite_pats_q(2)(0) = '1' then
      spr2_col_o    <= sprite_cols_q(2);
      num_spr_pix_v := num_spr_pix_v + 1;
    end if;
    if sprite_xpos_q(3) = 0 and sprite_pats_q(3)(0) = '1' then
      spr3_col_o    <= sprite_cols_q(3);
      num_spr_pix_v := num_spr_pix_v + 1;
    end if;

    spr_coll_o <= num_spr_pix_v > 1;
  end process col_mux;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  spr_num_o  <=   std_logic_vector(sprite_num_q)
                when access_type_i = AC_STST else
                  std_logic_vector(sprite_numbers_q(to_integer(sprite_idx_q(1 to 2))));
  spr_line_o <= sprite_line_q;
  spr_name_o <= sprite_name_q;

end rtl;
