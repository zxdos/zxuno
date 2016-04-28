-- A6500 - 6502 CPU and variants
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package types is
    -- ALU
    constant A: natural := 0;
    constant X: natural := 1;
    constant Y: natural := 2;
    constant S: natural := 3;
    constant PCL: natural := 4;
    constant PCH: natural := 5;
    constant ADL: natural := 6;
    constant DL: natural := 7;
    constant P: natural := 8;
    constant ADH: natural := 8;

    -- PC control
    constant PC_MEM: natural := 0;
    constant PC_ALU: natural := 1;
    constant PC_INC: natural := 2;

    -- Data Out control
    constant DO_ALU: natural := 0;
    constant DO_PCH: natural := 1;
    constant DO_PCL: natural := 2;
    constant DO_P: natural := 3;

    -- Address Bus
    constant PCHL: natural := 0;
    constant ADHDL: natural := 1;
    constant ADHL: natural := 2;
    constant DLADL: natural := 3;
    constant INTVEC: natural := 4;
    constant STAD: natural := 5;

    -- Flags
    constant C: natural := 0;
    constant Z: natural := 1;
    constant I: natural := 2;
    constant D: natural := 3;
    constant B: natural := 4;
    constant V: natural := 6;
    constant N: natural := 7;

    -- Flag controls
    constant FLG_ALU: natural := 0;
    constant FLG_MEM: natural := 1;
    constant FLG_ZERO: natural := 2;
    constant FLG_ONE: natural := 3;

    subtype datapath_src is bit_vector(8 downto 0);
    subtype datapath_dst is bit_vector(8 downto 0);
    subtype datapath_adr is bit_vector(5 downto 0);
    subtype datapath_pc_ctrl is bit_vector(2 downto 0);
    subtype datapath_do_ctrl is bit_vector(3 downto 0);
    subtype datapath_flg_ctrl is bit_vector(3 downto 0);
    subtype alu_fn is std_logic_vector(3 downto 0);

    constant flg_ctrl_alu: datapath_flg_ctrl := "0001";
    constant flg_ctrl_mem: datapath_flg_ctrl := "0010";
    constant flg_ctrl_zero: datapath_flg_ctrl := "0100";
    constant flg_ctrl_one: datapath_flg_ctrl := "1000";

    constant do_ctrl_alu: datapath_flg_ctrl := "0001";
    constant do_ctrl_pch: datapath_flg_ctrl := "0010";
    constant do_ctrl_pcl: datapath_flg_ctrl := "0100";
    constant do_ctrl_p: datapath_flg_ctrl := "1000";

    constant adr_pchl: datapath_adr := "000001";
    constant adr_adhdl: datapath_adr := "000010";
    constant adr_adhl: datapath_adr := "000100";
    constant adr_dladl: datapath_adr := "001000";
    constant adr_intvec: datapath_adr := "010000";
    constant adr_stad: datapath_adr := "100000";

    constant src_a: datapath_src := "000000001";
    constant src_x: datapath_src := "000000010";
    constant src_y: datapath_src := "000000100";
    constant src_s: datapath_src := "000001000";
    constant src_pcl: datapath_src := "000010000";
    constant src_pch: datapath_src := "000100000";
    constant src_adl: datapath_src := "001000000";
    constant src_dl: datapath_src := "010000000";
    constant src_p: datapath_src := "100000000";

end;
