library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RAM_32K_DualPort is

    port (
        clka  : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(14 downto 0);
        dina  : in  std_logic_vector(7 downto 0);
        douta : out std_logic_vector(7 downto 0);
        clkb  : in  std_logic;
        web   : in  std_logic;
        addrb : in  std_logic_vector(14 downto 0);
        dinb  : in  std_logic_vector(7 downto 0);
        doutb : out std_logic_vector(7 downto 0)
        );
end;

architecture behavioral of RAM_32K_DualPort is

    type ram_type is array (32767 downto 0) of std_logic_vector (7 downto 0);
    shared variable RAM : ram_type;

begin

    process (clka)
    begin
        if rising_edge(clka) then
            if (wea = '1') then
                RAM(conv_integer(addra)) := dina;
            end if;
            douta <= RAM(conv_integer(addra));
        end if;
    end process;

    process (clkb)
    begin
        if rising_edge(clkb) then
            if (web = '1') then
                RAM(conv_integer(addrb)) := dinb;
            end if;
            doutb <= RAM(conv_integer(addrb));
        end if;
    end process;

end behavioral;
