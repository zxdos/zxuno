--**********************************************************************************************
-- SPI Peripheral for the AVR Core
-- Version 1.2
-- Modified 10.01.2007
-- Designed by Ruslan Lepetenok
-- Internal resynchronizers for scki and ss_b inputs were added	
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.std_library.all;

use WORK.avr_adr_pack.all;
use WORK.rsnc_comp_pack.all;

entity spi_mod is port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);
                    dbus_out   : out std_logic_vector(7 downto 0);
                    iore       : in  std_logic;
                    iowe       : in  std_logic;
                    out_en     : out std_logic; 
                    -- SPI i/f
					misoi	   : in  std_logic;	
					mosii	   : in  std_logic; 
					scki       : in  std_logic;	-- Resynch
					ss_b       : in  std_logic;	-- Resynch
					misoo	   : out std_logic;
					mosio	   : out std_logic;
					scko	   : out std_logic;
					spe        : out std_logic;
					spimaster  : out std_logic;
					-- IRQ
					spiirq     : out std_logic;
					spiack     : in  std_logic;
					-- Slave Programming Mode
					por		   : in  std_logic;
					spiextload : in  std_logic;
					spidwrite  : out std_logic;
					spiload    : out std_logic
                    );					
end spi_mod;

architecture RTL of spi_mod is

-- Resynch
signal scki_resync	   :  std_logic;	
signal ss_b_resync     :  std_logic;

-- Registers
signal SPCR : std_logic_vector(7 downto 0);
alias SPIE : std_logic is SPCR(7);
alias SPEB : std_logic is SPCR(6); -- SPE in Atmel's doc
alias DORD : std_logic is SPCR(5);
alias MSTR : std_logic is SPCR(4);
alias CPOL : std_logic is SPCR(3);
alias CPHA : std_logic is SPCR(2);
alias SPR : std_logic_vector(1 downto 0) is SPCR(1 downto 0);

signal SPSR : std_logic_vector(7 downto 0);
alias SPIF  : std_logic is SPSR(7);
alias WCOL  : std_logic is SPSR(6);
alias SPI2X : std_logic is SPSR(0);

signal SPIE_Next         : std_logic;
signal SPEB_Next         : std_logic;
signal DORD_Next         : std_logic;	
signal CPOL_Next         : std_logic;	
signal CPHA_Next         : std_logic;	
signal SPR_Next	         : std_logic_vector(SPR'range);
signal SPI2X_Next        : std_logic;

signal SPDR_Rc           : std_logic_vector(7 downto 0);
signal SPDR_Rc_Next      : std_logic_vector(7 downto 0);
signal SPDR_Sh_Current   : std_logic_vector(7 downto 0);
signal SPDR_Sh_Next      : std_logic_vector(7 downto 0);

signal Div_Next          : std_logic_vector(5 downto 0);
signal Div_Current       : std_logic_vector(5 downto 0);
signal Div_Toggle        : std_logic;

signal DivCntMsb_Current : std_logic;
signal DivCntMsb_Next    : std_logic;

type MstSMSt_Type is (MstSt_Idle,MstSt_B0,MstSt_B1,MstSt_B2,MstSt_B3,MstSt_B4,MstSt_B5,MstSt_B6,MstSt_B7);
signal MstSMSt_Current   : MstSMSt_Type;
signal MstSMSt_Next      : MstSMSt_Type;

signal TrStart           : std_logic;

signal scko_Next         : std_logic;
signal scko_Current      : std_logic; --!!!


signal UpdRcDataRg_Current : std_logic;
signal UpdRcDataRg_Next    : std_logic;

signal TmpIn_Current     : std_logic;
signal TmpIn_Next        : std_logic;

-- Slave
signal sck_EdgeDetDFF    : std_logic;
signal SlvSampleSt       : std_logic;

signal SlvSMChangeSt     : std_logic;

type SlvSMSt_Type is (SlvSt_Idle,SlvSt_B0I,SlvSt_B0,SlvSt_B1,SlvSt_B2,SlvSt_B3,SlvSt_B4,SlvSt_B5,SlvSt_B6,SlvSt_B6W);
signal SlvSMSt_Current    : SlvSMSt_Type;
signal SlvSMSt_Next       : SlvSMSt_Type;

-- SIF clear SM
signal SPIFClrSt_Current  : std_logic; 
signal SPIFClrSt_Next     : std_logic; 

-- WCOL clear SM
signal WCOLClrSt_Current  : std_logic; 
signal WCOLClrSt_Next     : std_logic; 

signal MSTR_Next          : std_logic; 
signal SPIF_Next          : std_logic; 
signal WCOL_Next          : std_logic; 

signal MstDSamp_Next      : std_logic; 
signal MstDSamp_Current   : std_logic; 

function Fn_RevBitVector(InVector : std_logic_vector) return std_logic_vector is
variable TmpVect : std_logic_vector(InVector'range);
begin
 for i in TmpVect'range loop
  TmpVect(i) := InVector(InVector'high-i);	
 end loop;
 return TmpVect; 
end	Fn_RevBitVector;

begin

-- ******************** Resynchronizers ************************************
scki_resync_inst:component rsnc_bit generic map(
	                                            add_stgs_num => 0,
						                        inv_f_stgs   => 0
	                                            ) 
	                                    port map(	                   
	                                            clk => cp2,
							                    di  => scki,      
							                    do  => scki_resync
                                                );								
								
ss_b_resync_inst:component rsnc_bit generic map(
	                                            add_stgs_num => 0,
						                        inv_f_stgs   => 0
	                                            ) 
	                                    port map(	                   
	                                            clk => cp2,
							                    di  => ss_b,      
							                    do  => ss_b_resync
                                                );																				
-- ******************** Resynchronizers ************************************
								
	
SeqPrc:process(ireset,cp2)
begin
 if (ireset='0') then                 -- Reset
	 
  SPCR <= (others => '0');	 

  SPIF  <= '0';
  WCOL  <= '0';
  SPI2X <= '0';
  
  Div_Current <= (others => '0'); 
  DivCntMsb_Current <= '0';
  
  MstSMSt_Current <= MstSt_Idle;
  SlvSMSt_Current <= SlvSt_Idle;
  
  SPDR_Sh_Current <= (others => '1');
  SPDR_Rc         <= (others => '0');
  
  sck_EdgeDetDFF   <= '0';
  SPIFClrSt_Current <= '0';
  WCOLClrSt_Current <= '0';	

  scko             <= '0';  
  scko_Current     <= '0';   
  misoo            <= '0';
  mosio            <= '0';
  
  TmpIn_Current    <= '0';
  UpdRcDataRg_Current <= '0';
  MstDSamp_Current  <= '0';  
  
 elsif (cp2='1' and cp2'event) then -- Clock
	 
 SPIE   <= SPIE_Next;
 SPEB   <= SPEB_Next;
 DORD   <= DORD_Next;
 CPOL   <= CPOL_Next;
 CPHA   <= CPHA_Next;
 SPR    <= SPR_Next;  
  
  MSTR  <= MSTR_Next;	   
  SPIF  <= SPIF_Next;
  SPI2X <= SPI2X_Next;	    
  WCOL  <= WCOL_Next;
  
  Div_Current       <= Div_Next;  
  DivCntMsb_Current <= DivCntMsb_Next;
  MstSMSt_Current   <= MstSMSt_Next;
  SlvSMSt_Current   <= SlvSMSt_Next;
  SPDR_Sh_Current   <= SPDR_Sh_Next;
  SPDR_Rc           <= SPDR_Rc_Next;
  sck_EdgeDetDFF    <= scki_resync;
  SPIFClrSt_Current <= SPIFClrSt_Next;
  WCOLClrSt_Current <= WCOLClrSt_Next;
  
  scko_Current      <= scko_Next;     
  scko              <= scko_Next;  
  misoo             <= SPDR_Sh_Next(SPDR_Sh_Next'high);
  mosio             <= SPDR_Sh_Next(SPDR_Sh_Next'high);
  
  TmpIn_Current    <= TmpIn_Next; 
  UpdRcDataRg_Current <= UpdRcDataRg_Next;
  MstDSamp_Current  <= MstDSamp_Next;  
  
 end if;
end process;		


IORegWriteComb:process(adr,iowe,SPCR,SPSR,dbus_in)
begin

SPIE_Next  <= SPIE;
SPEB_Next  <= SPEB;
DORD_Next  <= DORD;
CPOL_Next  <= CPOL;
CPHA_Next  <= CPHA;
SPR_Next   <= SPR;	 
SPI2X_Next <= SPI2X;

 if(fn_to_integer(adr)=SPCR_Address and iowe='1')  then	 
  SPIE_Next <= dbus_in(7); 
  SPEB_Next <= dbus_in(6);
  DORD_Next <= dbus_in(5); 
  CPOL_Next <= dbus_in(3);  
  CPHA_Next <= dbus_in(2); 
  SPR_Next	<= dbus_in(1 downto 0);  
 end if;

 if(fn_to_integer(adr)=SPSR_Address and iowe='1')  then	  
  SPI2X_Next <= dbus_in(0);	 
 end if;		

end process;

SPSR(5 downto 1) <= (others => '0');

-- Divider
-- SPI2X | SPR1 | SPR0 | SCK Frequency
--   0   |  0   |   0  | fosc /4       (2)
--   0   |  0   |   1  | fosc /16	   (8)
--   0   |  1   |   0  | fosc /64	   (32)
--   0   |  1   |   1  | fosc /128	   (64)
-- ------+------+------+-------------
--   1   |  0   |   0  | fosc /2	   (1)
--   1   |  0   |   1  | fosc /8	   (4)
--   1   |  1   |   0  | fosc /32	   (16)
--   1   |  1   |   1  | fosc /64	   (32)


DividerToggleComb:process(MstSMSt_Current,Div_Current,SPCR,SPSR)
begin
 Div_Toggle <= '0';
 if(MstSMSt_Current /= MstSt_Idle) then
 if(SPI2X='1') then -- Extended mode
  case SPR is
   when "00" => if (Div_Current="000001") then Div_Toggle <= '1'; end if; -- fosc /2
   when "01" => if (Div_Current="000011") then Div_Toggle <= '1'; end if; -- fosc /8
   when "10" => if (Div_Current="001111") then Div_Toggle <= '1'; end if; -- fosc /32
   when "11" => if (Div_Current="011111") then Div_Toggle <= '1'; end if; -- fosc /64
   when others =>                              Div_Toggle <= '0';
  end case;	  
 else 	            -- Normal mode
  case SPR is
   when "00" => if (Div_Current="000001") then Div_Toggle <= '1'; end if; -- fosc /4	  
   when "01" => if (Div_Current="000111") then Div_Toggle <= '1'; end if; -- fosc /16
   when "10" => if (Div_Current="011111") then Div_Toggle <= '1'; end if; -- fosc /64
   when "11" => if (Div_Current="111111") then Div_Toggle <= '1'; end if; -- fosc /128
   when others =>                              Div_Toggle <= '0';
  end case;	   	 
 end if;
 end if;
end process;	


DividerNextComb:process(MstSMSt_Current,Div_Current,DivCntMsb_Current,Div_Toggle)
begin
 Div_Next <= Div_Current;
 DivCntMsb_Next <= DivCntMsb_Current;
 if(MstSMSt_Current /= MstSt_Idle) then
   if(Div_Toggle='1') then 	 
    Div_Next <= (others => '0');
	DivCntMsb_Next <= not DivCntMsb_Current;
   else 
    Div_Next <= Div_Current + 1;
   end if;
 
 end if;
end process;	


TrStart <= '1' when (fn_to_integer(adr)=SPDR_Address and iowe='1' and SPEB='1') else '0';

-- Transmitter Master Mode Shift Control SM
MstSmNextComb:process(MstSMSt_Current,DivCntMsb_Current,Div_Toggle,TrStart,SPCR)
begin
 MstSMSt_Next <= MstSMSt_Current;
  case MstSMSt_Current is
   when	MstSt_Idle => 
    if(TrStart='1' and MSTR='1')  then
	 MstSMSt_Next <= MstSt_B0;   
	end if;  
   when	MstSt_B0 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B1;
	end if; 
   when	MstSt_B1 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B2;  
   	end if; 
   when	MstSt_B2 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B3; 
   	end if; 
   when	MstSt_B3 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B4;  
   	end if; 
   when	MstSt_B4 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B5;  
   	end if; 
   when	MstSt_B5 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B6;  
   	end if; 
   when	MstSt_B6 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_B7;     
   	end if; 
   when	MstSt_B7 => 
    if(DivCntMsb_Current='1' and Div_Toggle='1') then
     MstSMSt_Next <= MstSt_Idle;
   	end if; 
   when others  => MstSMSt_Next <= MstSt_Idle;
  end case;	 
end process;	


SPIFClrCombProc:process(SPIFClrSt_Current,SPCR,SPSR,adr,iore,iowe)
begin
 SPIFClrSt_Next <= SPIFClrSt_Current;
 case SPIFClrSt_Current is
  when '0' => 
   if(fn_to_integer(adr)=SPSR_Address and iore='1' and SPIF='1' and SPEB='1') then 
    SPIFClrSt_Next <= '1';
   end if;
  when '1' =>  
   if(fn_to_integer(adr)=SPDR_Address and (iore='1' or iowe='1')) then 
    SPIFClrSt_Next <= '0';
   end if;   
  when others =>  SPIFClrSt_Next <= SPIFClrSt_Current;
  end case;
end process; --SPIFClrCombProc


WCOLClrCombProc:process(WCOLClrSt_Current,SPSR,adr,iore,iowe)
begin
 WCOLClrSt_Next <= WCOLClrSt_Current;
 case WCOLClrSt_Current is
  when '0' => 
   if(fn_to_integer(adr)=SPSR_Address and iore='1' and WCOL='1') then 
    WCOLClrSt_Next <= '1';
   end if;
  when '1' =>  
   if(fn_to_integer(adr)=SPDR_Address and (iore='1' or iowe='1')) then 
    WCOLClrSt_Next <= '0';
   end if;   
  when others =>  WCOLClrSt_Next <= WCOLClrSt_Current;
  end case;
end process; --WCOLClrCombProc


MstDataSamplingComb:process(SPCR,scko_Current,scko_Next,MstDSamp_Current,MstSMSt_Current)
begin
MstDSamp_Next <= '0';
 case MstDSamp_Current is
  when '0' =>
   if(MstSMSt_Current/=MstSt_Idle) then
   if(CPHA=CPOL) then
    if(scko_Next='1' and scko_Current='0') then  -- Rising edge 	  
	 MstDSamp_Next <= '1'; 
    end if;	
   else  	 -- CPHA/=CPOL
    if(scko_Next='0' and scko_Current='1') then  -- Falling edge 	  
	 MstDSamp_Next <= '1'; 
    end if;	
   end if;
  end if; 
  when '1' => MstDSamp_Next <= '0'; 
  when others => MstDSamp_Next <= '0'; 
 end case;

end process; -- MstDataSamplingComb	


--
DRLatchComb:process(UpdRcDataRg_Current,MstSMSt_Current,MstSMSt_Next,SlvSMSt_Current,SlvSMSt_Next,SPCR)
begin	
UpdRcDataRg_Next <= '0';
 case UpdRcDataRg_Current is
  when '0' => 	
  if((MSTR='1' and MstSMSt_Current/=MstSt_Idle and MstSMSt_Next=MstSt_Idle)or
	 (MSTR='0' and SlvSMSt_Current/=SlvSt_Idle and  SlvSMSt_Next=SlvSt_Idle)) then 
    UpdRcDataRg_Next <= '1';
   end if;	   
  when '1'    => UpdRcDataRg_Next <= '0';	
  when others => UpdRcDataRg_Next <= '0';	
 end case;
end process;	


TmpInComb:process(TmpIn_Current,mosii,misoi,MstDSamp_Current,SlvSampleSt,SPCR,ss_b_resync)
begin	
TmpIn_Next <= TmpIn_Current;
 if(MSTR='1' and MstDSamp_Current='1') then  -- Master mode
  TmpIn_Next <= misoi;	  	  
 elsif(MSTR='0' and SlvSampleSt='1' and ss_b_resync='0') then -- Slave mode ???
  TmpIn_Next <= mosii;	  
 end if;	  
end process;

ShiftRgComb:process(MstSMSt_Current,SlvSMSt_Current,SPDR_Sh_Current,SPCR,DivCntMsb_Current,Div_Toggle,TrStart,dbus_in,ss_b_resync,TmpIn_Current,SlvSMChangeSt,SlvSampleSt,UpdRcDataRg_Current)
begin
SPDR_Sh_Next <= SPDR_Sh_Current;
 if(TrStart='1' and (MstSMSt_Current=MstSt_Idle and SlvSMSt_Current = SlvSt_Idle and not(MSTR='0' and SlvSampleSt='1' and ss_b_resync='0') )) then -- Load
  if (DORD='1') then -- the LSB of the data word is transmitted first
   SPDR_Sh_Next <=  Fn_RevBitVector(dbus_in);
  else 				 -- the MSB of the data word is transmitted first
   SPDR_Sh_Next <= dbus_in;	  
  end if;
 elsif(MSTR='1' and UpdRcDataRg_Current='1') then -- ???
  SPDR_Sh_Next(SPDR_Sh_Next'high) <= '1';
 elsif((MSTR='1' and MstSMSt_Current/=MstSt_Idle and DivCntMsb_Current='1' and Div_Toggle='1') or 
	   (MSTR='0' and SlvSMSt_Current/=SlvSt_Idle and SlvSMChangeSt='1' and ss_b_resync='0')) then
  -- Shift
  SPDR_Sh_Next <= SPDR_Sh_Current(SPDR_Sh_Current'high-1 downto SPDR_Sh_Current'low)&TmpIn_Current;	 
 end if;
end process; --ShiftRgComb


sckoGenComb:process(scko_Current,SPCR,adr,iowe,dbus_in,DivCntMsb_Next,DivCntMsb_Current,TrStart,MstSMSt_Current,MstSMSt_Next)
begin
scko_Next <= scko_Current;
 if(fn_to_integer(adr)=SPCR_Address and iowe='1') then -- Write to SPCR
  scko_Next <= dbus_in(3); -- CPOL
 elsif(TrStart='1' and CPHA='1' and MstSMSt_Current=MstSt_Idle) then 
  scko_Next <= not CPOL;	 
 elsif(MstSMSt_Current/=MstSt_Idle and MstSMSt_Next=MstSt_Idle) then -- "Parking"
  scko_Next <= CPOL;	 
 elsif(MstSMSt_Current/=MstSt_Idle and DivCntMsb_Current/=DivCntMsb_Next) then  
  scko_Next <= not scko_Current;
 end if;	 
end process;


-- Receiver data register
SPDRRcComb:process(SPDR_Rc,SPCR,SPDR_Sh_Current,UpdRcDataRg_Current,TmpIn_Current)
begin
SPDR_Rc_Next <= SPDR_Rc;
if(UpdRcDataRg_Current='1') then
 if(MSTR='0' and CPHA='1') then
  if (DORD='1') then -- the LSB of the data word is transmitted first
   SPDR_Rc_Next <= Fn_RevBitVector(SPDR_Sh_Current(SPDR_Sh_Current'high-1 downto 0)&TmpIn_Current);	  
  else 				 -- the MSB of the data word is transmitted first
   SPDR_Rc_Next <= SPDR_Sh_Current(SPDR_Sh_Current'high-1 downto 0)&TmpIn_Current;	  
  end if;	  
 else  	 
  if (DORD='1') then -- the LSB of the data word is transmitted first
   SPDR_Rc_Next <= Fn_RevBitVector(SPDR_Sh_Current);	  
  else 				 -- the MSB of the data word is transmitted first
   SPDR_Rc_Next <= SPDR_Sh_Current;	  
  end if;	  
 end if;
end if;	    
end process;


--****************************************************************************************			
-- Slave
--****************************************************************************************

SlvSampleSt   <= '1' when ((sck_EdgeDetDFF='0' and  scki_resync='1' and CPOL=CPHA)or          -- Rising edge 
                           (sck_EdgeDetDFF='1' and  scki_resync='0' and CPOL/=CPHA))else '0'; -- Falling edge

SlvSMChangeSt <= '1' when ((sck_EdgeDetDFF='1' and  scki_resync='0' and CPOL=CPHA)or          -- Falling edge 
                           (sck_EdgeDetDFF='0' and  scki_resync='1' and CPOL/=CPHA))else '0'; -- Rising edge

-- Slave Master Mode Shift Control SM
SlvSMNextComb:process(SlvSMSt_Current,SPCR,SlvSampleSt,SlvSMChangeSt,ss_b_resync)
begin
 SlvSMSt_Next <= SlvSMSt_Current;
 if(ss_b_resync='0')  then
  case SlvSMSt_Current is
   when	SlvSt_Idle =>
   
   if(MSTR='0') then
	if(CPHA='1')  then  
     if(SlvSMChangeSt='1')  then
	  SlvSMSt_Next <= SlvSt_B0;   
	 end if;
	else --	CPHA='0'
     if(SlvSampleSt='1')  then
	  SlvSMSt_Next <= SlvSt_B0I;   
	 end if;		
	end if; 
   end if; 	
	
   when SlvSt_B0I =>	
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B0;
	end if; 
	
   when	SlvSt_B0 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B1;
	end if; 
   when	SlvSt_B1 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B2;  
   	end if; 
   when	SlvSt_B2 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B3; 
   	end if; 
   when	SlvSt_B3 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B4;  
   	end if; 
   when	SlvSt_B4 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B5;  
   	end if; 
   when	SlvSt_B5 => 
    if(SlvSMChangeSt='1') then
     SlvSMSt_Next <= SlvSt_B6;  
   	end if; 

   when	SlvSt_B6 => 
    if(SlvSMChangeSt='1') then 
     if(CPHA='0') then
      SlvSMSt_Next <= SlvSt_Idle;     
     else -- CPHA='1'
      SlvSMSt_Next <= SlvSt_B6W;     
	 end if;
	end if;
	
  when	SlvSt_B6W => 
    if(SlvSampleSt='1')then   
     SlvSMSt_Next <= SlvSt_Idle;     
   	end if;  
   when others  => SlvSMSt_Next <= SlvSt_Idle;
  end case;	
 end if;
end process;	


MSTRGenComb:process(adr,iowe,dbus_in,ss_b_resync,SPCR)
begin
 MSTR_Next <= MSTR;
 case MSTR is
  when '0' =>
   if(fn_to_integer(adr)=SPCR_Address and iowe='1' and dbus_in(4)='1') then -- TBD (ss_b_resync='0')
    MSTR_Next <= '1';
   end if;	   
  when '1' =>  
   if((fn_to_integer(adr)=SPCR_Address and iowe='1' and dbus_in(4)='0') or
	  (ss_b_resync='0')) then
     MSTR_Next <= '0';
   end if;	
  when others => MSTR_Next <= MSTR;	
 end case;	
end process;	


WCOLGenComb:process(WCOLClrSt_Current,SlvSMSt_Current,MstSMSt_Current,adr,iowe,iore,SPCR,SPSR,SlvSampleSt,ss_b_resync)
begin
 WCOL_Next <= WCOL;
 case WCOL is
  when '0' =>
  if(fn_to_integer(adr)=SPDR_Address and iowe='1' and  
	 ((MSTR='0' and (SlvSMSt_Current/=SlvSt_Idle or (SlvSampleSt='1' and ss_b_resync='0'))) or 
	  (MSTR='1' and MstSMSt_Current/=MstSt_Idle))) then 
    WCOL_Next <= '1';
   end if;	   
  when '1' =>  
  if(((fn_to_integer(adr)=SPDR_Address and (iowe='1' or iore='1')) and WCOLClrSt_Current='1') and 
	not (fn_to_integer(adr)=SPDR_Address and iowe='1' and  
	 ((MSTR='0' and (SlvSMSt_Current/=SlvSt_Idle or (SlvSampleSt='1' and ss_b_resync='0'))) or 
	  (MSTR='1' and MstSMSt_Current/=MstSt_Idle)))) then
     WCOL_Next <= '0';
   end if;	
  when others => WCOL_Next <= WCOL;	
 end case;	
end process;	


SPIFGenComb:process(SPIFClrSt_Current,adr,iowe,iore,SPCR,SPSR,SlvSMSt_Current,SlvSMSt_Next,MstSMSt_Current,MstSMSt_Next,spiack)
begin
 SPIF_Next <= SPIF;
 case SPIF is
  when '0' =>
  if((MSTR='0' and SlvSMSt_Current/=SlvSt_Idle and SlvSMSt_Next=SlvSt_Idle) or 
	 (MSTR='1' and MstSMSt_Current/=MstSt_Idle and MstSMSt_Next=MstSt_Idle))then 
    SPIF_Next <= '1';
   end if;	   
  when '1' =>  
   if((fn_to_integer(adr)=SPDR_Address and (iowe='1' or iore='1') and  SPIFClrSt_Current='1') or spiack='1') then
	SPIF_Next <= '0';
   end if;	
  when others => SPIF_Next <= SPIF;	
 end case;	
end process;	

--*************************************************************************************

spimaster <= MSTR;	
spe <= SPEB;

-- IRQ
spiirq <= SPIE and SPIF;	

OutMuxComb:process(adr,iore,SPDR_Rc,SPSR,SPCR)
begin
 case(fn_to_integer(adr)) is
  when SPDR_Address => dbus_out <= SPDR_Rc; out_en <= iore;
  when SPSR_Address => dbus_out <= SPSR;    out_en <= iore;   
  when SPCR_Address	=> dbus_out <= SPCR;    out_en <= iore;   
  when others       => dbus_out <= (others => '0'); out_en <= '0';  
 end case; 
end process; -- OutMuxComb	

--			
spidwrite  <= '0';
spiload    <= '0';
			
end RTL;
