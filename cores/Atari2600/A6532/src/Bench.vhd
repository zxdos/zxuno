-- A6532 RAM-I/O-Timer (RIOT)
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
    port(io_dbg: out std_logic_vector(7 downto 0));     
end bench;

architecture bench of bench is
        
    component A6532 is
        port(clk: in std_logic;
             rst: in std_logic;
             r: in std_logic;
             rs: in std_logic;
             cs1: in std_logic;
             cs2: in std_logic;
             irq: out std_logic;
             d: inout std_logic_vector(7 downto 0);
             pa: inout std_logic_vector(7 downto 0);
             pb: inout std_logic_vector(7 downto 0);
             pa7: in std_logic;
             a: in std_logic_vector(6 downto 0));
    end component;

    type io_data_array is array(0 to 3) of std_logic_vector(7 downto 0);
    constant io_data: io_data_array := (X"00", X"F0", X"0F", X"FF");

    signal clk: std_logic;
    signal rst: std_logic;
    signal r: std_logic;
    signal rs: std_logic;
    signal cs1: std_logic;
    signal cs2: std_logic;
    signal irq: std_logic;
    signal d: std_logic_vector(7 downto 0);
    signal pa: std_logic_vector(7 downto 0);
    signal pb: std_logic_vector(7 downto 0);
    signal pa7: std_logic;
    signal a: std_logic_vector(6 downto 0);

    constant clk_period: time := 40 ns;

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

    procedure test_ram(
        signal r: out std_logic;
        signal rs: out std_logic;
        signal cs1: out std_logic;
        signal cs2: out std_logic;
        signal d: inout std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(6 downto 0)) is
        variable i: integer;
        variable k: std_logic_vector(7 downto 0);
    begin
        rs <= '0';
        r <= '0';
        cs1 <= '1';
        cs2 <= '0';

        for i in 0 to 127 loop
            a <= conv_std_logic_vector(i, 7);
            d <= conv_std_logic_vector(255 - i, 8);
            wait for clk_period;
        end loop;

        d <= "ZZZZZZZZ";
        r <= '1';

        for i in 0 to 127 loop
            a <= conv_std_logic_vector(i, 7);
            wait for clk_period / 2;
            k := d;
            assert (k = conv_std_logic_vector(255 - i, 8)) report "RAM Read Failed.";
            wait for clk_period / 2;
        end loop;

    end procedure test_ram;

    procedure test_timer(
        signal r: out std_logic;
        signal rs: out std_logic;
        signal cs1: out std_logic;
        signal cs2: out std_logic;
        signal d: inout std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(6 downto 0);
        constant mode: in std_logic_vector(1 downto 0)) is
        variable i, j: integer;
        variable k: std_logic_vector(7 downto 0);
        variable intvl: integer;
    begin
        case mode is
            when "00" => intvl := 1;
            when "01" => intvl := 8;
            when "10" => intvl := 64;
            when "11" => intvl := 1024;
            when others => null;
        end case;

        rs <= '1';
        r <= '0';
        cs1 <= '1';
        cs2 <= '0';

        a <= "00111" & mode;
        d <= X"10";
        wait for clk_period;

        a <= "0011100";
        r <= '1';
        d <= "ZZZZZZZZ";
        for i in 16 downto 0 loop
            for j in intvl downto 1 loop
                k := d;
                assert (k = conv_std_logic_vector(i, 8)) report "Timer Read Failed.";
                assert (irq = '1') report "Timer IRQ Failed.";
                wait for clk_period;
            end loop;
        end loop;

        assert (irq = '0') report "Timer IRQ Failed.";

        cs1 <= '0';
        cs2 <= '1';
        for i in 255 downto 0 loop
            wait for clk_period;
            k := d;
            assert (k = "ZZZZZZZZ") report "Chip Select Failed.";
            assert (irq = '0') report "Timer IRQ Failed.";
        end loop;

        cs1 <= '1';
        cs2 <= '0';
        wait for clk_period / 4;
        k := d;
        assert (k = "00000000") report "Timer Read Failed.";
        wait for 3 * clk_period / 4;

        assert (irq = '1') report "Timer IRQ Failed.";

    end procedure test_timer;

    procedure test_io(
        signal r: out std_logic;
        signal rs: out std_logic;
        signal cs1: out std_logic;
        signal cs2: out std_logic;
        signal d: inout std_logic_vector(7 downto 0);
        signal a: out std_logic_vector(6 downto 0);
        constant ab: in std_logic;
        signal p: inout std_logic_vector(7 downto 0);
        signal io_dbg: out std_logic_vector(7 downto 0)
        ) is
        variable i, j, k, l: integer;
        variable d_in: std_logic_vector(7 downto 0);
        variable ddr: std_logic_vector(7 downto 0);
    begin

        cs1 <= '1';
        cs2 <= '0';
        rs <= '1';

        for i in io_data'range loop
            for j in io_data'range loop
                for k in 0 to 255 loop

                    ddr := conv_std_logic_vector(k, 8);

                    r <= '0';
                    a <= "00000" & ab & "0";
                    d <= io_data(i);
                    wait for clk_period;
                    a <= "00000" & ab & "1";
                    d <= ddr;
                    wait for clk_period;

                    r <= '1';
                    a <= "00000" & ab & "0";
                    d <= "ZZZZZZZZ";

                    io_dbg <= io_data(j);
                    for l in 0 to 7 loop
                        if (ddr(l) = '0') then
                            p(l) <= io_data(j)(l);
                        else
                            p(l) <= 'Z';
                        end if;
                    end loop;

                    wait for clk_period / 4;

                    d_in := d;

                    for l in 0 to 7 loop
                        if (ddr(l) = '0') then
                            assert (d_in(l) = io_data(j)(l)) report "Input failed.";
                        else
                            assert (p(l) = io_data(i)(l)) report "Output failed.";
                        end if;
                    end loop;

                    wait for 3 * clk_period / 4;

                end loop;
            end loop;
        end loop;

    end procedure test_io;

begin

    test_6532: A6532 port map(clk, rst, r, rs, cs1, cs2, irq, d, pa, pb, pa7, a);

    clk_sig: process
    begin
        clk <= '1';
        wait for clk_period / 2;
        clk <= '0';
        wait for clk_period / 2;
    end process;

    process
    begin

        rst <= '1';
        wait for clk_period / 4;
        rst <= '0';

        test_ram(r, rs, cs1, cs2, d, a);
        status_report("RAM Test: Done.");

        test_timer(r, rs, cs1, cs2, d, a, "00");
        test_timer(r, rs, cs1, cs2, d, a, "01");
        test_timer(r, rs, cs1, cs2, d, a, "10");
        test_timer(r, rs, cs1, cs2, d, a, "11");
        status_report("Timer Test: Done.");

        test_io(r, rs, cs1, cs2, d, a, '0', pa, io_dbg);
        test_io(r, rs, cs1, cs2, d, a, '1', pb, io_dbg);
        status_report("IO Test: Done.");

        wait;

    end process;

end bench;

