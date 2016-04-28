library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rgb2vga_dpram is

    port (
        wrclock  : in  std_logic;
        wren   : in  std_logic;
        wraddress : in  std_logic_vector(9 downto 0);
        data  : in  std_logic_vector(3 downto 0);
        rdclock  : in  std_logic;
        rdaddress : in  std_logic_vector(9 downto 0);
        q : out std_logic_vector(3 downto 0)
        );
end;

architecture behavioral of rgb2vga_dpram is

    type ram_type is array (1023 downto 0) of std_logic_vector (3 downto 0);
    shared variable RAM : ram_type;

begin

    process (wrclock)
    begin
        if rising_edge(wrclock) then
            if (wren = '1') then
                RAM(conv_integer(wraddress)) := data;
            end if;
        end if;
    end process;

    process (rdclock)
    begin
        if rising_edge(rdclock) then
            q <= RAM(conv_integer(rdaddress));
        end if;
    end process;

end behavioral;
