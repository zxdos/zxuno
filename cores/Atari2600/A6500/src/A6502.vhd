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

use work.types.all;

entity A6502 is 
    port(clk: in std_logic;       
         rst: in std_logic;  
         irq: in std_logic;
         nmi: in std_logic;
         rdy: in std_logic;
         d: inout std_logic_vector(7 downto 0);
         ad: out std_logic_vector(15 downto 0);
         r: out std_logic);
end A6502;

architecture arch of A6502 is

    component A6500 is
        port(clk: in std_logic;
             rst: in std_logic;
             irq: in std_logic;
             nmi: in std_logic;
             stop: in std_logic;
             de: in std_logic;
             d: inout std_logic_vector(7 downto 0);
             ad: out std_logic_vector(15 downto 0);
             r: out std_logic);
    end component;

    signal stop: std_logic;
    signal r_i: std_logic;
    signal de: std_logic;

begin

    r <= r_i;
    stop <= '1' when
        (rdy = '0' and r_i = '1')
        else '0';

    de <= not r_i;

    cpu_A6500: A6500
        port map(clk, rst, irq, nmi, stop, de, d, ad, r_i);

end arch;
