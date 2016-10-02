library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is port(
    clk50 : in  std_logic;
    sync  : out std_logic;
    pal   : out std_logic;
    r     : out std_logic_vector (2 downto 0);
    g     : out std_logic_vector (2 downto 0);
    b     : out std_logic_vector (2 downto 0));
end main;

architecture behavioral of main is

  signal  clk7    : std_logic;
  signal  hcount  : unsigned  (8 downto 0);
  signal  vcount  : unsigned  (8 downto 0);
  signal  color   : std_logic_vector (3 downto 0);

begin
  clock7_inst: entity work.clock7 port map (
    clkin_in  => clk50,
    clkfx_out => clk7);

  colenc_inst: entity work.colenc port map (
    clk_in => clk7,
    col_in => color,
    r_out  => r,
    g_out  => g,
    b_out  => b);

  process (clk7)
  begin
    sync <= '0';
    color <= "0000";
    if rising_edge( clk7 ) then
      if hcount=447 then
        hcount <= (others => '0');
        if vcount=311 then
          vcount <= (others => '0');
        else
          vcount <= vcount + 1;
        end if;
      else
        hcount <= hcount + 1;
      end if;
      if  ( vcount<248   or vcount>=252  ) and
          ( hcount<344-8 or hcount>=376-8) then
        sync <= '1';
        if hcount<256 and vcount<192 then
          color <= std_logic_vector(hcount(7 downto 4));
        elsif hcount<320-8 or hcount>=416-8 then
          color <= "0111";
        end if;
      end if;
    end if;
  end process;

  pal <= '1';

end behavioral;
