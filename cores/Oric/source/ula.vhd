--
-- A simulation model of ULA
-- Copyright (c) seilebost - 2001 - 2009
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email seilebost@free.fr
--
--
--
--
-- 2013 Significant rewrite by d18c7db(a)hotmail
--
--   Combined all ULA submodules into one file
--   Elliminated gated clocks
--   Overall simplified and streamlined RTL
--   Reduced number of synthesis warnings
--   Fixed attribute decoding
--   Fixed phase1/phase2 address generation
--   Changes in timing signal generation
--   Fixed attributes not alligned to characters on screen
--   Implemented 50/60Hz attribute

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

--      ULA pinout
--  1 MUX    U RAM_D1 40
--  2 RAM_D2   RAM_D0 39
--  3 RAM_D3   RAM_D7 38
--  4 RAM_D4   RAM_D5 37
--  5 D5       RAM_D6 36
--  6 GND         A12 35
--  7 CLK          D6 34
--  8 D0          A09 33
--  9 CAS         A08 32
-- 10 RAS         A10 31
-- 11 D2          A15 30
-- 12 D3          A14 29
-- 13 D4      RAM_R/W 28
-- 14 PHI         R/W 27
-- 15 A11         MAP 26
-- 16 SYNC        I/O 25
-- 17 D1          Vcc 24
-- 18 D7       ROM_CS 23
-- 19 BLU         A13 22
-- 20 GRN         RED 21

entity ula is
port (
	RESETn     :   in  std_logic;                     -- RESET master

	CLK        :   in  std_logic;                     -- 24 MHz                       -- pin 07
	PHI2       :   out std_logic;                     -- 1 MHz CPU & system           -- pin 14
        PRE_PHI2   :   out std_logic;
	RW         :   in  std_logic;                     -- R/W from CPU                 -- pin 27
	MAPn       :   in  std_logic;                     -- MAP                          -- pin 26
	DB         :   in  std_logic_vector( 7 downto 0); -- DATA BUS                     -- pin 18,34,5,13,12,11,17,8
	ADDR       :   in  std_logic_vector(15 downto 0); -- ADDRESS BUS                  -- pin 30,29,22,35,15,31,33,32, A7,A6,A5,A4,A3,A2,A1,A0

	-- SRAM
	CSRAMn     :   out std_logic;
	SRAM_AD    :   out std_logic_vector(15 downto 0);
	SRAM_OE    :   out std_logic;
	SRAM_CE    :   out std_logic;
	SRAM_WE    :   out std_logic;
        SRAM_DO    :   out std_logic; -- enable drive of databus
	LATCH_SRAM :   out std_logic;

	-- DRAM
--	AD_RAM     :   out std_logic_vector( 7 downto 0); -- ADDRESS BUS for dynamic ram  -- pin 38,36,37,4,3,2,40,39
--	RASn       :   out std_logic;                     -- RAS for dynamic ram          -- pin 10
--	CASn       :   out std_logic;                     -- CAS for dynamic ram          -- pin 09
--	MUX        :   out std_logic;                     -- MUX selector                 -- pin 01
--	RW_RAM     :   out std_logic;                     -- Read/Write for dynamic ram   -- pin 28

	CSIOn      :   out std_logic;                     -- Chip select IO (VIA)         -- pin 25
	CSROMn     :   out std_logic;                     -- ROM select                   -- pin 23
	R          :   out std_logic;                     -- Red                          -- pin 21
	G          :   out std_logic;                     -- Green                        -- pin 20
	B          :   out std_logic;                     -- Blue                         -- pin 19
	SYNC       :   out std_logic;                     -- Synchronisation              -- pin 16        
	                                                  -- VCC                          -- pin 24
	                                                  -- GND                          -- pin 06
	HSYNC      :   out std_logic;
	VSYNC      :   out std_logic;
        video_vga  :   in std_logic
);
end;

architecture RTL of ula is

	-- Signal CLOCK
	signal CLK_24        : std_logic;                    -- CLOCK 24 MHz internal
	signal CLK_1_INT     : std_logic;                    -- CLOCK  1 MHz internal
	signal CLK_PIXEL_INT : std_logic;                    -- CLOCK PIXEL  internal 
	signal CLK_FLASH     : std_logic;                    -- CLOCK FLASH  external

	-- Data Bus Internal
	signal DB_INT       : std_logic_vector( 7 downto 0);

	-- Manage memory access
	signal VAP1         : std_logic_vector(15 downto 0); -- VIDEO ADDRESS PHASE 1
	signal VAP2         : std_logic_vector(15 downto 0); -- VIDEO ADDRESS PHASE 2
	signal lADDR        : std_logic_vector(15 downto 0); -- BUS ADDRESS PROCESSOR 
	signal RW_INT       : std_logic;                     -- Read/Write INTERNAL FROM CPU

	-- local signal
	signal lHIRES_SEL   : std_logic;                     -- TXT/HIRES SELECT
	signal HIRES_DEC    : std_logic;                     -- TXT/HIRES DECODE
	signal lDBLHGT_SEL  : std_logic;                     -- Double Height SELECT
	signal lALT_SEL     : std_logic;                     -- Character set select
	signal lFORCETXT    : std_logic;                     -- Force text mode
	signal isAttrib     : std_logic;                     -- Attrib
	signal ATTRIB_DEC   : std_logic;                     -- Attrib decode
--	signal LD_REG_0     : std_logic;                     -- Load zero into video register
	signal RELD_REG     : std_logic;                     -- Reload from register to shift
	signal DATABUS_EN   : std_logic;                     -- Data bus enable
	signal lCOMPSYNC    : std_logic;                     -- Composite Synchronization for video
	signal lHSYNCn      : std_logic;                     -- Horizontal Synchronization for video
	signal lVSYNC50n    : std_logic;                     -- Vertical Synchronization for 50Hz video
	signal lVSYNC60n    : std_logic;                     -- Vertical Synchronization for 60Hz video
	signal lVSYNCn      : std_logic;                     -- Vertical Synchronization for video
	signal BLANKINGn    : std_logic;                     -- Blanking signal
	signal lRELOAD_SEL  : std_logic;                     -- reload register SELECT
	signal lFREQ_SEL    : std_logic;                     -- Frequency video SELECT (50 or 60 Hz)
	signal LDFROMBUS    : std_logic;                     -- Load from Bus Data
	signal CHROWCNT     : std_logic_vector( 2 downto 0); -- ch?? row count
	signal lCTR_H       : std_logic_vector( 6 downto 0); -- Horizontal counter
	signal lCTR_V       : std_logic_vector( 8 downto 0); -- Vertical counter

	signal rgb_int      : std_logic_vector( 2 downto 0); -- Red Green Blue video signal

	-- local select RAM, IO & ROM
	signal CSRAMn_INT   : std_logic;                     -- RAM Chip Select
	signal CSIOn_INT    : std_logic;                     -- Input/Output Chip Select
	signal CSROMn_INT   : std_logic;                     -- ROM Chip select

	-- Bus Address internal
	signal AD_RAM_INT   : std_logic_vector(15 downto 0); -- RAM ADDRESS BUS

	-- RESET internal 
	signal RESET_INT    : std_logic;

	-- MAP internal 
	signal lMAPn        : std_logic;

	signal DBLHGT_EN    : std_logic;                     -- ENABLE DOUBLE HEIGHT
	signal CTR_V_DIV8   : std_logic_vector( 8 downto 0); -- VERTICAL COUNTER DIVIDE OR NOT BY 8
	signal voffset      : std_logic_vector(15 downto 0); -- OFFSET SCREEN
	signal mulBy40      : std_logic_vector(14 downto 0); -- Used to mult by 40

	signal c            : std_logic_vector(23 downto 0); -- states
	signal ph           : std_logic_vector( 2 downto 0); -- phases

	signal lCTR_FLASH   : std_logic_vector( 4 downto 0);
	signal lVBLANKn     : std_logic;
	signal lHBLANKn     : std_logic;

	signal lDATABUS     : std_logic_vector( 7 downto 0);
	signal lSHFREG      : std_logic_vector( 5 downto 0);
	signal lREGHOLD     : std_logic_vector( 6 downto 0);
	signal lATTRIBHOLD     : std_logic_vector( 6 downto 0);
	signal lRGB         : std_logic_vector( 2 downto 0);
	signal lREG_INK     : std_logic_vector( 2 downto 0);
	signal lREG_STYLE   : std_logic_vector( 2 downto 0);
	signal lREG_PAPER   : std_logic_vector( 2 downto 0);
	signal lREG_MODE    : std_logic_vector( 2 downto 0);
	signal ModeStyle    : std_logic_vector( 1 downto 0);
	signal lADD         : std_logic_vector( 5 downto 0);
	signal lInv         : std_logic;                    -- inverse signal
	signal lInv_hold    : std_logic;                    -- inverse signal hold
	signal lBGFG_SEL    : std_logic;
	signal lFLASH_SEL   : std_logic;

begin

	-- input assignments
	lADDR        <= ADDR;
	DB_INT       <= DB;
	CLK_24       <= CLK;
	RESET_INT    <= not RESETn;
	lMAPn        <= MAPn;
	RW_INT       <= RW;

	-- output assignments
	PHI2         <= CLK_1_INT;
        PRE_PHI2     <= c(15);
--	AD_RAM       <= AD_RAM_INT(15 downto 8);
	CSIOn        <= CSIOn_INT;
	CSROMn       <= CSROMn_INT;
	CSRAMn       <= CSRAMn_INT;

	------------------
	-- SRAM signals --
	------------------
	SRAM_AD    <= AD_RAM_INT;
	LATCH_SRAM <= not c(4) and not c(12) and not c(20);

	--            phase 1  phase 2  phase 3
	SRAM_OE    <= ph(0) or ph(1) or        RW_INT                ;
        SRAM_CE    <= '1'; -- always enabled  (ph(0) and not c(0)) or (ph(1) and not c(8) ) or (not c(16) and not c(16) and ph(2) and (not CSRAMn_INT) );
 
	SRAM_WE    <=  (not CSRAMn_INT) and (not RW_INT) and (c(18) or c(19));
	SRAM_DO    <=  (not CSRAMn_INT) and (not RW_INT) and (c(19) or c(19));

	-- VIDEO OUT
	R       <= RGB_INT(0);
	G       <= RGB_INT(1);
	B       <= RGB_INT(2);
	SYNC    <= lCOMPSYNC;
	HSYNC   <= lHSYNCn;
	VSYNC   <= lVSYNCn;

	----------------------
	----------------------
	-- Address Decoding --
	----------------------
	----------------------

	-- PAGE 3 I/O decoder : 0x300-0x3FF
	CSIOn_INT  <= '0' when (lADDR(15 downto 8) = x"03") and (CLK_1_INT = '1') else '1';
				
	-- PAGE ROM : 0xC000-0xFFFF   
	CSROMn_INT <= '0' when (lADDR(15 downto 14) = "11" and lMAPn = '1' and CLK_1_INT = '1') else '1';

	CSRAMn_INT <= '0' when  -- shadow RAM section
								 (lADDR(15 downto 14) = "11" and lMAPn = '0' and CLK_1_INT = '1') 
							 or
								-- normal RAM section
								(((lADDR(15 downto 8) /= x"03") and (lADDR(15 downto 14) /= "11")) and lMAPn = '1' and CLK_1_INT = '1')
						else '1';

	----------------------------------------------
	----------------------------------------------
	-- Control signal generation and sequencing --
	----------------------------------------------
	----------------------------------------------

	-- state and phase shifter
	U_TB_CPT: process (CLK_24, RESET_INT)
	begin
		if (RESET_INT = '1') then
			c <= "000000000000000000000001";
			ph <= "001";
		elsif falling_edge(CLK_24) then
			-- advance states
			c <= c(22 downto 0) & c(23);
			if (c(7) or c(15) or c(23)) = '1' then
				-- advance phases
				ph <= ph(1 downto 0) & ph(2);
			end if;
		end if;
	end process;

	----------------------
	-- Clock generation --
	----------------------

	-- CPU clock --
	CLK_1_INT <= ph(2);


--	LD_REG_0      <= isAttrib and c(5);

	CLK_PIXEL_INT <= c(1) or c(5) or c(9) or c(13) or c(17) or c(21);
	ATTRIB_DEC    <= c(3);
	RELD_REG      <= c(17);
	DATABUS_EN    <= c(2) or c(10);
	LDFROMBUS     <= ((not isAttrib) and c(12) and (not HIRES_DEC)) or ((not isAttrib) and c(5) and HIRES_DEC) or (isAttrib and c(9));

	-------------------------------------
	-------------------------------------
	-- Video timing signals generation --
	-------------------------------------
	-------------------------------------

	-- Horizontal Counter 
	u_CPT_H: process(CLK_1_INT, RESET_INT)
	begin
		if (RESET_INT = '1') then
			lCTR_H  <= (others => '0');
		elsif rising_edge(CLK_1_INT) then
			if lCTR_H < 63 then
				lCTR_H <= lCTR_H + 1;
			else       
				lCTR_H <= (others => '0');
			end if;                             
		end if;
	end process;

	-- Vertical Counter
	u_CPT_V: process(CLK_1_INT, RESET_INT)
	begin
		if (RESET_INT = '1') then
			lCTR_V <= (others => '0');
			lCTR_FLASH <= (others => '0');
		elsif rising_edge(CLK_1_INT) then
			if (lCTR_H = 63) then
				-- 50Hz = 312 lines, 60Hz = 260 lines
				if ((lCTR_V < 311) and lFREQ_SEL='1') or
					((lCTR_V < 259) and lFREQ_SEL='0') then
					lCTR_V <= lCTR_V + 1;
				else
					lCTR_V <= (others => '0');
					-- increment flash counter every frame
					lCTR_FLASH <= lCTR_FLASH + 1;
				end if;
			end if;
		end if;    
	end process;



	-- Horizontal Synchronisation
	lHSYNCn     <= '0' when (lCTR_H >=  49) and (lCTR_H <=  53) else '1';

	-- Horizontal Blank
	hblankfr: process (CLK_24)
	begin
          if (rising_edge(CLK_24)) then
            if  (lCTR_H >   0) and (lCTR_H <=  40) then
              lHBLANKn <= '1';
            else
              lHBLANKn <= '0';
            end if;
          end if;
        end process;
        
                
                             

	-- Signal to Reload Register to reset attributes
	lRELOAD_SEL <= '1' when (lCTR_H >=  49) else '0';

	-- Vertical Synchronisation
        lVSYNC50n   <= '0' when (lCTR_V >= 258) and (lCTR_V <= 259) else '1'; -- 50Hz
        lVSYNC60n   <= '0' when (lCTR_V >= 241) and (lCTR_V <= 242) else '1'; -- 60Hz
	-- lVSYNC50n   <= '0' when (lCTR_V >= 258)  else '1'; -- 50Hz
	-- lVSYNC60n   <= '0' when (lCTR_V >= 241)  else '1'; -- 60Hz
	lVSYNCn     <= lVSYNC50n when lFREQ_SEL='1' else lVSYNC60n;

	-- Vertical Blank
	lVBLANKn    <= '0' when (lCTR_V >= 224) else '1';

	-- Signal To Force TEXT MODE
	lFORCETXT   <= '1' when (lCTR_V >  199) and (lCTR_V<224) else '0'; 

	-- Assign output signals
	CLK_FLASH    <= lCTR_FLASH(4); 	-- Flash clock toggles every 16 video frames
	lCOMPSYNC    <= not (lHSYNCn xor lVSYNCn);
	BLANKINGn    <= lVBLANKn and lHBLANKn;



	-----------------------------
	-----------------------------
	-- Video attribute decoder --
	-----------------------------
	-----------------------------

	-- Latch data from Data Bus
	u_data_bus: process
	begin
		wait until rising_edge(CLK_24);
		if (DATABUS_EN = '1') then
			lDATABUS <= DB_INT;
		end if;
	end process;

	u_isattrib : process(CLK_24, RESET_INT)
	begin
		if (RESET_INT = '1') then
			IsATTRIB  <= '0';
			lInv_hold <= '0';
                        lATTRIBHOLD <= b"0011000";
		elsif rising_edge(CLK_24) then
			if (ATTRIB_DEC = '1') and (lCTR_V <224 ) and (lCTR_H <40) then
                          IsATTRIB  <= not (DB_INT(6) or DB_INT(5)); -- 1 = attribute, 0 = not an attribute
                          lATTRIBHOLD <= DB_INT(6 downto 0);
                          lInv_hold <= DB_INT(7);
                        elsif  (ATTRIB_DEC = '1') then
                          IsATTRIB <= '0';
			end if;
		end if;
	end process;

	u_lInv_hold : process
	begin
		wait until rising_edge(CLK_24);
		if (CLK_PIXEL_INT = '1' and RELD_REG = '1') then
			lInv <= lInv_hold;
		end if;
	end process;

	-- hold data bus value
	u_hold_reg: process(CLK_24, RESET_INT)
	begin
		if (RESET_INT = '1') then
			lREGHOLD <= (others => '0');
		elsif rising_edge(CLK_24) then
			if LDFROMBUS = '1' then
				lREGHOLD <= lDATABUS(6 downto 0);
			end if;
		end if;
	end process;

	u_ld_reg: process(CLK_24)
	begin
          if (RESET_INT = '1') then
            lREG_INK   <= (others=>'1');
            lREG_STYLE <= (others=>'0');
            lREG_PAPER <= (others=>'0');
            lREG_MODE  <= (others=>'0');
          elsif rising_edge(CLK_24) then
            if (lRELOAD_SEL = '1') then
              lREG_INK   <= (others=>'1');
              lREG_STYLE <= (others=>'0');
              lREG_PAPER <= (others=>'0');
            elsif (RELD_REG = '1' and isAttrib = '1') then
              case lATTRIBHOLD(6 downto 3) is
                when "0000" => lREG_INK   <= lATTRIBHOLD(2 downto 0);
                when "0001" => lREG_STYLE <= lATTRIBHOLD(2 downto 0);
                when "0010" => lREG_PAPER <= lATTRIBHOLD(2 downto 0);
                when "0011" => lREG_MODE  <= lATTRIBHOLD(2 downto 0);
                when others => null;
              end case;
            end if;
          end if;
	end process;

	-- selector bits in mode/style registers
	lALT_SEL    <= lREG_STYLE(0); -- Character set select : 0=Standard  1=Alternate
	lDBLHGT_SEL <= lREG_STYLE(1); -- Character type select: 0=Standard  1=Double
	lFLASH_SEL  <= lREG_STYLE(2); -- Flash select         : 0=Steady    1=Flashing
	lFREQ_SEL   <= lREG_MODE(1) when video_vga = '0' else '0';  -- Frequency select     : 0=60Hz      1=50Hz
	lHIRES_SEL  <=  lREG_MODE(2);  -- Mode Select          : 0=Text      1=Hires 

	-- Output signal for text/hires mode decode
	HIRES_DEC   <= (lHIRES_SEL  and (not lFORCETXT));
	DBLHGT_EN   <= (lDBLHGT_SEL and (not HIRES_DEC));

	-- shift video data
	u_shf_reg: process
	begin
		wait until rising_edge(CLK_24);
		if CLK_PIXEL_INT = '1' then
			-- Load shifter before the rising edge of PHI2
			if (RELD_REG = '1' and isAttrib = '0') then
				lSHFREG <= lREGHOLD(5 downto 0);
			else
				-- send 6 bits
				lSHFREG <= lSHFREG(4 downto 0) & '0';
			end if;
		end if;
	end process;

	lBGFG_SEL  <= '0' when ( (CLK_FLASH = '1') and (lFLASH_SEL = '1') ) else lSHFREG(5);

	-- local assign for R(ed)G(reen)B(lue) signal
	lRGB <= lREG_INK when lBGFG_SEL = '1' else lREG_PAPER;

	-- Assign out signal
	RGB_INT <=     lRGB  when (lInv = '0') and (BLANKINGn = '1') else
			     not(lRGB) when (lInv = '1') and (BLANKINGn = '1') else
			     (others=>'0');

	-- Compute offset 
	ModeStyle <= lHIRES_SEL & lALT_SEL;
	with ModeStyle select
	lADD <= "100111" when "11",     -- HIRES & ALT  x9Cxx
			  "100110" when "10",     -- HIRES & STD  x98xx
			  "101110" when "01",     -- TEXT  & ALT  xB8xx
			  "101101" when others;   -- TEXT  & STD  xB4xx

	-----------------------------
	-----------------------------
	-- Video address generator --
	-----------------------------
	-----------------------------

	-- divide by 8 in LORES
	CTR_V_DIV8 <= lCTR_V when (HIRES_DEC = '1') else "000" & lCTR_V(8 downto 3) ;

	-- to multiply by 40 without using a multiplier we just sum the results of the operations of
	-- multiply by 32 by shifting 5 bits and multiply by 8 by shifting 3 bits 
	mulBy40     <= ("0" & CTR_V_DIV8 & "00000") + ("000" & CTR_V_DIV8 & "000");
	voffset     <= X"A000" when (HIRES_DEC = '1') else X"BB80";

	-- Generate Address Phase 1
	VAP1        <= (voffset + mulBy40) + lCTR_H;

	-- Compute character row counter
	CHROWCNT    <= lCTR_V(3 downto 1) when (DBLHGT_EN = '1') else lCTR_V(2 downto 0);
	-- Generate Address Phase 2
	VAP2        <= lADD & lDATABUS(6 downto 0) & CHROWCNT;

	-- multiplex addresses at rising edge of each phase
	addr_latch: process
	begin
		wait until rising_edge(CLK_24);
		if c(0) = '1' then
			-- Generate video phase 1 address
			AD_RAM_INT <= VAP1;
		elsif c(8) = '1' then
			-- Generate video phase 2 address
			AD_RAM_INT <= VAP2;
		elsif c(16) = '1' then
			-- Generate CPU phase 3 address
			AD_RAM_INT <= lADDR; 
		end if;
	end process;
end architecture RTL;
