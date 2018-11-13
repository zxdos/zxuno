-- base sur les infos des pages suivantes :
-- http://www.computer-engineering.org/ps2protocol/
-- http://www.computer-engineering.org/ps2keyboard/
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ps2key is
	generic (
		FREQ		: integer := 24
	);
	port(
		CLK		: in std_logic;
		RESETn	: in std_logic;
		
		PS2CLK	: in std_logic;
		PS2DATA	: in std_logic;

		BREAK		: out std_logic;
		EXTENDED	: out std_logic;
		CODE		: out std_logic_vector(6 downto 0);
		LATCH		: out std_logic		
	);	
end ps2key;

architecture rtl of ps2key is
constant CLKCNT_SAMPLE : integer := FREQ * 20;	-- 20us apres transition de l'horloge

-- Sampling
signal clkcnt	: std_logic_vector(15 downto 0);
signal shift	: std_logic;
signal idlcnt	: std_logic_vector(15 downto 0);

-- Shifting
signal bitcnt	: std_logic_vector(3 downto 0);
signal cready	: std_logic;
signal char		: std_logic_vector(10 downto 1);

-- Decodage
signal brkcode		: std_logic;
signal extcode	: std_logic;

-- Signal de controle
signal kready		: std_logic;

begin
	
process(RESETn, CLK, PS2CLK, PS2DATA)
begin
	if RESETn = '0' then
		clkcnt <= (others => '0');
		shift <= '0';		

		bitcnt <= x"0";
		cready <= '0';
		char <= (others => '0');

		brkcode <= '0';
		extcode <= '0';
		kready <= '0';

	elsif rising_edge(CLK) then

		-- Sampling des bits
		if PS2CLK = '1' then
			shift <= '0';
			clkcnt <= (others => '0');
		else
			clkcnt <= clkcnt + 1;
			if clkcnt = CLKCNT_SAMPLE then
				shift <= '1';
			else
				shift <= '0';
			end if;
		end if;

		-- Bit-shifting
		if shift = '1' then
			char <= PS2DATA & char(10 downto 2);

			if bitcnt = x"A" then
				bitcnt <= x"0";
				cready <= '1';
			else
				bitcnt <= bitcnt + 1;
			end if;
		end if;

		-- Decodage sequence
		if cready = '1' then	
			cready <= '0';
			if char(8 downto 1) = x"E0" then
				extcode <= '1';
				kready <= '0';				
			elsif char(8 downto 1) = x"F0" then
				brkcode <= '1';
				kready <= '0';							
			elsif char(8) = '1' then -- les codes > 0x7F sont reserves apparemment
				kready <= '0';				
			else
				kready <= '1';
			end if;	
		else 
			if kready = '1' then
				brkcode <= '0';
				extcode <= '0';
				kready <= '0';
			end if;
		end if;

	end if;
end process;

BREAK <= brkcode;
EXTENDED <= extcode;
CODE <= char(7 downto 1);
LATCH <= kready;

end rtl;
