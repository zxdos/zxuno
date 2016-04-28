library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
	port (
		clk:  		in  std_logic;
		WR_n:			in  std_logic;
		D_in: 		in  std_logic_vector(7 downto 0);
		serial_out:	out std_logic;
		ready:		out std_logic);
end uart_tx;

architecture Behavioral of uart_tx is

	constant clk_divider:	unsigned(9 downto 0) := "1101000000"; -- 832 = (8000000/9600)-1
	signal clk_counter:		unsigned(9 downto 0);
	signal bit_counter:		unsigned(3 downto 0) := (others=>'0');
	signal shift:				std_logic_vector(7 downto 0);

begin

	ready <= '1' when bit_counter=0 else '0';

	process (clk)
	begin
		if rising_edge(clk) then
			if WR_n='0' then
				bit_counter <= "1010";
				clk_counter <= unsigned(clk_divider);
				shift <= D_in;
				serial_out <= '0';
				
			elsif bit_counter>0 then
				if clk_counter=0 then
					serial_out <= shift(0);
					shift(7 downto 0) <= "1"&shift(7 downto 1);
					bit_counter <= bit_counter-1;
					clk_counter <= clk_divider;
				else
					clk_counter <= clk_counter-1;
				end if;
				
			else
				serial_out <= '1';
			end if;
		end if;
	end process;

end Behavioral;

