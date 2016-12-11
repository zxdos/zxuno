-- Listing 1.2
library ieee;
use ieee.std_logic_1164.all;
entity eq2 is
   port(
      a, b: in std_logic_vector(1 downto 0);
      aeqb: out std_logic
   );
end eq2;

architecture sop_arch of eq2 is
   signal p0,p1,p2,p3: std_logic;
begin
   -- sum of product terms
   aeqb <= p0 or p1 or p2 or p3;
   -- product terms
   p0 <= ((not a(1)) and (not b(1))) and
         ((not a(0)) and (not b(0)));
   p1 <= ((not a(1)) and (not b(1))) and (a(0) and b(0));
   p2 <= (a(1) and b(1)) and ((not a(0)) and (not b(0)));
   p3 <= (a(1) and b(1)) and (a(0) and b(0));
end sop_arch;


-- Listing 1.3
architecture struc_arch of eq2 is
   signal e0, e1: std_logic;
begin
   -- instantiate two 1-bit comparators
   eq_bit0_unit: entity work.eq1(sop_arch)
      port map(i0=>a(0), i1=>b(0), eq=>e0);
   eq_bit1_unit: entity work.eq1(sop_arch)
      port map(i0=>a(1), i1=>b(1), eq=>e1);
   -- a and b are equal if individual bits are equal
   aeqb <= e0 and e1;
end struc_arch;


-- Listing 1.4
architecture vhd_87_arch of eq2 is
   -- component declaration
   component eq1
      port(
         i0, i1: in std_logic;
         eq: out std_logic
      );
   end component;
   signal e0, e1: std_logic;
begin
   -- instantiate two 1-bit comparators
   eq_bit0_unit: eq1   -- use the declared name, eq1
      port map(i0=>a(0), i1=>b(0), eq=>e0);
   eq_bit1_unit: eq1   -- use the declared name, eq1
      port map(i0=>a(1), i1=>b(1), eq=>e1);
   -- a and b are equal if individual bits are equal
   aeqb <= e0 and e1;
end vhd_87_arch;
