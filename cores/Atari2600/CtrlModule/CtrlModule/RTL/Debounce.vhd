library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity debounce is
	generic(
		default : std_logic :='1';
		bits : integer := 12
	);
	port(
		clk : in std_logic;
		signal_in : in std_logic;
		signal_out : out std_logic
	);
end debounce;

architecture RTL of debounce is
signal counter : unsigned(bits-1 downto 0);
signal regin : std_logic := default;	-- Deglitched input signal
signal debtemp : std_logic := default;
begin

	process(clk)
	begin
		if rising_edge(clk) then
			regin <= signal_in;
			if counter=0 then
				if debtemp=regin then -- Is button stable?
					signal_out<=regin;
				else -- No? Start a delay...
					counter<=(others => '1');
				end if;
				debtemp<=regin;
			else
				counter<=counter-1;
			end if;
		end if;
	end process;

end architecture;