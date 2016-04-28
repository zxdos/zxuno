--**********************************************************************************************
-- Constants and types for JTAG "Flash" proggrammer for AVR Core
-- Version 0.11
-- Modified 13.05.2004
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package JTAGProgrammerPack is 

--	JTAG Programming Instruction (Page 311 Table 131)
constant CPrgComdRgLength     : positive := 15; 
-- ---------------------------------------------------------------------------------------------------
-- 1a. Chip erase
constant C_Prg_1A_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001110000000";
constant C_Prg_1A_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010000110000000"; -- "011000110000000"
constant C_Prg_1A_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001110000000"; -- "011001110000000"
constant C_Prg_1A_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001110000000"; -- "011001110000000"
-- 1b. Poll for chip erase complete
constant C_Prg_1B       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001110000000"; -- "011001110000000"
-- ---------------------------------------------------------------------------------------------------
-- 2a. Enter Flash Write 
constant C_Prg_2A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100010000";
-- 2b. Load Address High Byte (+ 8 Bit)
constant C_Prg_2B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000111";
-- 2c. Load Address Low Byte (+ 8 Bit)
constant C_Prg_2C       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 2d. Load Data Low Byte (+ 8 Bit)
constant C_Prg_2D       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010011";
-- 2e. Load Data High Byte (+ 8 Bit)
constant C_Prg_2E       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010111";
-- 2f. Latch Data 
constant C_Prg_2F_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
constant C_Prg_2F_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "111011100000000";
constant C_Prg_2F_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- 2g. Write Flash Page 
constant C_Prg_2G_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
constant C_Prg_2G_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011010100000000";
constant C_Prg_2G_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
constant C_Prg_2G_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- 2h. Poll for Page Write complete 
constant C_Prg_2H       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- ---------------------------------------------------------------------------------------------------
-- 3a. Enter Flash Read 
constant C_Prg_3A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100000010";
-- 3b. Load Address High Byte (+ 8 Bit)
constant C_Prg_3B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000111";
-- 3c. Load Address Low Byte (+ 8 Bit)
constant C_Prg_3C       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 3d. Read Data Low and High Byte 
constant C_Prg_3D_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001000000000";
constant C_Prg_3D_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011000000000";
constant C_Prg_3D_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- ---------------------------------------------------------------------------------------------------
-- 4a. Enter EEPROM Write 
constant C_Prg_4A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100010001";
-- 4b. Load Address High Byte (+ 8 Bit)
constant C_Prg_4B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000111";
-- 4c. Load Address Low Byte (+ 8 Bit)
constant C_Prg_4C       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 4d. Load Data Byte (+ 8 Bit)
constant C_Prg_4D       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010011";
-- 4e. Latch Data 
constant C_Prg_4E_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
constant C_Prg_4E_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "111011100000000";
constant C_Prg_4E_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- 4f. Write EEPROM Page 
constant C_Prg_4F_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
constant C_Prg_4F_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011000100000000";
constant C_Prg_4F_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
constant C_Prg_4F_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
-- 4g. Poll for Page Write complete 
constant C_Prg_4G     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
-- ---------------------------------------------------------------------------------------------------
-- 5a. Enter EEPROM Read 
constant C_Prg_5A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100000011";
-- 5b. Load Address High Byte (+ 8 Bit)
constant C_Prg_5B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000111";
-- 5c. Load Address Low Byte (+ 8 Bit)
constant C_Prg_5C       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 5d. Read Data Byte 
constant C_Prg_5D_1     : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0110011";
constant C_Prg_5D_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001000000000";
constant C_Prg_5D_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
-- ---------------------------------------------------------------------------------------------------
-- 6a. Enter Fuse Write 
constant C_Prg_6A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001101000000";
-- 6b. Load Data Low Byte(6) (+ 8 Bit)
constant C_Prg_6B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010011";
-- 6c. Write Fuse Extended byte 
constant C_Prg_6C_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101100000000";
constant C_Prg_6C_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011100100000000";
constant C_Prg_6C_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101100000000";
constant C_Prg_6C_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101100000000";
-- 6d. Poll for Fuse Write complete 
constant C_Prg_6D       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
-- 6e. Load Data Low Byte (+ 8 Bit)
constant C_Prg_6E       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010011";
-- 6f. Write Fuse High byte 
constant C_Prg_6F_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
constant C_Prg_6F_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011010100000000";
constant C_Prg_6F_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
constant C_Prg_6F_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";
-- 6g. Poll for Fuse Write complete 
constant C_Prg_6G       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
-- 6h. Load Data Low Byte (+ 8 Bit)
constant C_Prg_6H       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0010011";
-- 6i. Write Fuse Low byte 
constant C_Prg_6I_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
constant C_Prg_6I_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011000100000000";
constant C_Prg_6I_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
constant C_Prg_6I_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
-- 6j. Poll for Fuse Write complete 
constant C_Prg_6J       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
-- ---------------------------------------------------------------------------------------------------
-- 7a. Enter Lock bit Write 
constant C_Prg_7A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100100000";	
-- 7b. Load Data Byte (+6 Bit)
constant C_Prg_7B       : std_logic_vector(CPrgComdRgLength-6-1 downto 0) := "001001111";
-- 7c. Write Lock bits 
constant C_Prg_7C_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
constant C_Prg_7C_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011000100000000";
constant C_Prg_7C_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
constant C_Prg_7C_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";
-- 7d. Poll for Lock bit Write complete 
constant C_Prg_7D       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
-- ---------------------------------------------------------------------------------------------------
-- 8a. Enter Fuse/Lock bit Read 
constant C_Prg_8A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100000100";	
-- 8b. Read Extended Fuse Byte
constant C_Prg_8B_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101000000000";	
constant C_Prg_8B_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101100000000";	
-- 8c. Read Fuse High Byte
constant C_Prg_8C_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011111000000000";	
constant C_Prg_8C_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011111100000000";	
-- 8d. Read Fuse Low Byte
constant C_Prg_8D_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001000000000";	
constant C_Prg_8D_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
-- 8e. Read Lock bits 
constant C_Prg_8E_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011000000000";	
constant C_Prg_8E_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
--8f. Read Fuses and Lock bits 0111010000000
constant C_Prg_8F_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011101000000000";	
constant C_Prg_8F_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011111000000000";	
constant C_Prg_8F_3     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001000000000";	
constant C_Prg_8F_4     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011000000000";	
constant C_Prg_8F_5     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
-- ---------------------------------------------------------------------------------------------------
-- 9a. Enter Signature Byte Read 0100010001000
constant C_Prg_9A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100001000";	
-- 9b. Load Address Byte (+ 8 Bit)
constant C_Prg_9B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 9c. Read Signature Byte 
constant C_Prg_9C_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001000000000";	
constant C_Prg_9C_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
-- ---------------------------------------------------------------------------------------------------
-- 10a. Enter Calibration Byte Read 
constant C_Prg_10A       : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100001000";	
-- 10b. Load Address Byte (+ 8 Bit)
constant C_Prg_10B       : std_logic_vector(CPrgComdRgLength-8-1 downto 0) := "0000011";
-- 10c. Read Calibration Byte 
constant C_Prg_10C_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011000000000";	
constant C_Prg_10C_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011011100000000";	
-- ---------------------------------------------------------------------------------------------------
-- 11a. Load No Operation Command 
constant C_Prg_11A_1     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "010001100000000";	
constant C_Prg_11A_2     : std_logic_vector(CPrgComdRgLength-1 downto 0) := "011001100000000";	
-- ---------------------------------------------------------------------------------------------------

end JTAGProgrammerPack;
