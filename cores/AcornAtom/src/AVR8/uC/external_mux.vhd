--************************************************************************************************
-- External multeplexer for AVR core
-- Version 2.2
-- Designed by Ruslan Lepetenok 05.11.2001
-- Modified 29.08.2003
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.AVRuCPackage.all;

entity external_mux is port(
		                    ramre          : in  std_logic;
		                    dbus_out       : out std_logic_vector(7 downto 0);
		                    ram_data_out   : in  std_logic_vector(7 downto 0);
		                    io_port_bus    : in  ext_mux_din_type;
		                    io_port_en_bus : in  ext_mux_en_type;
                            irqack         : in  std_logic;
                            irqackad       : in  std_logic_vector(4 downto 0);		  
		                    ind_irq_ack    : out std_logic_vector(22 downto 0)		  
		                    );
end external_mux;

architecture RTL of external_mux is

signal   ext_mux_out      : ext_mux_din_type;

begin

ext_mux_out(0) <= io_port_bus(0) when io_port_en_bus(0)='1' else (others => '0');
data_mux_for_read:for i in 1 to ext_mux_out'high generate
 ext_mux_out(i) <= io_port_bus(i) when io_port_en_bus(i)='1' else ext_mux_out(i-1);
end generate;	

dbus_out <= ram_data_out when ramre='1' else ext_mux_out(ext_mux_out'high);
	
interrupt_ack:for i in ind_irq_ack'range generate
 ind_irq_ack(i) <= '1' when (irqackad=i+1 and irqack='1') else '0';
end generate;	

end RTL;
