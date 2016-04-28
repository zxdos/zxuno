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
 
 entity fsm is
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
 end;
 
 architecture behavior of fsm is
 --   state variables for machine sreg
   signal branch1, next_branch1, branch_pd, next_branch_pd, branch_pu, 
      next_branch_pu, data, next_data, data2, next_data2, data_idx, next_data_idx, 
      exec_fetch_op, next_exec_fetch_op, fetch_adh1, next_fetch_adh1, fetch_adh2, 
      next_fetch_adh2, fetch_op, next_fetch_op, fetch_op2, next_fetch_op2, 
      fetch_op_pc, next_fetch_op_pc, fetch_pch, next_fetch_pch, inc_pc, next_inc_pc
      , int_vec1, next_int_vec1, int_vec2, next_int_vec2, jmp_abs1, next_jmp_abs1, 
      jmp_abs2, next_jmp_abs2, modify, next_modify, rm_write, next_rm_write, stack,
       next_stack, stack_exec_op, next_stack_exec_op, stack_p, next_stack_p, 
      stack_pch, next_stack_pch, stack_pcl, next_stack_pcl, stack_pull, 
      next_stack_pull, zero, next_zero, zero_idx, next_zero_idx : std_logic;
 begin
   branch1_s <= branch1;
   branch_pd_s <= branch_pd;
   branch_pu_s <= branch_pu;
   data_s <= data;
   data2_s <= data2;
   data_idx_s <= data_idx;
   exec_fetch_op_s <= exec_fetch_op;
   fetch_adh1_s <= fetch_adh1;
   fetch_adh2_s <= fetch_adh2;
   fetch_op_s <= fetch_op;
   fetch_op2_s <= fetch_op2;
   fetch_op_pc_s <= fetch_op_pc;
   fetch_pch_s <= fetch_pch;
   inc_pc_s <= inc_pc;
   int_vec1_s <= int_vec1;
   int_vec2_s <= int_vec2;
   jmp_abs1_s <= jmp_abs1;
   jmp_abs2_s <= jmp_abs2;
   modify_s <= modify;
   rm_write_s <= rm_write;
   stack_s <= stack;
   stack_exec_op_s <= stack_exec_op;
   stack_p_s <= stack_p;
   stack_pch_s <= stack_pch;
   stack_pcl_s <= stack_pcl;
   stack_pull_s <= stack_pull;
   zero_s <= zero;
   zero_idx_s <= zero_idx;

   process (clk, rst, en, next_branch1, next_branch_pd, next_branch_pu, next_data
      , next_data2, next_data_idx, next_exec_fetch_op, next_fetch_adh1, 
      next_fetch_adh2, next_fetch_op, next_fetch_op2, next_fetch_op_pc, 
      next_fetch_pch, next_inc_pc, next_int_vec1, next_int_vec2, next_jmp_abs1, 
      next_jmp_abs2, next_modify, next_rm_write, next_stack, next_stack_exec_op, 
      next_stack_p, next_stack_pch, next_stack_pcl, next_stack_pull, next_zero, 
      next_zero_idx)
   begin
      if (rst = '1') then
         branch1 <= '0';
         branch_pd <= '0';
         branch_pu <= '0';
         data <= '0';
         data2 <= '0';
         data_idx <= '0';
         exec_fetch_op <= '0';
         fetch_adh1 <= '0';
         fetch_adh2 <= '0';
         fetch_op <= '0';
         fetch_op2 <= '0';
         fetch_op_pc <= '0';
         fetch_pch <= '0';
         inc_pc <= '0';
         int_vec1 <= '1';
         int_vec2 <= '0';
         jmp_abs1 <= '0';
         jmp_abs2 <= '0';
         modify <= '0';
         rm_write <= '0';
         stack <= '0';
         stack_exec_op <= '0';
         stack_p <= '0';
         stack_pch <= '0';
         stack_pcl <= '0';
         stack_pull <= '0';
         zero <= '0';
         zero_idx <= '0';
      elsif (clk = '1' and clk'event and en = '1') then
         branch1 <= next_branch1;
         branch_pd <= next_branch_pd;
         branch_pu <= next_branch_pu;
         data <= next_data;
         data2 <= next_data2;
         data_idx <= next_data_idx;
         exec_fetch_op <= next_exec_fetch_op;
         fetch_adh1 <= next_fetch_adh1;
         fetch_adh2 <= next_fetch_adh2;
         fetch_op <= next_fetch_op;
         fetch_op2 <= next_fetch_op2;
         fetch_op_pc <= next_fetch_op_pc;
         fetch_pch <= next_fetch_pch;
         inc_pc <= next_inc_pc;
         int_vec1 <= next_int_vec1;
         int_vec2 <= next_int_vec2;
         jmp_abs1 <= next_jmp_abs1;
         jmp_abs2 <= next_jmp_abs2;
         modify <= next_modify;
         rm_write <= next_rm_write;
         stack <= next_stack;
         stack_exec_op <= next_stack_exec_op;
         stack_p <= next_stack_p;
         stack_pch <= next_stack_pch;
         stack_pcl <= next_stack_pcl;
         stack_pull <= next_stack_pull;
         zero <= next_zero;
         zero_idx <= next_zero_idx;
      end if;
   end process;
 
   process (abs_0,abs_xy,acc,bpc_d,bpc_u,branch,branch1,branch_pd,branch_pu,brk
      ,c,data,data2,data_idx,exec_fetch_op,fetch_adh1,fetch_adh2,fetch_op,fetch_op2
      ,fetch_op_pc,fetch_pch,imm,inc_pc,ind_x,ind_y,int_vec1,int_vec2,jmp,jmp_abs,
      jmp_abs1,jmp_abs2,jsr,modify,pull,push,push_pull,rm_write,rmw,rti,rts,simple,
      stack,stack_exec_op,stack_p,stack_pch,stack_pcl,stack_pull,store,sub,taken,
      zero,zero_idx,zp,zp_xy)
   begin
 
      if (( branch='1' and taken='1' and  (fetch_op2='1'))) then 
         next_branch1<='1';
      else next_branch1<='0';
      end if;
 
      if (( bpc_d='1' and  (branch1='1'))) then next_branch_pd<='1';
      else next_branch_pd<='0';
      end if;
 
      if (( bpc_u='1' and  (branch1='1'))) then next_branch_pu<='1';
      else next_branch_pu<='0';
      end if;
 
      if (( abs_xy='1' and c='0' and  (fetch_adh1='1')) or ( abs_0='1' and  (
         fetch_adh1='1')) or ( ind_y='1' and c='0' and  (fetch_adh2='1')) or ( 
         ind_x='1' and  (fetch_adh2='1'))) then next_data<='1';
      else next_data<='0';
      end if;
 
      if ((  (data_idx='1')) or (( rmw='0' and store = '1' and abs_xy = '1') and (data='1'))) then next_data2<='1';
      else next_data2<='0';
      end if;
 
      if (( abs_xy='1' and c='1' and  (fetch_adh1='1')) or ( ind_y='1' and c='1' 
         and  (fetch_adh2='1'))) then next_data_idx<='1';
      else next_data_idx<='0';
      end if;
 
      if (( rmw='0' and (not (store = '1' and abs_xy = '1')) and (data='1')) or ( rmw='0' and  (data2='1')) or ( 
         simple='1' and  (fetch_op2='1')) or ( acc='1' and  (fetch_op2='1')) or ( 
         imm='1' and  (fetch_op2='1')) or ( rmw='0' and store='0' and zp='1' and  (
         zero='1')) or ( rmw='0' and store='0' and zp_xy='1' and  (zero_idx='1'))) 
         then next_exec_fetch_op<='1';
      else next_exec_fetch_op<='0';
      end if;
 
      if (( abs_xy='1' and  (fetch_op2='1')) or ( abs_0='1' and  (fetch_op2='1'))
         ) then next_fetch_adh1<='1';
      else next_fetch_adh1<='0';
      end if;
 
      if (( ind_y='1' and  (zero='1')) or ( ind_x='1' and  (zero_idx='1'))) then 
         next_fetch_adh2<='1';
      else next_fetch_adh2<='0';
      end if;
 
      if (( bpc_u='0' and bpc_d='0' and  (branch1='1')) or (  (branch_pd='1')) or
          (  (branch_pu='1')) or ( branch='1' and taken='0' and  (fetch_op2='1')) or (
           (inc_pc='1')) or (  (rm_write='1')) or ( zp='1' and store='1' and  (
         zero='1')) or ( zp_xy='1' and store='1' and  (zero_idx='1'))) then 
         next_fetch_op<='1';
      else next_fetch_op<='0';
      end if;
 
      if ((  (exec_fetch_op='1')) or (  (fetch_op='1')) or (  (fetch_op_pc='1')) 
         or (  (stack_exec_op='1'))) then next_fetch_op2<='1';
      else next_fetch_op2<='0';
      end if;
 
      if (( jmp_abs='0' and  (fetch_pch='1')) or (  (int_vec2='1')) or (  (
         jmp_abs2='1')) or ( rti='1' and  (stack_pch='1'))) then 
         next_fetch_op_pc<='1';
      else next_fetch_op_pc<='0';
      end if;
 
      if (( jmp_abs='1' and  (fetch_op2='1')) or ( jmp='1' and  (fetch_op2='1')) 
         or ( jsr='1' and  (stack_pcl='1'))) then next_fetch_pch<='1';
      else next_fetch_pch<='0';
      end if;
 
      if (( rts='1' and  (stack_pch='1'))) then next_inc_pc<='1';
      else next_inc_pc<='0';
      end if;
 
      if (( brk='1' and  (stack_p='1'))) then next_int_vec1<='1';
      else next_int_vec1<='0';
      end if;
 
      if ((  (int_vec1='1'))) then next_int_vec2<='1';
      else next_int_vec2<='0';
      end if;
 
      if (( jmp_abs='1' and  (fetch_pch='1'))) then next_jmp_abs1<='1';
      else next_jmp_abs1<='0';
      end if;
 
      if ((  (jmp_abs1='1'))) then next_jmp_abs2<='1';
      else next_jmp_abs2<='0';
      end if;
 
      if (( rmw='1' and  (data='1')) or ( rmw='1' and  (data2='1')) or ( zp='1' 
         and rmw='1' and  (zero='1')) or ( zp_xy='1' and rmw='1' and  (zero_idx='1')))
          then next_modify<='1';
      else next_modify<='0';
      end if;
 
      if ((  (modify='1'))) then next_rm_write<='1';
      else next_rm_write<='0';
      end if;
 
      if (( brk='0' and push_pull='1' and  (fetch_op2='1')) or ( brk='0' and 
         sub='1' and  (fetch_op2='1'))) then next_stack<='1';
      else next_stack<='0';
      end if;
 
      if (( push='1' and  (stack='1')) or (  (stack_pull='1'))) then 
         next_stack_exec_op<='1';
      else next_stack_exec_op<='0';
      end if;
 
      if (( rti='1' and  (stack='1')) or ( brk='1' and  (stack_pcl='1'))) then 
         next_stack_p<='1';
      else next_stack_p<='0';
      end if;
 
      if (( brk='1' and  (fetch_op2='1')) or ( jsr='1' and  (stack='1')) or ( 
         rti='1' and  (stack_pcl='1')) or ( rts='1' and  (stack_pcl='1'))) then 
         next_stack_pch<='1';
      else next_stack_pch<='0';
      end if;
 
      if (( rts='1' and  (stack='1')) or ( rti='1' and  (stack_p='1')) or ( 
         brk='1' and  (stack_pch='1')) or ( jsr='1' and  (stack_pch='1'))) then 
         next_stack_pcl<='1';
      else next_stack_pcl<='0';
      end if;
 
      if (( pull='1' and  (stack='1'))) then next_stack_pull<='1';
      else next_stack_pull<='0';
      end if;
 
      if (( zp='1' and  (fetch_op2='1')) or ( ind_y='1' and  (fetch_op2='1')) or 
         ( zp_xy='1' and  (fetch_op2='1')) or ( ind_x='1' and  (fetch_op2='1'))) then 
         next_zero<='1';
      else next_zero<='0';
      end if;
 
      if (( zp_xy='1' and  (zero='1')) or ( ind_x='1' and  (zero='1'))) then 
         next_zero_idx<='1';
      else next_zero_idx<='0';
      end if;
 
   end process;
 end behavior;
