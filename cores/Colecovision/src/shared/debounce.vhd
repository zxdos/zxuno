--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 3/26/2012 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debounce is
	generic (
		counter_size_g	:  integer := 10
	);
	port (
		clk_i				: in  std_logic;
		button_i			: in  std_logic;
		result_o			: out std_logic
	);
end entity;

architecture logic of debounce is

	signal flipflops_s	: std_logic_vector(1 downto 0);												-- input flip flops
	signal counter_set_s	: std_logic;																		-- sync reset to zero
	signal counter_out_s	: std_logic_vector(counter_size_g downto 0) := (others => '0');	-- counter output

begin

	counter_set_s <= flipflops_s(0) xor flipflops_s(1);		-- determine when to start/reset counter

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			flipflops_s(0) <= button_i;
			flipflops_s(1) <= flipflops_s(0);
			if counter_set_s = '1' then								-- reset counter because input is changing
				counter_out_s <= (others => '0');
			elsif counter_out_s(counter_size_g) = '0' then		-- stable input time is not yet met
				counter_out_s <= counter_out_s + 1;
			else																-- stable input time is met
				result_o <= flipflops_s(1);
			end if;
		end if;
	end process;

end architecture;
