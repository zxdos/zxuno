-------------------------------------------------------------------------------
--
-- $Id: vdp18_col_pack-p.vhd,v 1.3 2006/02/28 22:30:41 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package vdp18_col_pack is

  constant r_c : natural := 0;
  constant g_c : natural := 1;
  constant b_c : natural := 2;

  subtype rgb_val_t    is natural range 0 to 255;
  type    rgb_triple_t is array (natural range 0 to  2) of
    rgb_val_t;
  type    rgb_table_t  is array (natural range 0 to 15) of
    rgb_triple_t;

  -----------------------------------------------------------------------------
  -- Simple RGB Value Array
  --
  -- Refer to http://junior.apk.net/~drushel/pub/coleco/twwmca/wk970202.html
  -- This is the MF & MdK variant. Note: only the upper three bits are used.
  --
  --
  constant compat_rgb_table_c : rgb_table_t := (
  -- R  G  B
    (  0,   0,   0),                    -- Transparent
    (  0,   0,   0),                    -- Black
    ( 32, 192,  32),                    -- Medium Green
    ( 96, 224,  96),                    -- Light Green
    ( 32,  32, 224),                    -- Dark Blue
    ( 64,  96, 224),                    -- Light Blue
    (160,  32,  32),                    -- Dark Red
    ( 64, 192, 224),                    -- Cyan
    (224,  32,  32),                    -- Medium Red
    (224,  96,  96),                    -- Light Red
    (192, 192,  32),                    -- Dark Yellow
    (192, 192, 128),                    -- Light Yellow
    ( 32, 128,  32),                    -- Dark Green
    (192,  64, 160),                    -- Magenta
    (160, 160, 160),                    -- Gray
    (224, 224, 224)                     -- White
    );
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Full RGB Value Array
  --
  -- Refer to tms9928a.c of the MAME source distribution.
  --
  constant full_rgb_table_c : rgb_table_t := (
  --   R    G    B
    (  0,   0,   0),                    -- Transparent		RGB
    (  0,   0,   0),                    -- Black				000
    ( 33, 200,  66),                    -- Medium Green		162
    ( 94, 220, 120),                    -- Light Green		263
    ( 84,  85, 237),                    -- Dark Blue			227
    (125, 118, 252),                    -- Light Blue			337
    (212,  82,  77),                    -- Dark Red			622
    ( 66, 235, 245),                    -- Cyan					277
    (252,  85,  84),                    -- Medium Red			722
    (255, 121, 120),                    -- Light Red			733
    (212, 193,  84),                    -- Dark Yellow		662
    (230, 206, 128),                    -- Light Yellow		764
    ( 33, 176,  59),                    -- Dark Green			151
    (201,  91, 186),                    -- Magenta				625
    (204, 204, 204),                    -- Gray					333
    (255, 255, 255)                     -- White				777
    );
  --
  -----------------------------------------------------------------------------

end vdp18_col_pack;
