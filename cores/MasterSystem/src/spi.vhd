library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi is
	Port (
		clk	: in  STD_LOGIC;
		RD_n	: in  STD_LOGIC;
		WR_n	: in  STD_LOGIC;
		A		: in  STD_LOGIC_VECTOR (7 downto 0);
		D_in	: in  STD_LOGIC_VECTOR (7 downto 0);
		D_out	: out STD_LOGIC_VECTOR (7 downto 0);
		
		cs_n	: buffer STD_LOGIC;
		sclk	: out STD_LOGIC;
		miso	: in  STD_LOGIC;
		mosi	: out STD_LOGIC);
end spi;

architecture Behavioral of spi is
	signal ready	: std_logic := '1';
	signal clk_div	: unsigned(6 downto 0) := "0000000";
	signal clk_cnt	: unsigned(6 downto 0) := "0000000";
	signal bit_cnt	: unsigned(3 downto 0) := "0000";
	signal shift	: std_logic_vector(7 downto 0);
	signal in_sclk	: std_logic := '1';
begin
	ready <= '1' when bit_cnt=0 else '0';
	
	process (clk,A,WR_n,RD_n,D_in,miso)
	begin
		if rising_edge(clk) then
			if ready='0' then
				case clk_cnt is
				when "0000000" =>
					if in_sclk='1' then
						mosi <= shift(7);
					elsif in_sclk='0' then
						shift <= shift(6 downto 0)&miso;
						bit_cnt <= bit_cnt-1;
					end if;					
					clk_cnt <= clk_div;
					in_sclk <= not in_sclk;
				when others =>
					clk_cnt <= clk_cnt-1;
				end case;
				
			elsif WR_n='0' then
				if A(0)='0' then
					cs_n <= D_in(7);
					clk_div <= unsigned(D_in(6 downto 0));
				elsif ready='1' then
					shift <= D_in;
					bit_cnt <= "1000";
					clk_cnt <= "0000001";
				end if;
			end if;
		end if;
	end process;
	
	
	
	process (clk,A,WR_n,RD_n,D_in,miso)
	begin
		if rising_edge(clk) and RD_n='0' then
			if A(0)='0' then
				D_out <= ready&std_logic_vector(clk_div);
			else
				D_out <= shift;
			end if;
		end if;
	end process;
	
	sclk <= in_sclk;

end Behavioral;

