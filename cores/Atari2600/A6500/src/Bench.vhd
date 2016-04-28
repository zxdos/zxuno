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

library std;
use std.textio.all; 

library ieee;
use ieee.std_logic_1164.all;       
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all; 

entity bench is             
end bench;

architecture bench of bench is

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
    
    -- Flags
    constant C: natural := 0;
    constant Z: natural := 1;
    constant B: natural := 4;
    constant V: natural := 6;
    constant N: natural := 7;   

    component A6500 is
        port(clk: in std_logic;
             rst: in std_logic;
             irq: in std_logic;
             nmi: in std_logic;
             stop: in std_logic;
             d: inout std_logic_vector(7 downto 0);
             ad: out std_logic_vector(15 downto 0);
             r: out std_logic;

             a_dbg: out std_logic_vector(7 downto 0);
             x_dbg: out std_logic_vector(7 downto 0);
             y_dbg: out std_logic_vector(7 downto 0);
             s_dbg: out std_logic_vector(7 downto 0);
             pcl_dbg: out std_logic_vector(7 downto 0);
             pch_dbg: out std_logic_vector(7 downto 0);
             adl_dbg: out std_logic_vector(7 downto 0);
             adh_dbg: out std_logic_vector(7 downto 0);
             p_dbg: out std_logic_vector(7 downto 0));
    end component;

    signal clk: std_logic;
    signal rst: std_logic;
    signal irq: std_logic;
    signal nmi: std_logic;
    signal stop: std_logic;

    signal d: std_logic_vector(7 downto 0);
    signal ad: std_logic_vector(15 downto 0);
    signal r: std_logic;

    signal a_dbg: std_logic_vector(7 downto 0);
    signal x_dbg: std_logic_vector(7 downto 0);
    signal y_dbg: std_logic_vector(7 downto 0);
    signal s_dbg: std_logic_vector(7 downto 0);
    signal pcl_dbg: std_logic_vector(7 downto 0);
    signal pch_dbg: std_logic_vector(7 downto 0);
    signal adl_dbg: std_logic_vector(7 downto 0);
    signal adh_dbg: std_logic_vector(7 downto 0);
    signal p_dbg: std_logic_vector(7 downto 0);

    constant clk_period : time := 100 ns;
    constant rst_vec: std_logic_vector(15 downto 0) := X"A0F0";
    constant irq_vec: std_logic_vector(15 downto 0) := X"B0E0";
    constant nmi_vec: std_logic_vector(15 downto 0) := X"C0D0";

    shared variable pc: std_logic_vector(15 downto 0);
    shared variable last_adr: std_logic_vector(15 downto 0);

    shared variable ss_a: std_logic_vector(7 downto 0);
    shared variable ss_x: std_logic_vector(7 downto 0);
    shared variable ss_y: std_logic_vector(7 downto 0);
    shared variable ss_p: std_logic_vector(7 downto 0);
    shared variable ss_s: std_logic_vector(7 downto 0);

    shared variable op, i, j, k, l, m: natural;

    type imm_operands_array is array(0 to 31) of std_logic_vector(7 downto 0);
    constant imm_operands : imm_operands_array := (X"00", X"01", X"03", X"05", X"07", X"09", X"10", X"12", X"14", X"16", X"17",
                                                   X"30", X"31", X"33", X"36", X"37", X"39", X"40", X"43", X"44", X"46", X"48",
                                                   X"70", X"72", X"73", X"74", X"77", X"79", X"90", X"92", X"94", X"99");

    type adr_operands_array is array(0 to 1) of std_logic_vector(7 downto 0);
    constant adr_operands : adr_operands_array := (X"40", X"F0");

    type ad_operands_array is array(0 to 1) of std_logic_vector(15 downto 0);
    constant ad_operands : ad_operands_array := (X"4060", X"F030");

    type alu_01_opcodes_array is array(0 to 6) of std_logic_vector(2 downto 0);
    constant alu_01_opcodes : alu_01_opcodes_array := (b"000", b"001", b"010", b"011", b"101", b"110", b"111");

    type alu_10_opcodes_array is array(0 to 5) of std_logic_vector(2 downto 0);
    constant alu_10_opcodes : alu_10_opcodes_array := (b"000", b"001", b"010", b"011", b"110", b"111");

    procedure assert_report(
        constant cond: in boolean;
        constant ir: in std_logic_vector(7 downto 0);
        constant msg: in string
        ) is

        variable l: line;

    begin
        if (not cond) then
           write(l, msg);
            write(l, string'(" Instruction: "));
            hwrite(l, ir);
            writeline(output, l);
        end if;

        assert cond;
    end assert_report;

    procedure status_report(
        constant msg: in string
        ) is

        variable l: line;

    begin
       write(l, msg);
        writeline(output, l);
    end status_report;

    procedure increment_pc is
    begin
        pc := pc + 1;
    end procedure increment_pc;

    procedure jump_pc(
        constant new_pc: in std_logic_vector(15 downto 0)
    ) is
    begin
        pc := new_pc;
    end procedure jump_pc;

    procedure load_A(
        signal d: out std_logic_vector(7 downto 0);
        constant v: in std_logic_vector(7 downto 0)
        ) is

    begin
        d <= X"A9";
        increment_pc;
        wait for clk_period;
        d <= v;
        increment_pc;
        wait for clk_period;
    end procedure load_A;

    procedure load_X(
        signal d: out std_logic_vector(7 downto 0);
        constant v: in std_logic_vector(7 downto 0)
        ) is

    begin
        d <= X"A2";
        increment_pc;
        wait for clk_period;
        d <= v;
        increment_pc;
        wait for clk_period;
    end procedure load_X;

    procedure load_Y(
        signal d: out std_logic_vector(7 downto 0);
        constant v: in std_logic_vector(7 downto 0)
        ) is

    begin
        d <= X"A0";
        increment_pc;
        wait for clk_period;
        d <= v;
        increment_pc;
        wait for clk_period;
    end procedure load_Y;

   procedure nop(
        signal d: out std_logic_vector(7 downto 0)
        ) is
    begin
        d <= X"EA";
        increment_pc;
        wait for clk_period;
        wait for clk_period;
    end procedure nop;

    procedure test_imm_mode(
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;
    end procedure test_imm_mode;

    procedure test_zp_mode(
        constant adr: in std_logic_vector(7 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is
    begin   
        d <= adr;
        assert_report((ad = pc) and (r = '1'), ir, "Zero page mode failed: ad != pc.");
        increment_pc;
        wait for clk_period; 
        assert_report((ad = ("00000000" & adr)), ir, "Zero page mode failed: ad != (00, adr).");
        last_adr := ("00000000" & adr);     
    end procedure test_zp_mode;
    
    procedure test_zp_idx_mode(
        constant adr: in std_logic_vector(7 downto 0);
        constant idx: in std_logic_vector(7 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is      
    begin
        d <= adr;
        assert_report((ad = pc) and (r = '1'), ir, "Zero page mode failed: (ad != pc).");
        increment_pc;
        wait for clk_period; 
        assert_report((ad = ("00000000" & adr)) and (r = '1'), ir, "Indexed zero page mode failed: ad != (00, adr)");
        wait for clk_period;
        assert_report((ad = ("00000000" & (adr + idx))), 
            ir, "Indexed zero page mode failed: ad != (00, adr + idx)");
        last_adr := ("00000000" & (adr + idx));
    end procedure test_zp_idx_mode;
    
    procedure test_abs_mode(
        constant adr: in std_logic_vector(15 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is      
    begin
        d <= adr(7 downto 0);
        assert_report((ad = pc) and (r = '1'), ir, "Absolute mode failed: ad != pc.");
        increment_pc;
        wait for clk_period; 
        d <= adr(15 downto 8);
        assert_report((ad = pc) and (r = '1'), ir, "Absolute mode failed: ad != pc.");
        increment_pc;
        wait for clk_period;
        assert_report((ad = adr), ir, "Absolute mode failed: ad != adr");
        last_adr := adr;
    end procedure test_abs_mode;

    procedure test_abs_idx_mode(
        constant adr: in std_logic_vector(15 downto 0);
        constant idx: in std_logic_vector(7 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is      
        
        variable sum: std_logic_vector(8 downto 0);     
        
    begin
        sum := ('0' & adr(7 downto 0)) + ('0' & idx);       
        
        d <= adr(7 downto 0);
        assert_report((ad = pc) and (r = '1'), ir, "Zero page mode failed: ad != pc.");
        increment_pc;
        wait for clk_period; 
        d <= adr(15 downto 8);
        assert_report((ad = pc) and (r = '1'), ir, "Zero page mode failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = (adr(15 downto 8) & sum(7 downto 0))), 
            ir, "Indexed absolute mode failed: ad != (adr + idx).");
        last_adr := (adr(15 downto 8) & sum(7 downto 0));
        if (sum(8) = '1') then 
           wait for clk_period;
            assert_report((ad = (adr + ("00000000" & idx))), 
                ir, "Indexed absolute mode failed: ad != (adr + idx), (page crossing).");
            last_adr := (adr + ("00000000" & idx));
        end if;         
    end procedure test_abs_idx_mode;

    procedure test_ind_x_mode(
        constant bal: in std_logic_vector(7 downto 0);
        constant adr: in std_logic_vector(15 downto 0);
        constant idx: in std_logic_vector(7 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is      
    begin
        d <= bal;
        assert_report((ad = pc) and (r = '1'), ir, "Zero page mode failed: ad != pc.");
        increment_pc;
        wait for clk_period; 
        assert_report((ad = ("00000000" & bal)) and (r = '1'), ir, "Indirect X mode failed.");
        wait for clk_period;
        assert_report((ad = ("00000000" & (bal + idx))) and (r = '1'), ir, "Indirect X mode failed.");
        d <= adr(7 downto 0);
        wait for clk_period;
        assert_report((ad = ("00000000" & (bal + idx + 1))) and (r = '1'), ir, "Indirect X mode failed.");
        d <= adr(15 downto 8);
        wait for clk_period;
        assert_report((ad = adr), ir, "Indirect X mode failed.");
        last_adr := adr;
    end procedure test_ind_x_mode;

    procedure test_ind_y_mode(
        constant ial: in std_logic_vector(7 downto 0);
        constant adr: in std_logic_vector(15 downto 0);
        constant idx: in std_logic_vector(7 downto 0);
       constant ir: in std_logic_vector(7 downto 0);
        signal d: out std_logic_vector(7 downto 0)
        ) is      
        
        variable sum: std_logic_vector(8 downto 0);     
        
    begin   
        sum := ('0' & adr(7 downto 0)) + ('0' & idx);   

        d <= ial;
        assert_report((ad = pc) and (r = '1'), ir, "Indirect Y mode failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = ("00000000" & ial)) and (r = '1'), ir, "Indirect Y mode failed: ad != (00, ial).");
        d <= adr(7 downto 0);
        wait for clk_period;        
        assert_report((ad = ("00000000" & (ial + 1))) and (r = '1'), 
            ir, "Indirect Y mode failed: ad != (00, ial + 1).");
        d <= adr(15 downto 8);
        wait for clk_period;
        assert_report((ad = (adr(15 downto 8) & sum(7 downto 0))), 
            ir, "Indirect Y mode failed: ad != (adr + idx).");
        last_adr := (adr(15 downto 8) & sum(7 downto 0));
        if (sum(8) = '1') then 
           wait for clk_period;
            assert_report((ad = (adr + ("00000000" & idx))), 
                ir, "Indirect Y mode failed: ad != (adr + idx), (page crossing).");
            last_adr := (adr + ("00000000" & idx));
        end if;         
        
    end procedure test_ind_y_mode;

    procedure reset_cpu(
        signal rst: out std_logic;
        signal d: out std_logic_vector(7 downto 0)
        ) is      
    begin
        rst <= '1';
        wait for 5 * clk_period / 2;
        rst <= '0';

        assert (ad = X"FFFC") and (r = '1') report "CPU initialization failed.";
        d <= rst_vec(7 downto 0);
        wait for clk_period;
        assert (ad = X"FFFD") and (r = '1') report "CPU initialization failed.";
        d <= rst_vec(15 downto 8);
        wait for clk_period;
        assert (ad = rst_vec) and (r = '1') report "CPU initialization failed.";                
        
        jump_pc(rst_vec);
    end procedure reset_cpu;
    
    procedure sample_cpu_state is
    begin
        ss_a := a_dbg;
        ss_x := x_dbg;
        ss_y := y_dbg;
        ss_p := p_dbg;
        ss_s := s_dbg;
    end procedure sample_cpu_state;

    procedure test_nop(
        signal d: out std_logic_vector(7 downto 0)
        ) is 
    begin
        sample_cpu_state;
        
        d <= X"EA";
        assert_report((ad = pc) and (r = '1'), X"EA", "NOP failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"EA", "NOP failed: ad != pc.");     
        wait for clk_period;
        d <= X"EA";
        assert_report((ad = pc) and (r = '1'), X"EA", "NOP failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"EA", "NOP failed: ad != pc.");
        assert_report((ss_a = a_dbg), X"EA", "NOP failed: ss_a != a.");
        assert_report((ss_x = x_dbg), X"EA", "NOP failed: ss_x != x.");
        assert_report((ss_y = y_dbg), X"EA", "NOP failed: ss_y != y.");     
        assert_report((ss_p = p_dbg), X"EA", "NOP failed: ss_p != p.");
        wait for clk_period;                
    end procedure test_nop;
    
    procedure test_clsec(
        signal d: out std_logic_vector(7 downto 0)
        ) is 
    begin
        sample_cpu_state;
        
        d <= X"38";
        assert_report((ad = pc) and (r = '1'), X"38", "SEC failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"38", "SEC failed: ad != pc.");             
        wait for clk_period;
        d <= X"18";
        assert_report((ad = pc) and (r = '1'), X"18", "CLC failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"18", "CLC failed: ad != pc.");             
        
        assert_report((ss_a = a_dbg), X"38", "SEC failed: ss_a != a.");
        assert_report((ss_x = x_dbg), X"38", "SEC failed: ss_x != x.");
        assert_report((ss_y = y_dbg), X"38", "SEC failed: ss_y != y.");
        assert_report((p_dbg = ss_p(7 downto 1) & '1'), X"38", "SEC failed: C != 1.");      
        wait for clk_period;                        
        nop(d);     
        assert_report((ss_a = a_dbg), X"18", "CLC failed: ss_a != a.");
        assert_report((ss_x = x_dbg), X"18", "CLC failed: ss_x != x.");
        assert_report((ss_y = y_dbg), X"18", "CLC failed: ss_y != y.");
        assert_report((p_dbg = ss_p(7 downto 1) & '0'), X"18", "CLC failed: C != 0.");
    end procedure test_clsec;
    
    procedure test_clsed(
        signal d: out std_logic_vector(7 downto 0)
        ) is 
    begin
        sample_cpu_state;
        
        d <= X"F8";
        assert_report((ad = pc) and (r = '1'), X"F8", "SED failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"F8", "SED failed: ad != pc.");             
        wait for clk_period;
        d <= X"D8";
        assert_report((ad = pc) and (r = '1'), X"D8", "CLD failed: ad != pc.");
        increment_pc;
        wait for clk_period;        
        assert_report((ad = pc) and (r = '1'), X"D8", "CLD failed: ad != pc.");             
        
        assert_report((ss_a = a_dbg), X"F8", "SED failed: ss_a != a.");
        assert_report((ss_x = x_dbg), X"F8", "SED failed: ss_x != x.");
        assert_report((ss_y = y_dbg), X"F8", "SED failed: ss_y != y.");
        assert_report((p_dbg = ss_p(7 downto 4) & '1' & ss_p(2 downto 0)), X"F8", "SED failed: D != 1.");       
        wait for clk_period;                        
        nop(d);     
        assert_report((ss_a = a_dbg), X"D8", "CLD failed: ss_a != a.");
        assert_report((ss_x = x_dbg), X"D8", "CLD failed: ss_x != x.");
        assert_report((ss_y = y_dbg), X"D8", "CLD failed: ss_y != y.");
        assert_report((p_dbg = ss_p(7 downto 4) & '0' & ss_p(2 downto 0)), X"D8", "CLD failed: D != 0.");
    end procedure test_clsed;
    
    procedure test_load_imm(
        signal d: out std_logic_vector(7 downto 0)
        ) is                    
        
    begin
        
        d <= X"A9";
        assert_report((ad = pc) and (r = '1'), X"A9", "Load immediate failed: ad != pc.");
        increment_pc;
        wait for clk_period;
        d <= imm_operands(0);
        assert_report((ad = pc) and (r = '1'), X"A9", "Load immediate failed: ad != pc.");
        increment_pc;           
        wait for clk_period;
    
        for i in 1 to (imm_operands'length - 1) loop
            d <= X"A9";
            assert_report((ad = pc) and (r = '1'), X"A9", "Load immediate failed: ad != pc.");
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            d <= imm_operands(i);
            assert_report(a_dbg = imm_operands(i - 1), X"A9", "Load immediate failed: a != imm");
            assert_report(x_dbg = ss_x, X"A9", "Load immediate failed: x != ss_x");         
            assert_report(y_dbg = ss_y, X"A9", "Load immediate failed: y != ss_y");
            assert_report((ad = pc), X"A9", "Load immediate failed: ad != pc.");
            increment_pc;           
            wait for clk_period;            
        end loop;
        
        d <= X"A2";
        assert_report((ad = pc) and (r = '1'), X"A2", "Load immediate failed: ad != pc.");
        increment_pc;
        wait for clk_period;
        d <= imm_operands(0);
        assert_report((ad = pc) and (r = '1'), X"A2", "Load immediate failed: ad != pc.");
        increment_pc;           
        wait for clk_period;
    
        for i in 1 to (imm_operands'length - 1) loop
            d <= X"A2";
            assert_report((ad = pc) and (r = '1'), X"A2", "Load immediate failed: ad != pc.");
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            d <= imm_operands(i);
            assert_report(a_dbg = ss_a, X"A2", "Load immediate failed: a != ss_a");
            assert_report(x_dbg = imm_operands(i - 1), X"A2", "Load immediate failed: x != imm");
            assert_report(y_dbg = ss_y, X"A2", "Load immediate failed: y != ss_y");                     
            assert_report((ad = pc), X"A2", "Load immediate failed: ad != pc.");
            increment_pc;           
            wait for clk_period;            
        end loop;
        
        d <= X"A0";
        assert_report((ad = pc) and (r = '1'), X"A0", "Load immediate failed: ad != pc.");
        increment_pc;
        wait for clk_period;
        d <= imm_operands(0);
        assert_report((ad = pc) and (r = '1'), X"A0", "Load immediate failed: ad != pc.");
        increment_pc;           
        wait for clk_period;
    
        for i in 1 to (imm_operands'length - 1) loop
            d <= X"A0";
            assert_report((ad = pc) and (r = '1'), X"A0", "Load immediate failed: ad != pc.");
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            d <= imm_operands(i);
            assert_report(a_dbg = ss_a, X"A0", "Load immediate failed: a != ss_a");
            assert_report(x_dbg = ss_x, X"A0", "Load immediate failed: x != ss_x");
            assert_report(y_dbg = imm_operands(i - 1), X"A0", "Load immediate failed: y != imm");           
            assert_report((ad = pc), X"A0", "Load immediate failed: ad != pc.");
            increment_pc;           
            wait for clk_period;            
        end loop;
        
    end procedure test_load_imm;
    
    function bcd_add(
        constant oper1: in std_logic_vector(7 downto 0);
        constant oper2: in std_logic_vector(7 downto 0);
        constant c: in std_logic
        ) return std_logic_vector is
        
        variable result: std_logic_vector(8 downto 0);
        variable result_l: std_logic_vector(4 downto 0);
        variable result_h: std_logic_vector(4 downto 0);
    begin   
        result_l := (("0" & oper1(3 downto 0)) + ("0" & oper2(3 downto 0)) + ("0000" & c));
        
        if (result_l > 9) then 
            result_l := result_l + 6;
        end if; 
        
        result_h := (("0" & oper1(7 downto 4)) + ("0" & oper2(7 downto 4)) + ("0000" & result_l(4)));     

      if (result_h > 9) then 
            result_h := result_h + 6;
        end if;        
        
       result := result_h & result_l(3 downto 0);
        
        return result;
    end function bcd_add;
    
    function bcd_sub(
        constant oper1: in std_logic_vector(7 downto 0);
        constant oper2: in std_logic_vector(7 downto 0);
        constant c: in std_logic
        ) return std_logic_vector is
        
        variable result: std_logic_vector(7 downto 0);
        variable result_int: integer range 0 to 255;
        variable oper1_int: integer range 0 to 255;
        variable oper2_int: integer range 0 to 255;     
    begin   

        oper1_int := 10 * conv_integer(oper1(7 downto 4)) + conv_integer(oper1(3 downto 0));
        oper2_int := 10 * conv_integer(oper2(7 downto 4)) + conv_integer(oper2(3 downto 0));
        
        result_int := oper1_int - oper2_int;
        result := std_logic_vector(conv_unsigned(result_int, 8));

        return result;
    end function bcd_sub;

    procedure alu_01_assert_result(
        constant oper1: in std_logic_vector(7 downto 0);
        constant oper2: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)
    ) is 
    
        variable result: std_logic_vector(8 downto 0);
        variable s_result: std_logic_vector(7 downto 0);
        
    begin
        
        if ((ir(1 downto 0) = "00") and not (ir(7 downto 5) = "001")) then
            result := ("0" & oper1) + ("0" & not oper2) + 1;
        else
            case ir(7 downto 5) is 
                when "000" => result := "0" & (oper1 or oper2); 
                when "001" => result := "0" & (oper1 and oper2); 
                when "010" => result := "0" & (oper1 xor oper2); 
                when "011" => result := ("0" & oper1) + ("0" & oper2) + ("00000000" & ss_p(C));
                when "101" => result := "0" & oper2; 
                when "110" => result := ("0" & oper1) + ("0" & not oper2) + 1;
                when "111" => result := ("0" & oper1) + ("0" & not oper2) + ("00000000" & ss_p(C));
                when others => null;
            end case;   
        end if;
        
        if (ir(7 downto 5) = "011") and (p_dbg(3) = '1') then 
            result := bcd_add(oper1, oper2, ss_p(C));
        end if;
        
        if (ir(7 downto 5) = "111") and (p_dbg(3) = '1') then
            result := bcd_sub(oper1, oper2, ss_p(C));
        end if;
        
        s_result := result(7 downto 0);
        
        if ((ir(7 downto 5) = "110") or (ir(1 downto 0) = "00") or (ir = X"24") or (ir = X"2C")) then
            assert_report((a_dbg = ss_a ), ir, "ALU Failed: a != ss_a.");
        else
            assert_report((a_dbg = s_result), ir, "ALU Failed: a != result.");
        end if;
                    
        if (s_result = 0) then
            assert_report((p_dbg(Z) = '1'), ir, "ALU Failed: Z incorrect.");            
        else 
            assert_report((p_dbg(Z) = '0'), ir, "ALU Failed: Z incorrect.");            
        end if;

        if ((ir = X"24") or (ir = X"2C")) then 
            assert_report((oper2(7) = p_dbg(N)), ir, "ALU Failed: N incorrect.");
        else 
            assert_report((s_result(7) = p_dbg(N)), ir, "ALU Failed: N incorrect.");
        end if;
                
        if ((ir(7 downto 5) = "011") or (ir(7 downto 5) = "110") or (ir(7 downto 5) = "111")) then          
            assert_report((p_dbg(C) = result(8)), ir, "ALU Failed: C incorrect.");
        else 
            assert_report((p_dbg(C) = ss_p(C)), ir, "ALU Failed: C changed.");
        end if;
            
        assert_report((ss_x = x_dbg), ir, "ALU Failed: ss_x != x.");
        assert_report((ss_y = y_dbg), ir, "ALU Failed: ss_y != y.");    
        
    end procedure alu_01_assert_result;

    procedure alu_10_assert_result(
        signal d: in std_logic_vector(7 downto 0);
        constant oper: in std_logic_vector(7 downto 0);     
        constant ir: in std_logic_vector(7 downto 0)
    ) is 
    
        variable result : std_logic_vector(7 downto 0);
        
    begin
        
        case ir(7 downto 5) is 
            when "000" => result := oper(6 downto 0) & "0"; 
            when "001" => result := oper(6 downto 0) & ss_p(C); 
            when "010" => result := "0" & oper(7 downto 1);
            when "011" => result := ss_p(C) & oper(7 downto 1);
            when "110" => result := oper - 1;
            when "111" => result := oper + 1;
            when others => null;
        end case;
        
        assert_report((result = d), ir, "ALU Failed: d != result.");
            
        assert_report((result(7) = p_dbg(N)), ir, "ALU Failed: N incorrect.");
        
        if (result = 0) then
            assert_report((p_dbg(Z) = '1'), ir, "ALU Failed: Z incorrect.");
        else 
            assert_report((p_dbg(Z) = '0'), ir, "ALU Failed: Z incorrect.");
        end if; 
                
        case ir(7 downto 5) is 
            when "000" => assert_report((oper(7) = p_dbg(C)), ir, "ALU Failed: C incorrect."); 
            when "001" => assert_report((oper(7) = p_dbg(C)), ir, "ALU Failed: C incorrect."); 
            when "010" => assert_report((oper(0) = p_dbg(C)), ir, "ALU Failed: C incorrect.");
            when "011" => assert_report((oper(0) = p_dbg(C)), ir, "ALU Failed: C incorrect."); 
            when "110" => assert_report((ss_p(C) = p_dbg(C)), ir, "ALU Failed: C changed."); 
            when "111" => assert_report((ss_p(C) = p_dbg(C)), ir, "ALU Failed: C changed."); 
            when others => null;
        end case;   
        
        assert_report((ss_x = x_dbg), ir, "ALU Failed: ss_x != x.");
        assert_report((ss_y = y_dbg), ir, "ALU Failed: ss_y != y.");    
        
    end procedure alu_10_assert_result;

    procedure load_assert_result(
        constant oper: in std_logic_vector(7 downto 0);     
        constant ir: in std_logic_vector(7 downto 0)
    ) is 
        
    begin       
        
        if (ir(1 downto 0) = "10") then 
            assert_report((oper = x_dbg), ir, "ALU Failed: x != result.");
            assert_report((ss_a = a_dbg), ir, "ALU Failed: ss_a != a.");
            assert_report((ss_y = y_dbg), ir, "ALU Failed: ss_y != y.");    
        else 
            assert_report((oper = y_dbg), ir, "ALU Failed: y != result.");
            assert_report((ss_a = a_dbg), ir, "ALU Failed: ss_a != a.");
            assert_report((ss_x = x_dbg), ir, "ALU Failed: ss_x != x.");    
        end if;
                            
        if (oper = 0) then
            assert_report((p_dbg(Z) = '1'), ir, "ALU Failed: Z incorrect.");
        else 
            assert_report((p_dbg(Z) = '0'), ir, "ALU Failed: Z incorrect.");
        end if;

        assert_report((oper(7) = p_dbg(N)), ir, "ALU Failed: N incorrect.");
                        
    end procedure load_assert_result;
    
    procedure alu_01_prepare_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper1: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin       
        load_A(d, oper1);
        d <= ir;
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;                               
        wait for clk_period;                        
        sample_cpu_state;
    end procedure alu_01_prepare_op;
    
    procedure alu_10_prepare_op(
        signal d: out std_logic_vector(7 downto 0);     
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin               
        d <= ir;
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;                               
        wait for clk_period;                        
        sample_cpu_state;
    end procedure alu_10_prepare_op;
    
    procedure load_prepare_op(
        signal d: out std_logic_vector(7 downto 0);     
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin               
        d <= ir;
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;                               
        wait for clk_period;                        
        sample_cpu_state;
    end procedure load_prepare_op;
    
    procedure cmp_prepare_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper1: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin       
       if (ir(7 downto 5) = "110") then
            load_Y(d, oper1);
        else 
            load_X(d, oper1);
        end if;
        d <= ir;
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;                               
        wait for clk_period;                        
        sample_cpu_state;
    end procedure cmp_prepare_op;

    procedure stxy_prepare_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper1: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)
        ) is
    begin       
       if (ir(1 downto 0) = "00") then
            load_Y(d, oper1);
        else 
            load_X(d, oper1);
        end if;
        d <= ir;
        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
        increment_pc;                               
        wait for clk_period;                        
        sample_cpu_state;
    end procedure stxy_prepare_op;
    
    procedure alu_01_finalize_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper2: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)        
        ) is
    begin
        d <= oper2;
        assert_report((r = '1'), ir, "Failed: r != 1.");
        wait for clk_period;    
        nop(d);     
    end procedure alu_01_finalize_op;
    
    procedure load_finalize_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)        
        ) is
    begin
        d <= oper;
        assert_report((r = '1'), ir, "Failed: r != 1.");
        wait for clk_period;    
        nop(d);     
    end procedure load_finalize_op;

    procedure store_finalize_op(
        signal d: in std_logic_vector(7 downto 0);  
        constant oper: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)        
        ) is
    begin               
        assert_report((d = oper), ir, "Store failed: d != oper.");
        assert_report((r = '0'), ir, "Store failed: r != 0.");
        assert_report((ss_a = a_dbg), ir, "Store failed: ss_x != x.");
        assert_report((ss_x = x_dbg), ir, "Store failed: ss_x != x.");
        assert_report((ss_y = y_dbg), ir, "Store failed: ss_y != y.");  
        assert_report((ss_p = p_dbg), ir, "Store failed: P changed.");          
    end procedure store_finalize_op;
    
    procedure alu_10_finalize_op(
        signal d: out std_logic_vector(7 downto 0);
        constant oper: in std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)        
        ) is
    begin
        d <= oper;
        assert_report((r = '1'), ir, "Failed: r != 1.");
        wait for clk_period;    
        d <= "ZZZZZZZZ";
        assert_report((r = '0'), ir, "Failed: r != 0.");
        --assert_report((d = oper), ir, "Failed: d != oper.");      
        wait for clk_period;    
        assert_report((r = '0'), ir, "Failed: r != 0.");
        
    end procedure alu_10_finalize_op;

    procedure test_alu_01(
        signal d: out std_logic_vector(7 downto 0);
        constant op: in std_logic_vector(2 downto 0)
    ) is                
        variable ir : std_logic_vector(7 downto 0);             
    begin       
        for i in 0 to (imm_operands'length - 1) loop                                        
            for j in 0 to (imm_operands'length - 1) loop                            
                ir := op & "01001"; 
                alu_01_prepare_op(d, imm_operands(i), ir);
                test_imm_mode(ir);
                alu_01_finalize_op(d, imm_operands(j), ir);
                alu_01_assert_result(imm_operands(i), imm_operands(j), ir);             
            
                for k in 0 to (adr_operands'length - 1) loop 
                    ir := op & "00101"; 
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_zp_mode(adr_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir); 

                    ir := op & "01101"; 
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_abs_mode(ad_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir);                         
                
                    for l in 0 to (adr_operands'length - 1) loop 
                        ir := op & "10101"; 
                        load_X(d, adr_operands(l));
                        alu_01_prepare_op(d, imm_operands(i), ir);
                        test_zp_idx_mode(adr_operands(k), adr_operands(l), ir, d);
                        alu_01_finalize_op(d, imm_operands(j), ir);
                        alu_01_assert_result(imm_operands(i), imm_operands(j), ir);
                        
                        ir := op & "11101"; 
                        load_X(d, adr_operands(l));
                        alu_01_prepare_op(d, imm_operands(i), ir);
                        test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                        alu_01_finalize_op(d, imm_operands(j), ir);
                        alu_01_assert_result(imm_operands(i), imm_operands(j), ir);                         
                        
                        ir := op & "11001"; 
                        load_Y(d, adr_operands(l));
                        alu_01_prepare_op(d, imm_operands(i), ir);
                        test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                        alu_01_finalize_op(d, imm_operands(j), ir);
                        alu_01_assert_result(imm_operands(i), imm_operands(j), ir);     
                        
                        for m in 0 to (adr_operands'length - 1) loop
                            ir := op & "00001"; 
                            load_X(d, adr_operands(l));
                            alu_01_prepare_op(d, imm_operands(i), ir);
                            test_ind_x_mode(adr_operands(m), ad_operands(k), adr_operands(l), ir, d);
                            alu_01_finalize_op(d, imm_operands(j), ir);
                            alu_01_assert_result(imm_operands(i), imm_operands(j), ir);                         
                            
                            ir := op & "10001"; 
                            load_Y(d, adr_operands(l));
                            alu_01_prepare_op(d, imm_operands(i), ir);
                            test_ind_y_mode(adr_operands(m), ad_operands(k), adr_operands(l), ir, d);
                            alu_01_finalize_op(d, imm_operands(j), ir);
                            alu_01_assert_result(imm_operands(i), imm_operands(j), ir); 
                        end loop;                               
                    end loop;
                end loop;
            end loop;
        end loop;       
    end procedure test_alu_01;

    procedure test_bit(
        signal d: out std_logic_vector(7 downto 0)  
    ) is                
        variable ir : std_logic_vector(7 downto 0);             
    begin       
        for i in 0 to (imm_operands'length - 1) loop                                        
            for j in 0 to (imm_operands'length - 1) loop                                
                for k in 0 to (adr_operands'length - 1) loop 
                    ir := X"24"; 
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_zp_mode(adr_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir); 

                    ir := X"2C"; 
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_abs_mode(ad_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir);                         
                end loop;
            end loop;
        end loop;       
    end procedure test_bit;
        
    procedure test_alu_10(
        signal d: inout std_logic_vector(7 downto 0)
    ) is        
        variable ir : std_logic_vector(7 downto 0);             
    begin
    
        for op in 0 to (alu_10_opcodes'length - 1) loop         
            for i in 0 to (imm_operands'length - 1) loop                                                                                            
                for k in 0 to (adr_operands'length - 1) loop 
                    ir := alu_10_opcodes(op) & "00110"; 
                    alu_10_prepare_op(d, ir);
                    test_zp_mode(adr_operands(k), ir, d);
                    alu_10_finalize_op(d, imm_operands(i), ir);
                    alu_10_assert_result(d, imm_operands(i), ir);   
                    wait for clk_period;

                    ir := alu_10_opcodes(op) & "01110"; 
                    alu_10_prepare_op(d, ir);
                    test_abs_mode(ad_operands(k), ir, d);
                    alu_10_finalize_op(d, imm_operands(i), ir);
                    alu_10_assert_result(d, imm_operands(i), ir);
                    wait for clk_period;
                    
                    for l in 0 to (adr_operands'length - 1) loop 
                        ir := alu_10_opcodes(op) & "10110"; 
                        load_X(d, adr_operands(l));
                        alu_10_prepare_op(d, ir);
                        test_zp_idx_mode(adr_operands(k), adr_operands(l), ir, d);
                        alu_10_finalize_op(d, imm_operands(i), ir);
                        alu_10_assert_result(d, imm_operands(i), ir);                       
                        wait for clk_period;
                    
                        ir := alu_10_opcodes(op) & "11110"; 
                        load_X(d, adr_operands(l));
                        alu_10_prepare_op(d, ir);
                        test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                        alu_10_finalize_op(d, imm_operands(i), ir);
                        alu_10_assert_result(d, imm_operands(i), ir);
                        wait for clk_period;
                    end loop;
                end loop;           
            end loop;
        end loop;
        
    end procedure test_alu_10;
        
    procedure test_store(
        signal d: inout std_logic_vector(7 downto 0)
    ) is                    
        variable ir : std_logic_vector(7 downto 0);             
    begin
        
        for i in 0 to (imm_operands'length - 1) loop                                                                                    
            for k in 0 to (adr_operands'length - 1) loop 
                ir := "10000101"; 
                alu_01_prepare_op(d, imm_operands(i), ir);
                test_zp_mode(adr_operands(k), ir, d);
                d <= "ZZZZZZZZ";
                wait for clk_period / 4;
                store_finalize_op(d, imm_operands(i), ir);          
                wait for 3 * clk_period / 4;

                ir := "10001101"; 
                alu_01_prepare_op(d, imm_operands(i), ir);
                test_abs_mode(ad_operands(k), ir, d);
                d <= "ZZZZZZZZ";
                wait for clk_period / 4;
                store_finalize_op(d, imm_operands(i), ir);
                wait for 3 * clk_period / 4;        
            
                for l in 0 to (adr_operands'length - 1) loop 
                    ir := "10010101"; 
                    load_X(d, adr_operands(l));
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_zp_idx_mode(adr_operands(k), adr_operands(l), ir, d);
                    d <= "ZZZZZZZZ";
                    wait for clk_period / 4;
                    store_finalize_op(d, imm_operands(i), ir);          
                    wait for 3 * clk_period / 4;
                    
                    ir := "10011101"; 
                    load_X(d, adr_operands(l));
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                    d <= "ZZZZZZZZ";
                    wait for clk_period / 4;
                    store_finalize_op(d, imm_operands(i), ir);          
                    wait for 3 * clk_period / 4;                                    
                    
                    ir := "10011001"; 
                    load_Y(d, adr_operands(l));
                    alu_01_prepare_op(d, imm_operands(i), ir);
                    test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                    d <= "ZZZZZZZZ";
                    wait for clk_period / 4;
                    store_finalize_op(d, imm_operands(i), ir);          
                    wait for 3 * clk_period / 4;                
                    
                    for m in 0 to (adr_operands'length - 1) loop
                        ir := "10000001"; 
                        load_X(d, adr_operands(l));
                        alu_01_prepare_op(d, imm_operands(i), ir);
                        test_ind_x_mode(adr_operands(m), ad_operands(k), adr_operands(l), ir, d);
                        d <= "ZZZZZZZZ";
                        wait for clk_period / 4;
                        store_finalize_op(d, imm_operands(i), ir);          
                        wait for 3 * clk_period / 4;        

                        ir := "10010001"; 
                        load_Y(d, adr_operands(l));
                        alu_01_prepare_op(d, imm_operands(i), ir);
                        test_ind_y_mode(adr_operands(m), ad_operands(k), adr_operands(l), ir, d);
                        d <= "ZZZZZZZZ";
                        wait for clk_period / 4;
                        store_finalize_op(d, imm_operands(i), ir);          
                        wait for 3 * clk_period / 4;                                    
                    end loop;                               
                end loop;
            end loop;
        end loop;
    end procedure test_store;
        
    procedure test_load(
        signal d: out std_logic_vector(7 downto 0);
        constant cc: in std_logic_vector(1 downto 0)
    ) is      
        variable ir : std_logic_vector(7 downto 0);             
    begin
            
        for i in 0 to (imm_operands'length - 1) loop                                                        
            for k in 0 to (adr_operands'length - 1) loop 
                ir := "101001" & cc; 
                load_prepare_op(d, ir);
                test_zp_mode(adr_operands(k), ir, d);
                load_finalize_op(d, imm_operands(i), ir);   
                load_assert_result(imm_operands(i), ir);        

                ir := "101011" & cc; 
                load_prepare_op(d, ir);
                test_abs_mode(ad_operands(k), ir, d);
                load_finalize_op(d, imm_operands(i), ir);   
                load_assert_result(imm_operands(i), ir);                        
                
                for l in 0 to (adr_operands'length - 1) loop                    
                    ir := "101101" & cc; 
                    if (cc = "00") then 
                        load_X(d, adr_operands(l));
                    else                    
                        load_Y(d, adr_operands(l));
                    end if;
                    load_prepare_op(d, ir);
                    test_zp_idx_mode(adr_operands(k), adr_operands(l), ir, d);
                    load_finalize_op(d, imm_operands(i), ir);
                    load_assert_result(imm_operands(i), ir);
                        
                    ir := "101111" & cc; 
                    if (cc = "00") then 
                        load_X(d, adr_operands(l));
                    else                    
                        load_Y(d, adr_operands(l));
                    end if;
                    load_prepare_op(d, ir);
                    test_abs_idx_mode(ad_operands(k), adr_operands(l), ir, d);
                    load_finalize_op(d, imm_operands(i), ir);
                    load_assert_result(imm_operands(i), ir);
                end loop;
            end loop;
        end loop;       
    end procedure test_load;
    
    procedure test_cmp(
        signal d: out std_logic_vector(7 downto 0);
        constant aaa: in std_logic_vector(2 downto 0)
    ) is                    
        variable ir : std_logic_vector(7 downto 0);             
    begin
            
        for i in 0 to (imm_operands'length - 1) loop                                        
            for j in 0 to (imm_operands'length - 1) loop                            
                ir := aaa & "00000"; 
                cmp_prepare_op(d, imm_operands(i), ir);
                test_imm_mode(ir);
                alu_01_finalize_op(d, imm_operands(j), ir);
                alu_01_assert_result(imm_operands(i), imm_operands(j), ir);
            
                for k in 0 to (adr_operands'length - 1) loop 
                    ir := aaa & "00100"; 
                    cmp_prepare_op(d, imm_operands(i), ir);
                    test_zp_mode(adr_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir); 

                    ir := aaa & "01100"; 
                    cmp_prepare_op(d, imm_operands(i), ir);
                    test_abs_mode(ad_operands(k), ir, d);
                    alu_01_finalize_op(d, imm_operands(j), ir);
                    alu_01_assert_result(imm_operands(i), imm_operands(j), ir);                         
                end loop;
            end loop;
        end loop;       
        
    end procedure test_cmp;
        
    procedure test_inxy_dexy(
        signal d: out std_logic_vector(7 downto 0);     
        constant ir: in std_logic_vector(7 downto 0)
    ) is      
        
        variable op, i, j, k, l, m: natural;        
        variable result : std_logic_vector(7 downto 0); 
                
    begin               
            
        for i in 0 to (imm_operands'length - 1) loop 

            if (ir = X"E8" or ir = X"CA") then              
                load_X(d, imm_operands(i));
            else 
                load_Y(d, imm_operands(i));
            end if;
            
            if (ir = X"E8" or ir = X"C8") then 
                result := imm_operands(i) + 1;
            else 
                result := imm_operands(i) - 1;
            end if;
                
            d <= ir;
            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
            increment_pc;                               
            wait for clk_period;                        
            sample_cpu_state;
            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");                    
            wait for clk_period;                                        
            nop(d);
            
            assert_report((a_dbg = ss_a), ir, "Failed: a != ss_a");
            
            if (ir = X"E8" or ir = X"CA") then
                assert_report((x_dbg = result), ir, "Failed: x != result.");        
                assert_report((y_dbg = ss_y), ir, "Failed: y != ss_y");
            else 
                assert_report((y_dbg = result), ir, "Failed: y != result.");        
                assert_report((x_dbg = ss_x), ir, "Failed: x != ss_x");
            end if;
            
            if (result = 0) then
                assert_report((p_dbg(Z) = '1'), ir, "ALU Failed: Z incorrect.");            
            else
                assert_report((p_dbg(Z) = '0'), ir, "ALU Failed: Z incorrect.");            
            end if;

            assert_report((result(7) = p_dbg(N)), ir, "ALU Failed: N incorrect.");
            assert_report((p_dbg(C) = ss_p(C)), ir, "ALU Failed: C changed.");
                
        end loop;       
        
    end procedure test_inxy_dexy;
        
    procedure test_stxy(
        signal d: inout std_logic_vector(7 downto 0);
        constant cc: in std_logic_vector(1 downto 0)
    ) is            
        variable ir : std_logic_vector(7 downto 0);             
    begin
            
        for i in 0 to (imm_operands'length - 1) loop                                                                                    
            for k in 0 to (adr_operands'length - 1) loop 
                ir := "100001" & cc; 
                stxy_prepare_op(d, imm_operands(i), ir);
                test_zp_mode(adr_operands(k), ir, d);
                d <= "ZZZZZZZZ";
                wait for clk_period / 4;
                store_finalize_op(d, imm_operands(i), ir);          
                wait for 3 * clk_period / 4;

                ir := "100011" & cc; 
                stxy_prepare_op(d, imm_operands(i), ir);
                test_abs_mode(ad_operands(k), ir, d);
                d <= "ZZZZZZZZ";
                wait for clk_period / 4;
                store_finalize_op(d, imm_operands(i), ir);
                wait for 3 * clk_period / 4;
            
                for l in 0 to (adr_operands'length - 1) loop 
                    ir := "100101" & cc; 
                    if (cc = "10") then
                        load_Y(d, adr_operands(l));
                    else 
                        load_X(d, adr_operands(l));
                    end if;                 
                    stxy_prepare_op(d, imm_operands(i), ir);
                    test_zp_idx_mode(adr_operands(k), adr_operands(l), ir, d);
                    d <= "ZZZZZZZZ";
                    wait for clk_period / 4;
                    store_finalize_op(d, imm_operands(i), ir);          
                    wait for 3 * clk_period / 4;                                            
                end loop;
            end loop;
        end loop;
    end procedure test_stxy;
        
    procedure test_alu_10_acc(
        signal d: inout std_logic_vector(7 downto 0)
    ) is            
        variable ir : std_logic_vector(7 downto 0);
    begin
    
        for op in 0 to 3 loop           
            for i in 0 to (imm_operands'length - 1) loop        
                ir := alu_10_opcodes(op) & "01010"; 
                alu_01_prepare_op(d, imm_operands(i), ir);
                assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");                    
                wait for clk_period;                                        
                nop(d);
                alu_10_assert_result(a_dbg, imm_operands(i), ir);   
            end loop;
        end loop;
        
    end procedure test_alu_10_acc;
    
    procedure init_stack(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
    begin
        load_X(d, X"FF");
        d <= X"9A";
        increment_pc;
        wait for clk_period;
        wait for clk_period;
        nop(d);     
        assert (s_dbg = X"FF") report "Stack initialization failed.";
    end procedure init_stack;   
    
    procedure test_pha(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
        variable k: std_logic_vector(7 downto 0);
    begin 
        for i in 0 to (imm_operands'length - 1) loop 
            load_A(d, imm_operands(i));
            d <= X"48"; 
            assert_report((ad = pc) and (r = '1'), X"48", "Failed: ad != pc.");         
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            assert_report((ad = pc) and (r = '1'), X"48", "Failed: ad != pc.");
            wait for clk_period;
            d <= "ZZZZZZZZ";            
            wait for clk_period / 4;            
            assert_report((ad = (X"01" & s_dbg)) and (r = '0'), X"48", "Failed: ad != s.");
            k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
            assert_report((k = imm_operands(i)), X"48", "Failed: d != oper.");
            wait for 3 * clk_period / 4;
            nop(d);
            assert_report((s_dbg = (ss_s - 1)), X"48", "Failed: s != s - 1.");
            assert_report((a_dbg = ss_a), X"48", "Failed: a != ss_a.");
            assert_report((x_dbg = ss_x), X"48", "Failed: x != ss_x.");
            assert_report((y_dbg = ss_y), X"48", "Failed: y != ss_y.");
        end loop;
    end procedure test_pha; 
    
    procedure test_php(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
        variable k: std_logic_vector(7 downto 0);
    begin       
        d <= X"08"; 
        assert_report((ad = pc) and (r = '1'), X"08", "Failed: ad != pc.");         
        increment_pc;
        wait for clk_period;
        sample_cpu_state;
        assert_report((ad = pc) and (r = '1'), X"08", "Failed: ad != pc.");
        wait for clk_period;
        d <= "ZZZZZZZZ";            
        wait for clk_period / 4;            
        assert_report((ad = (X"01" & s_dbg)) and (r = '0'), X"08", "Failed: ad != s.");     
        k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
        assert_report((k = ss_p), X"08", "Failed: d != p.");
        wait for 3 * clk_period / 4;
        nop(d);
        assert_report((s_dbg = (ss_s - 1)), X"48", "Failed: s != s - 1.");
        assert_report((a_dbg = ss_a), X"48", "Failed: a != ss_a.");
        assert_report((x_dbg = ss_x), X"48", "Failed: x != ss_x.");
        assert_report((y_dbg = ss_y), X"48", "Failed: y != ss_y.");
    end procedure test_php; 
    
    procedure test_pla(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
    begin 
        for i in 0 to (imm_operands'length - 1) loop        
            d <= X"68"; 
            assert_report((ad = pc) and (r = '1'), X"68", "Failed: ad != pc.");         
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            assert_report((ad = pc) and (r = '1'), X"68", "Failed: ad != pc.");
            wait for clk_period;            
            assert_report((ad = (X"01" & s_dbg)) and (r = '1'), X"68", "Failed: ad != s.");
            wait for clk_period;            
            d <= imm_operands(i);
            assert_report((ad = (X"01" & (ss_s + 1))) and (r = '1'), X"68", "Failed: ad != s.");                                            
            wait for clk_period;            
            nop(d);
            assert_report((s_dbg = (ss_s + 1)), X"68", "Failed: s != s + 1.");
            assert_report((a_dbg = imm_operands(i)), X"68", "Failed: a != oper.");
            assert_report((x_dbg = ss_x), X"68", "Failed: x != ss_x.");
            assert_report((y_dbg = ss_y), X"68", "Failed: y != ss_y.");
        end loop;
    end procedure test_pla; 
    
    procedure test_plp(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
    begin       
        d <= X"28"; 
        assert_report((ad = pc) and (r = '1'), X"28", "Failed: ad != pc.");         
        increment_pc;
        wait for clk_period;
        sample_cpu_state;
        assert_report((ad = pc) and (r = '1'), X"28", "Failed: ad != pc.");
        wait for clk_period;            
        assert_report((ad = (X"01" & s_dbg)) and (r = '1'), X"28", "Failed: ad != s.");
        wait for clk_period;            
        d <= X"FF";
        assert_report((ad = (X"01" & (ss_s + 1))) and (r = '1'), X"28", "Failed: ad != s.");
        wait for clk_period;            
        nop(d);
        assert_report((s_dbg = (ss_s + 1)), X"28", "Failed: s != s + 1.");
        assert_report((p_dbg = X"FF"), X"28", "Failed: p != oper.");  -- FIXME
        assert_report((a_dbg = ss_a), X"28", "Failed: a != ss_a.");
        assert_report((x_dbg = ss_x), X"28", "Failed: x != ss_x.");
        assert_report((y_dbg = ss_y), X"28", "Failed: y != ss_y.");
    end procedure test_plp; 

    procedure test_jsr(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
        variable k: std_logic_vector(7 downto 0);
    begin 
        for i in 0 to (ad_operands'length - 1) loop         
            d <= X"20"; 
            assert_report((ad = pc) and (r = '1'), X"20", "Failed: ad != pc.");                     
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            d <= ad_operands(i)(7 downto 0);
            assert_report((ad = pc) and (r = '1'), X"20", "Failed: ad != pc.");
            increment_pc;
            wait for clk_period;            
            assert_report((ad = (X"01" & s_dbg)) and (r = '1'), X"20", "Failed: ad != s.");
            wait for clk_period;
            d <= "ZZZZZZZZ";            
            wait for clk_period / 4;            
            assert_report((ad = (X"01" & s_dbg)) and (r = '0'), X"20", "Failed: ad != s.");     
            k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
            assert_report((k = pc(15 downto 8)), X"20", "Failed: d != pch.");           
            wait for clk_period;
            assert_report((ad = (X"01" & (ss_s - 1))) and (r = '0'), X"20", "Failed: ad != s - 1.");        
            k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
            assert_report((k = pc(7 downto 0)), X"20", "Failed: d != pcl.");
            wait for 3 * clk_period / 4;
            d <= ad_operands(i)(15 downto 8);
            assert_report((ad = pc) and (r = '1'), X"20", "Failed: ad != pc.");
            wait for clk_period;
            jump_pc(ad_operands(i));
            assert_report((ad = pc) and (r = '1'), X"20", "Failed: ad != new_pc.");
            
            assert_report((s_dbg = (ss_s - 2)), X"20", "Failed: s != s - 2.");
            assert_report((a_dbg = ss_a), X"20", "Failed: a != ss_a.");
            assert_report((x_dbg = ss_x), X"20", "Failed: x != ss_x.");
            assert_report((y_dbg = ss_y), X"20", "Failed: y != ss_y.");
            assert_report((p_dbg = ss_p), X"20", "Failed: p != ss_p.");
        end loop;
    end procedure test_jsr; 
    
    procedure test_brk(
        signal d: inout std_logic_vector(7 downto 0);
        constant adr: std_logic_vector(15 downto 0);
        constant vec: std_logic_vector(15 downto 0);
        constant intr: boolean
    ) is 
        variable k: std_logic_vector(7 downto 0);
    begin       
        sample_cpu_state;       
        if (intr) then
            d <= X"EA";
        else 
            d <= X"00"; 
        end if;
        assert_report((ad = pc) and (r = '1'), X"00", "Failed: ad != pc.");
        if (not intr) then 
            increment_pc;
        end if;
        wait for clk_period;
        assert_report((ad = pc) and (r = '1'), X"00", "Failed: ad != pc.");
        if (not intr) then 
            increment_pc;
        end if;
        wait for clk_period;
        d <= "ZZZZZZZZ";
        wait for clk_period / 4;            
        assert_report((ad = (X"01" & s_dbg)) and (r = '0'), X"00", "Failed: ad != s.");     
        k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
        assert_report((k = pc(15 downto 8)), X"00", "Failed: d != pch.");           
        wait for clk_period;
        assert_report((ad = (X"01" & (ss_s - 1))) and (r = '0'), X"00", "Failed: ad != s - 1.");        
        k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
        assert_report((k = pc(7 downto 0)), X"00", "Failed: d != pcl.");
        wait for clk_period;
        assert_report((ad = (X"01" & (ss_s - 2))) and (r = '0'), X"00", "Failed: ad != s - 2.");        
        k := d;  --Stupid Xilinx ISE Simulator: "Generated C++ compilation was unsuccessful".
        if (not intr) then 
            assert_report((p_dbg = ss_p(7 downto 5) & "1" & ss_p(3 downto 0)), X"00", "Failed: d != p.");
      else 
            assert_report((p_dbg = ss_p(7 downto 5) & "0" & ss_p(3 downto 0)), X"00", "Failed: d != p.");       
        end if;
        wait for 3 * clk_period / 4;
        assert_report((ad = adr) and (r = '1'), X"00", "Failed: ad != adr.");           
        d <= vec(7 downto 0);
        wait for clk_period;
        assert_report((ad = adr + 1) and (r = '1'), X"00", "Failed: ad != adr + 1.");           
        d <= vec(15 downto 8);
        wait for clk_period;
        assert_report((ad = vec) and (r = '1'), X"00", "Failed: ad != vec.");           
        jump_pc(vec);
        
        assert_report((s_dbg = (ss_s - 3)), X"00", "Failed: s != s - 3.");
        assert_report((a_dbg = ss_a), X"00", "Failed: a != ss_a.");
        assert_report((x_dbg = ss_x), X"00", "Failed: x != ss_x.");
        assert_report((y_dbg = ss_y), X"00", "Failed: y != ss_y.");
        --assert_report((p_dbg = ss_p(7 downto 3) & "1" & ss_p(1 downto 0)), X"00", "Failed: p != ss_p.");
    end procedure test_brk; 
    
    procedure test_jmp(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
    begin 
        for i in 0 to (ad_operands'length - 1) loop         
            d <= X"4C"; 
            assert_report((ad = pc) and (r = '1'), X"4C", "Failed: ad != pc.");         
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            d <= ad_operands(i)(7 downto 0);
            assert_report((ad = pc) and (r = '1'), X"4C", "Failed: ad != pc."); 
            increment_pc;           
            wait for clk_period;            
            d <= ad_operands(i)(15 downto 8);
            assert_report((ad = pc) and (r = '1'), X"4C", "Failed: ad != pc.");
            wait for clk_period;        
            jump_pc(ad_operands(i));                
            assert_report((ad = pc) and (r = '1'), X"4C", "Failed: ad != new_pc.");     
            assert_report((s_dbg = ss_s), X"4C", "Failed: s != ss_s.");
            assert_report((a_dbg = ss_a), X"4C", "Failed: a != ss_a.");
            assert_report((x_dbg = ss_x), X"4C", "Failed: x != ss_x.");
            assert_report((y_dbg = ss_y), X"4C", "Failed: y != ss_y.");
            assert_report((p_dbg = ss_p), X"4C", "Failed: p != ss_p.");
        end loop;
    end procedure test_jmp; 
        
    procedure test_jmp_abs(
        signal d: inout std_logic_vector(7 downto 0)
    ) is 
    begin 
        for i in 0 to (ad_operands'length - 1) loop         
            for j in 0 to (ad_operands'length - 1) loop 
                d <= X"6C"; 
                assert_report((ad = pc) and (r = '1'), X"6C", "Failed: ad != pc.");         
                increment_pc;
                wait for clk_period;
                sample_cpu_state;
                d <= ad_operands(i)(7 downto 0);
                assert_report((ad = pc) and (r = '1'), X"6C", "Failed: ad != pc."); 
                increment_pc;           
                wait for clk_period;            
                d <= ad_operands(i)(15 downto 8);
                assert_report((ad = pc) and (r = '1'), X"6C", "Failed: ad != pc.");
                wait for clk_period;        
                d <= ad_operands(j)(7 downto 0);
                assert_report((ad = ad_operands(i)) and (r = '1'), X"6C", "Failed: ad != oper.");                       
                wait for clk_period;            
                d <= ad_operands(j)(15 downto 8);
                -- FIXME below: 6502 bug.
                assert_report((ad = (ad_operands(i) + 1)) and (r = '1'), X"6C", "Failed: ad != oper."); 
                wait for clk_period;                                

                jump_pc(ad_operands(j));
                assert_report((ad = pc) and (r = '1'), X"6C", "Failed: ad != new_pc.");

                assert_report((s_dbg = ss_s), X"6C", "Failed: s != ss_s.");
                assert_report((a_dbg = ss_a), X"6C", "Failed: a != ss_a.");
                assert_report((x_dbg = ss_x), X"6C", "Failed: x != ss_x.");
                assert_report((y_dbg = ss_y), X"6C", "Failed: y != ss_y.");
                assert_report((p_dbg = ss_p), X"6C", "Failed: p != ss_p.");
            end loop;
        end loop;
    end procedure test_jmp_abs;

    procedure test_rt(
        signal d: out std_logic_vector(7 downto 0);
        constant ir: in std_logic_vector(7 downto 0)
    ) is
    begin
        for i in 0 to (ad_operands'length - 1) loop
            d <= ir;
            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
            increment_pc;
            wait for clk_period;
            sample_cpu_state;
            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
            wait for clk_period;
            assert_report((ad = (X"01" & s_dbg)) and (r = '1'), ir, "Failed: ad != s.");
            wait for clk_period;
            if (ir = X"40") then
                d <= X"FF";
                ss_s := ss_s + 1;
                assert_report((ad = (X"01" & s_dbg)) and (r = '1'), ir, "Failed: ad != s.");
                wait for clk_period;
            end if;
            d <= ad_operands(i)(7 downto 0);
            assert_report((ad = (X"01" & (ss_s + 1))) and (r = '1'), ir, "Failed: ad != s.");
            wait for clk_period;
            d <= ad_operands(i)(15 downto 8);
            assert_report((ad = (X"01" & (ss_s + 2))) and (r = '1'), ir, "Failed: ad != s.");
            wait for clk_period;
            jump_pc(ad_operands(i));
            if (ir = X"60") then
                assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != new_pc.");
                increment_pc;
                wait for clk_period;
            end if;
            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != new_pc + 1.");

            assert_report((s_dbg = (ss_s + 2)), ir, "Failed: s != s + 2.");
            assert_report((a_dbg = ss_a), ir, "Failed: a != ss_a.");
            assert_report((x_dbg = ss_x), ir, "Failed: x != ss_x.");
            assert_report((y_dbg = ss_y), ir, "Failed: y != ss_y.");
            if (ir = X"40") then
                assert_report((p_dbg = X"FF"), ir, "Failed: p != (s).");  -- FIXME
            else
                assert_report((p_dbg = ss_p), ir, "Failed: p != ss_p.");
            end if;
        end loop;
    end procedure test_rt;

    procedure load_flags(
        signal d: out std_logic_vector(7 downto 0);
        constant v: in std_logic_vector(7 downto 0)
    ) is
    begin
        d <= X"28";
        increment_pc;
        wait for clk_period;
        wait for clk_period;
        d <= v;
        wait for clk_period;
        wait for clk_period;
    end procedure load_flags;

    procedure test_branch(
        signal d: out std_logic_vector(7 downto 0)
    ) is
        variable flgs: std_logic_vector(7 downto 0);
        variable ir: std_logic_vector(7 downto 0);
        variable flg: std_logic;
        variable sum: std_logic_vector(8 downto 0);
        variable flgs_pack: std_logic_vector(3 downto 0);
    begin
        flgs(5 downto 2) := "0000";

        for i in 0 to 15 loop
            flgs_pack := conv_std_logic_vector(i, 4);
            flgs(C) := flgs_pack(0);
            flgs(Z) := flgs_pack(1);
            flgs(V) := flgs_pack(2);
            flgs(N) := flgs_pack(3);
            load_flags(d, flgs);

            for j in 0 to 3 loop
                for k in 0 to 1 loop
                    ir := conv_std_logic_vector(j, 2) &
                            conv_std_logic_vector(k, 1) &
                            "10000";
                    case j is
                        when 0 => flg := flgs(N);
                        when 1 => flg := flgs(V);
                        when 2 => flg := flgs(C);
                        when 3 => flg := flgs(Z);
                    end case;

                    for l in 0 to (adr_operands'length - 1) loop
                        d <= ir;
                        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
                        increment_pc;
                        wait for clk_period;
                        d <= adr_operands(l);
                        assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
                        increment_pc;
                        wait for clk_period;
                        if (flg = conv_std_logic_vector(k, 1)(0)) then
                            assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != pc.");
                            wait for clk_period;
                            sum := ('0' & pc(7 downto 0)) + ('0' & adr_operands(l));
                            assert_report((ad = pc(15 downto 8) & sum(7 downto 0)) and (r = '1'), ir, "Failed: ad != new_pc.");
                            if (sum(8) = '1') and (adr_operands(l)(7) = '0') then
                                wait for clk_period;
                                jump_pc((pc(15 downto 8) + 1) & sum(7 downto 0));
                                assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != new_pc.");
                            elsif (sum(8) = '0') and (adr_operands(l)(7) = '1') then
                                wait for clk_period;
                                jump_pc((pc(15 downto 8) - 1) & sum(7 downto 0));
                                assert_report((ad = pc) and (r = '1'), ir, "Failed: ad != new_pc.");
                            else
                                jump_pc(pc(15 downto 8) & sum(7 downto 0));
                            end if;
                        end if;
                    end loop;
                end loop;
            end loop;
        end loop;
    end procedure test_branch;

    procedure test_interrupt(
        signal d: inout std_logic_vector(7 downto 0);
        signal irq: out std_logic;
        signal nmi: out std_logic
    ) is
    begin
        d <= X"58";
        increment_pc;
        wait for clk_period;
        wait for clk_period;
        d <= X"EA";
        increment_pc;
        wait for clk_period;
        irq <= '0';
        wait for clk_period;
        test_brk(d, X"FFFE", irq_vec, true);
        irq <= '1';
        d <= X"58";
        increment_pc;
        wait for clk_period;
        wait for clk_period;
        d <= X"EA";
        increment_pc;
        wait for clk_period;
        nmi <= '0';
        wait for clk_period;
        test_brk(d, X"FFFA", nmi_vec, true);
    end procedure test_interrupt;

begin

    test_A6500: A6500
        port map(clk, rst, irq, nmi, stop, d, ad, r,
            a_dbg, x_dbg, y_dbg, s_dbg, pcl_dbg, pch_dbg, adl_dbg, adh_dbg, p_dbg);

    clk_sig: process
    begin
        clk <= '1';
        wait for clk_period / 2;
        clk <= '0';
        wait for clk_period / 2;
    end process;

    process
        variable l : line;
    begin

        wait for 100 ns;

        irq <= '1';
        nmi <= '1';
        stop <= '0';
        reset_cpu(rst, d);
        status_report("CPU Initialization: Done.");
        test_nop(d);
        status_report("NOP Test: Done.");
        test_clsec(d);
        status_report("SEC/CLC Test: Done.");
        test_clsed(d);
        status_report("SED/CLD Test: Done.");
        test_load_imm(d);
        status_report("Load Immediate Test: Done.");

        for op in 0 to (alu_01_opcodes'length - 1) loop
            if ((op = 3) or (op = 7)) then
                d <= X"F8";
                increment_pc;
                wait for clk_period;
                wait for clk_period;
                test_alu_01(d, alu_01_opcodes(op));
                d <= X"D8";
                increment_pc;
                wait for clk_period;
                wait for clk_period;
            end if;
            test_alu_01(d, alu_01_opcodes(op));
        end loop;
        status_report("ALU 01 Test: Done.");

        test_alu_10(d);
        test_alu_10_acc(d);
        status_report("ALU 10 Test: Done.");
        test_bit(d);
        status_report("BIT Test: Done.");
        test_store(d);
        status_report("STA Test: Done.");
        test_stxy(d, "00");
        test_stxy(d, "10");
        status_report("STX/Y Test: Done.");
        test_load(d, "10");
        test_load(d, "00");
        status_report("LDX/Y Test: Done.");
        test_cmp(d, "110");
        test_cmp(d, "111");
        status_report("CPX/Y Test: Done.");
        test_inxy_dexy(d, X"C8");
        test_inxy_dexy(d, X"E8");
        status_report("INX/Y Test: Done.");
        test_inxy_dexy(d, X"88");
        test_inxy_dexy(d, X"CA");
        status_report("DEX/Y Test: Done.");
        init_stack(d);
        status_report("Stack Initialization: Done.");
        test_pha(d);
        test_pla(d);
        test_php(d);
        test_plp(d);
        status_report("Stack Test: Done.");
        test_jsr(d);
        test_jmp(d);
        test_jmp_abs(d);
        test_brk(d, X"FFFE", irq_vec, false);
        test_rt(d, X"60");
        test_rt(d, X"40");
        status_report("JMP/JSR/BRK/RTS/RTI Test: Done.");
        test_branch(d);
        status_report("Branch Test: Done.");
        test_interrupt(d, irq, nmi);
        status_report("IRQ/NMI Test: Done.");

        wait;

    end process;

end bench;

