-------------------------------------------------------------------------------
--
-- $Id: vdp18_pack-p.vhd,v 1.14 2006/02/22 23:07:05 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vdp18_pack is

  -----------------------------------------------------------------------------
  -- Subtype for horizontal/vertical counters/positions.
  --
  subtype hv_t is signed(0 to 8);
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Constants for first and last vertical line of NTSC and PAL mode.
  --
  constant hv_first_line_ntsc_c : hv_t := to_signed(-40, hv_t'length);
  constant hv_last_line_ntsc_c  : hv_t := to_signed(221, hv_t'length);
  --
  constant hv_first_line_pal_c  : hv_t := to_signed(-65, hv_t'length);
  constant hv_last_line_pal_c   : hv_t := to_signed(247, hv_t'length);
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Constants for first and last horizontal pixel in text and graphics.
  --
  constant hv_first_pix_text_c  : hv_t := to_signed(-102, hv_t'length);
  constant hv_last_pix_text_c   : hv_t := to_signed(239,  hv_t'length);
  --
  constant hv_first_pix_graph_c : hv_t := to_signed(-86,  hv_t'length);
  constant hv_last_pix_graph_c  : hv_t := to_signed(255,  hv_t'length);
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Miscellaneous constants for horizontal phases.
  --
  constant hv_vertical_inc_c    : hv_t := to_signed(-32,  hv_t'length);
  constant hv_sprite_start_c    : hv_t := to_signed(247,  hv_t'length);
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Operating modes of the VDP18 core.
  --
  type opmode_t is (OPMODE_GRAPH1, OPMODE_GRAPH2,
                    OPMODE_MULTIC, OPMODE_TEXTM);
  --
  constant opmode_graph1_c : std_logic_vector(0 to 2) := "000";
  constant opmode_graph2_c : std_logic_vector(0 to 2) := "001";
  constant opmode_multic_c : std_logic_vector(0 to 2) := "010";
  constant opmode_textm_c  : std_logic_vector(0 to 2) := "100";
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Access types.
  --
  type access_t is (-- pattern access
                    -- read Pattern Name Table
                    AC_PNT,
                    -- read Pattern Generator Table
                    AC_PGT,
                    -- read Pattern Color Table
                    AC_PCT,
                    -- sprite access
                    -- sprite test read (y coordinate)
                    AC_STST,
                    -- read Sprite Attribute Table/Y
                    AC_SATY,
                    -- read Sprite Attribute Table/X
                    AC_SATX,
                    -- read Sprite Attribute Table/N
                    AC_SATN,
                    -- read Sprite Attribute Table/C
                    AC_SATC,
                    -- read Sprite Pattern Table/high quadrant
                    AC_SPTH,
                    -- read Sprite Pattern Table/low quadrant
                    AC_SPTL,
                    --
                    -- CPU access
                    AC_CPU,
                    --
                    -- no access at all
                    AC_NONE
                   );
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Function enum_to_vec_f
  --
  -- Purpose:
  --   Translate access_t enumeration type to std_logic_vector.
  --
  function enum_to_vec_f(enum : in access_t) return
    std_logic_vector;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Function to_boolean_f
  --
  -- Purpose:
  --   Converts a std_logic value to boolean.
  --
  function to_boolean_f(val : in std_logic) return boolean;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Function to_std_logic_f
  --
  -- Purpose:
  --   Converts a boolean value to std_logic.
  --
  function to_std_logic_f(val : in boolean) return std_logic;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Function mod_6_f
  --
  -- Purpose:
  --   Calculate the modulo of 6.
  --   Only the positive part is considered.
  --
  function mod_6_f(val : in hv_t) return hv_t;
  --
  -----------------------------------------------------------------------------

end vdp18_pack;


package body vdp18_pack is

  -----------------------------------------------------------------------------
  -- Function enum_to_vec_f
  --
  -- Purpose:
  --   Translate access_t enumeration type to std_logic_vector.
  --
  function enum_to_vec_f(enum : in access_t) return
    std_logic_vector is
    variable result_v : std_logic_vector(3 downto 0);
  begin
    case enum is
      when AC_NONE =>
        result_v := "0000";
      when AC_PNT =>
        result_v := "0001";
      when AC_PGT =>
        result_v := "0010";
      when AC_PCT =>
        result_v := "0011";
      when AC_STST =>
        result_v := "0100";
      when AC_SATY =>
        result_v := "0101";
      when AC_SATX =>
        result_v := "0110";
      when AC_SATN =>
        result_v := "0111";
      when AC_SATC =>
        result_v := "1000";
      when AC_SPTL =>
        result_v := "1001";
      when AC_SPTH =>
        result_v := "1010";
      when AC_CPU =>
        result_v := "1111";
      when others =>
        result_v := "UUUU";
    end case;

    return result_v;
  end;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Function to_boolean_f
  --
  -- Purpose:
  --   Converts a std_logic value to boolean.
  --
  function to_boolean_f(val : in std_logic) return boolean is
    variable result_v : boolean;
  begin
    case to_X01(val) is
      when '1' =>
        result_v := true;
      when '0' =>
        result_v := false;
      when others =>
        result_v := false;
    end case;

    return result_v;
  end;
  --
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Function to_std_logic_f
  --
  -- Purpose:
  --   Converts a boolean value to std_logic.
  --
  function to_std_logic_f(val : in boolean) return std_logic is
    variable result_v : std_logic;
  begin
    case val is
      when true =>
        result_v := '1';
      when false =>
        result_v := '0';
    end case;

    return result_v;
  end;
  --
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Function mod_6_f
  --
  -- Purpose:
  --   Calculate the modulo of 6.
  --   Only the positive part is considered.
  --
  function mod_6_f(val : in hv_t) return hv_t is
    variable mod_v     : natural;
    variable result_v  : hv_t;
  begin
    if val(0) = '0' then
      result_v := (others => '0');
      mod_v    := 0;
      for idx in 0 to 255 loop
        if val = idx then
          result_v := to_signed(mod_v, hv_t'length);
        end if;

        if mod_v < 5 then
          mod_v := mod_v + 1;
        else
          mod_v := 0;
        end if;
      end loop;
    else
      result_v := (others => '-');
    end if;

    return result_v;
  end;
  --
  -----------------------------------------------------------------------------

end vdp18_pack;
