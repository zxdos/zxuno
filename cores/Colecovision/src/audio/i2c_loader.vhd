--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all; -- for AND_REDUCE
use ieee.numeric_std.all;

entity i2c_loader is
	generic (
		device_address	: integer := 16#1a#;		-- Address of slave to be loaded
		num_retries		: integer := 0;			-- Number of retries to allow before stopping
		log2_divider	: integer := 6				-- Length of clock divider in bits.  Resulting bus frequency is CLK/2^(log2_divider + 2)
	);
	port (
		clock_i			: in    std_logic;
		reset_i			: in    std_logic;
		
		i2c_scl_io		: inout std_logic;
		i2c_sda_io		: inout std_logic;
		
		is_done_o		: out   std_logic;
		is_error_o		: out   std_logic
	);
end entity;

architecture rtl of i2c_loader is

--/---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------\
--|Register |B15 B14 B13 B12 B11 B10 B9 |   B8    |   B7   |   B6    |   B5   |  B4  |  B3  |  B2  |   B1   |   B0    |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R0 (00h) | 0   0   0   0   0   0   0 |LRIN BOTH|LIN MUTE|    0    |   0    |                LINVOL                 |
--+---------+---------------------------+---------+--------+---------+--------+---------------------------------------+
--|R1 (02h) | 0   0   0   0   0   0   1 |RLIN BOTH|RIN MUTE|    0    |   0    |                RINVOL                 |
--+---------+---------------------------+---------+--------+---------+--------+---------------------------------------+
--|R2 (04h) | 0   0   0   0   0   1   0 |LRHP BOTH|LZCEN   |                          LHPVOL                          |
--+---------+---------------------------+---------+--------+----------------------------------------------------------+
--|R3 (06h) | 0   0   0   0   0   1   1 |RLHP BOTH|RZCEN   |                          RHPVOL                          |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R4 (08h) | 0   0   0   0   1   0   0 |    0    |      SIDEATT     |SIDETONE|DACSEL|BYPASS|INSEL |MUTE MIC|MIC BOOST|
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R5 (0Ah) | 0   0   0   0   1   0   1 |    0    |   0    |    0    |   0    | HPOR |DAC MU|    DEEMPH     | ADC HPD |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R6 (0Ch) | 0   0   0   0   1   1   0 |    0    |PWR OFF |CLK OUTPD| OSCPD  |OUTPD |DACPD |ADCPD | MICPD  |LINEINPD |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R7 (0Eh) | 0   0   0   0   1   1   1 |    0    |BCLK INV|   MS    |LR SWAP | LRP  |     IWL     |     FORMAT       |
--+---------+---------------------------+---------+--------+---------+--------+------+-------------+--------+---------+
--|R8 (10h) | 0   0   0   1   0   0   0 |    0    |CLKO /2 | CLKI /2 |              SR             |  BOSR  |USB/NORM |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R9 (12h) | 0   0   0   1   0   0   1 |    0    |   0    |    0    |   0    |  0   |  0   |  0   |   0    | ACTIVE  |
--+---------+---------------------------+---------+--------+---------+--------+------+------+------+--------+---------+
--|R15 (1Eh)| 0   0   0   1   1   1   1 |                              RESET                                          |
--\---------+---------------------------+-----------------------------------------------------------------------------/

	type regs is array(0 to 21) of std_logic_vector(7 downto 0);
	constant init_regs : regs := (
		X"00", X"00",			-- dummy
		X"00", X"08",			-- Left line in, unmute, ?dB -- 0 0 00 10111
		X"02", X"80",			-- Right line in, mute -- 0 1 00 00000
		X"04", X"79",			-- Left headphone out, 0dB
		X"06", X"79",			-- Right headphone out, 0dB
		X"08", X"10",			-- Audio path, DAC enabled, Line in, Bypass off, mic unmuted
--		X"0A", X"00",			-- Digital path, Unmute, HP filter enabled, no DEEMPH
--		X"0A", X"02",			-- Digital path, Unmute, HP filter enabled, DEEMPH 32KHz
--		X"0A", X"04",			-- Digital path, Unmute, HP filter enabled, DEEMPH 44.1KHz
		X"0A", X"06",			-- Digital path, Unmute, HP filter enabled, DEEMPH 48KHz
		X"0C", X"62",			-- Power down mic, clkout and xtal osc
		X"0E", X"02",			-- Format 16-bit I2S, no bit inversion or phase changes
--		X"10", X"0D",			-- Sampling control, 8 kHz USB mode (MCLK = 250fs * 6)
--		X"10", X"01",			-- Sampling control, 48 KHz, USB mode (MCLK = 250fs)
--		X"10", X"3F",			-- Sampling control, 88.2 KHz, USB mode (MCLK = 136fs)
		X"10", X"1D",			-- Sampling control, 96 KHz, USB mode (MCLK = 125fs)
		X"12", X"01"			-- Activate
	);

	constant burst_length	: positive := 2;												-- Number of bursts (i.e. total number of registers)
	constant num_bursts		: positive := (init_regs'length / burst_length);	-- Number of bytes to transfer per burst
		
	type state_t is (Idle, Start, Data, Ack, Stop, Pause, Done);
	signal state		: state_t;
	signal phase		: std_logic_vector(1 downto 0);
	subtype nbit_t is integer range 0 to 7;
	signal nbit			: nbit_t;
	subtype nbyte_t is integer range 0 to burst_length;			-- +1 for address byte
	signal nbyte		: nbyte_t;
	subtype thisbyte_t is integer range 0 to init_regs'length;	-- +1 for "done"
	signal thisbyte	: thisbyte_t;
	subtype retries_t is integer range 0 to num_retries;
	signal retries		: retries_t;

	signal clken		: std_logic;
	signal divider		: std_logic_vector(log2_divider-1 downto 0);
	signal shiftreg	: std_logic_vector(7 downto 0);
	signal scl_out		: std_logic;
	signal sda_out		: std_logic;
	signal nak			: std_logic;

begin
	-- Create open-drain outputs for I2C bus
	i2c_scl_io	<= '0' when scl_out = '0' else 'Z';
	i2c_sda_io	<= '0' when sda_out = '0' else 'Z';
	-- Status outputs are driven both ways
	is_done_o	<= '1' when state = Done else '0';
	is_error_o	<= nak;
	
	-- Generate clock enable for desired bus speed
	clken <= AND_REDUCE(divider);
	process(reset_i, clock_i)
	begin
		if reset_i = '1' then
			divider <= (others => '0');
		elsif falling_edge(clock_i) then
			divider <= divider + '1';
		end if;
	end process;

	-- The I2C loader process
	process(reset_i, clock_i, clken)
	begin
		if reset_i = '1' then
			scl_out <= '1';
			sda_out <= '1';
			state <= Idle;
			phase <= "00";
			nbit <= 0;
			nbyte <= 0;
			thisbyte <= 0;
			shiftreg <= (others => '0');
			nak <= '0'; -- No error
			retries <= num_retries;
		elsif rising_edge(clock_i) and clken = '1' then
  			-- Next phase by default
			phase <= phase + 1;

			-- STATE: IDLE
			if state = Idle then
				-- Start loading the device registers straight away
				-- A 'GO' bit could be polled here if required
				state <= Start;
				phase <= "00";
				scl_out <= '1';
				sda_out <= '1';
				
			-- STATE: START
			elsif state = Start then
				-- Generate START condition
				case phase is
				when "00" =>
					-- Drop SDA first
					sda_out <= '0';
				when "10" =>
					-- Then drop SCL
					scl_out <= '0';
				when "11" =>
					-- Advance to next state
					-- Shift register loaded with device slave address
					state <= Data;
					nbit <= 7;
					shiftreg <= std_logic_vector(to_unsigned(device_address,7)) & '0'; -- writing
					nbyte <= burst_length;
				when others =>
					null;
				end case;
				
			-- STATE: DATA
			elsif state = Data then
				-- Generate data
				case phase is
				when "00" =>
					-- Drop SCL
					scl_out <= '0';
				when "01" =>
					-- Output data and shift (MSb first)
					sda_out <= shiftreg(7);
					shiftreg <= shiftreg(6 downto 0) & '0';
				when "10" =>
					-- Raise SCL
					scl_out <= '1';
				when "11" =>
					-- Next bit or advance to next state when done
					if nbit = 0 then
						state <= Ack;
					else
						nbit <= nbit - 1;
					end if;
				when others =>
				  null;
				end case;
				
			-- STATE: ACK
			elsif state = Ack then
				-- Generate ACK clock and check for error condition
				case phase is
				when "00" =>
					-- Drop SCL
					scl_out <= '0';
				when "01" =>
					-- Float data
					sda_out <= '1';
				when "10" =>
					-- Sample ack bit
					nak <= i2c_sda_io;
					if i2c_sda_io = '1' then
						-- Error
						nbyte <= 0; -- Close this burst and skip remaining registers
						thisbyte <= init_regs'length;
					else
						-- Hold ACK to avoid spurious stops - this seems to fix a
						-- problem with the Wolfson codec which releases the ACK
						-- right on the falling edge of the clock pulse.  It looks like
						-- the device interprets this is a STOP condition and then fails
						-- to acknowledge the next byte.  We can avoid this by holding the
						-- ACK condition for a little longer.
						sda_out <= '0';
					end if;
					-- Raise SCL
					scl_out <= '1';
				when "11" =>
					-- Advance to next state
					if nbyte = 0 then
						-- No more bytes in this burst - generate a STOP
						state <= Stop;
					else
						-- Generate next byte
						state <= Data;
						nbit <= 7;
						shiftreg <= init_regs(thisbyte);
						nbyte <= nbyte - 1;
						thisbyte <= thisbyte + 1;
					end if;
				when others =>
					null;
				end case;
				
			-- STATE: STOP
			elsif state = Stop then
				-- Generate STOP condition
				case phase is
				when "00" =>
					-- Drop SCL first
					scl_out <= '0';
				when "01" =>
					-- Drop SDA
					sda_out <= '0';
				when "10" =>
					-- Raise SCL
					scl_out <= '1';
				when "11" =>
					if thisbyte = init_regs'length then
						-- All registers done, advance to finished state.  This will
						-- bring SDA high while SCL is still high, completing the STOP
						-- condition
						state <= Done;
					else
						-- Load the next register after a short delay
						state <= Pause;
					end if;
				when others =>
					null;
				end case;
				
			-- STATE: PAUSE
			elsif state = Pause then
				-- Delay for one cycle of 'phase' then start the next burst
				scl_out <= '1';
				sda_out <= '1';
				if phase = "11" then
					state <= Start;
				end if;
				
			-- STATE: DONE
			else
				-- Finished
				scl_out <= '1';
				sda_out <= '1';
				
				if nak = '1' and retries > 0 then
					-- We can retry in the event of a NAK in case the
					-- slave got out of sync for some reason
					retries <= retries - 1;
					state <= Idle;
				end if;
			end if;
		end if;
	end process;
end architecture;