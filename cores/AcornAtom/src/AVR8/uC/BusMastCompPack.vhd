--************************************************************************************************
-- Component declarations for AVR core (Bus Masters)
-- Version 0.3
-- Designed by Ruslan Lepetenok 
-- Modified 04.08.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;


package BusMastCompPack is

component uart_dma_top is port(
                               -- Clock and reset
   				               ireset           : in  std_logic; 
					           cp2              : in  std_logic;        
                               -- Data memory i/f (Slave part)
					           stb_IO           : in  std_logic;  -- SE
    			               stb_module       : in  std_logic;  -- SE
    		                   sramadr          : in  std_logic_vector(3 downto 0); -- ??
   				               sramre           : in  std_logic;     
					           sramwe           : in  std_logic;     
   			                   sram_dbus_out    : out std_logic_vector(7 downto 0);  
				               sram_dbus_in     : in  std_logic_vector(7 downto 0);  
				               sram_dbus_out_en : out std_logic;
                               -- Data memory i/f (Master part)					   
                               mramadr          : out std_logic_vector(15 downto 0);
                               mramre           : out std_logic;
                               mramwe           : out std_logic;					  
                               mram_dbus_out    : in  std_logic_vector(7 downto 0);
					           mram_dbus_in     : out std_logic_vector(7 downto 0);
					           mack             : in  std_logic;     
                               -- UART related ports
                               adr              : in  std_logic_vector(5 downto 0);
                               dbus_in          : in  std_logic_vector(7 downto 0);
                               dbus_out         : out std_logic_vector(7 downto 0);
                               iore             : in  std_logic;
                               iowe             : in  std_logic;
                               out_en           : out std_logic; 
                                -- Interrupts 					
                                txcirq          : out std_logic;
                                txc_irqack      : in  std_logic;
                                udreirq         : out std_logic;
								udreirq_ack     : in  std_logic;  
			                    rxcirq          : out std_logic;
					            rxcirq_ack		: in  std_logic;	
								-- Wake up IRQ 
					            wupirq          : out std_logic;
					            wup_irqack	    : in  std_logic;
					            -- External connections
					            rxd             : in  std_logic;
                                txd             : out std_logic;
                                rx_en           : out std_logic;
                                tx_en           : out std_logic;
								-- IE status
					            ie_stat         : out std_logic_vector(4 downto 0)
					            );
end component;


component aescmdi_top is port(
				      -- Clock and reset
	                  cp2              : in  std_logic;
                      ireset           : in  std_logic;
					  -- RAM interface (Slave part)
					  --ssel           : in  std_logic;
					  stb_IO     	   : in  std_logic;
					  stb_module 	   : in  std_logic;
                      sramadr          : in  std_logic_vector(3 downto 0); -- ??
                      sramre           : in  std_logic;
					  sramwe           : in  std_logic;
                      sram_dbus_out    : out std_logic_vector(7 downto 0);
					  sram_dbus_in     : in  std_logic_vector(7 downto 0);
					  sram_dbus_out_en : out std_logic;
					  -- RAM interface (Master part)					   
                      mramadr          : out std_logic_vector(15 downto 0);
                      mramre           : out std_logic;
                      mramwe           : out std_logic;					  
                      mram_dbus_out    : in  std_logic_vector(7 downto 0);
					  mram_dbus_in     : out std_logic_vector(7 downto 0);
					  mack             : in  std_logic;
 				      -- Interrupt support
			          aes_irq          : out std_logic;
					  aes_irqack       : in  std_logic
					  );
end component;


end BusMastCompPack;
