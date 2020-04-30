-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_ctrl.vhd,v 1.26 2006/06/18 10:47:01 arnim Exp $
--
-- Timing Controller
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

use work.vdp18_pack.opmode_t;
use work.vdp18_pack.hv_t;
use work.vdp18_pack.access_t;

entity vdp18_ctrl is

	port (
		clock_i        : in  std_logic;
		clk_en_5m37_i : in  boolean;
		reset_i       : in  boolean;
		opmode_i      : in  opmode_t;
		vram_read_i		: in  boolean;
		vram_write_i	: in  boolean;
		vram_ce_o		: out std_logic;
		vram_oe_o		: out std_logic;
		num_pix_i     : in  hv_t;
		num_line_i    : in  hv_t;
		vert_inc_i    : in  boolean;
		reg_blank_i   : in  boolean;
		reg_size1_i   : in  boolean;
		stop_sprite_i : in  boolean;
		clk_en_acc_o  : out boolean;
		access_type_o : out access_t;
		vert_active_o : out boolean;
		hor_active_o  : out boolean;
		irq_o         : out boolean
	);

end vdp18_ctrl;


use work.vdp18_pack.all;

architecture rtl of vdp18_ctrl is

  -----------------------------------------------------------------------------
  -- This enables a workaround for a bug in XST.
  -- ISE 8.1.02i implements wrong functionality otherwise :-(
  --
  constant xst_bug_wa_c : boolean := true;
  --
  -----------------------------------------------------------------------------

  signal access_type_s   : access_t;

  -- pragma translate_off
  -- Testbench signals --------------------------------------------------------
  --
  signal ac_s            : std_logic_vector(3 downto 0);
  --
  -----------------------------------------------------------------------------
  -- pragma translate_on

  signal vert_active_q,
         hor_active_q      : boolean;
  signal sprite_active_q   : boolean;
  signal sprite_line_act_q : boolean;

begin

  -- pragma translate_off
  -- Testbench signals --------------------------------------------------------
  --
  ac_s <= enum_to_vec_f(access_type_s);
  --
  -----------------------------------------------------------------------------
  -- pragma translate_on


  -----------------------------------------------------------------------------
  -- Process decode_access
  --
  -- Purpose:
  --   Decode horizontal counter value to access type.
  --
  decode_access: process (opmode_i,
                          num_pix_i,
                          vert_active_q,
                          sprite_line_act_q,
                          reg_size1_i)
    variable num_pix_plus_6_v  : hv_t;
    variable mod_6_v           : hv_t;
    variable num_pix_plus_8_v  : hv_t;
    variable num_pix_plus_32_v : hv_t;
    variable num_pix_spr_v     : integer;
  begin
    -- default assignment
    access_type_s <= AC_CPU;

    -- prepare number of pixels for pattern operations
    num_pix_plus_6_v  := num_pix_i + 6;
    num_pix_plus_8_v  := num_pix_i + 8;
    num_pix_plus_32_v := num_pix_i + 32;
    num_pix_spr_v     := to_integer(num_pix_i and "111111110");

	case opmode_i is
		-- Graphics I, II and Multicolor Mode -----------------------------------
		when OPMODE_GRAPH1 |
				OPMODE_GRAPH2 |
				OPMODE_MULTIC =>
			--
			-- Patterns
			--
			if vert_active_q then
				if num_pix_plus_8_v(0) = '0' then
					if not xst_bug_wa_c then

            -- original code, we want this
            case num_pix_plus_8_v(6 to 7) is
              when "01" =>
                access_type_s   <= AC_PNT;
              when "10" =>
                if opmode_i /= OPMODE_MULTIC then
                  -- no access to pattern color table in multicolor mode
                  access_type_s <= AC_PCT;
                end if;
              when "11" =>
                access_type_s   <= AC_PGT;
              when others =>
                null;
            end case;

            else

            -- workaround for XST bug, we need this
            if    num_pix_plus_8_v(6 to 7) = "01" then
              access_type_s   <= AC_PNT;
            elsif num_pix_plus_8_v(6 to 7) = "10" then
              if opmode_i /= OPMODE_MULTIC then
                access_type_s <= AC_PCT;
              end if;
            elsif num_pix_plus_8_v(6 to 7) = "11" then
              access_type_s   <= AC_PGT;
            end if;

            end if;
          end if;
        end if;

        --
        -- Sprite test
        --
        if sprite_line_act_q then
          if num_pix_i(0) = '0'            and
             num_pix_i(0 to 5) /= "011111" and
             num_pix_i(6 to 7)  = "00"     and
             num_pix_i(4 to 5) /= "00"     then
            -- sprite test interleaved with pattern accesses
            access_type_s <= AC_STST;
          end if;
          if (num_pix_plus_32_v(0 to 4) = "00000" or 
              num_pix_plus_32_v(0 to 5) = "000010") and
             num_pix_plus_32_v(6 to 7) /= "00"   then
            -- sprite tests before starting pattern phase
            access_type_s <= AC_STST;
          end if;

          --
          -- Sprite Attribute Table and Sprite Pattern Table
          --
          case num_pix_spr_v is
            when 250 | -78 |
                 -62 | -46 =>
              access_type_s   <= AC_SATY;
            when 254 | -76 |
                 -60 | -44 =>
              access_type_s   <= AC_SATX;
            when 252 | -74 |
                 -58 | -42 =>
              access_type_s   <= AC_SATN;
            when -86 | -70 |
                 -54 | -38 =>
              access_type_s   <= AC_SATC;
            when -84 | -68 |
                 -52 | -36 =>
              access_type_s   <= AC_SPTH;
            when -82 | -66 |
                 -50 | -34 =>
              if reg_size1_i then
                access_type_s <= AC_SPTL;
              end if;
            when others =>
              null;
          end case;
        end if;

      -- Text Mode ------------------------------------------------------------
      when OPMODE_TEXTM =>
        if vert_active_q                       and
           num_pix_plus_6_v(0) = '0'           and
           num_pix_plus_6_v(0 to 4) /= "01111" then
          mod_6_v := mod_6_f(num_pix_plus_6_v);
          case mod_6_v(6 to 7) is
            when "00" =>
              access_type_s <= AC_PNT;
            when "10" =>
              access_type_s <= AC_PGT;
            when others =>
              null;
          end case;
        end if;

      -- Unknown --------------------------------------------------------------
--      when others =>
--        null;

    end case;

  end process decode_access;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process vert_flags
  --
  -- Purpose:
  --   Track the vertical position with flags.
  --
  vert_flags: process (clock_i, reset_i)
  begin
    if reset_i then
      vert_active_q     <= false;
      sprite_active_q   <= false;
      sprite_line_act_q <= false;

    elsif clock_i'event and clock_i = '1' then
      if clk_en_5m37_i then
        -- line-local sprite processing
        if sprite_active_q then
          -- sprites are globally enabled
          if vert_inc_i then
            -- reload at beginning of every new line
            -- => scan with STST
            sprite_line_act_q <= true;
          end if;

          if num_pix_i = hv_sprite_start_c then
            -- reload when access to sprite memory starts
            sprite_line_act_q <= true;
          end if;
        end if;

        if vert_inc_i then
          -- global sprite processing
          if    reg_blank_i then
            sprite_active_q   <= false;
            sprite_line_act_q <= false;
          elsif num_line_i = -2 then
            -- start at line -1
            sprite_active_q   <= true;
            -- initialize immediately
            sprite_line_act_q <= true;
          elsif num_line_i = 191 then
            -- stop at line 192
            sprite_active_q   <= false;
            -- force stop
            sprite_line_act_q <= false;
          end if;

          -- global vertical display
          if    reg_blank_i then
            vert_active_q <= false;
          elsif num_line_i = -1 then
            -- start vertical display at line 0
            vert_active_q <= true;
          elsif num_line_i = 191 then
            -- stop at line 192
            vert_active_q <= false;
          end if;
        end if;

        if stop_sprite_i then
          -- stop processing of sprites in this line
          sprite_line_act_q <= false;
        end if;

      end if;
    end if;
  end process vert_flags;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process hor_flags
  --
  -- Purpose:
  --   Track the horizontal position.
  --
  hor_flags: process (clock_i, reset_i)
  begin
    if reset_i then
      hor_active_q     <= false;

    elsif clock_i'event and clock_i = '1' then
      if clk_en_5m37_i then
        if not reg_blank_i and
           num_pix_i = -1  then
          hor_active_q <= true;
        end if;

        if opmode_i = OPMODE_TEXTM then
          if num_pix_i = 239 then
            hor_active_q <= false;
          end if;
        else
          if num_pix_i = 255 then
            hor_active_q <= false;
          end if;
        end if;
      end if;
    end if;
  end process hor_flags;
  --
  -----------------------------------------------------------------------------

	vram_ctrl: process (clock_i)
		variable read_b_v	: boolean;
	begin
		if rising_edge(clock_i) then
			if clk_en_5m37_i then
				vram_ce_o	<= '0';
				vram_oe_o	<= '0';
				if access_type_s = AC_CPU then
					if vram_read_i and not read_b_v then
						vram_ce_o	<= '1';
						vram_oe_o	<= '1';
						read_b_v		:= true;
					elsif vram_write_i and not read_b_v then
						vram_ce_o	<= '1';
						--
						read_b_v		:= true;
					else
						read_b_v		:= false;
					end if;
				else
					if not read_b_v then
						vram_ce_o	<= '1';
						vram_oe_o	<= '1';
						read_b_v		:= true;
					else
						read_b_v		:= false;
					end if;
				end if;
			end if;
		end if;
	end process;

  -----------------------------------------------------------------------------
  -- Ouput mapping
  -----------------------------------------------------------------------------
  -- generate clock enable for flip-flops working on access_type
  clk_en_acc_o  <= clk_en_5m37_i and num_pix_i(8) = '1';
  access_type_o <= access_type_s;
  vert_active_o <= vert_active_q;
  hor_active_o  <= hor_active_q;
  irq_o         <= vert_inc_i and num_line_i = 191;

end rtl;
