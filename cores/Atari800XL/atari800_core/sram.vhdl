---------------------------------------------------------------------------
-- (c) 2013,2015 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

ENTITY sram IS
PORT 
( 
	ADDRESS : IN STD_LOGIC_VECTOR(18 DOWNTO 0); --20 downto 0
	DIN : IN STD_LOGIC_vector(31 downto 0);
	WREN : IN STD_LOGIC;
	
	clk : in std_logic;
	reset_n : in std_logic;
	
	request : in std_logic;

	width32bit : in std_logic;	-- 32-bit read/write
	
	-- SRAM interface
	SRAM_ADDR: OUT STD_LOGIC_VECTOR(18 downto 0); --20 downto 0
--	SRAM_CE_N: OUT STD_LOGIC;
--	SRAM_OE_N: OUT STD_LOGIC;
	SRAM_WE_N: OUT STD_LOGIC;

	SRAM_DQ: INOUT STD_LOGIC_VECTOR(7 downto 0);
	
	-- Provide data to system
	DOUT : OUT STD_LOGIC_VECTOR(31 downto 0);
	complete : out std_logic;
	scandc : out std_logic
);

END sram;

-- first cycle, capture inputs
-- second cycle, sram access
ARCHITECTURE slow OF sram IS
	signal oe_n_next : std_logic;
	signal oe_n_reg : std_logic;
	
	signal we_n_next : std_logic;
	signal we_n_reg : std_logic;	

	signal address_next : std_logic_vector(18 downto 0); --20 downto 0
	signal address_reg : std_logic_vector(18 downto 0); --20 downto 0
	
	signal data_write_next : std_logic_vector(31 downto 0);
	signal data_write_reg : std_logic_vector(31 downto 0);

	signal data_read_next : std_logic_vector(31 downto 0);
	signal data_read_reg : std_logic_vector(31 downto 0);
	
	signal complete_next : std_logic;
	signal complete_reg : std_logic;

	constant state_idle : std_logic_vector(3 downto 0) := "0000";
	constant state_read_byte1   : std_logic_vector(3 downto 0) := "0001";
	constant state_read_byte2   : std_logic_vector(3 downto 0) := "0010";
	constant state_read_byte3   : std_logic_vector(3 downto 0) := "0011";
	constant state_read_byte4   : std_logic_vector(3 downto 0) := "0100";
	constant state_write_byte1a : std_logic_vector(3 downto 0) := "0101";
	constant state_write_byte1b : std_logic_vector(3 downto 0) := "0110";
	constant state_write_byte2a : std_logic_vector(3 downto 0) := "0111";
	constant state_write_byte2b : std_logic_vector(3 downto 0) := "1000";
	constant state_write_byte3a : std_logic_vector(3 downto 0) := "1001";
	constant state_write_byte3b : std_logic_vector(3 downto 0) := "1010";
	constant state_write_byte4a : std_logic_vector(3 downto 0) := "1011";
	constant state_read_byte4b  : std_logic_vector(3 downto 0) := "1101";
	signal state_next : std_logic_vector(3 downto 0);
	signal state_reg : std_logic_vector(3 downto 0);
	
	signal scandoubler_ctrl: std_logic_vector(1 downto 0);
	
BEGIN

	-- registers
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			oe_n_reg <= '1';
			we_n_reg <= '1';
			data_write_reg <= (others=>'0');
			data_read_reg <= (others=>'0');
			complete_reg <= '0';
			state_reg <= state_idle;

			address_reg <= "0001000111111010101"; --0x8FD5 SRAM (SCANDBLCTRL ZXUNO REG)
			scandoubler_ctrl <= sram_dq(1 downto 0);			
			
		elsif (clk'event and clk='1') then
			oe_n_reg <= oe_n_next;
			we_n_reg <= we_n_next;
			data_write_reg <= data_write_next;
			data_read_reg <= data_read_next;
			complete_reg <= complete_next;
			state_reg <= state_next;
			address_reg <= address_next;
		end if;
	end process;

	-- next state
	process(din,wren,request,state_reg,width32bit,sram_dq,data_read_reg,data_write_reg,address_reg,address)
	begin		
		state_next <= state_reg;
		data_write_next <= data_write_reg;
		data_read_next <= data_read_reg;
		complete_next <= '0';
		
		oe_n_next <= '0';
		we_n_next <= '1';
		address_next <= address_reg;
		
			-- on second cycle do write - address/data stable by now guaranteed (normal timequest...)

		case state_reg is
		when state_idle =>
			if (request = '1') then
				data_write_next <= din;
				address_next <= address;
				if (width32bit = '1') then
					if (wren = '1') then
						address_next(1 downto 0) <= "00";
						state_next <= state_write_byte1a;
					else
						address_next(1 downto 0) <= "11";
						state_next <= state_read_byte1;
					end if;
				else
					if (wren = '1') then
						state_next <= state_write_byte4a;
					else
						state_next <= state_read_byte4;
					end if;
				end if;
			end if;

		when state_read_byte1 =>
			address_next(1 downto 0) <= "10";
			data_read_next(31 downto 24) <= SRAM_DQ;
			state_next <= state_read_byte2;
		when state_read_byte2 =>
			address_next(1 downto 0) <= "01";
			data_read_next(23 downto 16) <= SRAM_DQ;
			state_next <= state_read_byte3;
		when state_read_byte3 =>
			address_next(1 downto 0) <= "00";
			data_read_next(15 downto 8) <= SRAM_DQ;
			state_next <= state_read_byte4;
		when state_read_byte4 =>
			data_read_next(7 downto 0) <= SRAM_DQ;
			state_next <= state_idle;
			complete_next <= '1';

		when state_write_byte1a =>
			state_next <= state_write_byte1b;
			we_n_next <= '0';
			oe_n_next <= '1';
		when state_write_byte1b =>
			address_next(1 downto 0) <= "01";
			data_write_next(23 downto 0) <= data_write_reg(31 downto 8);
			state_next <= state_write_byte2a;
			we_n_next <= '1';
			oe_n_next <= '1';
		when state_write_byte2a =>
			state_next <= state_write_byte2b;
			we_n_next <= '0';
			oe_n_next <= '1';
		when state_write_byte2b =>
			address_next(1 downto 0) <= "10";
			data_write_next(23 downto 0) <= data_write_reg(31 downto 8);
			state_next <= state_write_byte3a;
			we_n_next <= '1';
			oe_n_next <= '1';
		when state_write_byte3a =>
			state_next <= state_write_byte3b;
			we_n_next <= '0';
			oe_n_next <= '1';
		when state_write_byte3b =>
			address_next(1 downto 0) <= "11";
			data_write_next(23 downto 0) <= data_write_reg(31 downto 8);
			state_next <= state_write_byte4a;
			we_n_next <= '1';
			oe_n_next <= '1';
		when state_write_byte4a =>
			we_n_next <= '0';
			oe_n_next <= '1';
			complete_next <= '1';
			state_next <= state_idle;
		when others =>
			state_next <= state_idle;
		end case;
	end process;
	
	-- output
--	SRAM_CE_N <= '0';
--	SRAM_OE_N <= oe_n_reg;
	SRAM_WE_N <= we_n_reg;
	SRAM_DQ <= data_write_reg(7 downto 0) when we_n_reg = '0' else (others=>'Z');
	SRAM_ADDR <= address_reg;

	DOUT <= data_read_next;
			
	complete <= complete_reg;		
	
	scandc <= scandoubler_ctrl(0);
		
	--GPIO <= (others=>'0');
END slow;

