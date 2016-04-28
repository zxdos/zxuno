library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_firmware is
generic
	(
		addrbits : integer := 15 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clock : in std_logic;
	address : in std_logic_vector(addrbits-1 downto 0);
	q : out std_logic
);
end soc_firmware;

architecture arch of soc_firmware is

type rom_type is array(natural range 0 to (2**(addrbits)-1)) of std_logic;

shared variable rom : rom_type :=
(
