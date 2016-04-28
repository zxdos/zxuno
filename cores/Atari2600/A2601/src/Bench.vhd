-- A2601 Main Bench
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
use ieee.numeric_std.all;   
use ieee.std_logic_textio.all;

entity bench is                     
    port (verbose: in std_logic);
end bench;

architecture bench of bench is
            
    component A2601 is
    port(vid_clk: in std_logic;
         rst: in std_logic;
         d: inout std_logic_vector(7 downto 0);
         a: out std_logic_vector(12 downto 0);
         r: out std_logic;
         pa: inout std_logic_vector(7 downto 0);
         pb: inout std_logic_vector(7 downto 0);
         inpt4: in std_logic;
         inpt5: in std_logic;
         colu: out std_logic_vector(6 downto 0);
         csyn: out std_logic;
         vsyn: out std_logic;
         hsyn: out std_logic;
         au0: out std_logic;
         au1: out std_logic;
         av0: out std_logic_vector(3 downto 0);
         av1: out std_logic_vector(3 downto 0);
         ph0_out: out std_logic;
         ph1_out: out std_logic);
   end component;

    component ram128x8 is
    port(clk: in std_logic;
         r: in std_logic;
         d_in: in std_logic_vector(7 downto 0);
         d_out: out std_logic_vector(7 downto 0);
         a: in std_logic_vector(6 downto 0));
    end component;

    signal vid_clk: std_logic;
    signal rst: std_logic;
    signal d: std_logic_vector(7 downto 0);
    signal a: std_logic_vector(15 downto 0);
    signal pa: std_logic_vector(7 downto 0);
    signal pb: std_logic_vector(7 downto 0);
    signal inpt4: std_logic;
    signal inpt5: std_logic;
    signal colu: std_logic_vector(6 downto 0);
    signal csyn: std_logic;
    signal vsyn: std_logic;
    signal hsyn: std_logic;
    signal au0: std_logic;
    signal au1: std_logic;
    signal av0: std_logic_vector(3 downto 0);
    signal av1: std_logic_vector(3 downto 0);
    signal ph0: std_logic;
    signal ph1: std_logic;

    signal sc_clk: std_logic;
    signal sc_r: std_logic;
    signal sc_d_in: std_logic_vector(7 downto 0);
    signal sc_d_out: std_logic_vector(7 downto 0);
    signal sc_a: std_logic_vector(6 downto 0);

    subtype bss_type is std_logic_vector(2 downto 0);

    constant BANK00: bss_type := "000";
    constant BANKF8: bss_type := "001";
    constant BANKF6: bss_type := "010";
    constant BANKFE: bss_type := "011";
    constant BANKE0: bss_type := "100";
    constant BANK3F: bss_type := "101";

    signal bank: std_logic_vector(3 downto 0) := "0000";
    signal tf_bank: std_logic_vector(1 downto 0);
    signal e0_bank: std_logic_vector(2 downto 0);
    signal e0_bank0: std_logic_vector(2 downto 0) := "000";
    signal e0_bank1: std_logic_vector(2 downto 0) := "000";
    signal e0_bank2: std_logic_vector(2 downto 0) := "000";
    signal bss: bss_type;
    signal sc: std_logic;

    signal cpu_d: std_logic_vector(7 downto 0);
    signal cpu_a: std_logic_vector(12 downto 0);
    signal r: std_logic;

    constant vid_clk_period: time := 17.5 ns;
    --constant vid_clk_period: time := 17.4375 ns;
    --constant vid_clk_period: time := 69.75 ns;
    --constant clk_period: time := 279.365 ns;
    --constant clk_period: time := 279 ns;
    constant clk_period: time := 280 ns;
    constant aud_period: time := 22.676 us;

    procedure print_msg(
        constant msg: in string;
        constant val: in std_logic_vector(7 downto 0)) is
        variable l: line;
    begin
        write(l, now);
        write(l, string'(": "));
        write(l, msg);
        write(l, string'(": "));
        hwrite(l, val);
        writeline(output, l);
    end print_msg;

    procedure print_msg(
        constant msg: in string;
        constant val: in integer) is
        variable l: line;
    begin
        write(l, now);
        write(l, string'(": "));
        write(l, msg);
        write(l, string'(": "));
        write(l, val);
        writeline(output, l);
    end print_msg;

    procedure print_a_d(
        constant a: in std_logic_vector(15 downto 0);
        constant d: in std_logic_vector(7 downto 0)
        ) is
        variable l: line;
    begin
        write(l, now);
        write(l, string'(" A: "));
        hwrite(l, a);
        write(l, string'(" D: "));
        hwrite(l, d);
        writeline(output, l);
    end print_a_d;

    procedure status_report(
        constant msg: in string) is
        variable l: line;
    begin
       write(l, msg);
        writeline(output, l);
    end status_report;

    type rom_array is array(0 to 65535) of std_logic_vector(7 downto 0);
    shared variable rom: rom_array;

    procedure load_rom(
        constant fln: in string) is
       file rf: text;
        variable status: file_open_status;
        variable l: line;
        variable i: integer;
        variable d: integer;
    begin
        file_open(status, rf, fln, read_mode);

        assert (status = open_ok) report "Cannot open file.";

        i := 0;
        while not (endfile(rf)) loop
            readline(rf, l);
            read(l, d);
            rom(i) := std_logic_vector(to_unsigned(d, 8));
            i := i + 1 ;
        end loop;

    end procedure load_rom;

    procedure write_byte(
        file f: text;
        constant val: in std_logic_vector(7 downto 0)) is
        variable l: line;
    begin
        write(l, to_integer(unsigned(val)));
        writeline(f, l);
    end procedure write_byte;

    procedure write_vsync(
        file f: text) is
        variable l: line;
    begin
        write(l, string'("VSYNC"));
        writeline(f, l);
    end procedure write_vsync;

begin

    test_A2601: A2601
        port map(vid_clk, rst, cpu_d, cpu_a, r, pa, pb, inpt4, inpt5, colu, csyn, vsyn, hsyn, au0, au1, av0, av1, ph0, ph1);

    sc_ram128x8: ram128x8
        port map(sc_clk, sc_r, sc_d_in, sc_d_out, sc_a);

    -- This clock is phase shifted so that we can use Xilinx synchronous block RAM.
    sc_clk <= not ph1;
    sc_r <= '0' when cpu_a(12 downto 7) = "100000" else '1';
    sc_d_in <= cpu_d;
    sc_a <= cpu_a(6 downto 0);

    -- ROM and SC output
    process(cpu_a, d, sc_d_out, sc)
    begin
        if (cpu_a(12 downto 7) = "100001" and sc = '1') then
            cpu_d <= sc_d_out;
        elsif (cpu_a(12 downto 7) = "100000" and sc = '1') then
            cpu_d <= "ZZZZZZZZ";
        elsif (cpu_a(12) = '1') then
            cpu_d <= d;
        else
            cpu_d <= "ZZZZZZZZ";
        end if;
    end process;

    with cpu_a(11 downto 10) select e0_bank <=
        e0_bank0 when "00",
        e0_bank1 when "01",
        e0_bank2 when "10",
        "111" when "11",
        "---" when others;

    tf_bank <= bank(1 downto 0) when (cpu_a(11) = '0') else "11";

    with bss    select a <=
        "0000" & cpu_a(11 downto 0) when BANK00,
        "000" & bank(0) & cpu_a(11 downto 0) when BANKF8,
        "00" & bank(1 downto 0) & cpu_a(11 downto 0) when BANKF6,
        "000" & bank(0) & cpu_a(11 downto 0) when BANKFE,
        "000" & e0_bank & cpu_a(9 downto 0) when BANKE0,
        "000" & tf_bank & cpu_a(10 downto 0) when BANK3F,
        "----------------" when others;

    bankswch: process(ph0)
    begin
        if (ph0'event and ph0 = '1') then
            if (rst = '1') then
                bank <= "0000";
                e0_bank0 <= "000";
                e0_bank1 <= "000";
                e0_bank2 <= "000";
            else
                case bss is
                    when BANKF8 =>
                        if (cpu_a = "1" & X"FF8") then
                            bank <= "0000";
                        elsif (cpu_a = "1" & X"FF9") then
                            bank <= "0001";
                        end if;
                    when BANKF6 =>
                        if (cpu_a = "1" & X"FF6") then
                            bank <= "0000";
                        elsif (cpu_a = "1" & X"FF7") then
                            bank <= "0001";
                        elsif (cpu_a = "1" & X"FF8") then
                            bank <= "0010";
                        elsif (cpu_a = "1" & X"FF9") then
                            bank <= "0011";
                        end if;
                    when BANKFE =>
                        if (cpu_a = "0" & X"1FE") then
                            bank <= "0000";
                        elsif (cpu_a = "1" & X"1FE") then
                            bank <= "0001";
                        end if;
                    when BANKE0 =>
                        if (cpu_a(12 downto 4) = "1" & X"FE" and cpu_a(3) = '0') then
                            e0_bank0 <= cpu_a(2 downto 0);
                        elsif (cpu_a(12 downto 4) = "1" & X"FE" and cpu_a(3) = '1') then
                            e0_bank1 <= cpu_a(2 downto 0);
                        elsif (cpu_a(12 downto 4) = "1" & X"FF" and cpu_a(3) = '0') then
                            e0_bank2 <= cpu_a(2 downto 0);
                        end if;
                    when BANK3F =>
                        --if (cpu_a(12 downto 6) = "0000000") then
                        if (cpu_a = "0" & X"03F") then
                            bank(1 downto 0) <= cpu_d(1 downto 0);
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;        
        
    bss <= BANK00;  
    sc <= '0';
    
    pa <= "11111111";
    pb(7 downto 1) <= "1111111";

    inpt4 <= '1';
    inpt5 <= '1';

    rst_sig: process
    begin
        rst <= '1';
        wait for 3 * clk_period / 2;
        rst <= '0';
        wait;
    end process;

    vid_clk_sig: process
    begin
        vid_clk <= '1';
        wait for vid_clk_period / 2;
        vid_clk <= '0';
        wait for vid_clk_period / 2;
    end process;

    d <= rom(to_integer(unsigned(a)));

    video: process
        variable i: integer;
        variable hcnt: integer;
        variable vcnt: integer;
       file ff: text;               
    begin 
    
        i := 0;         
        
        file_open(ff, "..\video\video.txt", write_mode);
    
        wait for clk_period / 2;
    
        while (true) loop       
            while (vsyn /= '1') loop 
                wait for clk_period;
            end loop;                   
            
            while (vsyn /= '0') loop 
                wait for clk_period;
            end loop;                   
                        
            vcnt := 0;
                    
            while (vsyn /= '1') loop 
                if (hsyn = '1') then                    
                    if (hcnt /= 0) then 
                        vcnt := vcnt + 1;
                    end if;
                    hcnt := 0;
                    write_byte(ff, X"FF");
                else                
                    write_byte(ff, colu & "0");                 
                    hcnt := hcnt + 1;
                end if;
                wait for clk_period;
            end loop;                                               
            
            print_msg("Frame", i);
            write_vsync(ff);
                            
            i := i + 1; 
            
        end loop;                       
        
        file_close(ff);
    
    end process;
    
    audio: process      
        variable val: unsigned(4 downto 0);     
       file fa: text;  
        variable auv0: unsigned(3 downto 0);
        variable auv1: unsigned(3 downto 0);
    begin 
    
        file_open(fa, "..\audio\audio.txt", write_mode);        
        
        while (true) loop
            
            val := "00000";

            if (au0 = '1') then
                val := "0" & unsigned(av0);
            end if;

            if (au1 = '1') then 
                val := val + ("0" & unsigned(av1));
            end if;

            write_byte(fa, std_logic_vector("000" & val));

            wait for aud_period;
        end loop;

    end process;
    
    process         
    begin
        load_rom("..\rom\astrblst.txt");
        wait;
    end process;
    
end bench;

