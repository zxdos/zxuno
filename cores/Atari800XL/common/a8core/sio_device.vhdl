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

-- Now USB is handled by ZPU its dropping SIO commands on the floor while polling USB
-- Capture the SIO command here, so it can poll the latest command instead
-- All other processing is direct to pokey...

-- memory map
-- 0-0xf = pokey
-- 0x10 = R: read command data(0)
-- 0x11 = R: read command data(1)
-- 0x12 = R: read command data(2)
-- 0x13 = R: read command data(3)
-- 0x14 = R: read command data(4)
-- 0x15 = R(0): command ready
-- 0x15 = W: clear command
ENTITY sio_device IS
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	EN : IN STD_LOGIC;
	WR_EN : IN STD_LOGIC;
	
	RESET_N : IN STD_LOGIC;

	-- clock for pokey
	POKEY_ENABLE : in std_logic;

	-- ATARI interface (in future we can also turbo load by directly hitting memory...)
	SIO_DATA_IN  : out std_logic;
	SIO_COMMAND : in std_logic;
	SIO_DATA_OUT : in std_logic;
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END sio_device;

ARCHITECTURE vhdl OF sio_device IS
	COMPONENT complete_address_decoder IS
	generic (width : natural := 1);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;
	
	signal addr_decoded : std_logic_vector(15 downto 0);

	signal bus_free : std_logic; -- bus is shared between cpu and pokey - free means the cpu is not using it, so the state machine may

	signal pokey_addr : std_logic_vector(3 downto 0);
	signal pokey_data_in : std_logic_vector(7 downto 0);
	signal pokey_wr_en : std_logic;

	signal command_reg : std_logic;
	signal command_next : std_logic;

	signal target_reg : std_logic_vector(2 downto 0);
	signal target_next : std_logic_vector(2 downto 0);
	signal target_wr_en : std_logic;

	signal state_reg : std_logic_vector(3 downto 0);
	signal state_next : std_logic_vector(3 downto 0);
	constant state_wait_high_low : std_logic_vector(3 downto 0) := "0000";
	constant state_command_clear_irq : std_logic_vector(3 downto 0) := "0001";
	constant state_command_enable_irq : std_logic_vector(3 downto 0) := "0010";
	constant state_command_reset_skstat : std_logic_vector(3 downto 0) := "1011";
	constant state_command_wait_for_byte : std_logic_vector(3 downto 0) := "0100";
	constant state_command_clear_irq2 : std_logic_vector(3 downto 0) := "0101";
	constant state_command_enable_irq2 : std_logic_vector(3 downto 0) := "0110";
	constant state_command_read_data : std_logic_vector(3 downto 0) := "0111";
	constant state_command_ready : std_logic_vector(3 downto 0) := "1000";
	constant state_command_error : std_logic_vector(3 downto 0) := "1001";
	constant state_command_stop : std_logic_vector(3 downto 0) := "1111";
	signal clear_request : std_logic;

	signal state_wr_en : std_logic;
	signal state_data : std_logic_vector(7 downto 0);
	signal state_addr : std_logic_vector(3 downto 0);

	subtype command_packet_data_type is std_logic_vector(7 downto 0);
	type command_packet_data_array is array(0 to 4) of command_packet_data_type;
	signal command_packet_data_reg : command_packet_data_array;
	signal command_packet_data_next : command_packet_data_array;

	signal pokey_data_out : std_logic_vector(7 downto 0);

	constant pokey_skrest : std_logic_vector(3 downto 0) := x"a";
	constant pokey_serout : std_logic_vector(3 downto 0) := x"d";
	constant pokey_irqen : std_logic_vector(3 downto 0) := x"e";

	signal en_delay_next : std_logic_vector(31 downto 0);
	signal en_delay_reg : std_logic_vector(31 downto 0);
begin
	-- uart - another Pokey! Running at atari frequency.
	pokey1 : entity work.pokey
		port map (clk=>clk,ENABLE_179=>pokey_enable,addr=>pokey_addr(3 downto 0),data_in=>pokey_data_in,wr_en=>pokey_wr_en,
		reset_n=>reset_n,keyboard_response=>"11",pot_in=>X"00",
		sio_in1=>sio_data_out,sio_in2=>'1',sio_in3=>'1', -- TODO, pokey dir...
		data_out=>pokey_data_out, 
		sio_out1=>sio_data_in);

	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			-- wait for explicit initialisation via clear
			state_reg <= state_command_stop;
			target_reg <= (others=>'0');
			command_reg <= '1';	
			en_delay_reg <= (others=>'0');
		elsif (clk'event and clk='1') then						
			state_reg <= state_next;
			target_reg <= target_next;
			command_packet_data_reg <= command_packet_data_next;
			command_reg <= command_next;
			en_delay_reg <= en_delay_next;
		end if;
	end process;

	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>4)
		port map (addr_in=>addr(3 downto 0), addr_decoded=>addr_decoded);
				
	-- Writes to registers
	process(cpu_data_in,wr_en,addr_decoded, addr)
	begin
		clear_request <= '0';

		if (wr_en = '1' and addr(4)='1') then
			if(addr_decoded(5) = '1') then
				clear_request <= '1';
			end if;	
		end if;
	end process;
	
	-- Read from registers
	process(addr_decoded, addr, pokey_data_out, state_reg, command_packet_data_reg)
	begin
		data_out <= X"00";

		if (addr(4)='1') then
			if (addr_decoded(0) = '1') then
				data_out <= command_packet_data_reg(0);
			end if;
			if (addr_decoded(1) = '1') then
				data_out <= command_packet_data_reg(1);
			end if;
			if (addr_decoded(2) = '1') then
				data_out <= command_packet_data_reg(2);
			end if;
			if (addr_decoded(3) = '1') then
				data_out <= command_packet_data_reg(3);
			end if;
			if (addr_decoded(4) = '1') then
				data_out <= command_packet_data_reg(4);
			end if;

			if (addr_decoded(5) = '1') then
				if (state_reg = state_command_ready) then
					data_out(0) <= '1';
				end if;
				if (state_reg = state_command_stop) then
					data_out(6) <= '1';
				end if;
				if (state_reg = state_command_error) then
					data_out(7) <= '1';
				end if;
			end if;
		else
			data_out <= pokey_data_out;
		end if;
		
	end process;

	-- capture bytes (could use bram, but short on some platforms...)
	process(command_packet_data_reg, target_wr_en, pokey_data_out, target_reg)
	begin
		command_packet_data_next <= command_packet_data_reg;

		if (target_wr_en='1') then
			command_packet_data_next(to_integer(unsigned(target_reg))) <= pokey_data_out;
		end if;
	end process;

	-- state machine
	process(state_reg, command_reg, bus_free, pokey_data_out, target_reg, clear_request, sio_command)
	begin
		state_next <= state_reg;
		state_wr_en <= '0';
		state_data <= (others=>'0');
		state_addr <= (others=>'0');

		target_wr_en<='0';
		target_next<=target_reg;

		command_next <= command_reg;

		if (bus_free = '1') then
			command_next <= sio_command;
			case (state_reg) is
			when state_wait_high_low =>
				target_next<=(others=>'0');
				if (sio_command = '0' and command_reg='1') then
					state_next <= state_command_clear_irq;
				end if;
			when state_command_clear_irq =>
				state_addr<=pokey_irqen;
				state_wr_en<='1';
				state_data<=x"18";
				state_next <= state_command_enable_irq;
			when state_command_enable_irq =>
				state_addr<=pokey_irqen;
				state_wr_en<='1';
				state_data<=x"38";
				state_next <= state_command_reset_skstat;
			when state_command_reset_skstat =>
				state_addr<=pokey_skrest;
				state_wr_en<='1';
				state_data<=x"00";
				state_next <= state_command_wait_for_byte;
			when state_command_wait_for_byte =>
				state_addr<=pokey_irqen;
				if (pokey_data_out(5)='0') then
					state_next <= state_command_clear_irq2;
				else
					if (sio_command = '1') then
						if (target_reg="101") then
							state_next <= state_command_ready;
						else
							state_next <= state_command_error;
						end if;
					end if;
				end if;
			when state_command_clear_irq2 =>
				state_addr<=pokey_irqen;
				state_wr_en<='1';
				state_data<=x"18";
				state_next <= state_command_enable_irq2;
			when state_command_enable_irq2 =>
				state_addr<=pokey_irqen;
				state_wr_en<='1';
				state_data<=x"38";
				state_next <= state_command_read_data;
			when state_command_read_data =>
				state_addr<=pokey_serout;
				state_next <= state_command_wait_for_byte;
				case target_reg is
				when "000"|"001"|"010"|"011"|"100" =>
					target_next <= std_logic_vector(unsigned(target_reg)+1);
					target_wr_en<='1';
				when others =>
					-- indicate error, too many command bytes
					target_next <= "111";
				end case;
			when state_command_ready =>
				if (sio_command = '0') then
					-- invalidate command frame when command goes low
					state_next <= state_command_error;
				end if;
			when state_command_error => null;
			when state_command_stop => null;
			when others =>
				state_next <= state_command_stop;
			end case;
		end if;

		if (clear_request = '1') then
			state_next <= state_wait_high_low;
			command_next <= sio_command;
		end if;
	end process;

	bus_free <= not(en or en_delay_reg(31) or wr_en);

	process(en,en_delay_reg)
	begin
		en_delay_next <= en_delay_reg;
		if (en = '1') then
			en_delay_next <= (others=>'1');
		else
			en_delay_next <= en_delay_reg(30 downto 0)&'0';
		end if;
	end process;

	process(bus_free,addr,state_addr, wr_en, state_wr_en, cpu_data_in, state_data)
	begin
		pokey_addr <= addr(3 downto 0);
		pokey_data_in <= cpu_data_in;
		pokey_wr_en <= wr_en and not(addr(4));
		if (bus_free = '1') then
			pokey_addr <= state_addr;
			pokey_data_in <= state_data;
			pokey_wr_en <= state_wr_en;
		end if;
	end process;

end vhdl;


