-- clkdiv.vhd
-- Description: Clock divider by DIVRATIO (a parameter).
-- Author: Thientu Ho at FPGAcore.com
-- Date: 2/28/2010

library IEEE;
use IEEE.std_logic_1164.all;

entity clkdiv is
    generic (DIVRATIO : integer := 4);  -- ratio by which to divide the clk: clkout = clk/DIVRATIO. Conditions: DIVRATIO > 1.
                                        -- if DIVRATIO is an even number, then clkout is 50% duty cycle.
                                        -- if odd, clkout is greater than 50% duty cycle
    port (
        clk     : in std_logic;         -- input clock
        nreset  : in std_logic;         -- active-low asynchronous global reset
        --
        clkout  : out std_logic         -- output clock
    );
end entity clkdiv;

architecture RTL of clkdiv is
signal clkout_i : std_logic;        -- internal clkout signal (can't use clkout directly because sometimes
                                    -- you need to read present value of clkout, and it's illegal to read
                                    -- an output port), to be buffered out to clkout port
begin
    
    -- this process implement clock divider by counter:
    -- The counter counts from 0 to DIVRATIO-1. At midpoint and end point, clkout is toggled.
    -- For example, if DIVRATIO = 4:
    -- clkout is toggled at count=1 and count=3, creating a 50% duty cycle clock, whose period equals 4 times
    -- the input clock period.
    clkdiv_proc : process (clk, nreset)
    variable count : integer range 0 to DIVRATIO-1;
    begin
        if nreset='0' then          -- initialize power up reset conditions
            clkout_i <= '0';
            count := 0;
        elsif rising_edge(clk) then
            if count=DIVRATIO/2-1 then      -- toggle at half period
                clkout_i <= not clkout_i;
                count := count + 1;
            elsif count=DIVRATIO-1 then     -- toggle at end 
                clkout_i <= not clkout_i;
                count := 0;                 -- reached end of clock period. reset count
            else
                count := count + 1;
            end if;
        end if;
    end process;

    clkout <= clkout_i;     -- buffer to output port
end RTL;
