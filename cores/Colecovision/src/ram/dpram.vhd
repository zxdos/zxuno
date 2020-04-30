-------------------------------------------------------------------------------
-- $Id: dpram.vhd,v 1.1 2006/02/23 21:46:45 arnim Exp $
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dpram is
  generic (
    addr_width_g : integer := 8;
    data_width_g : integer := 8
  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
    data_a_o : out std_logic_vector(data_width_g-1 downto 0);
    clk_b_i  : in  std_logic;
    addr_b_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_b_o : out std_logic_vector(data_width_g-1 downto 0)
  );
end entity;


library ieee;
use ieee.numeric_std.all;

architecture rtl of dpram is

  type   ram_t		is array (natural range 2**addr_width_g-1 downto 0) of
    std_logic_vector(data_width_g-1 downto 0);
  signal ram_q		: ram_t;
 
begin

	mem_a: process (clk_a_i)
		variable read_addr_v	: unsigned(addr_width_g-1 downto 0);
	begin
		if rising_edge(clk_a_i) then
			read_addr_v := unsigned(addr_a_i);
			if we_i = '1' then
				ram_q(to_integer(read_addr_v)) <= data_a_i;
			end if;
			data_a_o <= ram_q(to_integer(read_addr_v));
		end if;
	end process mem_a;

	mem_b: process (clk_b_i)
		variable read_addr_v	: unsigned(addr_width_g-1 downto 0);
	begin
		if rising_edge(clk_b_i) then
			read_addr_v := unsigned(addr_b_i);
			data_b_o <= ram_q(to_integer(read_addr_v));
		end if;
	end process mem_b;

end rtl;
