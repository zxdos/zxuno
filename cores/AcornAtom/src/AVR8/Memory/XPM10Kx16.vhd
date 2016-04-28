--************************************************************************************************
-- 8Kx16(8 KB) PM RAM for AVR Core(Xilinx)
-- Version 0.1
-- Designed by Ruslan Lepetenok 
-- Modified by Jack Gassett for use with Papilio
-- Modified 11.06.2009
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.SynthCtrlPack.all; -- Synthesis control
 use WORK.prog_mem_init_pkg_normal.all; -- Init file for program memory (serial debugging off).
--use WORK.prog_mem_init_pkg_debug.all; -- Init file for program memory (serial debugging on).

-- For Synplicity Synplify
--library virtexe;
--use	virtexe.components.all; 

-- Aldec
library	unisim;
use unisim.vcomponents.all;

entity XPM10Kx16 is port(
	                  cp2     : in  std_logic;
					  ce      : in  std_logic; 
	                  address : in  std_logic_vector(13 downto 0); 
					  din     : in  std_logic_vector(15 downto 0);		                
					  dout    : out std_logic_vector(15 downto 0);
					  we     : in  std_logic
					  );
end XPM10Kx16;

architecture RTL of XPM10Kx16 is

type   RAMBlDOut_Type is array(2**(address'length-10)-1 downto 0) of  std_logic_vector(dout'range);
signal RAMBlDOut     : RAMBlDOut_Type;

signal WEB     : std_logic_vector(2**(address'length-10)-1 downto 0);
signal gnd      : std_logic;
signal DIP : STD_LOGIC_VECTOR(1 downto 0) := "11";
signal SSR : STD_LOGIC := '0'; -- Don't use the output resets.


begin

gnd <= '0';	

WEB_Dcd:for i in WEB'range generate 
 WEB(i) <= '1' when (we='1' and address(address'high downto 10)=i) else '0';
end generate ;


--RAM_Inst:for i in 0 to 2**(address'length-10)-1 generate

RAM_Word0:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word0_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word0_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word0_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word0_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word0_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(0)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(0)
                                      );
												  
RAM_Word1:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word1_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word1_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word1_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word1_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word1_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(1)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(1)
                                      );

RAM_Word2:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word2_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word2_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word2_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word2_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word2_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(2)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(2)
                                      );

RAM_Word3:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word3_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word3_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word3_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word3_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word3_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(3)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(3)
                                      );

RAM_Word4:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word4_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word4_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word4_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word4_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word4_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(4)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(4)
                                      );

RAM_Word5:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word5_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word5_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word5_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word5_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word5_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(5)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(5)
                                      );

RAM_Word6:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word6_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word6_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word6_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word6_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word6_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(6)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(6)
                                      );

RAM_Word7:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word7_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word7_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word7_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word7_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word7_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(7)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(7)
                                      );												  
									  
--end generate;

RAM_Word8:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word8_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word8_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word8_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word8_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word8_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(8)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(8)
                                      );												  
									  
--end generate;



RAM_Word9:component RAMB16_S18 
generic map (
INIT => X"00000", -- Value of output RAM registers at startup
SRVAL => X"00000", -- Ouput value upon SSR assertion
WRITE_MODE => "WRITE_FIRST", -- WRITE_FIRST, READ_FIRST or NO_CHANGE
-- The following INIT_xx declarations specify the intial contents of the RAM
-- Address 0 to 255
INIT_00 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_00,
INIT_01 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_01,
INIT_02 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_02,
INIT_03 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_03,
INIT_04 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_04,
INIT_05 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_05,
INIT_06 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_06,
INIT_07 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_07,
INIT_08 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_08,
INIT_09 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_09,
INIT_0A => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0A,
INIT_0B => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0B,
INIT_0C => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0C,
INIT_0D => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0D,
INIT_0E => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0E,
INIT_0F => Inst_AVR8_PM_Inst_RAM_Word9_INIT_0F,
INIT_10 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_10,
INIT_11 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_11,
INIT_12 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_12,
INIT_13 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_13,
INIT_14 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_14,
INIT_15 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_15,
INIT_16 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_16,
INIT_17 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_17,
INIT_18 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_18,
INIT_19 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_19,
INIT_1A => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1A,
INIT_1B => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1B,
INIT_1C => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1C,
INIT_1D => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1D,
INIT_1E => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1E,
INIT_1F => Inst_AVR8_PM_Inst_RAM_Word9_INIT_1F,
INIT_20 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_20,
INIT_21 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_21,
INIT_22 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_22,
INIT_23 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_23,
INIT_24 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_24,
INIT_25 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_25,
INIT_26 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_26,
INIT_27 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_27,
INIT_28 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_28,
INIT_29 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_29,
INIT_2A => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2A,
INIT_2B => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2B,
INIT_2C => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2C,
INIT_2D => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2D,
INIT_2E => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2E,
INIT_2F => Inst_AVR8_PM_Inst_RAM_Word9_INIT_2F,
-- Address 768 to 1023
INIT_30 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_30,
INIT_31 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_31,
INIT_32 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_32,
INIT_33 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_33,
INIT_34 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_34,
INIT_35 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_35,
INIT_36 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_36,
INIT_37 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_37,
INIT_38 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_38,
INIT_39 => Inst_AVR8_PM_Inst_RAM_Word9_INIT_39,
INIT_3A => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3A,
INIT_3B => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3B,
INIT_3C => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3C,
INIT_3D => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3D,
INIT_3E => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3E,
INIT_3F => Inst_AVR8_PM_Inst_RAM_Word9_INIT_3F
)
port map(
                                      DO   => RAMBlDOut(9)(15 downto 0),
                                      ADDR => address(9 downto 0),
                                      DI   => din(15 downto 0),
												  DIP  => DIP,
                                      EN   => ce,
												  SSR  => SSR,
                                      CLK  => cp2,
                                      WE   => WEB(9)
                                      );												  
									  
--end generate;
        


        
-- Output data mux
dout <= RAMBlDOut(CONV_INTEGER(address(address'high downto 10)));



end RTL;
