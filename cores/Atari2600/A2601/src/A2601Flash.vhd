-- A2601 Top Level Entity (Rev B Board with Flash Memory)
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

-- This top level entity supports many bankswitching schemes and multiple
-- game ROMs stored in on-board Flash memory. ROM properties are stored in
-- FPGA built-in SRAM (see CartTable entity). To generate the CartTable, use
-- multirom.py in util directory.,
--
-- This top level entity accepts user input from a MegaDrive/Genesis Joypad.
-- Pin names starting with p_ designate joypad input/outputs.
--
-- For more information, see the A2601 Rev B Board Schematics and project
-- website at <http://retromaster.wordpress.org/a2601>.

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity A2601Flash is
   port (clk: in std_logic;
         d: in std_logic_vector(7 downto 0);
         a: out std_logic_vector(18 downto 0);
         oe: out std_logic;
         we: out std_logic;
         cv: out std_logic_vector(7 downto 0);
         au: out std_logic_vector(4 downto 0);
         p_l: in std_logic;
         p_r: in std_logic;
         p_a: in std_logic;
         p_u: in std_logic;
         p_d: in std_logic;
         p_s: in std_logic;
         p_bs: out std_logic);
end A2601Flash;

architecture arch of A2601Flash is

    component a2601_dcm is
        port(clkin_in: in std_logic;
             rst_in: in std_logic;
             clkfx_out: out std_logic;
             clkin_ibufg_out: out std_logic);
    end component;

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
         cv: out std_logic_vector(7 downto 0);
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

    component CartTable is
        port(clk: in std_logic;
             d: out std_logic_vector(10 downto 0);
             c: out std_logic_vector(6 downto 0);
             a: in std_logic_vector(6 downto 0));
    end component;

    signal vid_clk: std_logic;
    signal pa: std_logic_vector(7 downto 0) := "11111111";
    signal pb: std_logic_vector(7 downto 0) := "11111111";
    signal inpt4: std_logic := '1';
    signal inpt5: std_logic := '1';
    signal colu: std_logic_vector(6 downto 0);
    signal csyn: std_logic;
    signal vsyn: std_logic;
    signal hsyn: std_logic;
    signal au0: std_logic;
    signal au1: std_logic;
    signal av0: std_logic_vector(3 downto 0);
    signal av1: std_logic_vector(3 downto 0);

    signal auv0: unsigned(4 downto 0);
    signal auv1: unsigned(4 downto 0);

    signal rst: std_logic := '1';

    signal rst_cntr: unsigned(7 downto 0) := "00000000";

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

    signal cpu_a: std_logic_vector(12 downto 0);
    signal cpu_d: std_logic_vector(7 downto 0);
    signal cpu_r: std_logic;

    signal cart_info: std_logic_vector(10 downto 0) := "00000000000";
    signal cart_cntr: unsigned(6 downto 0) := "0000000";
    signal cart_max: std_logic_vector(6 downto 0);
    signal cart_vect: std_logic_vector(6 downto 0) := "0000000";

    signal cart_next: std_logic;
    signal cart_prev: std_logic;
    signal cart_swch: std_logic := '0';
    signal cart_next_l: std_logic;
    signal cart_prev_l: std_logic;

    signal gsel: std_logic;
    signal p_fn: std_logic;
    signal res: std_logic;
    signal sel: std_logic;

    signal ctrl_cntr: unsigned(3 downto 0);

begin

    brd_a2601_dcm: a2601_dcm
        port map(clk, '0', vid_clk, open);

    brd_A2601: A2601
        port map(vid_clk, rst, cpu_d, cpu_a, cpu_r, pa, pb, inpt4, inpt5, colu, csyn, vsyn, hsyn, cv, au0, au1, av0, av1, ph0, ph1);

    brd_CartTable: CartTable
        port map(ph0, cart_info, cart_max, std_logic_vector(cart_cntr));

    auv0 <= ("0" & unsigned(av0)) when (au0 = '1') else "00000";
    auv1 <= ("0" & unsigned(av1)) when (au1 = '1') else "00000";

    au <= std_logic_vector(auv0 + auv1);

    process(ph0)
    begin
        if (ph0'event and ph0 = '1') then
            rst_cntr <= rst_cntr + 1;
            if (rst_cntr = "11111111") then
                if (cart_next_l = '0') and (cart_next = '1') then
                    if (cart_cntr = unsigned(cart_max)) then
                        cart_cntr <= "0000000";
                    else
                        cart_cntr <= cart_cntr + 1;
                    end if;
                    rst <= '1';
                    cart_next_l <= '1';
                    cart_prev_l <= '1';
                elsif (cart_prev_l = '0') and (cart_prev = '1') then
                    if (cart_cntr = "0000000") then
                        cart_cntr <= unsigned(cart_max);
                    else
                        cart_cntr <= cart_cntr - 1;
                    end if;
                    rst <= '1';
                    cart_next_l <= '1';
                    cart_prev_l <= '1';
                else
                    cart_next_l <= cart_next;
                    cart_prev_l <= cart_prev;
                end if;
            elsif   (rst_cntr = "10000000") then
                rst <= '0';
            end if;
        end if;
    end process;

    oe <= '0';
    we <= '1';

    -- Controller inputs sampling
    p_bs <= ctrl_cntr(3);

    -- Only one controller port supported.
    pa(3 downto 0) <= "1111";
    inpt5 <= '1';

    process(ph0)
    begin
        if (ph0'event and ph0 = '1') then
            ctrl_cntr <= ctrl_cntr + 1;
            if (ctrl_cntr = "1111") then    -- p_bs
                p_fn <= p_a;
                pb(0) <= p_s;
            elsif (ctrl_cntr = "0111") then
                pa(7 downto 4) <= p_r & p_l & p_d & p_u;
                inpt4 <= p_a;
                gsel <= p_s;
            end if;

            pb(7) <= pa(7) or p_fn;
            pb(6) <= pa(6) or p_fn;
            pb(1) <= pa(4) or p_fn;
            pb(3) <= pa(5) or p_fn;
        end if;
    end process;

    pb(5) <= '1';
    pb(4) <= '1';
    pb(2) <= '1';

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

    with bss select a <=
        cart_vect & cpu_a(11 downto 0) when BANK00,
        cart_vect(6 downto 1) & bank(0) & cpu_a(11 downto 0) when BANKF8,
        cart_vect(6 downto 2) & bank(1 downto 0) & cpu_a(11 downto 0) when BANKF6,
        cart_vect(6 downto 1) & bank(0) & cpu_a(11 downto 0) when BANKFE,
        cart_vect(6 downto 1) & e0_bank & cpu_a(9 downto 0) when BANKE0,
        cart_vect(6 downto 1) & tf_bank & cpu_a(10 downto 0) when BANK3F,
        "-------------------" when others;

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

    bss <= cart_info(3 downto 1);
    sc <= cart_info(0);
    cart_vect <= cart_info(10 downto 4);

    cart_next <= (not pa(7)) and (not gsel);
    cart_prev <= (not pa(6)) and (not gsel);

end arch;





