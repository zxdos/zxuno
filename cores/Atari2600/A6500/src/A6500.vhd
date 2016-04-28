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

use work.types.all;

entity A6500 is 
    port(clk: in std_logic;       
         rst: in std_logic; 
         irq: in std_logic;
         nmi: in std_logic;
         stop: in std_logic;
         de: in std_logic;
         d: inout std_logic_vector(7 downto 0);
         ad: out std_logic_vector(15 downto 0);
         r: out std_logic;

         -- For debugging and running testbenches
         a_dbg: out std_logic_vector(7 downto 0);
         x_dbg: out std_logic_vector(7 downto 0);
         y_dbg: out std_logic_vector(7 downto 0);
         s_dbg: out std_logic_vector(7 downto 0);
         pcl_dbg: out std_logic_vector(7 downto 0);
         pch_dbg: out std_logic_vector(7 downto 0);
         adl_dbg: out std_logic_vector(7 downto 0);
         adh_dbg: out std_logic_vector(7 downto 0);
         p_dbg: out std_logic_vector(7 downto 0));
end A6500;

architecture arch of A6500 is

    signal ir: std_logic_vector(7 downto 0);
    signal ir_in: std_logic_vector(7 downto 0);
    signal ir_load: std_logic;
    signal ir_en: std_logic;
    signal ir_rst: std_logic;

    component reg8 is
        port(clk: in std_logic;
             rst: in std_logic;
             en: in std_logic;
             d_in: in std_logic_vector(7 downto 0);
             d_out: out std_logic_vector(7 downto 0));
    end component;

    component fsm is
        port(clk: in std_logic;
             rst: in std_logic;
             en: in std_logic;

             abs_0: in std_logic;
             abs_xy: in std_logic;
             acc: in std_logic;
             bpc_d: in std_logic;
             bpc_u: in std_logic;
             branch: in std_logic;
             brk: in std_logic;
             c: in std_logic;
             imm: in std_logic;
             ind_x: in std_logic;
             ind_y: in std_logic;
             jmp: in std_logic;
             jmp_abs: in std_logic;
             jsr: in std_logic;
             pull: in std_logic;
             push: in std_logic;
             push_pull: in std_logic;
             rmw: in std_logic;
             rti: in std_logic;
             rts: in std_logic;
             simple: in std_logic;
             store: in std_logic;
             sub: in std_logic;
             taken: in std_logic;
             zp: in std_logic;
             zp_xy: in std_logic;
             branch1_s: out std_logic;
             branch_pd_s: out std_logic;
             branch_pu_s: out std_logic;
             data_s: out std_logic;
             data2_s: out std_logic;
             data_idx_s: out std_logic;
             exec_fetch_op_s: out std_logic;
             fetch_adh1_s: out std_logic;
             fetch_adh2_s: out std_logic;
             fetch_op_s: out std_logic;
             fetch_op2_s: out std_logic;
             fetch_op_pc_s: out std_logic;
             fetch_pch_s: out std_logic;
             inc_pc_s: out std_logic;
             int_vec1_s: out std_logic;
             int_vec2_s: out std_logic;
             jmp_abs1_s: out std_logic;
             jmp_abs2_s: out std_logic;
             modify_s: out std_logic;
             rm_write_s: out std_logic;
             stack_s: out std_logic;
             stack_exec_op_s: out std_logic;
             stack_p_s: out std_logic;
             stack_pch_s: out std_logic;
             stack_pcl_s: out std_logic;
             stack_pull_s: out std_logic;
             zero_s: out std_logic;
             zero_idx_s: out std_logic);
    end component;

    component datapath is
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
    end component;

    signal abs_0: std_logic;
    signal abs_xy: std_logic;
    signal acc: std_logic;
    signal branch: std_logic;
    signal brk: std_logic;
    signal c: std_logic;
    signal imm: std_logic;
    signal ind_x: std_logic;
    signal ind_y: std_logic;
    signal jmp: std_logic;
    signal jmp_abs: std_logic;
    signal jsr: std_logic;
    signal pull: std_logic;
    signal push: std_logic;
    signal push_pull: std_logic;
    signal rmw: std_logic;
    signal rti: std_logic;
    signal rts: std_logic;
    signal simple: std_logic;
    signal store: std_logic;
    signal sub: std_logic;
    signal taken: std_logic;
    signal zp: std_logic;
    signal zp_xy: std_logic;
    signal branch1: std_logic;
    signal branch_pd: std_logic;
    signal branch_pu: std_logic;
    signal data: std_logic;
    signal data2: std_logic;
    signal data_idx: std_logic;
    signal exec_fetch_op: std_logic;
    signal fetch_adh: std_logic;
    signal fetch_adh2: std_logic;
    signal fetch_op: std_logic;
    signal fetch_op2: std_logic;
    signal fetch_op_pc: std_logic;
    signal fetch_pch: std_logic;
    signal inc_pc: std_logic;
    signal int_vec1: std_logic;
    signal int_vec2: std_logic;
    signal jmp_abs1: std_logic;
    signal jmp_abs2: std_logic;
    signal modify: std_logic;
    signal rm_write: std_logic;
    signal stack: std_logic;
    signal stack_exec_op: std_logic;
    signal stack_p: std_logic;
    signal stack_pch: std_logic;
    signal stack_pcl: std_logic;
    signal stack_pull: std_logic;
    signal zero: std_logic;
    signal zero_idx: std_logic;

    signal aaa: std_logic_vector(2 downto 0);
    signal bbb: std_logic_vector(2 downto 0);
    signal cc: std_logic_vector(1 downto 0);

    signal bit_instr: std_logic;

    signal b: std_logic;

    signal zp_x: std_logic;
    signal zp_y: std_logic;
    signal abs_x: std_logic;
    signal abs_y: std_logic;

    signal fn_sel: std_logic_vector(7 downto 0);

    signal p_o: std_logic_vector(7 downto 0);
    signal dl_o: std_logic_vector(7 downto 0);

    signal nz_sel_alu: std_logic;
    signal nz_sel_mem: std_logic;

    signal src: datapath_src;
    signal dst: datapath_dst;
    signal adr: datapath_adr;
    signal c_sel: datapath_flg_ctrl;
    signal z_sel: datapath_flg_ctrl;
    signal n_sel: datapath_flg_ctrl;
    signal v_sel: datapath_flg_ctrl;
    signal i_sel: datapath_flg_ctrl;
    signal d_sel: datapath_flg_ctrl;
    signal do_sel: datapath_do_ctrl;
    signal int_vec: std_logic_vector(15 downto 0);
    signal adh_d: std_logic;
    signal adh_rst: std_logic;
    signal pch_d: std_logic;
    signal pc_incr: std_logic;
    signal fn: alu_fn;

    signal int_vec_sel: std_logic_vector(3 downto 0);
    signal rw: std_logic;
    signal read: std_logic;
    signal fsm_en: std_logic;

    signal branch_flg: std_logic;
    signal bpc_d: std_logic;
    signal bpc_u: std_logic;

    signal nmi_old: std_logic := '1';
    signal nmi_p: std_logic := '0';
    signal nmi_l: std_logic := '0';
    signal irq_p: std_logic := '0';
    signal res_p: std_logic := '1';
    signal intr: std_logic;

begin

    a6500_datapath: datapath
        port map(clk, rst, stop, de, d, ad, src, dst, adr,
            c_sel, z_sel, n_sel, v_sel, i_sel, d_sel,
            p_o, dl_o, c, b, do_sel, int_vec, adh_d, adh_rst,
            pch_d, pc_incr, read, fn, a_dbg, x_dbg, y_dbg,
            s_dbg, pcl_dbg, pch_dbg, adl_dbg, adh_dbg);

    a6500_fsm: fsm
        port map(clk, rst, fsm_en, abs_0, abs_xy, acc,
            bpc_d, bpc_u, branch, brk, c, imm, ind_x,
            ind_y, jmp, jmp_abs, jsr, pull, push, push_pull,
            rmw, rti, rts, simple, store, sub, taken, zp,
            zp_xy, branch1, branch_pd, branch_pu, data,
            data2, data_idx, exec_fetch_op, fetch_adh,
            fetch_adh2, fetch_op, fetch_op2, fetch_op_pc,
            fetch_pch, inc_pc, int_vec1, int_vec2, jmp_abs1,
            jmp_abs2, modify, rm_write, stack, stack_exec_op,
            stack_p, stack_pch, stack_pcl, stack_pull,
            zero, zero_idx);

    ir_reg8: reg8 port map(clk, '0', ir_en, ir_in, ir);

    ir_in <= "00000000" when ir_rst = '1' else d;
    ir_en <= ir_load or ir_rst;

    -- Instruction fields
    aaa <= ir(7 downto 5);
    bbb <= ir(4 downto 2);
    cc <= ir(1 downto 0);

    ir_load <= (exec_fetch_op or fetch_op or fetch_op_pc or stack_exec_op) and not stop;
    --intr <= ir_load and ((nmi_old and not nmi) or (not irq and not p_o(I)));
    --intr <= ir_load and (irq_p or nmi_p);
    intr <= ir_load and (nmi_l or (not irq and not p_o(I)));
    ir_rst <= intr;   -- Reset to load BRK opcode.

    -- FSM Inputs (Addressing modes)
    ind_x <= '1' when (cc = "01") and (bbb = "000") else '0';
    zp <= '1' when
        (bbb = "001")  -- 16/C when cc = 00, undocumented in cc = 11
        else '0';
    imm <= '1' when
        (cc = "01" and bbb = "010") or
        (ir = X"A2" or ir = X"A0" or ir = X"C0" or ir = X"E0")  -- LDX/LDY/CPY/CPX
        else '0';
    abs_0 <= '1' when
        (bbb = "011" and jmp = '0' and jmp_abs = '0')  -- undocumented in cc = 11
        else '0';
    ind_y <= '1' when
        (cc = "01" and bbb = "100")
        else '0';
    zp_y <= '1' when
        (ir = X"96" or ir = X"B6")  -- STX/LDX
        else '0';
    zp_x <= '1' when
        (bbb = "101" and zp_y = '0')  -- 16/C when cc = 00, undocumented in cc = 11
        else '0';
    abs_y <= '1' when
        (cc = "01" and bbb = "110") or
        (ir = X"BE")  -- LDX   -- STX abs,Y?
        else '0';
    abs_x <= '1' when
        (bbb = "111" and ir /= X"BE")  -- not LDX
        -- 16/C when cc = 00, C when STX, undocumented in cc = 11
        else '0';
    acc <= '1' when
        (ir = X"0A" or ir = X"2A" or ir = X"4A" or ir = X"6A")  -- ASL/ROL/LSR/ROR A
        else '0';

    zp_xy <= zp_x or zp_y;
    abs_xy <= abs_y or abs_x;

    -- FSM Inputs (Instruction Classification)
    rmw <= '1' when
        (cc = "10" and aaa /= "100" and aaa /= "101")  -- not STX/LDX
        else '0';
    store <= '1' when
        (aaa = "100")  -- Undocumented?
        else '0';
    simple <= '1' when
        ((cc = "10" or cc = "00") and
            (bbb = "110" or  -- SEx/CLx/TYA/TXS/TSX, includes C
            (bbb = "010" and aaa(2) = '1')))  -- DEY/TAY/INY/INX/TXA/TAX/DEX/NOP
        else '0';
    push_pull <= '1' when
        (cc = "00") and (aaa(2) = '0') and (bbb = "010")
        else '0';
    sub <= '1' when
        (cc = "00") and (aaa(2) = '0') and (bbb = "000")
        else '0';
    brk <= '1' when
        (ir = "00000000")
        else '0';
    push <= '1' when
        (bbb(1) = '1' and aaa(0) = '0')
        else '0';
    pull <= '1' when
        (bbb(1) = '1' and aaa(0) = '1')
        else '0';
    jsr <= '1' when
        (bbb(1) = '0' and aaa(0) = '1' and aaa(1) = '0')
        else '0';
    rti <= '1' when
        (bbb(1) = '0' and aaa(0) = '0' and aaa(1) = '1')
        else '0';
    rts <= '1' when
        (bbb(1) = '0' and aaa(0) = '1' and aaa(1) = '1')
        else '0';
    jmp <= '1' when
        (ir = X"4C")
        else '0';
    jmp_abs <= '1' when
        (ir = X"6C")
        else '0';
    branch <= '1' when
        (cc = "00" and bbb = "100")
        else '0';
    bit_instr <= '1' when
        (ir = X"24" or ir = X"2C")
        else '0';
    b <= not (irq_p or nmi_p);

    int_vec_sel <= int_vec1 & int_vec2 & nmi_p & res_p;
    with (int_vec_sel) select int_vec <=
        X"FFFA" when "1010",
        X"FFFB" when "0110",
        X"FFFC" when "1001",
        X"FFFD" when "0101",
        X"FFFE" when "1000",
        X"FFFF" when "0100",
        "----------------" when others;

    -- Address Bus control
    adr(PCHL) <= '1' when
        (exec_fetch_op = '1') or
        (fetch_op = '1') or
        (fetch_op2 = '1') or
        (fetch_adh = '1') or
        (stack_exec_op = '1') or
        (fetch_pch = '1') or
        (branch1 = '1') or
        (branch_pd = '1') or
        (branch_pu = '1') or
        (fetch_op_pc = '1') or
        (inc_pc = '1')
        else '0';
    adr(ADHDL) <= '1' when
        (zero = '1')
        else '0';
    adr(ADHL) <= '1' when
        (zero_idx = '1') or
        (fetch_adh2 = '1') or
        (data2 = '1') or
        (modify = '1') or
        (rm_write = '1') or
        (jmp_abs2 = '1')
        else '0';
    adr(DLADL) <= '1' when
        (data = '1') or
        (data_idx = '1') or
        (jmp_abs1 = '1')
        else '0';
    adr(INTVEC) <= '1' when
        (int_vec1 = '1') or
        (int_vec2 = '1')
        else '0';
    adr(STAD) <= '1' when
        (stack = '1') or
        (stack_pull = '1') or
        (stack_pcl = '1') or
        (stack_pch = '1') or
        (stack_p = '1')
        else '0';
    adh_rst <= '1' when
        (fetch_op2 = '1')
        else '0';

    fsm_en <= not stop;

    r <= read;
    read <= (stack and not push) or
        ((not (stack or stack_pcl or stack_pch or stack_p)) and rw) or
        ((stack_pcl or stack_pch or stack_p) and not (jsr or brk));

    rw <= not (((data or data2 or (zero and zp) or (zero_idx and zp_xy)) and store) or modify or rm_write);

    pc_incr <= not intr and
        (fetch_adh or exec_fetch_op or fetch_op or stack_exec_op or   -- Next: fetch_op2
        fetch_op_pc or fetch_pch or inc_pc or
        (fetch_op2 and not (simple or acc or push_pull or irq_p or nmi_p)));

    -- ALU Source
    src(A) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01") or
            (acc = '1') or
            (ir = X"24" or ir = X"2C") or  -- BIT
            (ir = X"A8" or ir = X"AA"))) or -- TAY/TAX
        (zero = '1' and ir = X"85") or  -- STA zp
        (zero_idx = '1' and ir = X"95") or   -- STA zp, X
        (data = '1' and cc = "01" and aaa = "100" and abs_xy = '0') or  -- STA
        (data2 = '1' and cc = "01" and aaa = "100") or  -- STA
        (stack = '1' and push = '1' and aaa(1) = '1')  -- PHA
        else '0';

    src(X) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "10" and aaa = "100") or  -- TXA/TXS, includes 16/C/STX
            (cc = "00" and aaa = "111" and bbb(2) = '0') or  -- CPX/INX
            (ir = X"CA"))) or  -- DEX
        (zero = '1' and (ind_x = '1' or zp_x = '1')) or
        (zero = '1' and ir = X"86") or  -- -- STX zp
        (zero_idx = '1' and ir = X"96") or   -- STX zp, Y
        (data = '1' and cc = "10" and aaa = "100" and abs_xy = '0') or  -- STX
        (data2 = '1' and cc = "10" and aaa = "100") or  -- STX
        (fetch_adh = '1' and abs_x = '1')
        else '0';

    src(Y) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "00" and (aaa = "100" or aaa = "110") and bbb(2) = '0') or  -- STY/CPY/INY/DEY, STY imm is C
            (ir = X"98"))) or   -- TYA
        (zero = '1' and zp_y = '1') or
        (zero = '1' and ir = X"84") or  -- -- STY zp
        (zero_idx = '1' and ir = X"94") or   -- STY zp, X
        (data = '1' and cc = "00" and aaa = "100" and abs_xy = '0') or  -- STY
        (data2 = '1' and cc = "00" and aaa = "100") or  -- STY
        (fetch_adh = '1' and abs_y = '1') or
        (fetch_adh2 = '1' and ind_y = '1')
        else '0';

    src(S) <= '1' when
        (exec_fetch_op = '1' and ir = X"BA") or  -- TSX
        (stack_exec_op = '1' and push = '1') or  -- PHx
        (stack = '1' and push = '0' and jsr = '0') or
        (stack_pcl = '1') or
        (stack_pch = '1' and (jsr = '1' or brk = '1')) or
        (stack_p = '1')
        else '0';

    src(PCL) <= '1' when
        (branch1 = '1')
        else '0';

    src(PCH) <= '1' when
        (branch_pd = '1') or
        (branch_pu = '1')
        else '0';

    src(ADL) <= '1' when
        (zero_idx = '1' and ind_x = '1') or
        (jmp_abs1 = '1') or
        (fetch_pch = '1' and jsr = '1')
        else '0';

    src(DL) <= '1' when
        (exec_fetch_op = '1' and
            (cc = "10" and
            (aaa /= "100") and  -- STX
            (bbb /= "010" and bbb /= "100" and bbb /= "110"))) or  -- TXS/TSX, unavailable addr. modes (C)
        (stack_exec_op = '1' and pull = '1') or
        (stack = '1' and jsr = '1') or
        (stack_pch = '1' and (rts = '1' or rti = '1')) or
        (fetch_pch = '1' and (jmp = '1' or jmp_abs = '1')) or
        (jmp_abs2 = '1') or
        (rm_write = '1') or
        (zero = '1' and ind_y = '1') or
        (data_idx = '1') or
        (data = '1' and (store = '0' or (store = '1' and abs_xy = '1'))) or
        (modify = '1')
        else '0';

    src(P) <= '1' when
        (stack = '1' and push = '1' and aaa(1) = '0')  -- PHP
        else '0';

    -- ALU Destination
    dst(A) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01" and aaa /= "110") or  -- not CMP  -- STA?
            (acc = '1') or
            (ir = X"98" or ir = X"8A"))) or  -- TYA/TXA
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '1')  -- PLA
        else '0';

    dst(X) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "10" and aaa = "101") or  -- LDX/TAX/TSX, C when bbb = 100
            (ir = X"E8" or ir = X"CA")))    -- INX/DEX
        else '0';

    dst(Y) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "00" and aaa = "101" and bbb /= "100" and bbb /= "110") or  -- LDY/TAY
            (ir = X"88" or ir = X"C8")))  -- DEY/INY
        else '0';

    dst(S) <= '1' when
        (exec_fetch_op = '1' and ir = X"9A") or  -- TXS
        (stack = '1' and push = '0' and jsr = '0') or
        (stack_exec_op = '1' and push = '1') or  -- PHx
        (stack_pcl = '1') or
        (stack_pch = '1' and (jsr = '1' or brk = '1')) or
        (stack_p = '1')
        else '0';

    dst(PCL) <= '1' when
        (branch1 = '1') or
        (jmp_abs2 = '1') or
        (fetch_pch = '1' and (jmp = '1' or jsr = '1')) or
        (stack_pch = '1' and (rts = '1' or rti = '1')) or
        (int_vec2 = '1')
        else '0';

    dst(PCH) <= '1' when
        (branch_pd = '1') or
        (branch_pu = '1')
        else '0';

    pch_d <= '1' when
        (int_vec2 = '1') or
        (jmp_abs2 = '1') or
        (fetch_pch = '1' and jmp_abs = '0') or
        (stack_pch = '1' and (rts = '1' or rti = '1'))
        else '0';

    dst(ADL) <= '1' when
        (zero = '1' and not (store = '1' and zp = '1')) or
        (zero_idx = '1' and ind_x = '1') or
        (stack = '1' and jsr = '1') or
        (fetch_pch = '1' and jmp_abs = '1') or
        (fetch_adh = '1') or
        (fetch_adh2 = '1') or
        (jmp_abs1 = '1')
        else '0';

    dst(ADH) <= '1' when
        (data = '1' and (store = '0' or (store = '1' and abs_xy = '1'))) or
        (data_idx = '1')
        else '0';

    dst(DL) <= '1' when
        (modify = '1')
        else '0';

    do_sel(DO_PCH) <= '1' when
        (stack_pch = '1') and (jsr = '1' or brk = '1')
        else '0';
    do_sel(DO_PCL) <= '1' when
        (stack_pcl = '1') and (jsr = '1' or brk = '1')
        else '0';
    do_sel(DO_P) <= '1' when
        (stack_p = '1' and brk = '1')
        else '0';
    do_sel(DO_ALU) <= '1' when
        (rw = '0') or (stack = '1' and push = '1')
        else '0';

    adh_d <= '1' when
        (fetch_pch = '1' and jmp_abs = '1')
        else '0';

    -- ALU Functions
    with fn_sel select fn <=
        ('0' & aaa) when "00000001",
        ('1' & aaa) when "00000010",
        "0110" when "00000100",  -- CMP
        "1110" when "00001000",  -- DEC
        "1111" when "00010000",  -- INC
        "1101" when "00100000",  -- ADD
        "0101" when "01000000",  -- LDx (NOP)
        "0100" when "10000000",  -- STx (NOP)
        "----" when others;

    fn_sel(0) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01") or
            ((cc = "00" or cc = "10") and (aaa = "101") and
                not (bbb = "010" or bbb = "100" or bbb = "110")) or  -- LDX/LDY, includes 16/C
           (bit_instr = '1')))  -- BIT
        else '0';
    fn_sel(1) <= '1' when
    (modify = '1') or
        (exec_fetch_op = '1' and acc = '1')
        else '0';
    fn_sel(2) <= '1' when
        (exec_fetch_op = '1' and
            (cc = "00") and
            (aaa = "110" or aaa = "111") and
            (bbb = "000" or bbb = "001" or bbb = "011"))  -- CPX/CPY
        else '0';
    fn_sel(3) <= '1' when
        (exec_fetch_op = '1' and (ir = X"CA" or ir = X"88")) or  -- DEX/DEY
        (stack_exec_op = '1' and push = '1') or
        ((stack_pcl = '1' or stack_pch = '1' or stack_p = '1') and
            (jsr = '1' or brk = '1')) or
        (branch_pd = '1')
        else '0';
    fn_sel(4) <= '1' when
        (exec_fetch_op = '1' and (ir = X"E8" or ir = X"C8")) or  -- INX/INY
        (zero = '1' and ind_y = '1') or
        (zero_idx = '1' and ind_x = '1') or
        (data_idx = '1') or
        ((stack = '1' or stack_pcl = '1' or stack_p = '1') and
            (rts = '1' or rti = '1' or pull = '1')) or
        (jmp_abs1 = '1') or
        (branch_pu = '1')
        else '0';
    fn_sel(5) <= '1' when
        (zero = '1' and (ind_x = '1' or zp_xy = '1')) or
        (fetch_adh = '1' and abs_xy = '1') or
        (fetch_adh2 = '1' and ind_y = '1') or
        (branch1 = '1')
        else '0';
    fn_sel(6) <= '1' when
        (fetch_adh = '1' and abs_0 = '1') or
        (fetch_adh2 = '1' and ind_x = '1') or
        (zero = '1' and zp = '1' and store = '0') or
        (data = '1' and (store = '0' or (store = '1' and abs_xy = '1'))) or
        (int_vec2 = '1') or
        (stack_exec_op = '1' and pull = '1')
        else '0';

    -- It seems that there are very few cases where we do not care about what the ALU does, if at all.
    -- So, the following assigns NOP by default to the ALU. We do not use "when others" because
    -- that also takes into account the cases where multiple members of the fn_sel vector are 1.
    -- These take care of most transfer instructions.
    fn_sel(7) <= not (fn_sel(0) or fn_sel(1) or fn_sel(2) or fn_sel(3) or fn_sel(4) or fn_sel(5) or fn_sel(6));

    c_sel(FLG_ALU) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01" and
                (aaa = "011" or aaa = "110" or aaa = "111")) or  -- ADC/CMP/SBC
            (cc = "00" and
                (aaa = "110" or aaa = "111") and bbb /= "010" and bbb /= "110") or  -- CPX/CPY
            (acc = '1'))) or
        (modify = '1' and (
            (cc = "10") and aaa(2) /= '1'))  -- ASL/LSR/ROL/ROR
        else '0';
    c_sel(FLG_MEM) <= '1' when
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '0') or -- PLP
        (stack_pcl = '1' and rti = '1')
        else '0';
    c_sel(FLG_ZERO) <= '1' when
        (exec_fetch_op = '1' and ir = X"18")  -- CLC
        else '0';
    c_sel(FLG_ONE) <= '1' when
        (exec_fetch_op = '1' and ir = X"38")  -- SEC
        else '0';

    nz_sel_alu <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01" and aaa /= "100") or -- not STA
            (ir = X"8A" or ir = X"BA" or ir = X"88" or ir = X"98") or  -- TXA/TSX/DEY/TYA
            (ir = X"AA" or ir = X"A8") or  -- TAX/TAY
            (cc = "00" and
                (aaa = "101" or aaa = "110" or aaa = "111") and  -- LDY/CPY/CPX
                not (bbb = "100" or bbb = "110")) or  -- unavailable modes, includes 16
            (cc = "10" and
                (aaa = "101") and  -- LDX
                not (bbb = "010" or bbb = "110")) or
            (ir = X"CA") or  -- DEX
            (acc = '1'))) or
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '1') or  -- PLA
        (modify = '1')
        else '0';

    nz_sel_mem <= '1' when
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '0') or  -- PLP
        (stack_pcl = '1' and rti = '1')
        else '0';

    n_sel(FLG_ALU) <= '1' when
        (nz_sel_alu = '1')
        else '0';
    n_sel(FLG_MEM) <= '1' when
        (nz_sel_mem = '1' or bit_instr = '1')
        else '0';
    n_sel(FLG_ZERO) <= '0';
    n_sel(FLG_ONE) <= '0';

    z_sel(FLG_ALU) <= '1' when
        (nz_sel_alu = '1' or bit_instr = '1')
        else '0';
    z_sel(FLG_MEM) <= '1' when
        (nz_sel_mem = '1')
        else '0';
    z_sel(FLG_ZERO) <= '0';
    z_sel(FLG_ONE) <= '0';

    v_sel(FLG_ALU) <= '1' when
        (exec_fetch_op = '1' and (
            (cc = "01" and (aaa = "011" or aaa = "111"))))  -- ADC/CMP/SBC
        else '0';
    v_sel(FLG_MEM) <= '1' when
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '0') or  -- PLP
        (stack_pcl = '1' and rti = '1') or
        (ir = X"24" or ir = X"2C")  -- BIT
        else '0';
    v_sel(FLG_ZERO) <= '1' when
        (exec_fetch_op = '1' and ir = X"B8")  -- CLV
        else '0';
    v_sel(FLG_ONE) <= '0';

    i_sel(FLG_ALU) <= '0';
    i_sel(FLG_MEM) <= '1' when
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '0') or  -- PLP
        (stack_pcl = '1' and rti = '1')
        else '0';
    i_sel(FLG_ZERO) <= '1' when
        (exec_fetch_op = '1' and ir = X"58")  -- CLI
        else '0';
    i_sel(FLG_ONE) <= '1' when
        (exec_fetch_op = '1' and ir = X"78") or  -- SEI
        (int_vec2 = '1')
        else '0';

    d_sel(FLG_ALU) <= '0';
    d_sel(FLG_MEM) <= '1' when
        (stack_exec_op = '1' and pull = '1' and aaa(1) = '0') or  -- PLP
        (stack_pcl = '1' and rti = '1')
        else '0';
    d_sel(FLG_ZERO) <= '1' when
        (exec_fetch_op = '1' and ir = X"D8")  -- CLD
        else '0';
    d_sel(FLG_ONE) <= '1' when
        (exec_fetch_op = '1' and ir = X"F8")  -- SED
        else '0';

    with ir(7 downto 6) select branch_flg <=
        p_o(7) when "00",
        p_o(6) when "01",
        p_o(0) when "10",
        p_o(1) when "11",
        '-' when others;

    taken <= '1' when
        (branch_flg = ir(5))
        else '0';

    bpc_u <= '1' when
        (dl_o(7) = '0' and c = '1')
        else '0';
    bpc_d <= '1' when
        (dl_o(7) = '1' and c = '0')
        else '0';

    -- Interrupt logic
    process(clk, rst, nmi, fetch_op, exec_fetch_op, fetch_op_pc,
            stack_exec_op, fetch_op2, nmi_p, irq, p_o)
    begin
        if (clk = '1' and clk'event) then
            if (rst = '1') then
                nmi_p <= '0';
                irq_p <= '0';
                res_p <= '1';
                nmi_old <= '1';
                nmi_l <= '0';
            else
                nmi_old <= nmi;

                if (nmi_l = '0' and nmi_old = '1' and nmi = '0') then
                    nmi_l <= '1';
                elsif (fetch_op = '1' or
                         exec_fetch_op = '1' or
                         fetch_op_pc = '1' or
                         stack_exec_op = '1')
                        and (stop = '0') then
                    nmi_l <= '0';
                end if;

                if (fetch_op = '1' or
                    exec_fetch_op = '1' or
                    fetch_op_pc = '1' or
                    stack_exec_op = '1')
                    and (stop = '0') then
                    -- Next state: fetch_op2

                    if (nmi_l = '1') then
                        nmi_p <= '1';
                        irq_p <= '0';
                    elsif (irq = '0' and p_o(I) = '0') then
                        nmi_p <= '0';
                        irq_p <= '1';
                    else
                        nmi_p <= '0';
                        irq_p <= '0';
                    end if;
                    res_p <= '0';
                end if;
            end if;
        end if;

    end process;

    p_dbg <= p_o;

end arch;



