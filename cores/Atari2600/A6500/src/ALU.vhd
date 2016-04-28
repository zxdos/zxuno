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
use ieee.numeric_std.all;    

entity bcd_fixup is
   port(a: in unsigned(4 downto 0);       
        o: out unsigned(4 downto 0);
        add: in std_logic);
end bcd_fixup;

architecture arch of bcd_fixup is
    signal add_o: unsigned(4 downto 0);
    signal sub_o: unsigned(4 downto 0);
begin
    with a select add_o <=
        "00000" when "00000",
        "00001" when "00001",
        "00010" when "00010",
        "00011" when "00011",
        "00100" when "00100",
        "00101" when "00101",
        "00110" when "00110",
        "00111" when "00111",
        "01000" when "01000",
        "01001" when "01001",
        "10000" when "01010",
        "10001" when "01011",
        "10010" when "01100",
        "10011" when "01101",
        "10100" when "01110",
        "10101" when "01111",
        "10110" when "10000",
        "10111" when "10001",
        "11000" when "10010",
        "11001" when "10011",
        "XXXXX" when others;

    with a select sub_o <=
        "00000" when "00110",
        "00001" when "00111",
        "00010" when "01000",
        "00011" when "01001",
        "00100" when "01010",
        "00101" when "01011",
        "00110" when "01100",
        "00111" when "01101",
        "01000" when "01110",
        "01001" when "01111",
        "10000" when "10000",
        "10001" when "10001",
        "10010" when "10010",
        "10011" when "10011",
        "10100" when "10100",
        "10101" when "10101",
        "10110" when "10110",
        "10111" when "10111",
        "11000" when "11000",
        "11001" when "11001",
        "XXXXX" when others;

    o <= add_o when add = '1' else sub_o;

end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity ALU is
   Port(a: in std_logic_vector (7 downto 0);
        b: in std_logic_vector (7 downto 0);
        o: out std_logic_vector (7 downto 0);
        c_in: in std_logic;
        c_out: out std_logic;
        z: out std_logic;
        n: out std_logic;
        v: out std_logic;
        fn: in alu_fn;
        bcd: in std_logic);
end ALU;

architecture arch of ALU is

    component bcd_fixup is
        port(a: in unsigned(4 downto 0);
             o: out unsigned(4 downto 0);
             add: in std_logic);
    end component bcd_fixup;

    signal full_sum: std_logic_vector(8 downto 0);
    signal sum: std_logic_vector(7 downto 0);
    signal res: std_logic_vector(7 downto 0);
    signal res_nz: std_logic_vector(7 downto 0);

    signal adder_b: std_logic_vector(7 downto 0);
    signal adder_c_in: std_logic;
    signal adder_c_out: std_logic;
    signal adder_bcd: std_logic;

    signal sum_lo: unsigned(4 downto 0);
    signal sum_hi: unsigned(4 downto 0);
    signal fixed_sum_lo: unsigned(4 downto 0);
    signal fixed_sum_hi: unsigned(4 downto 0);
    signal sum_bcd_lo: unsigned(4 downto 0);
    signal sum_bcd_hi: unsigned(4 downto 0);
    signal fixup_add: std_logic;

begin

    with fn select fixup_add <=
        '1' when "0011",
        '0' when "0111",
        '-' when others;

    bcd_fixup_lo: bcd_fixup port map(sum_lo, sum_bcd_lo, fixup_add);
    bcd_fixup_hi: bcd_fixup port map(sum_hi, sum_bcd_hi, fixup_add);

    -- The adder is divided into two to get the half-carry required for BCD fixup.
    sum_lo <= unsigned("0" & a(3 downto 0)) +
              unsigned("0" & adder_b(3 downto 0)) +
              (unsigned'("0000") & adder_c_in);

    fixed_sum_lo <= sum_lo when adder_bcd = '0' else sum_bcd_lo;

    sum_hi <= unsigned("0" & a(7 downto 4)) +
              unsigned("0" & adder_b(7 downto 4)) +
              (unsigned'("0000") & fixed_sum_lo(4));

    fixed_sum_hi <= sum_hi when adder_bcd = '0' else sum_bcd_hi;

    full_sum <= std_logic_vector(fixed_sum_hi & fixed_sum_lo(3 downto 0));
    sum <= full_sum(7 downto 0);

    adder_c_out <= full_sum(8);

    -- The following is due to not having access to carrys from the adder
    v <= (a(7) xnor adder_b(7)) and (a(7) xor full_sum(7));

    o <= res;

    res_nz <= full_sum(7 downto 0) when (adder_bcd = '1') and (bcd = '1') else res;

    n <= res_nz(7);
    z <= '1' when (res_nz = "00000000") else '0';

    with fn select res <=
        (a or b) when "0000",  -- OR
        (a and b) when "0001",  -- AND
        (a xor b) when "0010",  -- XOR
        (sum) when "0011",  -- ADC
        (a) when "0100",  -- ST(A)
        (b) when "0101",  -- LD(A)  -- b is connected to memory
        (sum) when "0110",  -- CMP
        (sum) when "0111",  -- SBC
        (a(6 downto 0) & '0') when "1000",  -- ASL
        (a(6 downto 0) & c_in) when "1001",  -- ROL
        ('0' & a(7 downto 1)) when "1010",  -- LSR
        (c_in & a(7 downto 1)) when "1011",  -- ROR
        (a) when "1100",  -- ST(X)
        (sum) when "1101",  -- ADD
        (sum) when "1110",  -- DEC
        (sum) when "1111",  -- INC
        "--------" when others;

    with fn select c_out <=
        (adder_c_out) when "0011",  -- ADC
        (adder_c_out) when "0110",  -- CMP  -- CHECK
        (adder_c_out) when "0111",  -- SBC  -- CHECK
        (a(7)) when "1000",  -- ASL
        (a(7)) when "1001",  -- ROL
        (a(0)) when "1010",  -- LSR
        (a(0)) when "1011",  -- ROR
        (adder_c_out) when "1101",  -- ADD
        '-' when others;

    with fn select adder_bcd <=
        (bcd) when "0011",  -- ADC
        '0' when "0110",  -- CMP
        (bcd) when "0111", -- SBC
        '0' when "1101",  -- ADD
        '0' when "1110",  -- DEC
        '0' when "1111",  -- INC
        '-' when others;

    with fn select adder_c_in <=
        (c_in) when "0011",  -- ADC
        '1' when "0110",  -- CMP
        (c_in) when "0111",  -- SBC
        '0' when "1101",  -- ADD
        '0' when "1110",  -- DEC
        '1' when "1111",  -- INC
        '-' when others;

    with fn select adder_b <=
        (b) when "0011",  -- ADC
        (not b) when "0110",  -- CMP
        (not b) when "0111",  -- SBC
        (b) when "1101",  -- ADD
        "11111111" when "1110",  -- DEC
        "00000000" when "1111",  -- INC
        "--------" when others;

end arch;

