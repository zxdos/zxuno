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
use ieee.numeric_std.ALL;    

--use work.types.all;

entity A6507 is 
    port(clk: in std_logic;       
         rst: in std_logic;
         rdy: in std_logic;
         d: inout std_logic_vector(7 downto 0);
         ad: out std_logic_vector(12 downto 0);
         r: out std_logic);
end A6507;

architecture arch of A6507 is

    component A6502 is
        port(clk: in std_logic;
             rst: in std_logic;
             irq: in std_logic;
             nmi: in std_logic;
             rdy: in std_logic;
             d: inout std_logic_vector(7 downto 0);
             ad: out std_logic_vector(15 downto 0);
             r: out std_logic);
    end component;

    signal ad_full: unsigned(15 downto 0);
    signal cpuDi: std_logic_vector(7 downto 0);
    signal cpuDo: unsigned(7 downto 0);
    signal cpuWe: std_logic;

begin

    ad <= std_logic_vector(ad_full(12 downto 0));
    r <= not cpuWe;
    
    cpuDi <= d when cpuWe = '0' else "ZZZZZZZZ";
    d <= std_logic_vector(cpuDo) when cpuWe = '1' else "ZZZZZZZZ";
        
	cpu: entity work.cpu65xx
		generic map (
			pipelineOpcode => false,
			pipelineAluMux => false,
			pipelineAluOut => false
		)
		port map (
			clk => clk,
			reset => rst,
			enable => rdy or cpuWe,
			nmi_n => '1',
			irq_n => '1',

			di => unsigned(cpuDi),
			addr => ad_full,
			do => cpuDo,
			we => cpuWe,

			debugOpcode => open,
			debugPc => open,
			debugA => open,
			debugX => open,
			debugY => open,
			debugS => open
		);

end arch;
