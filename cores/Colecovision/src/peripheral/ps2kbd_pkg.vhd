-------------------------------------------------------------------------------
--
-- Copyright (c) 2002, Daniel Wallner (jesus@opencores.org)
-- Copyright (c) 2016, Fabio Belavenuto (belavenuto@gmail.com)
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

package kbd_pkg is

  constant SCANCODE_BACKQUOTE   : std_logic_vector(7 downto 0) := X"0E";
  constant SCANCODE_A           : std_logic_vector(7 downto 0) := X"1C";
  constant SCANCODE_B           : std_logic_vector(7 downto 0) := X"32";
  constant SCANCODE_C           : std_logic_vector(7 downto 0) := X"21";
  constant SCANCODE_D           : std_logic_vector(7 downto 0) := X"23";
  constant SCANCODE_E           : std_logic_vector(7 downto 0) := X"24";
  constant SCANCODE_F           : std_logic_vector(7 downto 0) := X"2B";
  constant SCANCODE_G           : std_logic_vector(7 downto 0) := X"34";
  constant SCANCODE_H           : std_logic_vector(7 downto 0) := X"33";
  constant SCANCODE_I           : std_logic_vector(7 downto 0) := X"43";
  constant SCANCODE_J           : std_logic_vector(7 downto 0) := X"3B";
  constant SCANCODE_K           : std_logic_vector(7 downto 0) := X"42";
  constant SCANCODE_L           : std_logic_vector(7 downto 0) := X"4B";
  constant SCANCODE_M           : std_logic_vector(7 downto 0) := X"3A";
  constant SCANCODE_N           : std_logic_vector(7 downto 0) := X"31";
  constant SCANCODE_O           : std_logic_vector(7 downto 0) := X"44";
  constant SCANCODE_P           : std_logic_vector(7 downto 0) := X"4D";
  constant SCANCODE_Q           : std_logic_vector(7 downto 0) := X"15";
  constant SCANCODE_R           : std_logic_vector(7 downto 0) := X"2D";
  constant SCANCODE_S           : std_logic_vector(7 downto 0) := X"1B";
  constant SCANCODE_T           : std_logic_vector(7 downto 0) := X"2C";
  constant SCANCODE_U           : std_logic_vector(7 downto 0) := X"3C";
  constant SCANCODE_V           : std_logic_vector(7 downto 0) := X"2A";
  constant SCANCODE_W           : std_logic_vector(7 downto 0) := X"1D";
  constant SCANCODE_X           : std_logic_vector(7 downto 0) := X"22";
  constant SCANCODE_Y           : std_logic_vector(7 downto 0) := X"35";
  constant SCANCODE_Z           : std_logic_vector(7 downto 0) := X"1A";
  constant SCANCODE_0           : std_logic_vector(7 downto 0) := X"45";
  constant SCANCODE_1           : std_logic_vector(7 downto 0) := X"16";
  constant SCANCODE_2           : std_logic_vector(7 downto 0) := X"1E";
  constant SCANCODE_3           : std_logic_vector(7 downto 0) := X"26";
  constant SCANCODE_4           : std_logic_vector(7 downto 0) := X"25";
  constant SCANCODE_5           : std_logic_vector(7 downto 0) := X"2E";
  constant SCANCODE_6           : std_logic_vector(7 downto 0) := X"36";
  constant SCANCODE_7           : std_logic_vector(7 downto 0) := X"3D";
  constant SCANCODE_8           : std_logic_vector(7 downto 0) := X"3E";
  constant SCANCODE_9           : std_logic_vector(7 downto 0) := X"46";
  constant SCANCODE_QUOTE       : std_logic_vector(7 downto 0) := X"52";
  constant SCANCODE_SEMICOLON   : std_logic_vector(7 downto 0) := X"4C";
  constant SCANCODE_COMMA       : std_logic_vector(7 downto 0) := X"41";
  constant SCANCODE_MINUS       : std_logic_vector(7 downto 0) := X"4E";
  constant SCANCODE_PERIOD      : std_logic_vector(7 downto 0) := X"49";
  constant SCANCODE_SLASH       : std_logic_vector(7 downto 0) := X"4A";
  constant SCANCODE_ENTER       : std_logic_vector(7 downto 0) := X"5A";
  constant SCANCODE_HOME        : std_logic_vector(7 downto 0) := X"6C";
  constant SCANCODE_INS         : std_logic_vector(7 downto 0) := X"70"; -- E0
  constant SCANCODE_PGUP        : std_logic_vector(7 downto 0) := X"7D"; -- E0
  constant SCANCODE_PGDN        : std_logic_vector(7 downto 0) := X"7A"; -- E0
  constant SCANCODE_UP          : std_logic_vector(7 downto 0) := X"75"; -- E0
  constant SCANCODE_DOWN        : std_logic_vector(7 downto 0) := X"72"; -- E0
  constant SCANCODE_LEFT        : std_logic_vector(7 downto 0) := X"6B"; -- E0
  constant SCANCODE_BACKSPACE   : std_logic_vector(7 downto 0) := X"66";
  constant SCANCODE_RIGHT       : std_logic_vector(7 downto 0) := X"74"; -- E0
  constant SCANCODE_SPACE       : std_logic_vector(7 downto 0) := X"29";
  constant SCANCODE_LSHIFT      : std_logic_vector(7 downto 0) := X"12";
  constant SCANCODE_RSHIFT      : std_logic_vector(7 downto 0) := X"59";
  constant SCANCODE_TAB					: std_logic_vector(7 downto 0) := X"0D";
  constant SCANCODE_ESC					: std_logic_vector(7 downto 0) := X"76";
  constant SCANCODE_EQUALS			: std_logic_vector(7 downto 0) := X"55";
	constant SCANCODE_F1					: std_logic_vector(7 downto 0) := X"05";
	constant SCANCODE_F2					: std_logic_vector(7 downto 0) := X"06";
	constant SCANCODE_F3					: std_logic_vector(7 downto 0) := X"04";
	constant SCANCODE_F4					: std_logic_vector(7 downto 0) := X"0C";
	constant SCANCODE_F5					: std_logic_vector(7 downto 0) := X"03";
	constant SCANCODE_F6					: std_logic_vector(7 downto 0) := X"0B";
	constant SCANCODE_F7					: std_logic_vector(7 downto 0) := X"83";
	constant SCANCODE_F8					: std_logic_vector(7 downto 0) := X"0A";
	constant SCANCODE_F9					: std_logic_vector(7 downto 0) := X"01";
	constant SCANCODE_F10					: std_logic_vector(7 downto 0) := X"09";
	constant SCANCODE_F11					: std_logic_vector(7 downto 0) := X"78";
	constant SCANCODE_F12					: std_logic_vector(7 downto 0) := X"07";
	constant SCANCODE_CAPSLOCK    : std_logic_vector(7 downto 0) := X"58";
	constant SCANCODE_BACKSLASH   : std_logic_vector(7 downto 0) := X"5D";
  constant SCANCODE_LCTRL      	: std_logic_vector(7 downto 0) := X"14";
	constant SCANCODE_LALT				: std_logic_vector(7 downto 0) := X"11";
	alias SCANCODE_TILDE          : std_logic_vector(7 downto 0) is SCANCODE_BACKQUOTE;
	constant SCANCODE_OPENBRKT    : std_logic_vector(7 downto 0) := X"54";
	alias SCANCODE_OPENBRACE      : std_logic_vector(7 downto 0) is SCANCODE_OPENBRKT;
	constant SCANCODE_CLOSEBRKT   : std_logic_vector(7 downto 0) := X"5B";
	alias SCANCODE_CLOSEBRACE     : std_logic_vector(7 downto 0) is SCANCODE_CLOSEBRKT;
	constant SCANCODE_END         : std_logic_vector(7 downto 0) := X"69"; -- E0
	alias SCANCODE_PAD0           : std_logic_vector(7 downto 0) is SCANCODE_INS;
	alias SCANCODE_PAD1           : std_logic_vector(7 downto 0) is SCANCODE_END;
	alias SCANCODE_PAD2           : std_logic_vector(7 downto 0) is SCANCODE_DOWN;
	alias SCANCODE_PAD3           : std_logic_vector(7 downto 0) is SCANCODE_PGDN;
	alias SCANCODE_PAD4           : std_logic_vector(7 downto 0) is SCANCODE_LEFT;
	constant  SCANCODE_PAD5       : std_logic_vector(7 downto 0) := X"73";
	alias SCANCODE_PAD6           : std_logic_vector(7 downto 0) is SCANCODE_RIGHT;
	alias SCANCODE_PAD7           : std_logic_vector(7 downto 0) is SCANCODE_HOME;
	alias SCANCODE_PAD8           : std_logic_vector(7 downto 0) is SCANCODE_UP;
	alias SCANCODE_PAD9           : std_logic_vector(7 downto 0) is SCANCODE_PGUP;

  type kbd_row is array (natural range <>) of std_logic_vector(7 downto 0);
  type kbd_col is array (natural range <>) of std_logic_vector(7 downto 0);

end;
