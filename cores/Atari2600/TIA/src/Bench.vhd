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

library std;
use std.textio.all; 

library ieee;
use ieee.std_logic_1164.all;       
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_signed.all;

use work.TIA_common.all;

entity bench is                 
end bench;

architecture bench of bench is
            
    component TIA is
        port(clk: in std_logic;
              rst: in std_logic;
              cs: in std_logic;       
              r: in std_logic;
              a: in std_logic_vector(5 downto 0);
              d: inout std_logic_vector(7 downto 0);
              colu: out std_logic_vector(6 downto 0);         
              csyn: out std_logic;
              hsyn: out std_logic;
              vsyn: out std_logic;
              rdy: out std_logic;
              ph0: out std_logic;
              inpt4: in std_logic;
              inpt5: in std_logic
             );
    end component; 
        
    signal clk: std_logic;
    signal rst: std_logic;      
    
    signal cs: std_logic;         
    signal r: std_logic;
    signal a: std_logic_vector(5 downto 0);
    signal d: std_logic_vector(7 downto 0);
    signal colu: std_logic_vector(6 downto 0);        
    signal csyn: std_logic; 
    signal hsyn: std_logic;
    signal vsyn: std_logic;
    signal rdy: std_logic;
    signal ph0: std_logic;
    signal inpt4: std_logic;
    signal inpt5: std_logic;
        
    constant clk_period: time := 40 ns;
    constant ph0_period: time := clk_period * 3;
    
    shared variable pf_grp: std_logic_vector(19 downto 0);
    shared variable p0_grp: std_logic_vector(7 downto 0);   
    shared variable p1_grp: std_logic_vector(7 downto 0);   
        
    shared variable bk_colu: std_logic_vector(6 downto 0);
    shared variable pf_colu: std_logic_vector(6 downto 0);
    shared variable p0_colu: std_logic_vector(6 downto 0);
    shared variable p1_colu: std_logic_vector(6 downto 0);

    shared variable p0_nusiz: std_logic_vector(2 downto 0);
    shared variable p1_nusiz: std_logic_vector(2 downto 0);
    shared variable p0_reflect: std_logic;
    shared variable p1_reflect: std_logic;
    shared variable m0_siz: std_logic_vector(1 downto 0);
    shared variable m1_siz: std_logic_vector(1 downto 0);
    shared variable m0_en: std_logic;   
    shared variable m1_en: std_logic;
    shared variable bl_siz: std_logic_vector(1 downto 0);
    shared variable bl_en: std_logic;
    
    shared variable pf_reflect: std_logic;
    shared variable pf_score: std_logic;
    shared variable pf_priority: std_logic; 
    
    shared variable p0_pos: integer;
    shared variable p1_pos: integer;
    shared variable m0_pos: integer;
    shared variable m1_pos: integer;
    shared variable bl_pos: integer;
    
    shared variable p0_pos_new: integer;
    shared variable p1_pos_new: integer;
    shared variable m0_pos_new: integer;
    shared variable m1_pos_new: integer;
    shared variable bl_pos_new: integer;
    
    procedure print_msg(        
        constant msg: in string;        
        constant val: in std_logic_vector(7 downto 0)) is       
        variable l: line;       
    begin       
        write(l, msg);
        write(l, ": ");
        hwrite(l, val);
        writeline(output, l);
    end print_msg;  
    
    procedure status_report(
        constant msg: in string) is             
        variable l: line;       
    begin
       write(l, msg);
        writeline(output, l);
    end status_report;
    
    procedure setup_pf( 
        signal r: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0);
        constant reflect: std_logic;
        constant score: std_logic;
        constant priority: std_logic;   
        constant grp: in std_logic_vector(19 downto 0);
        constant pfcolu: in std_logic_vector(6 downto 0);
        constant bkcolu: in std_logic_vector(6 downto 0)) is
    begin       
        r <= '0';
        
        a <= A_COLUPF;
        d(7 downto 1) <= pfcolu;
        wait for ph0_period;        
        pf_colu := pfcolu;
        
        a <= A_COLUBK;
        d(7 downto 1) <= bkcolu;
        wait for ph0_period;        
        bk_colu := bkcolu;
        
        a <= A_PF0;
        d(7 downto 4) <= grp(3 downto 0);
        wait for ph0_period;
        a <= A_PF1;
        d <= grp(11 downto 4);
        wait for ph0_period;
        a <= A_PF2;
        d <= grp(19 downto 12);
        wait for ph0_period;        
        pf_grp := grp;
        
        a <= A_CTRLPF;
        d <= "00" & bl_siz & "0" & priority & score & reflect;
        wait for ph0_period;        
        
        pf_reflect := reflect;
        pf_score := score;
        pf_priority := priority;
        
    end procedure setup_pf;
    
    procedure setup_pm0(    
        signal r: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0);
        constant men: in std_logic;
        constant reflect: in std_logic;
        constant nusiz: in std_logic_vector(2 downto 0);
        constant msiz: in std_logic_vector(1 downto 0);
        constant grp: in std_logic_vector(7 downto 0);
        constant colu: in std_logic_vector(6 downto 0)) is
    begin       
        r <= '0';
        
        a <= A_COLUP0;
        d(7 downto 1) <= colu;
        wait for ph0_period;        
        p0_colu := colu;
        
        a <= A_GRP0;
        d <= grp;
        wait for ph0_period;    
        p0_grp := grp;
        
        a <= A_VDELP0;
        d(0) <= '0';
        wait for ph0_period;            
        
        a <= A_REFP0;
        d <= "0000" & reflect & "000";
        wait for ph0_period;                
        p0_reflect := reflect;
        
        a <= A_NUSIZ0;
        d <= "00" & msiz & "0" & nusiz;
        wait for ph0_period;                
        p0_nusiz := nusiz;
        m0_siz := msiz;
        
        a <= A_ENAM0;
        d(1) <= men;
        wait for ph0_period;        
        m0_en := men;
        
    end procedure setup_pm0;
    
    procedure setup_pm1(    
        signal r: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0);
        constant men: in std_logic;
        constant reflect: in std_logic;
        constant nusiz: in std_logic_vector(2 downto 0);
        constant msiz: in std_logic_vector(1 downto 0);
        constant grp: in std_logic_vector(7 downto 0);
        constant colu: in std_logic_vector(6 downto 0)) is
    begin       
        r <= '0';
        
        a <= A_COLUP1;
        d(7 downto 1) <= colu;
        wait for ph0_period;        
        p1_colu := colu;
        
        a <= A_GRP1;
        d <= grp;
        wait for ph0_period;                
        p1_grp := grp;

        a <= A_VDELP1;
        d(0) <= '0';
        wait for ph0_period;            
                
        a <= A_REFP1;
        d <= "0000" & reflect & "000";
        wait for ph0_period;                
        p1_reflect := reflect;
        
        a <= A_NUSIZ1;
        d <= "00" & msiz & "0" & nusiz;
        wait for ph0_period;        

        p1_nusiz := nusiz;
        m1_siz := msiz;
        
        a <= A_ENAM1;
        d(1) <= men;
        wait for ph0_period;
        
        m1_en := men;
        
    end procedure setup_pm1;
    
    procedure setup_bl( 
        signal r: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0);
        constant siz: in std_logic_vector(1 downto 0);
        constant enable: in std_logic) is
    begin       
        r <= '0';
        
        a <= A_ENABL;
        d(1) <= enable;
        wait for ph0_period;
        
        a <= A_CTRLPF;
        d <= "00" & siz & "0" & pf_priority & pf_score & pf_reflect;
        wait for ph0_period;                
        bl_siz := siz;      
                
    end procedure setup_bl;
    
    procedure setpos_p0(
        constant pos: integer) is 
    begin
        p0_pos_new := pos;      
    end procedure setpos_p0;

    procedure setpos_p1(
        constant pos: integer) is 
    begin
        p1_pos_new := pos;      
    end procedure setpos_p1;
    
    procedure setpos_m0(
        constant pos: integer) is 
    begin
        m0_pos_new := pos;      
    end procedure setpos_m0;
    
    procedure setpos_m1(
        constant pos: integer) is 
    begin
        m1_pos_new := pos;      
    end procedure setpos_m1;
    
    procedure wait_hblank(
        signal r: out std_logic;
        signal a: out std_logic_vector(5 downto 0)) is
    begin 
        r <= '0';
        
        a <= A_WSYNC;       
        wait for ph0_period;
        
        while rdy = '0' loop
            wait for clk_period;                
      end loop;         
    end procedure wait_hblank;
    
    function get_pl_pix_adr(
        constant scan: integer;
        constant pos: integer;
        constant nusiz: in std_logic_vector(2 downto 0);
        constant reflect: in std_logic)
        return integer is
        variable result: integer;
    begin
        
        result := scan - (pos + 2); 
        if (nusiz = "101") then 
            if (result >= 0) then 
                result := result / 2;
            end if;
        elsif (nusiz = "111") then 
            if (result >= 0) then 
                result := result / 4;
            end if;
        end if;
        
        if (result >= 0) and (result <= 7) then 
            if (reflect = '0') then 
                return 7 - result;
            else 
                return result;
            end if;
        end if;
        
        if (nusiz = "001") or (nusiz = "011") then 
            result := scan - (pos + 18);
        elsif (nusiz = "010") or (nusiz = "110") then 
            result := scan - (pos + 35);
        elsif (nusiz = "100") then 
            result := scan - (pos + 68);
        end if;
        
        if (result >= 0) and (result <= 7) then 
            if (reflect = '0') then 
                return 7 - result;
            else 
                return result;
            end if;
        end if;
        
        if (nusiz = "011") then 
            result := scan - (pos + 35);
        elsif (nusiz = "110") then 
            result := scan - (pos + 68);
        end if;
        
        if (result >= 0) and (result <= 7) then 
            if (reflect = '0') then 
                return 7 - result;
            else 
                return result;
            end if;
        end if;
            
        return -1;
    end function get_pl_pix_adr;            

    function get_mi_pix_adr(
        constant scan: integer;
        constant pos: integer;
        constant nusiz: in std_logic_vector(2 downto 0);
        constant siz: in std_logic_vector(1 downto 0))
        return integer is
        variable result: integer;
    begin
        
        result := scan - (pos + 1); 
        if (result >= 0) then 
            case siz is 
                when "01" => result := result / 2;      
                when "10" => result := result / 4;
                when "11" => result := result / 8;
                when others => null;
            end case;
        end if;     
        
        if (result = 0) then 
            return result;                  
        end if;
        
        if (nusiz = "001") or (nusiz = "011") then 
            result := scan - (pos + 17);
        elsif (nusiz = "010") or (nusiz = "110") then 
            result := scan - (pos + 34);
        elsif (nusiz = "100") then 
            result := scan - (pos + 67);
        else
            return -1;
        end if;
        
        if (result >= 0) then 
            case siz is 
                when "01" => result := result / 2;      
                when "10" => result := result / 4;
                when "11" => result := result / 8;
                when others => null;
            end case;
        end if;
        
        if (result = 0) then 
            return result;          
        end if;
        
        if (nusiz = "011") then 
            result := scan - (pos + 34);
        elsif (nusiz = "110") then 
            result := scan - (pos + 67);
        else 
            return -1;
        end if;
        
        if (result >= 0) then 
            case siz is 
                when "01" => result := result / 2;      
                when "10" => result := result / 4;
                when "11" => result := result / 8;
                when others => null;
            end case;
        end if;
        
        if (result = 0) then 
            return result;          
        end if;
            
        return -1;
    end function get_mi_pix_adr;
    
    function get_bl_pix_adr(
        constant scan: integer;
        constant pos: integer;
        constant siz: in std_logic_vector(1 downto 0)) 
        return integer is
        variable result: integer;
    begin
        result := scan - (pos + 1); 
        if (result >= 0) then 
            case siz is 
                when "01" => result := result / 2;      
                when "10" => result := result / 4;
                when "11" => result := result / 8;
                when others => null;
            end case;
        end if;
        
        if (result = 0) then 
            return result;
        end if;
        
        return -1;      
    end function get_bl_pix_adr;
    
    function get_pf_adr(
        constant scan: integer;
        constant reflect: std_logic) 
        return integer is
        variable result: integer;
    begin
        result := scan / 4;
        
        if (result >= 20) then 
            result := result - 20;
            
            if (reflect = '1') then 
                result := 19 - result;
            end if;
        end if;
        
        if (result >= 4) and (result < 12) then 
            result := (11 - result) + 4;
        end if;
  
        return result;      
    end function get_pf_adr;
        
    procedure test_line(
        signal r: out std_logic;
        signal cs: out std_logic;
        signal a: out std_logic_vector(5 downto 0)) is
        variable i: integer;
        variable j: integer;
        variable ex_colu: std_logic_vector(6 downto 0);
        variable p0_adr: integer;
        variable p1_adr: integer;
        variable m0_adr: integer;
        variable m1_adr: integer;
        variable pf_adr: integer;
        variable bl_adr: integer;               
    begin 
    
        r <= '0';
        cs <= '0';
        
        for i in 2 to 68 loop
            assert colu = "000000" report "HBLANK failed.";
            wait for clk_period;
        end loop;
        
        for i in 0 to 159 loop 
                            
            p0_adr := get_pl_pix_adr(i, p0_pos, p0_nusiz, p0_reflect);
            p1_adr := get_pl_pix_adr(i, p1_pos, p1_nusiz, p1_reflect);
            m0_adr := get_mi_pix_adr(i, m0_pos, p0_nusiz, m0_siz);
            m1_adr := get_mi_pix_adr(i, m1_pos, p1_nusiz, m1_siz);
            bl_adr := get_bl_pix_adr(i, bl_pos, bl_siz);
            pf_adr := get_pf_adr(i, pf_reflect);

            ex_colu := bk_colu;
            
            if (pf_priority = '0') then 
                if (pf_grp(pf_adr) = '1') or ((bl_adr >= 0) and (bl_en = '1')) then 
                    ex_colu := pf_colu;
                end if;                 
            end if;

            if (p1_adr >= 0) then  
                if (p1_grp(p1_adr) = '1') then
                    ex_colu := p1_colu;
                end if;
            end if;
            
            if (m1_adr >= 0) and (m1_en = '1') then 
                ex_colu := p1_colu;
            end if;
            
            if (p0_adr >= 0) then  
                if (p0_grp(p0_adr) = '1') then
                    ex_colu := p0_colu;
                end if;
            end if;
            
            if (m0_adr >= 0) and (m0_en = '1') then 
                ex_colu := p0_colu;
            end if;
            
            if (pf_priority = '1') then 
                if (pf_grp(pf_adr) = '1') or ((bl_adr >= 0) and (bl_en = '1')) then 
                    ex_colu := pf_colu;
                end if;                 
            end if;
            
            assert (ex_colu = colu) report "Pixel output failed.";
            if not (ex_colu = colu) then 
                print_msg("Expecting", "0" & ex_colu);
                print_msg("Found", "0" & colu);
                --print_msg("pf_adr", conv_std_logic_vector(pf_adr, 8));
                print_msg("p0_adr", conv_std_logic_vector(p0_adr, 8));
                --print_msg("m0_adr", conv_std_logic_vector(m0_adr, 8));                
            end if;
            
            if (i = p0_pos_new) and not (p0_pos = p0_pos_new) then 
                cs <= '1';
                j := 3;
                a <= A_RESP0;
                p0_pos := p0_pos_new;
            elsif (i = p1_pos_new) and not (p1_pos = p1_pos_new) then 
                cs <= '1';
                j := 3;
                a <= A_RESP1;   
                p1_pos := p1_pos_new;
            elsif (i = m0_pos_new) and not (m0_pos = m0_pos_new) then 
                cs <= '1';
                j := 3;
                a <= A_RESM0;   
                m0_pos := m0_pos_new;
            elsif (i = m1_pos_new) and not (m1_pos = m1_pos_new) then 
                cs <= '1';
                j := 3;
                a <= A_RESM1;   
                m1_pos := m1_pos_new;
            elsif (i = bl_pos_new) and not (bl_pos = bl_pos_new) then 
                cs <= '1';
                j := 3;
                a <= A_RESBL;   
                bl_pos := bl_pos_new;           
            end if;
            
            if (j > 0) then 
                j := j - 1;
                wait for clk_period;
            else
                wait for clk_period / 2;
                cs <= '0';
                wait for clk_period / 2;
            end if;
            
        end loop;
        
        cs <= '1';
    end procedure test_line;        
    
    procedure test_pm(
        signal r: out std_logic;
        signal cs: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0)) is      
        variable i, j, k, l, m: integer;
        variable nusiz: std_logic_vector(2 downto 0);
        variable reflect: std_logic;
        variable msiz: std_logic_vector(1 downto 0);
        variable men: std_logic;
    begin   
        for m in 0 to 1 loop
            for i in 0 to 7 loop
                for j in 0 to 1 loop
                    for k in 0 to 1 loop
                        for l in 0 to 3 loop
                            reflect := conv_std_logic_vector(j, 1)(0);
                            nusiz := conv_std_logic_vector(i, 3);
                            men := conv_std_logic_vector(k, 1)(0);
                            msiz := conv_std_logic_vector(l, 2);
                            
    --                      print_msg("p0_nusiz", "00000" & nusiz);
    --                      print_msg("p0_reflect", "0000000" & reflect);
    --                      print_msg("m0_siz", "000000" & msiz);
    --                      print_msg("m0_en", "0000000" & men);
                            
                            if (m = 0) then
                                setup_pm0(r, d, a, men, reflect, nusiz, msiz, "10110110", "1010111");       
                            else 
                                setup_pm1(r, d, a, men, reflect, nusiz, msiz, "11100011", "0101000");       
                            end if;
                            wait_hblank(r, a);      
                            test_line(r, cs, a);
                        end loop;
                    end loop;
                end loop;
            end loop;
        end loop;
    end procedure test_pm;
    
    procedure test_hmove(
        signal r: out std_logic;
        signal cs: out std_logic;
        signal d: out std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(5 downto 0)) is 
        variable p0_hmove: std_logic_vector(3 downto 0);
        variable p1_hmove: std_logic_vector(3 downto 0);
        variable m0_hmove: std_logic_vector(3 downto 0);
        variable m1_hmove: std_logic_vector(3 downto 0);
        variable bl_hmove: std_logic_vector(3 downto 0);
    begin
        
        p0_hmove := "0011";
        p1_hmove := "0000";
        m0_hmove := "0000";
        m1_hmove := "0000";
        bl_hmove := "0000";

        r <= '0';       
        
        a <= A_HMP0;
        d <= p0_hmove & "0000";
        wait for ph0_period;        
        a <= A_HMP1;
        d <= p1_hmove & "0000";
        wait for ph0_period;                
        a <= A_HMM0;
        d <= m0_hmove & "0000";
        wait for ph0_period;        
        a <= A_HMM1;
        d <= m1_hmove & "0000";
        wait for ph0_period;        
        a <= A_HMBL;
        d <= bl_hmove & "0000";
        wait for ph0_period;        
        
        wait_hblank(r, a);
        
        a <= A_HMOVE;
        wait for ph0_period;            
        
        p0_pos := p0_pos + conv_integer(p0_hmove); 
        p1_pos := p1_pos + conv_integer(p1_hmove);
        m0_pos := m0_pos + conv_integer(m0_hmove);
        m1_pos := m1_pos + conv_integer(m1_hmove);
        bl_pos := bl_pos + conv_integer(bl_hmove);  
        
        p0_pos_new := p0_pos; 
        p1_pos_new := p1_pos;
        m0_pos_new := m0_pos;
        m1_pos_new := m1_pos;
        bl_pos_new := bl_pos;
        
        wait_hblank(r, a);      
        test_line(r, cs, a);        
    end procedure test_hmove;
    
    procedure init_tia(
        signal rst: out std_logic) is 
    begin
        rst <= '1';
        wait for 4 * clk_period;
        rst <= '0';                 
        
        p0_pos := 0;
        p1_pos := 0;
        m0_pos := 0;
        m1_pos := 0;
        bl_pos := 0;
        p0_pos_new := 0;
        p1_pos_new := 0;
        m0_pos_new := 0;
        m1_pos_new := 0;
        bl_pos_new := 0;        
        
        bl_en := '0';
    end procedure init_tia;
    
begin

    test_TIA: TIA port map(clk, rst, cs, r, a, d, colu, csyn, hsyn, vsyn, rdy, ph0, inpt4, inpt5);
    
    inpt4 <= '1';
    inpt5 <= '1';   
    
    clk_sig: process    
    begin
        clk <= '1';             
        wait for clk_period / 2;
        clk <= '0';
        wait for clk_period / 2;
    end process;
        
    process         
    begin
            
        init_tia(rst);
        
        cs <= '1';                                      
        setup_pf(r, d, a, '0', '0', '0', "01010101010101010101", "1111111", "0000000");     
        setpos_p0(20);      
        setpos_m0(5);
        setpos_p1(40);      
        setpos_m1(15);
        wait_hblank(r, a);                      
        test_line(r, cs, a);
                
        setup_pf(r, d, a, '1', '0', '0', "01010101010101010101", "1111111", "0000000");             
        wait_hblank(r, a);                      
        test_line(r, cs, a);
        status_report("PF Test: Done.");
        
        test_pm(r, cs, d, a);
        
        status_report("PM Test: Done.");

        setup_pm0(r, d, a, '0', '0', "000", "00", "10110110", "1010111");       
        test_hmove(r, cs, d, a);
        
        status_report("HMOVE Test: Done.");
        
        wait;       
    
    end process;
    
end bench;

