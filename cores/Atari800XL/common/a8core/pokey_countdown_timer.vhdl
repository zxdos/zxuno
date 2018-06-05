---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pokey_countdown_timer IS
generic(UNDERFLOW_DELAY : natural := 3);
PORT 
( 
	CLK : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	ENABLE_UNDERFLOW : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	
	WR_EN : IN STD_LOGIC;
	DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);

	DATA_OUT : OUT STD_LOGIC
);
END pokey_countdown_timer;

ARCHITECTURE vhdl OF pokey_countdown_timer IS
	component delay_line IS
	generic(COUNT : natural := 1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		SYNC_RESET : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC;
		
		ENABLE : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		
		DATA_OUT : OUT STD_LOGIC
	);
	END component;
	
	function To_Std_Logic(L: BOOLEAN) return std_ulogic is
	begin
		if L then
			return('1');
		else
			return('0');
		end if;
	end function To_Std_Logic;
	
	signal count_reg : std_logic_vector(7 downto 0);
	signal count_next: std_logic_vector(7 downto 0);
	
	signal underflow : std_logic;
	
	signal count_command : std_logic_vector(1 downto 0);	
	signal underflow_command: std_logic_vector(1 downto 0);	
BEGIN
	-- Instantiate delay (provides output)
	underflow0_delay : delay_line
		generic map (COUNT=>UNDERFLOW_DELAY)
		port map(clk=>clk,sync_reset=>wr_en,data_in=>underflow,enable=>ENABLE_UNDERFLOW,reset_n=>reset_n,data_out=>data_out);

	-- register
	process(clk,reset_n)
	begin
		if (reset_N = '0') then
			count_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			count_reg <= count_next;
		end if;
	end process;

	-- count down on enable
	process(count_reg,enable,wr_en,count_command,data_in)
	begin	
		count_command <= enable&wr_en;
		case count_command is
			when "10" =>
				count_next <= std_logic_vector(unsigned(count_reg) -1);
			when "01"|"11" =>
				count_next <= data_in;
			when others =>
				count_next <= count_reg;
		end case;
	end process;
		
	-- underflow
	process(count_reg,enable,underflow_command)
	begin
		underflow_command <= enable & To_Std_Logic(count_reg = X"00");
		case underflow_command is
			when "11" =>
				underflow <= '1';
			when others =>
				underflow <= '0';
		end case;
	end process;
		
END vhdl;
