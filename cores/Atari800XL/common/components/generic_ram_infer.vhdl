---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY generic_ram_infer IS
	generic
	(
		ADDRESS_WIDTH : natural := 9;
		SPACE : natural := 512;
		DATA_WIDTH : natural := 8
	);
   PORT
   (
      clock: IN   std_logic;
      data:  IN   std_logic_vector (data_width-1 DOWNTO 0);
      address:  IN   std_logic_vector(address_width-1 downto 0);
      we:    IN   std_logic;
      q:     OUT  std_logic_vector (data_width-1 DOWNTO 0)
   );
END generic_ram_infer;

ARCHITECTURE rtl OF generic_ram_infer IS
   TYPE mem IS ARRAY(0 TO space-1) OF std_logic_vector(data_width-1 DOWNTO 0);
   SIGNAL ram_block : mem;	

   SIGNAL q_ram : std_logic_vector(data_width-1 downto 0);
   SIGNAL we_ram : std_logic;

   signal address2 : std_logic_vector(address_width-1 downto 0);
BEGIN

   PROCESS (clock)
   BEGIN
     IF (clock'event AND clock = '1') THEN
	 IF (we_ram = '1') THEN
		 ram_block(to_integer(to_01(unsigned(address2), '0'))) <= data;
		 q_ram <= data;
	 ELSE
		 q_ram <= ram_block(to_integer(to_01(unsigned(address2), '0')));
	  END IF;
     END IF;
   END PROCESS;

   PROCESS(address, we, q_ram)
   begin
	q <= (others=>'1');
	we_ram <= '0';
	address2 <= (others=>'0');
	IF (to_integer(to_01(unsigned(address))) < space) THEN
		q <= q_ram;
		we_ram <= we;
		address2 <= address;
	end if;
   end process;
END rtl;
