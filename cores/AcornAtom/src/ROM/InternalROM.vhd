library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity InternalROM is
    port (
        CLK  : in  std_logic;
        ADDR : in  std_logic_vector(16 downto 0);
        DATA : out std_logic_vector(7 downto 0)
    );
end;

architecture BEHAVIORAL of InternalROM is

    component e000 is
        port (
            CLK  : in  std_logic;
            ADDR : in  std_logic_vector(11 downto 0);
            DATA : out std_logic_vector(7 downto 0));
    end component;

    component atombasic
        port (
            CLK  : in  std_logic;
            ADDR : in  std_logic_vector(11 downto 0);
            DATA : out std_logic_vector(7 downto 0));
    end component;

    component atomfloat
        port (
            CLK  : in  std_logic;
            ADDR : in  std_logic_vector(11 downto 0);
            DATA : out std_logic_vector(7 downto 0));
    end component;

    component atomkernal
        port (
            CLK  : in  std_logic;
            ADDR : in  std_logic_vector(11 downto 0);
            DATA : out std_logic_vector(7 downto 0));
    end component;

    signal basic_rom_enable  : std_logic;
    signal kernal_rom_enable : std_logic;
    signal float_rom_enable  : std_logic;
    signal sddos_rom_enable  : std_logic;

    signal kernal_data       : std_logic_vector(7 downto 0);
    signal basic_data        : std_logic_vector(7 downto 0);
    signal float_data        : std_logic_vector(7 downto 0);
    signal sddos_data        : std_logic_vector(7 downto 0);

begin

    romc000 : atombasic port map(
        CLK  => CLK,
        ADDR => ADDR(11 downto 0),
        DATA => basic_data);

    romd000 : atomfloat port map(
        CLK  => CLK,
        ADDR => ADDR(11 downto 0),
        DATA => float_data);

    rome000 : e000 port map(
        CLK  => CLK,
        ADDR => ADDR(11 downto 0),
        DATA => sddos_data);

    romf000 : atomkernal port map(
        CLK  => CLK,
        ADDR => ADDR(11 downto 0),
        DATA => kernal_data);

    process(ADDR)
    begin
        -- All regions normally de-selected
        sddos_rom_enable  <= '0';
        basic_rom_enable  <= '0';
        kernal_rom_enable <= '0';
        float_rom_enable  <= '0';

        case ADDR(15 downto 12) is
            when x"C"   => basic_rom_enable  <= '1';
            when x"D"   => float_rom_enable  <= '1';
            when x"E"   => sddos_rom_enable  <= '1';
            when x"F"   => kernal_rom_enable <= '1';
            when others => null;
        end case;

    end process;

    DATA <=
        basic_data      when basic_rom_enable  = '1' else
        float_data      when float_rom_enable  = '1' else
        sddos_data      when sddos_rom_enable  = '1' else
        kernal_data     when kernal_rom_enable = '1' else
        x"f1"; -- un-decoded locations

end BEHAVIORAL;
