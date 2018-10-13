
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_8dos is  
  port (
    CLK_24        : in std_logic;
    PHI_2         : in std_logic;
    RW            : in std_logic;
    IO_SELECTn    : in std_logic; -- 0x300 - 0x3ff
    IO_CONTROLn   : out std_logic;
    RESETn        : in std_logic;
    O_ROMDISn     : out std_logic;
    O_MAPn        : out std_logic;
    A             : in std_logic_vector(15 downto 0);
    D_IN          : in std_logic_vector(7 downto 0);  -- From 6502
    D_OUT         : out std_logic_vector(7 downto 0)  -- To 6502
    );
end controller_8dos;

architecture imp of controller_8dos is
  signal s_map :std_logic;
  signal s_romdis: std_logic;
  signal s_extension: std_logic;
  signal rom_out: std_logic_vector(7 downto 0);
  signal IO_CONTROLn_int : std_logic;
  signal CUR_PHI_2:std_logic;
  signal OLD_PHI_2:std_logic;
  signal rising_PHI_2:std_logic;
  signal falling_PHI_2:std_logic;
begin

  -- PHI_2 edges
  phi_2_edges: process(CLK_24)
  begin
    if (rising_edge(CLK_24))then
      OLD_PHI_2 <= CUR_PHI_2;
      CUR_PHI_2 <= PHI_2;
    end if;
  end process;
  rising_PHI_2 <= CUR_PHI_2 and not OLD_PHI_2;
  falling_PHI_2<= not CUR_PHI_2 and CUR_PHI_2;  
     
  
  --IO_CONTROL_SIGNAL
  IO_CONTROLn_int <= '0'
                 when (A(15 downto 8) = x"03")
                 and (A(7 downto 4) /= x"0")
                 and (IO_SELECTn = '0')
                     else '1';
  IO_CONTROLn <= IO_CONTROLn_int;
  s_romdis <=  '1';
  O_ROMDISn <= s_romdis;
  
  mappr: process (CLK_24,RESETn)
  begin
    if (RESETn = '0') then
      s_map <= '1';
    else
      if (rising_edge(CLK_24)) then
        if (rising_PHI_2 = '1') and
          (IO_CONTROLn_int = '0') and
          (RW = '0') and
          (A(7 downto 4) = x"8") then
            s_map  <= not A(0);
        end if;
      end if;
    end if;
  end process;
  O_MAPn <= '0' when  s_map = '0'  and A(15 downto 14)="11" else '1';       
  
  extension:process (CLK_24, RESETn)
  begin
    if (RESETn = '0') then
      s_extension <= '0';
    else
      if (rising_edge(CLK_24)) then
        if (rising_PHI_2 = '1') and
          (IO_CONTROLn_int = '0') and
          (RW = '0') and
          (A(7 downto 4) = x"8") then
            s_extension  <= A(1);
        end if;
      end if;
    end if;
  end process;

  -- 8dos rom

  rom8dos: entity work.dos8rom
    port map (
      addr(8) => s_extension,
      addr(7 downto 0) => A(7 downto 0),
      clk=>CLK_24,
      dout => rom_out
      );

  D_OUT <= rom_out;

  -- disk : entity work.disk_ii port map (
  --   CLK_14M        => CLK_14M,
  --   CLK_2M         => CLK_2M,
  --   PRE_PHASE_ZERO => PRE_PHASE_ZERO,
  --   IO_SELECT      => IO_SELECT(6),
  --   DEVICE_SELECT  => DEVICE_SELECT(6),
  --   RESET          => reset,
  --   A              => ADDR,
  --   D_IN           => D,
  --   D_OUT          => PD,
  --   TRACK          => TRACK,
  --   TRACK_ADDR     => TRACK_ADDR,
  --   D1_ACTIVE      => D1_ACTIVE,
  --   D2_ACTIVE      => D2_ACTIVE,
  --   ram_write_addr => TRACK_RAM_ADDR,
  --   ram_di         => TRACK_RAM_DI,
  --   ram_we         => TRACK_RAM_WE
  --   );

  -- sdcard_interface : entity work.spi_controller port map (
  --   CLK_14M        => CLK_14M,
  --   RESET          => RESET,

  --   CS_N           => CS_N,
  --   MOSI           => MOSI,
  --   MISO           => MISO,
  --   SCLK           => SCLK,
    
  --   track          => TRACK,
  --   image          => image,
    
  --   ram_write_addr => TRACK_RAM_ADDR,
  --   ram_di         => TRACK_RAM_DI,
  --   ram_we         => TRACK_RAM_WE
  --   );

  -- SD_DAT3 <= CS_N;
  -- SD_CMD  <= MOSI;
  -- MISO    <= SD_DAT;
  -- SD_CLK  <= SCLK;

end imp;
