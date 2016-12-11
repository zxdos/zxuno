-- Listing 3.19
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity fp_adder is
   port (
      sign1, sign2: in  std_logic;
      exp1, exp2: in  std_logic_vector(3 downto 0);
      frac1, frac2: in  std_logic_vector(7 downto 0);
      sign_out: out std_logic;
      exp_out: out std_logic_vector(3 downto 0);
      frac_out: out std_logic_vector(7 downto 0)
   );
end fp_adder ;

architecture arch of fp_adder is
   -- suffix b, s, a, n for
   --        big, small, aligned, normalized number
   signal signb, signs: std_logic;
   signal expb, exps, expn: unsigned(3 downto 0);
   signal fracb, fracs, fraca, fracn: unsigned(7 downto 0);
   signal sum_norm: unsigned(7 downto 0);
   signal exp_diff: unsigned(3 downto 0);
   signal sum: unsigned(8 downto 0); --one extra for carry
   signal lead0: unsigned(2 downto 0);
begin
   -- 1st stage: sort to find the larger number
   process (sign1, sign2, exp1, exp2, frac1, frac2)
   begin
      if (exp1 & frac1) > (exp2 & frac2) then
         signb <= sign1;
         signs <= sign2;
         expb <= unsigned(exp1);
         exps <= unsigned(exp2);
         fracb <= unsigned(frac1);
         fracs <= unsigned(frac2);
      else
         signb <= sign2;
         signs <= sign1;
         expb <= unsigned(exp2);
         exps <= unsigned(exp1);
         fracb <= unsigned(frac2);
         fracs <= unsigned(frac1);
      end if;
   end process;

   --  2nd stage: align smaller number
   exp_diff <= expb - exps;
   with exp_diff select
      fraca <=
         fracs                         when "0000",
         "0"       & fracs(7 downto 1) when "0001",
         "00"      & fracs(7 downto 2) when "0010",
         "000"     & fracs(7 downto 3) when "0011",
         "0000"    & fracs(7 downto 4) when "0100",
         "00000"   & fracs(7 downto 5) when "0101",
         "000000"  & fracs(7 downto 6) when "0110",
         "0000000" & fracs(7)          when "0111",
         "00000000"                    when others;

   -- 3rd stage: add/substract
   sum <= ('0' & fracb) + ('0' & fraca) when signb=signs else
          ('0' & fracb) - ('0' & fraca);

   -- 4th stage: normalize
   -- count leading 0s
   lead0 <= "000" when (sum(7)='1') else
            "001" when (sum(6)='1') else
            "010" when (sum(5)='1') else
            "011" when (sum(4)='1') else
            "100" when (sum(3)='1') else
            "101" when (sum(2)='1') else
            "110" when (sum(1)='1') else
            "111";
   -- shift significand according to leading 0
   with lead0 select
      sum_norm <=
         sum(7 downto 0)             when "000",
         sum(6 downto 0) & '0'       when "001",
         sum(5 downto 0) & "00"      when "010",
         sum(4 downto 0) & "000"     when "011",
         sum(3 downto 0) & "0000"    when "100",
         sum(2 downto 0) & "00000"   when "101",
         sum(1 downto 0) & "000000"  when "110",
         sum(0) &          "0000000" when others;

   -- normalize with special conditions
   process(sum,sum_norm,expb,lead0)
   begin
      if sum(8)='1' then -- w/ carry out; shift frac to right
         expn <= expb + 1;
         fracn <= sum(8 downto 1);
      elsif (lead0 > expb) then  -- too small to normalize;
         expn <= (others=>'0');  -- set to 0
         fracn <= (others=>'0');
      else
         expn <= expb - lead0;
         fracn <= sum_norm;
      end if;
   end process;

   -- form output
   sign_out <= signb;
   exp_out <= std_logic_vector(expn);
   frac_out <= std_logic_vector(fracn);
end arch;
