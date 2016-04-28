-- Interrupt Controller
-- Copyright © 2013 by Alastair M. Robinson
-- Released under the terms of the GNU Lesser General Public License
-- version 3 or later.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity interrupt_controller is
generic (
	max_int : integer :=15  -- Specify here how many interrupts should be handled.
);
port (
	clk : in std_logic;
	reset_n : in std_logic; -- active low
	enable : in std_logic :='1'; -- Interrupt enable
	trigger : in std_logic_vector(max_int downto 0) := (others => '0'); -- Unused inputs will be optimised awayby the synthesis tools
	ack : in std_logic;
	int : buffer std_logic; -- 1 if an interrupt is pending
	status : out std_logic_vector(max_int downto 0) -- Bitfield with a set bit for each pending interrupt
);
end entity;

architecture rtl of interrupt_controller is

signal pending : std_logic_vector(max_int+1 downto 0) := (others => '0'); -- highest bit is set if any other bit is set.
begin

process(clk)
begin
	if rising_edge(clk) then

		-- Clear the int bit if the interrupt is acknowledged.
		-- While int is 1, the status is frozen, and new interrupts
		-- are held pending, which prevents them being lost.
		if ack='1' then
			int<='0';
		end if;

		-- If no interrupts are currently signalled
		-- copy any pending interrupts to status.
		-- We clear the pending signal at the same time.
		if int='0' and enable='1' then
			status<=pending(status'high downto 0);
			int<=pending(pending'high);
			pending<=(others => '0');
		end if;

		-- Latch any incoming interrupt pulses in the pending signal
		-- If no interrupts are already pending this will be propagated
		-- on the next clock edge; otherwise it will be stored until
		-- the pending interrupt is acknowledged.
		for I in trigger'low to trigger'high loop
			if trigger(I)='1' then
				pending(I)<='1';
				pending(pending'high)<='1';
			end if;
		end loop;
	end if;
end process;

end architecture;
