--===================================
-- Listing 4.17
--===================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity stop_watch is
   port(
      clk: in std_logic;
      go, clr: in std_logic;
      d2, d1, d0: out std_logic_vector(3 downto 0)
   );
end stop_watch;

architecture cascade_arch of stop_watch is
   constant DVSR: integer:=5000000;
   signal ms_reg, ms_next: unsigned(22 downto 0);
   signal d2_reg, d1_reg, d0_reg: unsigned(3 downto 0);
   signal d2_next, d1_next, d0_next: unsigned(3 downto 0);
   signal d1_en, d2_en, d0_en: std_logic;
   signal ms_tick, d0_tick, d1_tick: std_logic;
begin
   -- register
   process(clk)
   begin
      if (clk'event and clk='1') then
         ms_reg <= ms_next;
         d2_reg <= d2_next;
         d1_reg <= d1_next;
         d0_reg <= d0_next;
      end if;
   end process;

   -- next-state logic
   -- 0.1 sec tick generator: mod-5000000
   ms_next <=
      (others=>'0') when clr='1' or
                        (ms_reg=DVSR and go='1') else
      ms_reg + 1 when go='1' else
      ms_reg;
   ms_tick <= '1' when ms_reg=DVSR else '0';
   -- 0.1 sec counter
   d0_en <= '1' when ms_tick='1' else '0';
   d0_next <=
      "0000" when (clr='1') or (d0_en='1' and d0_reg=9) else
      d0_reg + 1 when d0_en='1' else
      d0_reg;
   d0_tick <= '1' when d0_reg=9 else '0';
   -- 1 sec counter
   d1_en <= '1' when ms_tick='1' and d0_tick='1' else '0';
   d1_next <=
      "0000" when (clr='1') or (d1_en='1' and d1_reg=9) else
      d1_reg + 1 when d1_en='1' else
      d1_reg;
   d1_tick <= '1' when d1_reg=9 else '0';
   -- 10 sec counter
   d2_en <=
      '1' when ms_tick='1' and d0_tick='1' and d1_tick='1' else
      '0';
   d2_next <=
      "0000" when (clr='1') or (d2_en='1' and d2_reg=9) else
      d2_reg + 1 when d2_en='1' else
      d2_reg;

   -- output logic
   d0 <= std_logic_vector(d0_reg);
   d1 <= std_logic_vector(d1_reg);
   d2 <= std_logic_vector(d2_reg);
end cascade_arch;


--===================================
-- Listing 4.18
--===================================
architecture if_arch of stop_watch is
   constant DVSR: integer:=5000000;
   signal ms_reg, ms_next: unsigned(22 downto 0);
   signal d2_reg, d1_reg, d0_reg: unsigned(3 downto 0);
   signal d2_next, d1_next, d0_next: unsigned(3 downto 0);
   signal ms_tick: std_logic;
begin
   -- register
   process(clk)
   begin
      if (clk'event and clk='1') then
         ms_reg <= ms_next;
         d2_reg <= d2_next;
         d1_reg <= d1_next;
         d0_reg <= d0_next;
      end if;
   end process;

   -- next-state logic
   -- 0.1 sec tick generator: mod-5000000
   ms_next <=
      (others=>'0') when clr='1' or
                        (ms_reg=DVSR and go='1') else
      ms_reg + 1 when go='1' else
      ms_reg;
   ms_tick <= '1' when ms_reg=DVSR else '0';
   -- 0.1 sec counter
   process(d0_reg,d1_reg,d2_reg,ms_tick,clr)
   begin
      -- defult
      d0_next <= d0_reg;
      d1_next <= d1_reg;
      d2_next <= d2_reg;
      if clr='1' then
         d0_next <= "0000";
         d1_next <= "0000";
         d2_next <= "0000";
      elsif ms_tick='1' then
         if (d0_reg/=9) then
            d0_next <= d0_reg + 1;
         else       -- reach XX9
            d0_next <= "0000";
            if (d1_reg/=9) then
               d1_next <= d1_reg + 1;
            else    -- reach X99
               d1_next <= "0000";
               if (d2_reg/=9) then
                  d2_next <= d2_reg + 1;
               else -- reach 999
                  d2_next <= "0000";
               end if;
            end if;
         end if;
      end if;
   end process;
   -- output logic
   d0 <= std_logic_vector(d0_reg);
   d1 <= std_logic_vector(d1_reg);
   d2 <= std_logic_vector(d2_reg);
end if_arch;
