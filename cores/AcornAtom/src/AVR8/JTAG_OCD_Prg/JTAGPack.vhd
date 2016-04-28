--**********************************************************************************************
-- Constants for OCD and "Flash" controller for AVR Core
-- Version 0.31
-- Modified 04.06.2004
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package JTAGPack is 

constant CInstrLength     : positive := 4; 

-- JTAG instructions
constant C_BYPASS         : std_logic_vector(CInstrLength-1 downto 0) := x"F";
constant C_SAMPLE_PRELOAD : std_logic_vector(CInstrLength-1 downto 0) := x"2";
constant C_EXTEST         : std_logic_vector(CInstrLength-1 downto 0) := x"0";

constant C_IDCODE         : std_logic_vector(CInstrLength-1 downto 0) := x"1";

constant C_AVR_RESET      : std_logic_vector(CInstrLength-1 downto 0) := x"C";

-- Program
constant C_PROG_ENABLE    : std_logic_vector(CInstrLength-1 downto 0) := x"4";
constant C_PROG_COMMANDS  : std_logic_vector(CInstrLength-1 downto 0) := x"5";
constant C_PROG_PAGELOAD  : std_logic_vector(CInstrLength-1 downto 0) := x"6";
constant C_PROG_PAGEREAD  : std_logic_vector(CInstrLength-1 downto 0) := x"7";

-- OCD (Private)
constant C_FORCE_BREAK    : std_logic_vector(CInstrLength-1 downto 0) := x"8";
constant C_RUN            : std_logic_vector(CInstrLength-1 downto 0) := x"9";
constant C_EX_INST        : std_logic_vector(CInstrLength-1 downto 0) := x"A";
constant C_OCD_ACCESS     : std_logic_vector(CInstrLength-1 downto 0) := x"B";

constant C_UNUSED_3       : std_logic_vector(CInstrLength-1 downto 0) := x"3";
constant C_UNUSED_D       : std_logic_vector(CInstrLength-1 downto 0) := x"D";
constant C_UNUSED_E       : std_logic_vector(CInstrLength-1 downto 0) := x"E";

constant CInitInstrRegVal : std_logic_vector(CInstrLength-1 downto 0) := C_IDCODE; -- May be C_IDCODE or C_BYPASS

-- IDCODE register fields
--constant CVersion         : std_logic_vector(3 downto 0)  := x"E"; -- Version Number (ATmega16)
--constant CPartNumber      : std_logic_vector(15 downto 0) := x"9403"; -- Part Number (ATmega16)
constant CVersion         : std_logic_vector(3 downto 0)  := x"6"; -- Version Number (ATmega128)
constant CPartNumber      : std_logic_vector(15 downto 0) := x"9702"; -- Part Number (ATmega128)
constant CManufacturerId  : std_logic_vector(10 downto 0) := "000"&x"1F"; -- Manufacturer ID(Atmel)	

constant C_ProgEnableVect : std_logic_vector(15 downto 0) := x"A370"; 

-- OCD register addresses
constant C_OCDPSB0Adr    : std_logic_vector(3 downto 0) := x"0";
constant C_OCDPSB1Adr    : std_logic_vector(3 downto 0) := x"1";
constant C_OCDPDMSBAdr   : std_logic_vector(3 downto 0) := x"2";
constant C_OCDPDSBAdr    : std_logic_vector(3 downto 0) := x"3";
constant C_OCDBCRAdr     : std_logic_vector(3 downto 0) := x"8";
constant C_OCDBSRAdr     : std_logic_vector(3 downto 0) := x"9";
constant C_OCDOCDRAdr    : std_logic_vector(3 downto 0) := x"C";
constant C_OCDCSRAdr     : std_logic_vector(3 downto 0) := x"D";

constant C_AVRBreakInst  : std_logic_vector(15 downto 0) := x"9598";

constant C_MaxEraseAdr   : std_logic_vector(15 downto 0) := x"FFFF";

end JTAGPack;
