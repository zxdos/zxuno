library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity ps2 is
port
(
	clock    : in    std_logic;
	ps2c     : inout std_logic;
	ps2d     : inout std_logic;
	received : out   std_logic;
	scancode : out   std_logic_vector(7 downto 0)
);
end;

architecture behavioral of ps2 is

	constant state_idle       : std_logic_vector(1 downto 0) := "00";
	constant state_receiving  : std_logic_vector(1 downto 0) := "01";
	constant state_waiting    : std_logic_vector(1 downto 0) := "10";
	constant state_received   : std_logic_vector(1 downto 0) := "11";

	constant minClockPulseLen : natural := 30*32; -- 30us @ 32MHz
	constant maxClockPulseLen : natural := 50*32; -- 50us @ 32MHz

	type reg is
	record
		state                 : std_logic_vector( 1 downto 0);
		clockCounter          : std_logic_vector(10 downto 0);
		dataReg               : std_logic_vector(10 downto 0);
		receivedCount         : std_logic_vector( 3 downto 0);
		ps2clkDeglitch        : std_logic_vector( 4 downto 0);
		ps2dataDeglitch       : std_logic_vector( 4 downto 0);
		scancode              : std_logic_vector( 7 downto 0);
		ps2lastClkDeglitched  : std_logic;
		ps2lastDataDeglitched : std_logic;
		ps2ClkDeglitched      : std_logic;
		ps2DataDeglitched     : std_logic;
		dataReceived          : std_logic;
	end record;

	signal n : reg;
	signal r : reg :=
	(
		(others => '0'),
		(others => '0'),
		(others => '0'),
		(others => '0'),
		(others => '0'),
		(others => '0'),
		(others => '0'),
		'0',
		'0',
		'0',
		'0',
		'0'
	);

begin
	ps2c <= 'Z';
	ps2d <= 'Z';
	
	received <= r.dataReceived;
	scancode <= r.scancode;

	process(r, ps2d, ps2c) 
	begin
		n <= r;

		-- remember what the last signals were
		n.ps2lastClkDeglitched <= r.ps2clkDeglitched;
		n.ps2lastClkDeglitched <= r.ps2clkDeglitched;

		-- Deglitch the clock signal
		if ps2c = '1' then
			if r.ps2clkDeglitch < 31 then
				n.ps2clkDeglitch <= r.ps2clkDeglitch+1;
			else
				n.ps2clkDeglitched <= '1';
				n.clockCounter     <= (others => '0');
			end if;
		else
			if r.ps2clkDeglitch > 0 then
				n.ps2clkDeglitch <= r.ps2clkDeglitch-1;
			else
				n.ps2clkDeglitched <= '0';
				n.clockCounter     <= (others => '0');
			end if;
		end if;

		-- Deglitch the data signal
		if ps2d = '1' then
			if r.ps2dataDeglitch < 31 then
				n.ps2dataDeglitch <= r.ps2dataDeglitch+1;
			else
				n.ps2dataDeglitched <= '1';
			end if;
		else
			if r.ps2dataDeglitch > 0 then
				n.ps2dataDeglitch <= r.ps2dataDeglitch-1;
			else
				n.ps2dataDeglitched <= '0';
			end if;
		end if;

		----------------------------------------------------
		-- Now the actual processing of the tidied up signal
		----------------------------------------------------
		case r.state is
		when state_idle =>
			-- Are we waiting for the ps2clk to go low? (start of data)
			n.clockCounter  <= (others => '0');
			n.receivedCount <= (others => '0');
			n.dataReceived  <= '0';
			if r.ps2clkDeglitched = '0' then n.state <= state_receiving; end if;

		when state_receiving =>
			n.clockCounter <= r.clockCounter+1;
			-- is the pulse too long?
			if r.clockCounter > maxClockPulseLen then
				if r.ps2clkDeglitched = '1' then n.state <= state_idle; else n.state <= state_receiving; end if;
			end if;

			if r.ps2lastClkDeglitched = '0' and r.ps2clkDeglitched = '1' then
				-- we on the rising edge of the clock singal
				if r.clockCounter < minClockPulseLen then
					n.state <= state_idle;
				else
					n.receivedCount <= r.receivedCount+1;
					n.clockCounter  <= (others => '0');
					n.dataReg       <= r.ps2dataDeglitched & r.dataReg(10 downto 1);

					if r.receivedCount = 10 then n.state <= state_received; else n.receivedCount <= r.receivedCount+1; end if;
				end if;
			elsif r.ps2lastClkDeglitched = '1' and r.ps2clkDeglitched = '0' then
				-- we on the falling edge of the clock singal
				if r.clockCounter < minClockPulseLen then n.state <= state_waiting; end if;
				n.clockCounter  <= (others => '0');
			end if;

		when state_received =>
			-- Check the start, parity and stopbits are valid, if all are correct, set the "data Received" signal
			if r.dataReg(10) = '1' and (r.dataReg(9) xor r.dataReg(8) xor r.dataReg(7) xor r.dataReg(6) xor r.dataReg(5) xor r.dataReg(4) xor r.dataReg(3) xor r.dataReg(2) xor r.dataReg(1)) = '1'  and r.dataReg (0) = '0' then
				n.scancode     <= r.dataReg(8 downto 1);
				n.dataReceived <= '1';
				n.state        <= state_idle;
			end if;

		when others =>
			-- We are waiting for the ps2clk to go high
			if r.ps2clkDeglitched = '1' then n.state <= state_idle; end if;

		end case;
	end process;

	process(clock, n)
	begin
		if rising_edge(clock) then r <= n; end if;
	end process;

end;
