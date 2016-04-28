---------------------------------------------------
-- Alan Daly 2009(c)
-- AtomIC project
-- minimal implementation of an 8255 
-- just enough for the machine to function 
---------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity I82C55 is
    port (
        I_ADDR : in  std_logic_vector(1 downto 0);  -- A1-A0
        I_DATA : in  std_logic_vector(7 downto 0);  -- D7-D0
        O_DATA : out std_logic_vector(7 downto 0);
        CS_H   : in  std_logic;
        WR_L   : in  std_logic;
        O_PA   : out std_logic_vector(7 downto 0);
        I_PB   : in  std_logic_vector(7 downto 0);
        I_PC   : in  std_logic_vector(3 downto 0);
        O_PC   : out std_logic_vector(3 downto 0);
        RESET  : in  std_logic;
        ENA    : in  std_logic;                     -- (CPU) clk enable
        CLK    : in  std_logic);
end;

architecture RTL of I82C55 is
    -- registers
    signal r_porta  : std_logic_vector(7 downto 0);
    signal r_portb  : std_logic_vector(7 downto 0);
    signal l_portc  : std_logic_vector(3 downto 0);
    signal h_portc  : std_logic_vector(3 downto 0);
    signal ctrl_reg : std_logic_vector(7 downto 0);

begin
    p_write_reg_reset : process(RESET, CLK)
    begin
        if (RESET = '0') then
            r_porta  <= x"00";
            r_portb  <= x"00";
            l_portc  <= x"0";
            h_portc  <= x"0";
            ctrl_reg <= x"00";
        elsif rising_edge(CLK) then

            O_PA    <= r_porta;
            r_portb <= I_PB;
            h_portc <= I_PC;
            O_PC    <= l_portc;

            if (CS_H = '1') then
                if (WR_L = '0') then
                    case I_ADDR is
                        when "00" => r_porta <= I_DATA;
                                                                --when "01" => r_portb   <= I_DATA;
                        when "10" => l_portc <= I_DATA (3 downto 0);
                        when "11" => if (I_DATA(7) = '0') then  -- set/clr
                                         l_portc(2) <= I_DATA(0);
                                     else
                                         ctrl_reg <= I_DATA;
                                     end if;
                        when others => null;
                    end case;
                else                                            -- read ports
                    case I_ADDR is
                        when "00"   => O_DATA <= r_porta;
                        when "01"   => O_DATA <= r_portb;
                        when "10"   => O_DATA <= h_portc & l_portc;
                        when "11"   => O_DATA <= ctrl_reg;
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
end architecture RTL;
