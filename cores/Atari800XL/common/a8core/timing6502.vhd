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

ENTITY timing6502 IS
GENERIC
(
	CYCLE_LENGTH : INTEGER :=32;
	CONTROL_BITS : INTEGER :=0
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	-- FPGA side
	ENABLE_179_EARLY : IN STD_LOGIC;

	REQUEST : IN STD_LOGIC;
	ADDR_IN : IN STD_LOGIC_VECTOR(15 downto 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	WRITE_IN : IN STD_LOGIC;
	CONTROL_N_IN : IN STD_LOGIC_VECTOR(CONTROL_BITS-1 downto 0);

	DATA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	COMPLETE : OUT STD_LOGIC;

	-- 6502 side
	BUS_DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	
	BUS_PHI1 : OUT STD_LOGIC;
	BUS_PHI2 : OUT STD_LOGIC;
	BUS_SUBCYCLE : OUT STD_LOGIC_VECTOR(3 downto 0);
	BUS_ADDR_OUT : OUT STD_LOGIC_VECTOR(15 downto 0);
	BUS_ADDR_OE : OUT STD_LOGIC;
	BUS_DATA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	BUS_DATA_OE : OUT STD_LOGIC;
	BUS_WRITE_N : OUT STD_LOGIC;
	BUS_CONTROL_N : OUT STD_LOGIC_VECTOR(CONTROL_BITS-1 downto 0);
	BUS_CONTROL_OE : OUT STD_LOGIC
);
END timing6502;

ARCHITECTURE vhdl OF timing6502 IS
	signal state_next : std_logic_vector(3 downto 0);
	signal state_reg : STD_LOGIC_VECTOR(3 DOWNTO 0);

	signal odd_next : std_logic;
	signal odd_reg : std_logic;

	signal addr_next : std_logic_vector(15 downto 0);
	signal addr_reg : std_logic_vector(15 downto 0);

	signal addr_oe_next : std_logic;
	signal addr_oe_reg : std_logic;

	signal data_next : std_logic_vector(7 downto 0);
	signal data_reg : std_logic_vector(7 downto 0);

	signal data_oe_next : std_logic;
	signal data_oe_reg : std_logic;

	signal data_read_next : std_logic_vector(7 downto 0);
	signal data_read_reg : std_logic_vector(7 downto 0);

	signal phi1_next : std_logic;
	signal phi1_reg : std_logic;

	signal phi2_next : std_logic;
	signal phi2_reg : std_logic;

	signal write_n_next : std_logic;
	signal write_n_reg : std_logic;

	signal control_n_next : std_logic_vector(CONTROL_BITS-1 downto 0);
	signal control_n_reg : std_logic_vector(CONTROL_BITS-1 downto 0);

	signal control_oe_next : std_logic;
	signal control_oe_reg : std_logic;

	signal complete_next : std_logic;
	signal complete_reg : std_logic;

	signal request_pending_next : std_logic;
	signal request_pending_reg : std_logic;

	signal request_handling_next : std_logic;
	signal request_handling_reg : std_logic;
BEGIN
	-- regs

	process(clk, reset_n)
	begin
		if (reset_n='0') then
			state_reg <= (others=>'0');
			odd_reg <= '0';
			addr_reg <= (others=>'0');
			addr_oe_reg <= '0';
			data_reg <= (others=>'0');
			data_read_reg <= (others=>'0');
			data_oe_reg <= '0';
			phi1_reg <= '0';
			phi2_reg <= '0';
			write_n_reg <= '1';
			control_n_reg <= (others=>'1');
			control_oe_reg <= '0';
			complete_reg <= '0';
			request_pending_reg <= '0';
			request_handling_reg <= '0';
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
			odd_reg <= odd_next;
			addr_reg <= addr_next;
			addr_oe_reg <= addr_oe_next;
			data_reg <= data_next;
			data_read_reg <= data_read_next;
			data_oe_reg <= data_oe_next;
			phi1_reg <= phi1_next;
			phi2_reg <= phi2_next;
			write_n_reg <= write_n_next;
			control_n_reg <= control_n_next;
			control_oe_reg <= control_oe_next;
			complete_reg <= complete_next;
			request_pending_reg <= request_pending_next;
			request_handling_reg <= request_handling_next;
		end if;
	end process;

	-- next state
	process(enable_179_early, state_reg, odd_reg, phi1_reg, phi2_reg, request, addr_in, data_in, addr_reg, addr_oe_reg, data_reg, data_oe_reg, data_read_reg, bus_data_in, write_n_reg, write_in,  request_pending_reg, request_handling_reg, control_n_reg, control_oe_reg, control_n_in)
	begin
		state_next <= state_reg;
		odd_next <= not(odd_reg);
		phi1_next <= phi1_reg;
		phi2_next <= phi2_reg;
		addr_next <= addr_reg;
		addr_oe_next <= addr_oe_reg;
		data_next <= data_reg;
		data_oe_next <= data_oe_reg;
		complete_next <= '0';
		data_read_next <= data_read_reg;
		write_n_next <= write_n_reg;
		request_pending_next <= request_pending_reg;
		request_handling_next <= request_handling_reg;
		control_n_next <= control_n_reg;
		control_oe_next <= control_oe_reg;

		if (enable_179_early = '1') then
			state_next <= (others=>'0'); -- re-sync
			odd_next <= '1';
		end if;

		if (odd_reg = '1' or cycle_length = 16) then
			state_next <= std_logic_vector(unsigned(state_reg)+1);
		end if;

		request_pending_next <= request_pending_reg or request;

		case state_reg is
		when x"0" =>
			if ((request or request_pending_reg)='1') then
				addr_next <= addr_in;
				data_next <= data_in;
				write_n_next <= not(write_in);
				control_n_next <= control_n_in;
				request_pending_next <= '0';
				request_handling_next <= '1';
			end if;
		when x"1"=>
			addr_oe_next <= '1';
			control_oe_next <= '1';
		when x"2"|x"3"|x"4"|x"5" =>
		when x"6" =>
			phi1_next <= '0';
		when x"7" =>
			phi2_next <= '1';
		when x"8" =>
		when x"9"|x"a" =>
		when x"b" =>
			if (write_in = '1') then
				data_oe_next <= '1';
			end if;
		when x"c" =>
		when x"d" =>
			complete_next <= request_handling_reg;
			request_handling_next <= '0';
			data_read_next <= bus_data_in;
		when x"e" =>
			phi2_next <= '0';
		when x"f" =>
			addr_next <= (others=>'0');
			addr_oe_next <= '0';
			control_n_next <= (others=>'1');
			control_oe_next <= '0';
			data_oe_next <= '0';
			write_n_next <= '1';
			phi1_next <= '1';
		end case;

	end process;

	-- outputs
	BUS_SUBCYCLE <= state_reg;
	BUS_PHI1 <= phi1_reg;
	BUS_PHI2 <= phi2_reg;
	BUS_ADDR_OUT <= addr_reg;
	BUS_ADDR_OE <= addr_oe_reg;
	BUS_DATA_OUT <= data_reg;
	BUS_DATA_OE <= data_oe_reg;
	BUS_WRITE_N <= write_n_reg;
	BUS_CONTROL_N <= control_n_reg;
	BUS_CONTROL_OE <= control_oe_reg;
	
	DATA_OUT <= data_read_reg;
	COMPLETE <= complete_reg;
	
END vhdl;
