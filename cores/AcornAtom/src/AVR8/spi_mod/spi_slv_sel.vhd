--**********************************************************************************************
-- SPI Peripheral for the AVR Core
-- Version 1.2
-- Modified 10.01.2007
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.std_library.all;
use WORK.avr_adr_pack.all;

entity spi_slv_sel is generic(num_of_slvs : integer := 7);
	              port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);
                    dbus_out   : out std_logic_vector(7 downto 0);
                    iore       : in  std_logic;
                    iowe       : in  std_logic;
                    out_en     : out std_logic;
					-- Output
                    slv_sel_n  : out std_logic_vector(num_of_slvs-1 downto 0)
                    );					
end spi_slv_sel;

architecture RTL of spi_slv_sel is

constant SPISlvDcd_Address : integer := PINF_Address;

signal SlvSelRg_Current    : std_logic_vector(num_of_slvs-1 downto 0);
signal SlvSelRg_Next       : std_logic_vector(num_of_slvs-1 downto 0);

begin

RegWrSeqPrc:process(ireset,cp2)
begin
 if (ireset='0') then                 -- Reset	
  SlvSelRg_Current <= (others => '0');
 elsif (cp2='1' and cp2'event) then -- Clock
  SlvSelRg_Current <= SlvSelRg_Next;
 end if;
end process;			 


RegWrComb:process(adr,iowe,dbus_in,SlvSelRg_Current)
begin
 SlvSelRg_Next  <= SlvSelRg_Current;
 if(fn_to_integer(adr)=SPISlvDcd_Address and iowe='1') then
  SlvSelRg_Next <= dbus_in(num_of_slvs-1 downto 0);
 end if;
end process;			 

slv_sel_n <= not SlvSelRg_Current(slv_sel_n'range);

out_en <= '1' when (fn_to_integer(adr)=SPISlvDcd_Address and iore='1') else '0';	

dbus_out(num_of_slvs-1 downto 0) <= SlvSelRg_Current;

UnusedBits:if(num_of_slvs<8) generate 
 dbus_out(dbus_out'high downto num_of_slvs) <= (others => '0');
end generate;


end RTL;


