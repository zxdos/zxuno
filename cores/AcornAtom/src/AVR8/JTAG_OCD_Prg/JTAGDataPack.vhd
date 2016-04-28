--**********************************************************************************************
-- Fuses/Lock bits and Calibration bytes for JTAG "Flash" Programmer
-- Version 0.11
-- Modified 19.05.2004
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package JTAGDataPack is 

	
-- Extended Fuse Byte
constant C_ExtFuseByte    : std_logic_vector(7 downto 0) := x"FD"; -- x"00"

-- Fuse High Byte
constant C_HighFuseByte   : std_logic_vector(7 downto 0) := x"19"; -- x"01"

-- Fuse Low Byte
constant C_LowFuseByte   : std_logic_vector(7 downto 0) := x"E3"; -- x"00"

-- Lock bits
constant C_LockBits      : std_logic_vector(7 downto 0) := x"FF";

-- Signature Bytes(3 Bytes)
constant C_SignByte1     : std_logic_vector(7 downto 0) := x"1E";
constant C_SignByte2     : std_logic_vector(7 downto 0) := x"97";
constant C_SignByte3     : std_logic_vector(7 downto 0) := x"02";

-- Calibration Bytes(4 Bytes)
constant C_CalibrByte1     : std_logic_vector(7 downto 0) := x"C1";
constant C_CalibrByte2     : std_logic_vector(7 downto 0) := x"C2";
constant C_CalibrByte3     : std_logic_vector(7 downto 0) := x"C3";
constant C_CalibrByte4     : std_logic_vector(7 downto 0) := x"C4";

end JTAGDataPack;
