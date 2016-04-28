-- TV Interface Adapter (TIA)
-- Copyright 2006, 2010 Retromaster
--
--  This file is part of A2601.
--
--  A2601 is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License,
--  or any later version.
--
--  A2601 is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with A2601.  If not, see <http://www.gnu.org/licenses/>.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TIA_common is

    subtype w_adr is std_logic_vector(5 downto 0);

    constant A_VSYNC:  w_adr := "000000";
    constant A_VBLANK: w_adr := "000001";
    constant A_WSYNC:  w_adr := "000010";
    constant A_RSYNC:  w_adr := "000011";
    constant A_NUSIZ0: w_adr := "000100";
    constant A_NUSIZ1: w_adr := "000101";
    constant A_COLUP0: w_adr := "000110";
    constant A_COLUP1: w_adr := "000111";
    constant A_COLUPF: w_adr := "001000";
    constant A_COLUBK: w_adr := "001001";
    constant A_CTRLPF: w_adr := "001010";
    constant A_REFP0:  w_adr := "001011";
    constant A_REFP1:  w_adr := "001100";
    constant A_PF0:    w_adr := "001101";
    constant A_PF1:    w_adr := "001110";
    constant A_PF2:    w_adr := "001111";
    constant A_RESP0:  w_adr := "010000";
    constant A_RESP1:  w_adr := "010001";
    constant A_RESM0:  w_adr := "010010";
    constant A_RESM1:  w_adr := "010011";
    constant A_RESBL:  w_adr := "010100";
    constant A_AUDC0:  w_adr := "010101";
    constant A_AUDC1:  w_adr := "010110";
    constant A_AUDF0:  w_adr := "010111";
    constant A_AUDF1:  w_adr := "011000";
    constant A_AUDV0:  w_adr := "011001";
    constant A_AUDV1:  w_adr := "011010";
    constant A_GRP0:   w_adr := "011011";
    constant A_GRP1:   w_adr := "011100";
    constant A_ENAM0:  w_adr := "011101";
    constant A_ENAM1:  w_adr := "011110";
    constant A_ENABL:  w_adr := "011111";
    constant A_HMP0:   w_adr := "100000";
    constant A_HMP1:   w_adr := "100001";
    constant A_HMM0:   w_adr := "100010";
    constant A_HMM1:   w_adr := "100011";
    constant A_HMBL:   w_adr := "100100";
    constant A_VDELP0: w_adr := "100101";
    constant A_VDELP1: w_adr := "100110";
    constant A_VDELBL: w_adr := "100111";
    constant A_RESMP0: w_adr := "101000";
    constant A_RESMP1: w_adr := "101001";
    constant A_HMOVE:  w_adr := "101010";
    constant A_HMCLR:  w_adr := "101011";
    constant A_CXCLR:  w_adr := "101100";

    subtype r_adr is std_logic_vector(3 downto 0);

    constant A_CXM0P:  r_adr := "0000";
    constant A_CXM1P:  r_adr := "0001";
    constant A_CXP0FB: r_adr := "0010";
    constant A_CXP1FB: r_adr := "0011";
    constant A_CXM0FB: r_adr := "0100";
    constant A_CXM1FB: r_adr := "0101";
    constant A_CXBLPF: r_adr := "0110";
    constant A_CXPPMM: r_adr := "0111";
    constant A_INPT0:  r_adr := "1000";
    constant A_INPT1:  r_adr := "1001";
    constant A_INPT2:  r_adr := "1010";
    constant A_INPT3:  r_adr := "1011";
    constant A_INPT4:  r_adr := "1100";
    constant A_INPT5:  r_adr := "1101";

end TIA_common;

package body TIA_common is

end TIA_common;
