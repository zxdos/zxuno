 --**********************************************************************************************
-- Quick and Dirty peripheral to connect pins for PWM etc to external pins
-- Version 1.5 "Original" (Mega103) version
-- Modified 14.06.20010
-- MOdified by Jack Gassett
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.AVRuCPackage.all;



entity swap_pins is port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);

                    iore       : in  std_logic;
                    iowe       : in  std_logic;

                    -- External connection
						OC0_PWM0_Loc : out integer;
						OC1A_PWM1A_Loc : out integer;
						OC1B_PWM1B_Loc : out integer;
						OC2_PWM2_Loc : out integer;
						mosi_Loc : out integer;
						miso_Loc : out integer;
						sck_Loc : out integer;
						spi_cs_n_Loc : out integer
					);
end swap_pins;

architecture RTL of swap_pins is

--PWM signals
signal OC0_PWM0_Int  		       : std_logic_vector(7 downto 0);
signal OC0_PWM0_En			       : std_logic;
signal OC1A_PWM1A_Int	          : std_logic_vector(7 downto 0);
signal OC1A_PWM1A_En			       : std_logic;
signal OC1B_PWM1B_Int  				 : std_logic_vector(7 downto 0);
signal OC1B_PWM1B_En			       : std_logic;
signal OC2_PWM2_Int  				 : std_logic_vector(7 downto 0);
signal OC2_PWM2_En			       : std_logic;

signal mosi_Int  				 : std_logic_vector(7 downto 0);
signal mosi_En			       : std_logic;
signal miso_Int  				 : std_logic_vector(7 downto 0);
signal miso_En			       : std_logic;
signal sck_Int  				 : std_logic_vector(7 downto 0);
signal sck_En			       : std_logic;
signal spi_cs_n_Int 			 : std_logic_vector(7 downto 0);
signal spi_cs_n_En	       : std_logic;


begin
	
OC0_PWM0_En <= '1' when (adr=x"1000" and iowe='1') else '0'; -- Hijacks unused external SRAM space	
OC1A_PWM1A_En <= '1' when (adr=x"1001" and iowe='1') else '0'; -- Hijacks unused external SRAM space		
OC1B_PWM1B_En <= '1' when (adr=x"1002" and iowe='1') else '0'; -- Hijacks unused external SRAM space		
OC2_PWM2_En <= '1' when (adr=x"1003" and iowe='1') else '0'; -- Hijacks unused external SRAM space	

mosi_En <= '1' when (adr=x"1004" and iowe='1') else '0'; -- Hijacks unused external SRAM space	
miso_En <= '1' when (adr=x"1005" and iowe='1') else '0'; -- Hijacks unused external SRAM space		
sck_En <= '1' when (adr=x"1006" and iowe='1') else '0'; -- Hijacks unused external SRAM space		
spi_cs_n_En <= '1' when (adr=x"1007" and iowe='1') else '0'; -- Hijacks unused external SRAM space	
	
process(cp2,ireset)
begin
if (ireset='0') then                 -- Reset
 OC0_PWM0_Int <= (others => '0'); 
 OC1A_PWM1A_Int <= (others => '0');
 OC1B_PWM1B_Int <= (others => '0');
 OC2_PWM2_Int <= (others => '0');

 mosi_Int <= (others => '0'); 
 miso_Int <= (others => '0');
 sck_Int <= (others => '0');
 spi_cs_n_Int <= (others => '0');
  elsif (cp2='1' and cp2'event) then -- Clock
   if OC0_PWM0_En='1' and iowe='1' then -- Clock enable
    OC0_PWM0_Int <= dbus_in;
   elsif OC1A_PWM1A_En='1' and iowe='1' then -- Clock enable
    OC1A_PWM1A_Int <= dbus_in;
   elsif OC1B_PWM1B_En='1' and iowe='1' then -- Clock enable
    OC1B_PWM1B_Int <= dbus_in;
   elsif OC2_PWM2_En='1' and iowe='1' then -- Clock enable
    OC2_PWM2_Int <= dbus_in;

   elsif mosi_En='1' and iowe='1' then -- Clock enable
    mosi_Int <= dbus_in;
   elsif miso_En='1' and iowe='1' then -- Clock enable
    miso_Int <= dbus_in;
   elsif sck_En='1' and iowe='1' then -- Clock enable
    sck_Int <= dbus_in;	 
   elsif spi_cs_n_En='1' and iowe='1' then -- Clock enable
    spi_cs_n_Int <= dbus_in;	 	 
   end if;
  end if;
end process;
	
OC0_PWM0_Loc <= conv_integer(OC0_PWM0_Int);	
OC1A_PWM1A_Loc <= conv_integer(OC1A_PWM1A_Int);	
OC1B_PWM1B_Loc <= conv_integer(OC1B_PWM1B_Int);	
OC2_PWM2_Loc <= conv_integer(OC2_PWM2_Int);	

mosi_Loc <= conv_integer(mosi_Int);	
miso_Loc <= conv_integer(miso_Int);	
sck_Loc <= conv_integer(sck_Int);	
spi_cs_n_Loc <= conv_integer(spi_cs_n_Int);

end RTL;
