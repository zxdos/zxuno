-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity VIC20_CHAR_ROM is
  port (
    CLK         : in    std_logic;
    ENA         : in    std_logic;
    ADDR        : in    std_logic_vector(11 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of VIC20_CHAR_ROM is

  function romgen_str2bv (str : string) return bit_vector is
    variable result : bit_vector (str'length*4-1 downto 0);
  begin
    for i in 0 to str'length-1 loop
      case str(str'high-i) is
        when '0'       => result(i*4+3 downto i*4) := x"0";
        when '1'       => result(i*4+3 downto i*4) := x"1";
        when '2'       => result(i*4+3 downto i*4) := x"2";
        when '3'       => result(i*4+3 downto i*4) := x"3";
        when '4'       => result(i*4+3 downto i*4) := x"4";
        when '5'       => result(i*4+3 downto i*4) := x"5";
        when '6'       => result(i*4+3 downto i*4) := x"6";
        when '7'       => result(i*4+3 downto i*4) := x"7";
        when '8'       => result(i*4+3 downto i*4) := x"8";
        when '9'       => result(i*4+3 downto i*4) := x"9";
        when 'A'       => result(i*4+3 downto i*4) := x"A";
        when 'B'       => result(i*4+3 downto i*4) := x"B";
        when 'C'       => result(i*4+3 downto i*4) := x"C";
        when 'D'       => result(i*4+3 downto i*4) := x"D";
        when 'E'       => result(i*4+3 downto i*4) := x"E";
        when 'F'       => result(i*4+3 downto i*4) := x"F";
        when others    => null;
      end case;
    end loop;
    return result;
  end romgen_str2bv;

  attribute INIT_00 : string;
  attribute INIT_01 : string;
  attribute INIT_02 : string;
  attribute INIT_03 : string;
  attribute INIT_04 : string;
  attribute INIT_05 : string;
  attribute INIT_06 : string;
  attribute INIT_07 : string;
  attribute INIT_08 : string;
  attribute INIT_09 : string;
  attribute INIT_0A : string;
  attribute INIT_0B : string;
  attribute INIT_0C : string;
  attribute INIT_0D : string;
  attribute INIT_0E : string;
  attribute INIT_0F : string;
  attribute INIT_10 : string;
  attribute INIT_11 : string;
  attribute INIT_12 : string;
  attribute INIT_13 : string;
  attribute INIT_14 : string;
  attribute INIT_15 : string;
  attribute INIT_16 : string;
  attribute INIT_17 : string;
  attribute INIT_18 : string;
  attribute INIT_19 : string;
  attribute INIT_1A : string;
  attribute INIT_1B : string;
  attribute INIT_1C : string;
  attribute INIT_1D : string;
  attribute INIT_1E : string;
  attribute INIT_1F : string;
  attribute INIT_20 : string;
  attribute INIT_21 : string;
  attribute INIT_22 : string;
  attribute INIT_23 : string;
  attribute INIT_24 : string;
  attribute INIT_25 : string;
  attribute INIT_26 : string;
  attribute INIT_27 : string;
  attribute INIT_28 : string;
  attribute INIT_29 : string;
  attribute INIT_2A : string;
  attribute INIT_2B : string;
  attribute INIT_2C : string;
  attribute INIT_2D : string;
  attribute INIT_2E : string;
  attribute INIT_2F : string;
  attribute INIT_30 : string;
  attribute INIT_31 : string;
  attribute INIT_32 : string;
  attribute INIT_33 : string;
  attribute INIT_34 : string;
  attribute INIT_35 : string;
  attribute INIT_36 : string;
  attribute INIT_37 : string;
  attribute INIT_38 : string;
  attribute INIT_39 : string;
  attribute INIT_3A : string;
  attribute INIT_3B : string;
  attribute INIT_3C : string;
  attribute INIT_3D : string;
  attribute INIT_3E : string;
  attribute INIT_3F : string;

  component RAMB16_S4
    --pragma translate_off
    generic (
      INIT_00 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_10 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_11 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_12 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_13 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_14 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_15 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_16 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_17 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_18 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_19 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_20 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_21 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_22 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_23 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_24 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_25 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_26 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_27 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_28 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_29 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_30 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_31 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_32 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_33 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_34 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_35 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_36 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_37 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_38 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_39 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DO    : out std_logic_vector (3 downto 0);
      ADDR  : in  std_logic_vector (11 downto 0);
      CLK   : in  std_logic;
      DI    : in  std_logic_vector (3 downto 0);
      EN    : in  std_logic;
      SSR   : in  std_logic;
      WE    : in  std_logic 
      );
  end component;

  signal rom_addr : std_logic_vector(11 downto 0);

begin

  p_addr : process(ADDR)
  begin
     rom_addr <= (others => '0');
     rom_addr(11 downto 0) <= ADDR;
  end process;

  rom0 : if true generate
    attribute INIT_00 of inst : label is "0C22E02C0000800E0E00800E084222480C20002C0C22C22C0222E2480E0C6A2C";
    attribute INIT_01 of inst : label is "084222480226A2220222AA620E000000024808420844444E0C88888C0222E222";
    attribute INIT_02 of inst : label is "026AA222088442220C2222220888888E0C22C02C0248C22C0A4A22480000C22C";
    attribute INIT_03 of inst : label is "000F00008888AC800C44444C0E00C00C0C00000C0E00842E0888C22202248422";
    attribute INIT_04 of inst : label is "000000840A4A08800660842008CAC8E8044E4E44000004440800888800000000";
    attribute INIT_05 of inst : label is "00008420088000000000E000088000000088E88008ACECA80008880004800084";
    attribute INIT_06 of inst : label is "0000842E0C22C00C0842480E044E44C40C22C22C0E00C22C0E8888880C22A62C";
    attribute INIT_07 of inst : label is "0000C22C008C6C80000E0E000E80008E08800800008008000842E22C0C22C22C";
    attribute INIT_08 of inst : label is "0000000000F00000000000F000000F000000F000000000000ECFFEC8000F0000";
    attribute INIT_09 of inst : label is "0000000F0000842112480000F000000000000888000348888800000044444444";
    attribute INIT_0A of inst : label is "0C2222C012488421884300000000000008CEFFF60F0000000CEEEEC01111111F";
    attribute INIT_0B of inst : label is "137FFFFF0444E1008888888800000000888F888808CEFEC822222222088A7AC8";
    attribute INIT_0C of inst : label is "111111115A5A5A5A00000000F00000000000000FFFFF00000000000000000000";
    attribute INIT_0D of inst : label is "FF00000088880000000F8888FFFF0000888F88883333333300008CEF5A5A0000";
    attribute INIT_0E of inst : label is "000000FF77777777000000000000000088888888888F0000000F8888888F0000";
    attribute INIT_0F of inst : label is "FFFF000000000000000888880000FFFF00000000F1111111FFF0000000000FFF";
    attribute INIT_10 of inst : label is "F3DD1FD3FFFF7FF1F1FF7FF1F7BDDDB7F3DFFFD3F3DD3DD3FDDD1DB7F1F395D3";
    attribute INIT_11 of inst : label is "F7BDDDB7FDD95DDDFDDD559DF1FFFFFFFDB7F7BDF7BBBBB1F3777773FDDD1DDD";
    attribute INIT_12 of inst : label is "FD955DDDF77BBDDDF3DDDDDDF7777771F3DD3FD3FDB73DD3F5B5DDB7FFFF3DD3";
    attribute INIT_13 of inst : label is "FFF0FFFF7777537FF3BBBBB3F1FF3FF3F3FFFFF3F1FF7BD1F7773DDDFDDB7BDD";
    attribute INIT_14 of inst : label is "FFFFFF7BF5B5F77FF99F7BDFF7353717FBB1B1BBFFFFFBBBF7FF7777FFFFFFFF";
    attribute INIT_15 of inst : label is "FFFF7BDFF77FFFFFFFFF1FFFF77FFFFFFF77177FF7531357FFF777FFFB7FFF7B";
    attribute INIT_16 of inst : label is "FFFF7BD1F3DD3FF3F7BDB7F1FBB1BB3BF3DD3DD3F1FF3DD3F1777777F3DD59D3";
    attribute INIT_17 of inst : label is "FFFF3DD3FF73937FFFF1F1FFF17FFF71F77FF7FFFF7FF7FFF7BD1DD3F3DD3DD3";
    attribute INIT_18 of inst : label is "FFFFFFFFFF0FFFFFFFFFFF0FFFFFF0FFFFFF0FFFFFFFFFFFF1300137FFF0FFFF";
    attribute INIT_19 of inst : label is "FFFFFFF0FFFF7BDEEDB7FFFF0FFFFFFFFFFFF777FFFCB77777FFFFFFBBBBBBBB";
    attribute INIT_1A of inst : label is "F3DDDD3FEDB77BDE77BCFFFFFFFFFFFFF7310009F0FFFFFFF311113FEEEEEEE0";
    attribute INIT_1B of inst : label is "EC800000FBBB1EFF77777777FFFFFFFF77707777F7310137DDDDDDDDF7758537";
    attribute INIT_1C of inst : label is "EEEEEEEEA5A5A5A5FFFFFFFF0FFFFFFFFFFFFFF00000FFFFFFFFFFFFFFFFFFFF";
    attribute INIT_1D of inst : label is "00FFFFFF7777FFFFFFF077770000FFFF77707777CCCCCCCCFFFF7310A5A5FFFF";
    attribute INIT_1E of inst : label is "FFFFFF0088888888FFFFFFFFFFFFFFFF777777777770FFFFFFF077777770FFFF";
    attribute INIT_1F of inst : label is "0000FFFFFFFFFFFFFFF77777FFFF0000FFFFFFFF0EEEEEEE000FFFFFFFFFF000";
    attribute INIT_20 of inst : label is "C2A66A000000C02C0C0E2C000A626A220C202C000C222C000A4C48000E0C6A2C";
    attribute INIT_21 of inst : label is "0C222C0002222C00099996000C8888880480840084444C040C88880802222C00";
    attribute INIT_22 of inst : label is "06999100084222000A6222000C200C000C2C0E0000002C0022A66A0000C22C00";
    attribute INIT_23 of inst : label is "000F00008888AC800C44444C0E00C00C0C00000C0E084E00C2A6220002484200";
    attribute INIT_24 of inst : label is "000000840A4A08800660842008CAC8E8044E4E44000004440800888800000000";
    attribute INIT_25 of inst : label is "00008420088000000000E000088000000088E88008ACECA80008880004800084";
    attribute INIT_26 of inst : label is "0000842E0C22C00C0842480E044E44C40C22C22C0E00C22C0E8888880C22A62C";
    attribute INIT_27 of inst : label is "0000C22C008C6C80000E0E000E80008E08800800008008000842E22C0C22C22C";
    attribute INIT_28 of inst : label is "0C22E02C0000800E0E00800E084222480C20002C0C22C22C0222E248000F0000";
    attribute INIT_29 of inst : label is "084222480226A2220222AA620E000000024808420844444E0C88888C0222E222";
    attribute INIT_2A of inst : label is "026AA222088442220C2222220888888E0C22C02C0248C22C0A4A22480000C22C";
    attribute INIT_2B of inst : label is "936C936C33CC33CC8888888800000000888F88880E00842E0888C22202248422";
    attribute INIT_2C of inst : label is "111111115A5A5A5A00000000F00000000000000FFFFF00000000000000000000";
    attribute INIT_2D of inst : label is "FF00000088880000000F8888FFFF0000888F888833333333C639C6395A5A0000";
    attribute INIT_2E of inst : label is "000000FF77777777000000000000000088888888888F0000000F8888888F0000";
    attribute INIT_2F of inst : label is "FFFF000000000000000888880000FFFF0000000000008421FFF0000000000FFF";
    attribute INIT_30 of inst : label is "3D5995FFFFFF3FD3F3F1D3FFF59D95DDF3DFD3FFF3DDD3FFF5B3B7FFF1F395D3";
    attribute INIT_31 of inst : label is "F3DDD3FFFDDDD3FFF66669FFF3777777FB7F7BFF7BBBB3FBF37777F7FDDDD3FF";
    attribute INIT_32 of inst : label is "F9666EFFF7BDDDFFF59DDDFFF3DFF3FFF3D3F1FFFFFFD3FFDD5995FFFF3DD3FF";
    attribute INIT_33 of inst : label is "FFF0FFFF7777537FF3BBBBB3F1FF3FF3F3FFFFF3F1F7B1FF3D59DDFFFDB7BDFF";
    attribute INIT_34 of inst : label is "FFFFFF7BF5B5F77FF99F7BDFF7353717FBB1B1BBFFFFFBBBF7FF7777FFFFFFFF";
    attribute INIT_35 of inst : label is "FFFF7BDFF77FFFFFFFFF1FFFF77FFFFFFF77177FF7531357FFF777FFFB7FFF7B";
    attribute INIT_36 of inst : label is "FFFF7BD1F3DD3FF3F7BDB7F1FBB1BB3BF3DD3DD3F1FF3DD3F1777777F3DD59D3";
    attribute INIT_37 of inst : label is "FFFF3DD3FF73937FFFF1F1FFF17FFF71F77FF7FFFF7FF7FFF7BD1DD3F3DD3DD3";
    attribute INIT_38 of inst : label is "F3DD1FD3FFFF7FF1F1FF7FF1F7BDDDB7F3DFFFD3F3DD3DD3FDDD1DB7FFF0FFFF";
    attribute INIT_39 of inst : label is "F7BDDDB7FDD95DDDFDDD559DF1FFFFFFFDB7F7BDF7BBBBB1F3777773FDDD1DDD";
    attribute INIT_3A of inst : label is "FD955DDDF77BBDDDF3DDDDDDF7777771F3DD3FD3FDB73DD3F5B5DDB7FFFF3DD3";
    attribute INIT_3B of inst : label is "6C936C93CC33CC3377777777FFFFFFFF77707777F1FF7BD1F7773DDDFDDB7BDD";
    attribute INIT_3C of inst : label is "EEEEEEEEA5A5A5A5FFFFFFFF0FFFFFFFFFFFFFF00000FFFFFFFFFFFFFFFFFFFF";
    attribute INIT_3D of inst : label is "00FFFFFF7777FFFFFFF077770000FFFF77707777CCCCCCCC39C639C6A5A5FFFF";
    attribute INIT_3E of inst : label is "FFFFFF0088888888FFFFFFFFFFFFFFFF777777777770FFFFFFF077777770FFFF";
    attribute INIT_3F of inst : label is "0000FFFFFFFFFFFFFFF77777FFFF0000FFFFFFFFFFFF7BDE000FFFFFFFFFF000";
  begin
  inst : RAMB16_S4
      --pragma translate_off
      generic map (
        INIT_00 => romgen_str2bv(inst'INIT_00),
        INIT_01 => romgen_str2bv(inst'INIT_01),
        INIT_02 => romgen_str2bv(inst'INIT_02),
        INIT_03 => romgen_str2bv(inst'INIT_03),
        INIT_04 => romgen_str2bv(inst'INIT_04),
        INIT_05 => romgen_str2bv(inst'INIT_05),
        INIT_06 => romgen_str2bv(inst'INIT_06),
        INIT_07 => romgen_str2bv(inst'INIT_07),
        INIT_08 => romgen_str2bv(inst'INIT_08),
        INIT_09 => romgen_str2bv(inst'INIT_09),
        INIT_0A => romgen_str2bv(inst'INIT_0A),
        INIT_0B => romgen_str2bv(inst'INIT_0B),
        INIT_0C => romgen_str2bv(inst'INIT_0C),
        INIT_0D => romgen_str2bv(inst'INIT_0D),
        INIT_0E => romgen_str2bv(inst'INIT_0E),
        INIT_0F => romgen_str2bv(inst'INIT_0F),
        INIT_10 => romgen_str2bv(inst'INIT_10),
        INIT_11 => romgen_str2bv(inst'INIT_11),
        INIT_12 => romgen_str2bv(inst'INIT_12),
        INIT_13 => romgen_str2bv(inst'INIT_13),
        INIT_14 => romgen_str2bv(inst'INIT_14),
        INIT_15 => romgen_str2bv(inst'INIT_15),
        INIT_16 => romgen_str2bv(inst'INIT_16),
        INIT_17 => romgen_str2bv(inst'INIT_17),
        INIT_18 => romgen_str2bv(inst'INIT_18),
        INIT_19 => romgen_str2bv(inst'INIT_19),
        INIT_1A => romgen_str2bv(inst'INIT_1A),
        INIT_1B => romgen_str2bv(inst'INIT_1B),
        INIT_1C => romgen_str2bv(inst'INIT_1C),
        INIT_1D => romgen_str2bv(inst'INIT_1D),
        INIT_1E => romgen_str2bv(inst'INIT_1E),
        INIT_1F => romgen_str2bv(inst'INIT_1F),
        INIT_20 => romgen_str2bv(inst'INIT_20),
        INIT_21 => romgen_str2bv(inst'INIT_21),
        INIT_22 => romgen_str2bv(inst'INIT_22),
        INIT_23 => romgen_str2bv(inst'INIT_23),
        INIT_24 => romgen_str2bv(inst'INIT_24),
        INIT_25 => romgen_str2bv(inst'INIT_25),
        INIT_26 => romgen_str2bv(inst'INIT_26),
        INIT_27 => romgen_str2bv(inst'INIT_27),
        INIT_28 => romgen_str2bv(inst'INIT_28),
        INIT_29 => romgen_str2bv(inst'INIT_29),
        INIT_2A => romgen_str2bv(inst'INIT_2A),
        INIT_2B => romgen_str2bv(inst'INIT_2B),
        INIT_2C => romgen_str2bv(inst'INIT_2C),
        INIT_2D => romgen_str2bv(inst'INIT_2D),
        INIT_2E => romgen_str2bv(inst'INIT_2E),
        INIT_2F => romgen_str2bv(inst'INIT_2F),
        INIT_30 => romgen_str2bv(inst'INIT_30),
        INIT_31 => romgen_str2bv(inst'INIT_31),
        INIT_32 => romgen_str2bv(inst'INIT_32),
        INIT_33 => romgen_str2bv(inst'INIT_33),
        INIT_34 => romgen_str2bv(inst'INIT_34),
        INIT_35 => romgen_str2bv(inst'INIT_35),
        INIT_36 => romgen_str2bv(inst'INIT_36),
        INIT_37 => romgen_str2bv(inst'INIT_37),
        INIT_38 => romgen_str2bv(inst'INIT_38),
        INIT_39 => romgen_str2bv(inst'INIT_39),
        INIT_3A => romgen_str2bv(inst'INIT_3A),
        INIT_3B => romgen_str2bv(inst'INIT_3B),
        INIT_3C => romgen_str2bv(inst'INIT_3C),
        INIT_3D => romgen_str2bv(inst'INIT_3D),
        INIT_3E => romgen_str2bv(inst'INIT_3E),
        INIT_3F => romgen_str2bv(inst'INIT_3F)
        )
      --pragma translate_on
      port map (
        DO   => DATA(3 downto 0),
        ADDR => rom_addr,
        CLK  => CLK,
        DI   => "0000",
        EN   => ENA,
        SSR  => '0',
        WE   => '0'
        );
  end generate;
  rom1 : if true generate
    attribute INIT_00 of inst : label is "0124442104447447074474470722222701244421072232270444742101245421";
    attribute INIT_01 of inst : label is "0124442104444564044455640744444404447444034000000100000104447444";
    attribute INIT_02 of inst : label is "0465544401122444034444440000000303403443044474470124442104447447";
    attribute INIT_03 of inst : label is "0127210000002100030000030671311003222223074210070000122204421244";
    attribute INIT_04 of inst : label is "0000010003443443042106600030121002272722000002220000000000000000";
    attribute INIT_05 of inst : label is "0421000001100000000070001000000000003000002131200210001200011100";
    attribute INIT_06 of inst : label is "0111004703447421034007470007210003401043074300430300021003465443";
    attribute INIT_07 of inst : label is "0101004307100017000707000013631010000000000000000300344303443443";
    attribute INIT_08 of inst : label is "2222222200F00000000000F000000F000000F0001111111103177310000F0000";
    attribute INIT_09 of inst : label is "8888888F8421000000001248F8888888000E100000000000001E000000000000";
    attribute INIT_0A of inst : label is "03444430842112480000000044444444001377730F000000037777300000000F";
    attribute INIT_0B of inst : label is "0000137F01153000000000005A5A5A5A000F0000001373100000000000027210";
    attribute INIT_0C of inst : label is "000000005A5A5A5A88888888F00000000000000FFFFF0000FFFFFFFF00000000";
    attribute INIT_0D of inst : label is "FF000000000F0000000000000000000000000000000000008CEFFFFF5A5A0000";
    attribute INIT_0E of inst : label is "000000FF00000000EEEEEEEECCCCCCCC000F0000000F0000000F000000000000";
    attribute INIT_0F of inst : label is "0000FFFF0000FFFF000F000000000000FFFF0000F0000000FFF0000000000FFF";
    attribute INIT_10 of inst : label is "FEDBBBDEFBBB8BB8F8BB8BB8F8DDDDD8FEDBBBDEF8DDCDD8FBBB8BDEFEDBABDE";
    attribute INIT_11 of inst : label is "FEDBBBDEFBBBBA9BFBBBAA9BF8BBBBBBFBBB8BBBFCBFFFFFFEFFFFFEFBBB8BBB";
    attribute INIT_12 of inst : label is "FB9AABBBFEEDDBBBFCBBBBBBFFFFFFFCFCBFCBBCFBBB8BB8FEDBBBDEFBBB8BB8";
    attribute INIT_13 of inst : label is "FED8DEFFFFFFDEFFFCFFFFFCF98ECEEFFCDDDDDCF8BDEFF8FFFFEDDDFBBDEDBB";
    attribute INIT_14 of inst : label is "FFFFFEFFFCBBCBBCFBDEF99FFFCFEDEFFDD8D8DDFFFFFDDDFFFFFFFFFFFFFFFF";
    attribute INIT_15 of inst : label is "FBDEFFFFFEEFFFFFFFFF8FFFEFFFFFFFFFFFCFFFFFDECEDFFDEFFFEDFFFEEEFF";
    attribute INIT_16 of inst : label is "FEEEFFB8FCBB8BDEFCBFF8B8FFF8DEFFFCBFEFBCF8BCFFBCFCFFFDEFFCB9ABBC";
    attribute INIT_17 of inst : label is "FEFEFFBCF8EFFFE8FFF8F8FFFFEC9CEFEFFFFFFFFFFFFFFFFCFFCBBCFCBBCBBC";
    attribute INIT_18 of inst : label is "DDDDDDDDFF0FFFFFFFFFFF0FFFFFF0FFFFFF0FFFEEEEEEEEFCE88CEFFFF0FFFF";
    attribute INIT_19 of inst : label is "777777707BDEFFFFFFFFEDB707777777FFF1EFFFFFFFFFFFFFE1FFFFFFFFFFFF";
    attribute INIT_1A of inst : label is "FCBBBBCF7BDEEDB7FFFFFFFFBBBBBBBBFFEC888CF0FFFFFFFC8888CFFFFFFFF0";
    attribute INIT_1B of inst : label is "FFFFEC80FEEACFFFFFFFFFFFA5A5A5A5FFF0FFFFFFEC8CEFFFFFFFFFFFFD8DEF";
    attribute INIT_1C of inst : label is "FFFFFFFFA5A5A5A5777777770FFFFFFFFFFFFFF00000FFFF00000000FFFFFFFF";
    attribute INIT_1D of inst : label is "00FFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF73100000A5A5FFFF";
    attribute INIT_1E of inst : label is "FFFFFF00FFFFFFFF1111111133333333FFF0FFFFFFF0FFFFFFF0FFFFFFFFFFFF";
    attribute INIT_1F of inst : label is "FFFF0000FFFF0000FFF0FFFFFFFFFFFF0000FFFF0FFFFFFF000FFFFFFFFFF000";
    attribute INIT_20 of inst : label is "3034430001117110034743000344430003444300056465440343030001245421";
    attribute INIT_21 of inst : label is "0344430004446500044447000100000104654444340000000100010004446544";
    attribute INIT_22 of inst : label is "0344440001244400034444000011171107034300044465000034430044566500";
    attribute INIT_23 of inst : label is "0127210000002100030000030671311003222223072107003034440004212400";
    attribute INIT_24 of inst : label is "0000010003443443042106600030121002272722000002220000000000000000";
    attribute INIT_25 of inst : label is "0421000001100000000070001000000000003000002131200210001200011100";
    attribute INIT_26 of inst : label is "0111004703447421034007470007210003401043074300430300021003465443";
    attribute INIT_27 of inst : label is "0101004307100017000707000013631010000000000000000300344303443443";
    attribute INIT_28 of inst : label is "01244421044474470744744707222227012444210722322704447421000F0000";
    attribute INIT_29 of inst : label is "0124442104444564044455640744444404447444034000000100000104447444";
    attribute INIT_2A of inst : label is "0465544401122444034444440000000303403443044474470124442104447447";
    attribute INIT_2B of inst : label is "936C936C33CC33CC000000005A5A5A5A000F0000074210070000122204421244";
    attribute INIT_2C of inst : label is "000000005A5A5A5A88888888F00000000000000FFFFF0000FFFFFFFF00000000";
    attribute INIT_2D of inst : label is "FF000000000F000000000000000000000000000000000000C639C6395A5A0000";
    attribute INIT_2E of inst : label is "000000FF00000000EEEEEEEECCCCCCCC000F0000000F0000000F000000000000";
    attribute INIT_2F of inst : label is "0000FFFF0000FFFF000F000000000000FFFF000004654400FFF0000000000FFF";
    attribute INIT_30 of inst : label is "CFCBBCFFFEEE8EEFFCB8BCFFFCBBBCFFFCBBBCFFFA9B9ABBFCBCFCFFFEDBABDE";
    attribute INIT_31 of inst : label is "FCBBBCFFFBBB9AFFFBBBB8FFFEFFFFFEFB9ABBBBCBFFFFFFFEFFFEFFFBBB9ABB";
    attribute INIT_32 of inst : label is "FCBBBBFFFEDBBBFFFCBBBBFFFFEEE8EEF8FCBCFFFBBB9AFFFFCBBCFFBBA99AFF";
    attribute INIT_33 of inst : label is "FED8DEFFFFFFDEFFFCFFFFFCF98ECEEFFCDDDDDCF8DEF8FFCFCBBBFFFBDEDBFF";
    attribute INIT_34 of inst : label is "FFFFFEFFFCBBCBBCFBDEF99FFFCFEDEFFDD8D8DDFFFFFDDDFFFFFFFFFFFFFFFF";
    attribute INIT_35 of inst : label is "FBDEFFFFFEEFFFFFFFFF8FFFEFFFFFFFFFFFCFFFFFDECEDFFDEFFFEDFFFEEEFF";
    attribute INIT_36 of inst : label is "FEEEFFB8FCBB8BDEFCBFF8B8FFF8DEFFFCBFEFBCF8BCFFBCFCFFFDEFFCB9ABBC";
    attribute INIT_37 of inst : label is "FEFEFFBCF8EFFFE8FFF8F8FFFFEC9CEFEFFFFFFFFFFFFFFFFCFFCBBCFCBBCBBC";
    attribute INIT_38 of inst : label is "FEDBBBDEFBBB8BB8F8BB8BB8F8DDDDD8FEDBBBDEF8DDCDD8FBBB8BDEFFF0FFFF";
    attribute INIT_39 of inst : label is "FEDBBBDEFBBBBA9BFBBBAA9BF8BBBBBBFBBB8BBBFCBFFFFFFEFFFFFEFBBB8BBB";
    attribute INIT_3A of inst : label is "FB9AABBBFEEDDBBBFCBBBBBBFFFFFFFCFCBFCBBCFBBB8BB8FEDBBBDEFBBB8BB8";
    attribute INIT_3B of inst : label is "6C936C93CC33CC33FFFFFFFFA5A5A5A5FFF0FFFFF8BDEFF8FFFFEDDDFBBDEDBB";
    attribute INIT_3C of inst : label is "FFFFFFFFA5A5A5A5777777770FFFFFFFFFFFFFF00000FFFF00000000FFFFFFFF";
    attribute INIT_3D of inst : label is "00FFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF39C639C6A5A5FFFF";
    attribute INIT_3E of inst : label is "FFFFFF00FFFFFFFF1111111133333333FFF0FFFFFFF0FFFFFFF0FFFFFFFFFFFF";
    attribute INIT_3F of inst : label is "FFFF0000FFFF0000FFF0FFFFFFFFFFFF0000FFFFFB9ABBFF000FFFFFFFFFF000";
  begin
  inst : RAMB16_S4
      --pragma translate_off
      generic map (
        INIT_00 => romgen_str2bv(inst'INIT_00),
        INIT_01 => romgen_str2bv(inst'INIT_01),
        INIT_02 => romgen_str2bv(inst'INIT_02),
        INIT_03 => romgen_str2bv(inst'INIT_03),
        INIT_04 => romgen_str2bv(inst'INIT_04),
        INIT_05 => romgen_str2bv(inst'INIT_05),
        INIT_06 => romgen_str2bv(inst'INIT_06),
        INIT_07 => romgen_str2bv(inst'INIT_07),
        INIT_08 => romgen_str2bv(inst'INIT_08),
        INIT_09 => romgen_str2bv(inst'INIT_09),
        INIT_0A => romgen_str2bv(inst'INIT_0A),
        INIT_0B => romgen_str2bv(inst'INIT_0B),
        INIT_0C => romgen_str2bv(inst'INIT_0C),
        INIT_0D => romgen_str2bv(inst'INIT_0D),
        INIT_0E => romgen_str2bv(inst'INIT_0E),
        INIT_0F => romgen_str2bv(inst'INIT_0F),
        INIT_10 => romgen_str2bv(inst'INIT_10),
        INIT_11 => romgen_str2bv(inst'INIT_11),
        INIT_12 => romgen_str2bv(inst'INIT_12),
        INIT_13 => romgen_str2bv(inst'INIT_13),
        INIT_14 => romgen_str2bv(inst'INIT_14),
        INIT_15 => romgen_str2bv(inst'INIT_15),
        INIT_16 => romgen_str2bv(inst'INIT_16),
        INIT_17 => romgen_str2bv(inst'INIT_17),
        INIT_18 => romgen_str2bv(inst'INIT_18),
        INIT_19 => romgen_str2bv(inst'INIT_19),
        INIT_1A => romgen_str2bv(inst'INIT_1A),
        INIT_1B => romgen_str2bv(inst'INIT_1B),
        INIT_1C => romgen_str2bv(inst'INIT_1C),
        INIT_1D => romgen_str2bv(inst'INIT_1D),
        INIT_1E => romgen_str2bv(inst'INIT_1E),
        INIT_1F => romgen_str2bv(inst'INIT_1F),
        INIT_20 => romgen_str2bv(inst'INIT_20),
        INIT_21 => romgen_str2bv(inst'INIT_21),
        INIT_22 => romgen_str2bv(inst'INIT_22),
        INIT_23 => romgen_str2bv(inst'INIT_23),
        INIT_24 => romgen_str2bv(inst'INIT_24),
        INIT_25 => romgen_str2bv(inst'INIT_25),
        INIT_26 => romgen_str2bv(inst'INIT_26),
        INIT_27 => romgen_str2bv(inst'INIT_27),
        INIT_28 => romgen_str2bv(inst'INIT_28),
        INIT_29 => romgen_str2bv(inst'INIT_29),
        INIT_2A => romgen_str2bv(inst'INIT_2A),
        INIT_2B => romgen_str2bv(inst'INIT_2B),
        INIT_2C => romgen_str2bv(inst'INIT_2C),
        INIT_2D => romgen_str2bv(inst'INIT_2D),
        INIT_2E => romgen_str2bv(inst'INIT_2E),
        INIT_2F => romgen_str2bv(inst'INIT_2F),
        INIT_30 => romgen_str2bv(inst'INIT_30),
        INIT_31 => romgen_str2bv(inst'INIT_31),
        INIT_32 => romgen_str2bv(inst'INIT_32),
        INIT_33 => romgen_str2bv(inst'INIT_33),
        INIT_34 => romgen_str2bv(inst'INIT_34),
        INIT_35 => romgen_str2bv(inst'INIT_35),
        INIT_36 => romgen_str2bv(inst'INIT_36),
        INIT_37 => romgen_str2bv(inst'INIT_37),
        INIT_38 => romgen_str2bv(inst'INIT_38),
        INIT_39 => romgen_str2bv(inst'INIT_39),
        INIT_3A => romgen_str2bv(inst'INIT_3A),
        INIT_3B => romgen_str2bv(inst'INIT_3B),
        INIT_3C => romgen_str2bv(inst'INIT_3C),
        INIT_3D => romgen_str2bv(inst'INIT_3D),
        INIT_3E => romgen_str2bv(inst'INIT_3E),
        INIT_3F => romgen_str2bv(inst'INIT_3F)
        )
      --pragma translate_on
      port map (
        DO   => DATA(7 downto 4),
        ADDR => rom_addr,
        CLK  => CLK,
        DI   => "0000",
        EN   => ENA,
        SSR  => '0',
        WE   => '0'
        );
  end generate;
end RTL;
