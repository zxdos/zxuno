--**********************************************************************************************
--  Parallel Port Peripheral for the AVR Core
--  Version 0.7
--  Modified 10.08.2003
--  Designed by Ruslan Lepetenok.
--
--  The possibility of implementing level sensitive LATCH instead of edge sensitive DFF 
--  (for the first stage of the synchronizer) is added.
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.AVRuCPackage.all;
use WORK.SynthCtrlPack.all; -- Synthesis control
use WORK.SynchronizerCompPack.all; -- Component declarations for the synchronizers 

entity pport is generic(PPortNum : natural); 
	               port(
	                    -- AVR Control
                        ireset     : in std_logic;
                        cp2	       : in std_logic;
                        adr        : in std_logic_vector(15 downto 0);
                        dbus_in    : in std_logic_vector(7 downto 0);
                        dbus_out   : out std_logic_vector(7 downto 0);
                        iore       : in std_logic;
                        iowe       : in std_logic;
                        out_en     : out std_logic; 
--							--Info							
--								miso_LOC	  : in integer;
--								spi_spe    : in std_logic;							
			            -- External connection
--							spi_misoi  : out std_logic;							
			            portx      : out std_logic_vector(7 downto 0);
			            ddrx       : out std_logic_vector(7 downto 0);
			            pinx       : in  std_logic_vector(7 downto 0);
                        irqlines   : out std_logic_vector(7 downto 0));
end pport;

architecture RTL of pport is

signal PORTx_Int   : std_logic_vector(portx'range);
signal DDRx_Int    : std_logic_vector(ddrx'range);
signal PINx_Tmp : std_logic_vector(pinx'range);
signal PINx_Resync  : std_logic_vector(pinx'range);

signal PORTx_Sel : std_logic;
signal DDRx_Sel  : std_logic;
signal PINx_Sel  : std_logic;

begin
	
PORTx_Sel <= '1' when adr=PPortAdrArray(PPortNum).Port_Adr else '0';
DDRx_Sel  <= '1' when adr=PPortAdrArray(PPortNum).DDR_Adr else '0';	
PINx_Sel  <= '1' when adr=PPortAdrArray(PPortNum).Pin_Adr else '0';	
--spi_misoi_Sel  <= '1' when adr=PPortAdrArray(PPortNum).Pin_Adr else '0';
	
out_en <= (PORTx_Sel or DDRx_Sel or PINx_Sel) and iore;
	
PORTx_DFF:process(cp2,ireset)
begin
if (ireset='0') then                   -- Reset
 PORTx_Int <= (others => '0'); 
  elsif (cp2='1' and cp2'event) then   -- Clock
   if PORTx_Sel='1' and iowe='1' then  -- Clock enable
    PORTx_Int <= dbus_in;
   end if;
  end if;
end process;		

DDRx_DFF:process(cp2,ireset)
begin
if (ireset='0') then                 -- Reset
 DDRx_Int <= (others => '0'); 
  elsif (cp2='1' and cp2'event) then -- Clock
   if DDRx_Sel='1' and iowe='1' then -- Clock enable
    DDRx_Int <= dbus_in;
   end if;
  end if;
end process;		

-- The first stage of the resynchronizer : DFF or Latch
SynchDFF:if not CSynchLatchUsed generate
 PINxDFFSynchronizer:for i in pinx'range generate 
  PINxDFFSynchronizer_Inst:component SynchronizerDFF port map(
							                                  NRST => ireset,
	                                                          CLK  => cp2,
							                                  D    => pinx(i),
							                                  Q    => PINx_Tmp(i));
 end generate;
end generate;

SynchLatch:if CSynchLatchUsed generate
 PINxLatchSynchronizer:for i in pinx'range generate 
  PINxLatchSynchronizer_Inst:component SynchronizerLatch port map(
	                                                              D => pinx(i),
								                                  G => cp2,
																  Q => PINx_Tmp(i),
																  QN => open);
 end generate;	
end generate;
-- End of the first stage of the resynchronizer 

PINXInputReg:process(cp2,ireset)
begin
 if (ireset='0') then                  -- Reset
  PINx_Resync <= (others => '0'); 
 elsif (cp2='1' and cp2'event) then  -- Clock
  PINx_Resync <= PINx_Tmp;
 end if;
end process;		

DBusOutMux:for i in pinx'range generate
dbus_out(i) <= (PORTx_Int(i) and PORTx_Sel)or(DDRx_Int(i) and DDRx_Sel)or(PINx_Resync(i) and PINx_Sel);
irqlines(i) <= PINx_Resync(i);
--spi_misoi <= pinx(i) when miso_Loc = i and spi_spe = '1';
end generate;	

-- Outputs
portx <= PORTx_Int;     
ddrx  <= DDRx_Int;     

end RTL;
