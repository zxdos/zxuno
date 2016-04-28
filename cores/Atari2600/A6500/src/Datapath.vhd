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

entity reg is
   port(clk: in std_logic;
        en: in std_logic;
        d_in: in std_logic;
        d_out: out std_logic);
end reg;

architecture arch of reg is
    signal d: std_logic := '0';
begin

    process(d_in, clk, en)
    begin
        if (clk = '1' and clk'event and en = '1') then
            d <= d_in;
        end if;
    end process;

    d_out <= d;

end arch;

library ieee;
use ieee.std_logic_1164.all;

entity reg8 is
    port(clk: in std_logic;
         rst: in std_logic;
         en: in std_logic;
         d_in: in std_logic_vector(7 downto 0);
         d_out: out std_logic_vector(7 downto 0));
end reg8;

architecture arch of reg8 is
    signal d: std_logic_vector(7 downto 0) := "00000000";
begin

    process(d_in, clk, en)
    begin
        if (clk = '1' and clk'event) then
             if (rst = '1') then
                 d <= "00000000";
             elsif (en = '1') then
                 d <= d_in;
             end if;
        end if;
    end process;

    d_out <= d;

end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc16 is
    port(clk: in std_logic;
         load_pch: in std_logic;
         load_pcl: in std_logic;
         count: in std_logic;
         pch_in: in std_logic_vector(7 downto 0);
         pcl_in: in std_logic_vector(7 downto 0);
         pch_out: out std_logic_vector(7 downto 0);
         pcl_out: out std_logic_vector(7 downto 0));
end pc16;

architecture arch of pc16 is

    signal pc: unsigned(15 downto 0);
    signal pc_in: unsigned(15 downto 0);
    signal load: std_logic;

begin

    pch_out <= std_logic_vector(pc(15 downto 8));
    pcl_out <= std_logic_vector(pc(7 downto 0));

    pc_in(15 downto 8) <= unsigned(pch_in) when (load_pch = '1') else pc(15 downto 8);
    pc_in(7 downto 0) <= unsigned(pcl_in) when (load_pcl = '1') else pc(7 downto 0);

    load <= load_pch or load_pcl;

    process(clk, load_pch, load_pcl, count, pch_in, pcl_in)
    begin
        if (clk'event and clk = '1') then
            if (load = '1') then
                pc <= pc_in;
        elsif (count = '1') then
            pc <= pc + 1;
        end if;
    end if;
end process;

end arch;

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.types.all;

entity datapath is
    port(clk: in std_logic;
         rst: in std_logic;
         stop: in std_logic;
         de: in std_logic;
         d: inout std_logic_vector(7 downto 0);
         ad: out std_logic_vector(15 downto 0);
         src: in datapath_src;
         dst: in datapath_dst;
         adr: in datapath_adr;
         c_sel: in datapath_flg_ctrl;
         z_sel: in datapath_flg_ctrl;
         n_sel: in datapath_flg_ctrl;
         v_sel: in datapath_flg_ctrl;
         i_sel: in datapath_flg_ctrl;
         d_sel: in datapath_flg_ctrl;
         p_out: out std_logic_vector(7 downto 0);
         dl_out: out std_logic_vector(7 downto 0);
         c_out: out std_logic;
         b_in: in std_logic;
         do_sel: in datapath_do_ctrl;
         int_vec: in std_logic_vector(15 downto 0);
         adh_d: in std_logic;
         adh_rst: in std_logic;
         pch_d: in std_logic;
         pc_incr: in std_logic;
         r: in std_logic;
         fn: in alu_fn;

         a_dbg: out std_logic_vector(7 downto 0);
         x_dbg: out std_logic_vector(7 downto 0);
         y_dbg: out std_logic_vector(7 downto 0);
         s_dbg: out std_logic_vector(7 downto 0);
         pcl_dbg: out std_logic_vector(7 downto 0);
         pch_dbg: out std_logic_vector(7 downto 0);
         adl_dbg: out std_logic_vector(7 downto 0);
         adh_dbg: out std_logic_vector(7 downto 0));
end datapath;

architecture arch of datapath is

    component reg8 is
        port(clk: in std_logic;
             rst: in std_logic;
             en: in std_logic;
             d_in: in std_logic_vector(7 downto 0);
             d_out: out std_logic_vector(7 downto 0));
    end component;

    component reg is
        port(clk: in std_logic;
             en: in std_logic;
             d_in: in std_logic;
             d_out: out std_logic);
    end component;

    component pc16 is
        port(clk: in std_logic;
             load_pch: in std_logic;
             load_pcl: in std_logic;
             count: in std_logic;
             pch_in: in std_logic_vector(7 downto 0);
             pcl_in: in std_logic_vector(7 downto 0);
             pch_out: out std_logic_vector(7 downto 0);
             pcl_out: out std_logic_vector(7 downto 0));
    end component;

    component ALU is
        port(a: in std_logic_vector (7 downto 0);
             b: in std_logic_vector (7 downto 0);
             o: out std_logic_vector (7 downto 0);
             c_in: in std_logic;
             c_out: out std_logic;
             z: out std_logic;
             n: out std_logic;
             v: out std_logic;
             fn: in alu_fn;
             bcd: in std_logic);
    end component;

    signal a_o: std_logic_vector(7 downto 0);
    signal a_i: std_logic_vector(7 downto 0);
    signal a_en: std_logic;

    signal x_o: std_logic_vector(7 downto 0);
    signal x_i: std_logic_vector(7 downto 0);
    signal x_en: std_logic;

    signal y_o: std_logic_vector(7 downto 0);
    signal y_i: std_logic_vector(7 downto 0);
    signal y_en: std_logic;

    signal s_o: std_logic_vector(7 downto 0);
    signal s_i: std_logic_vector(7 downto 0);
    signal s_en: std_logic;

    signal pcl_o: std_logic_vector(7 downto 0);
    signal pcl_i: std_logic_vector(7 downto 0);
    signal pcl_en: std_logic;

    signal pch_o: std_logic_vector(7 downto 0);
    signal pch_i: std_logic_vector(7 downto 0);
    signal pch_en: std_logic;

    signal adl_o: std_logic_vector(7 downto 0);
    signal adl_i: std_logic_vector(7 downto 0);
    signal adl_en: std_logic;

    signal adh_o: std_logic_vector(7 downto 0);
    signal adh_i: std_logic_vector(7 downto 0);
    signal adh_en: std_logic;

    signal dl_o: std_logic_vector(7 downto 0);
    signal dl_i: std_logic_vector(7 downto 0);
    signal dl_en: std_logic;

    signal alu_i: std_logic_vector(7 downto 0);
    signal alu_o: std_logic_vector(7 downto 0);

    signal c_i: std_logic;
    signal c_o: std_logic;
    signal c_en: std_logic;
    signal alu_c_o: std_logic;

    signal z_i: std_logic;
    signal z_o: std_logic;
    signal z_en: std_logic;
    signal alu_z_o: std_logic;

    signal n_i: std_logic;
    signal n_o: std_logic;
    signal n_en: std_logic;
    signal alu_n_o: std_logic;

    signal v_i: std_logic;
    signal v_o: std_logic;
    signal v_en: std_logic;
    signal alu_v_o: std_logic;

    signal i_i: std_logic;
    signal i_o: std_logic;
    signal i_en: std_logic;

    signal d_i: std_logic;
    signal d_o: std_logic;
    signal d_en: std_logic;

    signal p_o: std_logic_vector(7 downto 0);

    signal pc_incr_halt: std_logic;

    signal adh_sel: std_logic_vector(2 downto 0);
    signal adh_dst: std_logic;

    signal d_int: std_logic_vector(7 downto 0);

begin

    a_reg8: reg8 port map(clk, rst, a_en, a_i, a_o);
    x_reg8: reg8 port map(clk, rst, x_en, x_i, x_o);
    y_reg8: reg8 port map(clk, rst, y_en, y_i, y_o);
    s_reg8: reg8 port map(clk, rst, s_en, s_i, s_o);
    adl_reg8: reg8 port map(clk, rst, adl_en, adl_i, adl_o);
    adh_reg8: reg8 port map(clk, rst, adh_en, adh_i, adh_o);
    dl_reg8: reg8 port map(clk, rst, dl_en, dl_i, dl_o);

    pc_pc16: pc16 port map(clk, pch_en, pcl_en, pc_incr_halt, pch_i, pcl_i, pch_o, pcl_o);

    c_reg: reg port map(clk, c_en, c_i, c_o);
    z_reg: reg port map(clk, z_en, z_i, z_o);
    n_reg: reg port map(clk, n_en, n_i, n_o);
    v_reg: reg port map(clk, v_en, v_i, v_o);
    i_reg: reg port map(clk, i_en, i_i, i_o);
    d_reg: reg port map(clk, d_en, d_i, d_o);

    pc_incr_halt <= pc_incr and not stop;

    p_o <= (n_o & v_o & "1" & b_in & d_o & i_o & z_o & c_o);
    p_out <= p_o;

    dl_out <= dl_o;

    alu_inst: ALU port map(alu_i, dl_o, alu_o, c_o, alu_c_o, alu_z_o, alu_n_o, alu_v_o, fn, d_o);

    c_out <= alu_c_o;

    with src select alu_i <=
        (a_o) when src_a,
        (x_o) when src_x,
        (y_o) when src_y,
        (s_o) when src_s,
        (pcl_o) when src_pcl,
        (pch_o) when src_pch,
        (adl_o) when src_adl,
        (dl_o) when src_dl,
        (p_o) when src_p,
        "--------" when others;

    a_i <= alu_o;
    x_i <= alu_o;
    y_i <= alu_o;
    s_i <= alu_o;
    adl_i <= alu_o;
    pch_i <= alu_o when
        (dst(PCH) = '1')
        else d;
    pcl_i <= alu_o when
        (dst(PCL) = '1')
        else d;

    adh_dst <= '1' when
        (dst(ADH) = '1')
        else '0';

    adh_sel <= adh_dst & adh_d & adh_rst;
    with adh_sel select adh_i <=
        alu_o when "100",
        d when "010",
        "00000000" when "001",
        "--------" when others;

    a_en <= '1' when
        (dst(A) = '1' and stop = '0')
        else '0';
    x_en <= '1' when
        (dst(X) = '1' and stop = '0')
        else '0';
    y_en <= '1' when
        (dst(Y) = '1' and stop = '0')
        else '0';
    s_en <= '1' when
        (dst(S) = '1' and stop = '0')
        else '0';
    adl_en <= '1' when
        (dst(ADL) = '1' and stop = '0')
        else '0';
    adh_en <= '1' when
        (dst(ADH) = '1' or adh_d = '1' or adh_rst = '1') and (stop = '0')
        else '0';
    pcl_en <= '1' when
        (dst(PCL) = '1' and stop = '0')
        else '0';
    pch_en <= '1' when
        (dst(PCH) = '1' or pch_d = '1') and (stop = '0')
        else '0';

    with do_sel select d_int <=
        alu_o when do_ctrl_alu,
        pch_o when do_ctrl_pch,
        pcl_o when do_ctrl_pcl,
        p_o when do_ctrl_p,
        "ZZZZZZZZ" when others;

    d <= d_int when (de = '1') else "ZZZZZZZZ";

    dl_i <= alu_o when
        (dst(DL) = '1')
        else d;
    dl_en <= '1' when
        (dst(DL) = '1' or r = '1') and (stop = '0')
        else '0';

    with adr select ad <=
        (pch_o & pcl_o) when adr_pchl,
        (adh_o & dl_o) when adr_adhdl,
        (adh_o & adl_o) when adr_adhl,
        (dl_o & adl_o) when adr_dladl,
        (int_vec) when adr_intvec,
        (X"01" & s_o) when adr_stad,
        "----------------" when others;

    c_en <= '1' when
        (c_sel(0) = '1' or c_sel(1) = '1' or c_sel(2) = '1' or c_sel(3) = '1') and (stop = '0')
        else '0';
    z_en <= '1' when
        (z_sel(0) = '1' or z_sel(1) = '1' or z_sel(2) = '1' or z_sel(3) = '1') and (stop = '0')
        else '0';
    n_en <= '1' when
        (n_sel(0) = '1' or n_sel(1) = '1' or n_sel(2) = '1' or n_sel(3) = '1') and (stop = '0')
        else '0';
    v_en <= '1' when
        (v_sel(0) = '1' or v_sel(1) = '1' or v_sel(2) = '1' or v_sel(3) = '1') and (stop = '0')
        else '0';
    i_en <= '1' when
        (i_sel(0) = '1' or i_sel(1) = '1' or i_sel(2) = '1' or i_sel(3) = '1') and (stop = '0')
        else '0';
    d_en <= '1' when
        (d_sel(0) = '1' or d_sel(1) = '1' or d_sel(2) = '1' or d_sel(3) = '1') and (stop = '0')
        else '0';

    with c_sel select c_i <=
        alu_c_o when flg_ctrl_alu,
        dl_o(0) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    with z_sel select z_i <=
        alu_z_o when flg_ctrl_alu,
        dl_o(1) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    with n_sel select n_i <=
        alu_n_o when flg_ctrl_alu,
        dl_o(7) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    with v_sel select v_i <=
        alu_v_o when flg_ctrl_alu,
        dl_o(6) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    with i_sel select i_i <=
        dl_o(2) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    with d_sel select d_i <=
        dl_o(3) when flg_ctrl_mem,
        '0' when flg_ctrl_zero,
        '1' when flg_ctrl_one,
        '-' when others;

    a_dbg <= a_o;
    x_dbg <= x_o;
    y_dbg <= y_o;
    s_dbg <= s_o;
    pcl_dbg <= pcl_o;
    pch_dbg <= pch_o;
    adl_dbg <= adl_o;
    adh_dbg <= adh_o;

end arch;
