-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity cart_rom2 is
  port (
    CLK         : in    std_logic;
    ADDR        : in    std_logic_vector(11 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of cart_rom2 is


  type ROM_ARRAY is array(4096 to 5119) of std_logic_vector(7 downto 0);
  constant ROM : ROM_ARRAY := (
    x"BA",x"38",x"16",x"20",x"08",x"2B",x"7E",x"BB", -- 0x0000
    x"38",x"0F",x"28",x"31",x"23",x"56",x"2B",x"5E", -- 0x0008
    x"1B",x"1B",x"1B",x"1B",x"73",x"23",x"72",x"18", -- 0x0010
    x"00",x"E1",x"23",x"23",x"23",x"E5",x"18",x"CE", -- 0x0018
    x"06",x"00",x"B7",x"E1",x"D1",x"E5",x"2A",x"D5", -- 0x0020
    x"73",x"ED",x"52",x"4D",x"6B",x"62",x"23",x"23", -- 0x0028
    x"23",x"23",x"ED",x"B0",x"01",x"08",x"00",x"ED", -- 0x0030
    x"42",x"22",x"D5",x"73",x"E1",x"C9",x"02",x"00", -- 0x0038
    x"01",x"00",x"02",x"00",x"01",x"3E",x"10",x"11", -- 0x0040
    x"BF",x"73",x"CD",x"98",x"00",x"2A",x"C0",x"73", -- 0x0048
    x"3A",x"BF",x"73",x"4F",x"EB",x"2A",x"D3",x"73", -- 0x0050
    x"AF",x"47",x"CB",x"6E",x"28",x"3E",x"E5",x"7E", -- 0x0058
    x"E6",x"10",x"F6",x"20",x"77",x"AF",x"B2",x"20", -- 0x0060
    x"0B",x"B1",x"28",x"02",x"CB",x"F6",x"23",x"73", -- 0x0068
    x"23",x"73",x"18",x"42",x"CB",x"DE",x"79",x"B7", -- 0x0070
    x"28",x"1B",x"D5",x"EB",x"2A",x"D5",x"73",x"EB", -- 0x0078
    x"CB",x"F6",x"23",x"73",x"23",x"72",x"EB",x"D1", -- 0x0080
    x"73",x"23",x"72",x"23",x"73",x"23",x"72",x"23", -- 0x0088
    x"22",x"D5",x"73",x"18",x"21",x"23",x"73",x"23", -- 0x0090
    x"72",x"23",x"18",x"1A",x"CB",x"66",x"20",x"06", -- 0x0098
    x"23",x"23",x"23",x"04",x"18",x"B4",x"D5",x"E5", -- 0x00A0
    x"23",x"23",x"23",x"04",x"36",x"30",x"EB",x"E1", -- 0x00A8
    x"CB",x"A6",x"EB",x"D1",x"18",x"A4",x"E1",x"CB", -- 0x00B0
    x"AE",x"78",x"C9",x"01",x"00",x"01",x"00",x"01", -- 0x00B8
    x"BB",x"10",x"11",x"C2",x"73",x"CD",x"98",x"00", -- 0x00C0
    x"3A",x"C2",x"73",x"4F",x"2A",x"D3",x"73",x"47", -- 0x00C8
    x"11",x"03",x"00",x"B7",x"28",x"08",x"CB",x"66", -- 0x00D0
    x"20",x"0C",x"19",x"0D",x"20",x"F8",x"CB",x"6E", -- 0x00D8
    x"20",x"04",x"CB",x"7E",x"20",x"03",x"AF",x"18", -- 0x00E0
    x"0A",x"CB",x"76",x"20",x"02",x"CB",x"EE",x"CB", -- 0x00E8
    x"BE",x"3E",x"01",x"B7",x"C9",x"0F",x"06",x"01", -- 0x00F0
    x"03",x"09",x"00",x"0A",x"0F",x"02",x"0B",x"07", -- 0x00F8
    x"0F",x"05",x"04",x"08",x"0F",x"D3",x"C0",x"AF", -- 0x0100
    x"DD",x"2A",x"08",x"80",x"DD",x"23",x"DD",x"23", -- 0x0108
    x"FD",x"21",x"D7",x"73",x"06",x"0A",x"DD",x"77", -- 0x0110
    x"00",x"DD",x"23",x"FD",x"77",x"00",x"FD",x"23", -- 0x0118
    x"FD",x"77",x"00",x"FD",x"23",x"05",x"20",x"EE", -- 0x0120
    x"32",x"EB",x"73",x"32",x"EC",x"73",x"32",x"EE", -- 0x0128
    x"73",x"32",x"EF",x"73",x"32",x"F0",x"73",x"32", -- 0x0130
    x"F1",x"73",x"C9",x"00",x"C9",x"7C",x"FE",x"00", -- 0x0138
    x"20",x"04",x"DB",x"FC",x"18",x"02",x"DB",x"FF", -- 0x0140
    x"2F",x"C9",x"DB",x"FC",x"2F",x"32",x"EE",x"73", -- 0x0148
    x"DB",x"FF",x"2F",x"32",x"EF",x"73",x"D3",x"80", -- 0x0150
    x"CD",x"3B",x"11",x"DB",x"FC",x"2F",x"32",x"F0", -- 0x0158
    x"73",x"DB",x"FF",x"2F",x"32",x"F1",x"73",x"D3", -- 0x0160
    x"C0",x"C9",x"DB",x"FC",x"21",x"EB",x"73",x"CB", -- 0x0168
    x"67",x"20",x"08",x"CB",x"6F",x"20",x"03",x"35", -- 0x0170
    x"18",x"01",x"34",x"DB",x"FF",x"CB",x"67",x"20", -- 0x0178
    x"09",x"23",x"CB",x"6F",x"20",x"03",x"35",x"18", -- 0x0180
    x"01",x"34",x"C9",x"7D",x"FE",x"01",x"28",x"1A", -- 0x0188
    x"01",x"EB",x"73",x"7C",x"FE",x"00",x"28",x"01", -- 0x0190
    x"03",x"0A",x"5F",x"AF",x"02",x"CD",x"3D",x"11", -- 0x0198
    x"57",x"E6",x"0F",x"6F",x"7A",x"E6",x"40",x"67", -- 0x01A0
    x"18",x"16",x"D3",x"80",x"CD",x"3D",x"11",x"57", -- 0x01A8
    x"D3",x"C0",x"E6",x"0F",x"21",x"F5",x"10",x"06", -- 0x01B0
    x"00",x"4F",x"09",x"6E",x"7A",x"E6",x"40",x"67", -- 0x01B8
    x"C9",x"CD",x"4A",x"11",x"FD",x"21",x"D7",x"73", -- 0x01C0
    x"DD",x"2A",x"08",x"80",x"DD",x"E5",x"DD",x"7E", -- 0x01C8
    x"00",x"CB",x"7F",x"28",x"1E",x"47",x"11",x"02", -- 0x01D0
    x"00",x"DD",x"19",x"E6",x"07",x"28",x"09",x"3A", -- 0x01D8
    x"EE",x"73",x"21",x"EB",x"73",x"CD",x"20",x"12", -- 0x01E0
    x"78",x"E6",x"18",x"28",x"06",x"3A",x"F0",x"73", -- 0x01E8
    x"CD",x"3F",x"12",x"DD",x"E1",x"DD",x"7E",x"01", -- 0x01F0
    x"CB",x"7F",x"28",x"23",x"47",x"11",x"0A",x"00", -- 0x01F8
    x"FD",x"19",x"11",x"07",x"00",x"DD",x"19",x"E6", -- 0x0200
    x"07",x"28",x"09",x"3A",x"EF",x"73",x"21",x"EC", -- 0x0208
    x"73",x"CD",x"20",x"12",x"78",x"E6",x"18",x"28", -- 0x0210
    x"06",x"3A",x"F1",x"73",x"CD",x"3F",x"12",x"C9", -- 0x0218
    x"4F",x"CB",x"48",x"28",x"04",x"CD",x"B9",x"12", -- 0x0220
    x"79",x"CB",x"40",x"28",x"04",x"CD",x"89",x"12", -- 0x0228
    x"79",x"CB",x"50",x"28",x"09",x"7E",x"DD",x"86", -- 0x0230
    x"02",x"DD",x"77",x"02",x"AF",x"77",x"C9",x"4F", -- 0x0238
    x"CB",x"58",x"28",x"04",x"CD",x"E9",x"12",x"79", -- 0x0240
    x"CB",x"60",x"28",x"03",x"CD",x"50",x"12",x"C9", -- 0x0248
    x"C5",x"D5",x"E5",x"E6",x"0F",x"5F",x"FD",x"46", -- 0x0250
    x"08",x"FD",x"7E",x"09",x"FE",x"00",x"20",x"1A", -- 0x0258
    x"7B",x"B8",x"28",x"05",x"FD",x"73",x"08",x"18", -- 0x0260
    x"1C",x"3E",x"01",x"FD",x"77",x"09",x"21",x"F5", -- 0x0268
    x"10",x"16",x"00",x"19",x"7E",x"DD",x"77",x"04", -- 0x0270
    x"18",x"0B",x"7B",x"B8",x"28",x"07",x"FD",x"73", -- 0x0278
    x"08",x"AF",x"FD",x"77",x"09",x"E1",x"D1",x"C1", -- 0x0280
    x"C9",x"C5",x"D5",x"E6",x"40",x"5F",x"FD",x"46", -- 0x0288
    x"00",x"FD",x"7E",x"01",x"FE",x"00",x"20",x"13", -- 0x0290
    x"7B",x"B8",x"28",x"05",x"FD",x"73",x"00",x"18", -- 0x0298
    x"15",x"3E",x"01",x"FD",x"77",x"01",x"DD",x"73", -- 0x02A0
    x"00",x"18",x"0B",x"7B",x"B8",x"28",x"07",x"FD", -- 0x02A8
    x"73",x"00",x"AF",x"FD",x"77",x"01",x"D1",x"C1", -- 0x02B0
    x"C9",x"C5",x"D5",x"E6",x"0F",x"5F",x"FD",x"46", -- 0x02B8
    x"02",x"FD",x"7E",x"03",x"FE",x"00",x"20",x"13", -- 0x02C0
    x"7B",x"B8",x"28",x"05",x"FD",x"73",x"02",x"18", -- 0x02C8
    x"15",x"3E",x"01",x"FD",x"77",x"03",x"DD",x"73", -- 0x02D0
    x"01",x"18",x"0B",x"7B",x"B8",x"28",x"07",x"FD", -- 0x02D8
    x"73",x"02",x"AF",x"FD",x"77",x"03",x"D1",x"C1", -- 0x02E0
    x"C9",x"C5",x"D5",x"E6",x"40",x"5F",x"FD",x"46", -- 0x02E8
    x"06",x"FD",x"7E",x"07",x"FE",x"00",x"20",x"13", -- 0x02F0
    x"7B",x"B8",x"28",x"05",x"FD",x"73",x"06",x"18", -- 0x02F8
    x"15",x"3E",x"01",x"FD",x"77",x"07",x"DD",x"73", -- 0x0300
    x"03",x"18",x"0B",x"7B",x"B8",x"28",x"07",x"FD", -- 0x0308
    x"73",x"06",x"AF",x"FD",x"77",x"07",x"D1",x"C1", -- 0x0310
    x"C9",x"21",x"00",x"00",x"11",x"00",x"40",x"3E", -- 0x0318
    x"00",x"CD",x"D4",x"18",x"CD",x"E9",x"18",x"CD", -- 0x0320
    x"27",x"19",x"21",x"A3",x"18",x"11",x"60",x"00", -- 0x0328
    x"E5",x"D5",x"7E",x"FE",x"FF",x"28",x"1B",x"47", -- 0x0330
    x"04",x"21",x"C3",x"14",x"11",x"08",x"00",x"10", -- 0x0338
    x"15",x"D1",x"D5",x"FD",x"21",x"01",x"00",x"3E", -- 0x0340
    x"03",x"CD",x"BE",x"1F",x"D1",x"E1",x"13",x"23", -- 0x0348
    x"18",x"DE",x"D1",x"E1",x"18",x"03",x"19",x"18", -- 0x0350
    x"E6",x"21",x"4D",x"14",x"11",x"85",x"00",x"FD", -- 0x0358
    x"21",x"16",x"00",x"3E",x"02",x"CD",x"BE",x"1F", -- 0x0360
    x"21",x"63",x"14",x"11",x"A5",x"00",x"FD",x"21", -- 0x0368
    x"16",x"00",x"3E",x"02",x"CD",x"BE",x"1F",x"21", -- 0x0370
    x"C1",x"14",x"11",x"9B",x"00",x"FD",x"21",x"02", -- 0x0378
    x"00",x"3E",x"02",x"CD",x"BE",x"1F",x"21",x"B4", -- 0x0380
    x"14",x"11",x"AA",x"02",x"FD",x"21",x"0D",x"00", -- 0x0388
    x"3E",x"02",x"CD",x"BE",x"1F",x"21",x"3B",x"14", -- 0x0390
    x"11",x"00",x"00",x"3E",x"04",x"FD",x"21",x"12", -- 0x0398
    x"00",x"CD",x"BE",x"1F",x"06",x"01",x"0E",x"C0", -- 0x03A0
    x"CD",x"D9",x"1F",x"21",x"00",x"80",x"7E",x"FE", -- 0x03A8
    x"AA",x"20",x"4C",x"23",x"7E",x"FE",x"55",x"20", -- 0x03B0
    x"46",x"21",x"24",x"80",x"CD",x"46",x"19",x"11", -- 0x03B8
    x"24",x"80",x"21",x"01",x"02",x"CD",x"51",x"19", -- 0x03C0
    x"21",x"24",x"80",x"CD",x"46",x"19",x"23",x"54", -- 0x03C8
    x"5D",x"CD",x"46",x"19",x"21",x"C1",x"01",x"CD", -- 0x03D0
    x"51",x"19",x"21",x"24",x"80",x"CD",x"46",x"19", -- 0x03D8
    x"23",x"CD",x"46",x"19",x"23",x"11",x"AC",x"02", -- 0x03E0
    x"FD",x"21",x"04",x"00",x"3E",x"02",x"CD",x"BE", -- 0x03E8
    x"1F",x"CD",x"68",x"19",x"06",x"01",x"0E",x"80", -- 0x03F0
    x"CD",x"D9",x"1F",x"2A",x"0A",x"80",x"E9",x"21"  -- 0x03F8
  );

signal AR	: std_logic_vector(12 downto 0);

begin
  AR(12 downto 10) <= "100";
  
  process(CLK)
  begin
    if Clk'event and Clk = '1' then
		AR(9 downto 0) <= ADDR(9 downto 0);   
	  end if;
  end process;

   process (AR)
	 begin
	   DATA <= ROM(to_integer(unsigned(AR)));
    end process; 

end RTL;
