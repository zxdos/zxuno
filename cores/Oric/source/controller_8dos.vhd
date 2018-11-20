
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
    D_OUT         : out std_logic_vector(7 downto 0);  -- To 6502

    -- indication
    disk_a_on     : out std_logic;
    disk_cur_TRACK: out std_logic_vector(5 downto 0);  -- Current track (0-34)
    disk_track_addr: out std_logic_vector(13 downto 0);
    IMAGE_NUMBER_out  : out std_logic_vector(9 downto 0);
    track_ok  : out std_logic; -- 0 when disk is active else 1

    IMAGE_UP :in std_logic;
    IMAGE_DOWN :in std_logic;

    -- sd card
    SD_DAT        : in std_logic;
    SD_DAT3       : out std_logic;
    SD_CMD        : out std_logic;
    SD_CLK        : out std_logic
    
    );
end controller_8dos;

architecture imp of controller_8dos is
  signal s_map :std_logic;
  signal s_romdis: std_logic;
  signal s_extension: std_logic;
  signal rom_out: std_logic_vector(7 downto 0);
  signal IO_CONTROLn_int : std_logic;
  signal disk_select : std_logic;
  signal CUR_PHI_2:std_logic;
  signal OLD_PHI_2:std_logic;
  signal rising_PHI_2:std_logic;
--  signal falling_PHI_2:std_logic;
  signal disk_D_OUT  : std_logic_vector(7 downto 0);

  -- connection between spi_controller & disk_ii
  signal IMAGE_NUMBER : unsigned(9 downto 0) := "0000000001";
  signal TRACK : unsigned(5 downto 0);
  signal TRACK_ADDR : unsigned(13 downto 0);
  signal TRACK_RAM_ADDR : unsigned(13 downto 0);
  signal TRACK_RAM_DI : unsigned(7 downto 0);
  signal TRACK_RAM_WE : std_logic;
  signal TRACK_GOOD: std_logic;
  --
  signal D1_ACTIVE, D2_ACTIVE : std_logic;

  signal IMAGE_UP_old : std_logic;
  signal IMAGE_DOWN_old :  std_logic;
  signal IMAGE_UP_cur : std_logic;
  signal IMAGE_DOWN_cur : std_logic;
  
begin
  IMAGE_NUMBER_OUT <= std_logic_vector(IMAGE_NUMBER);

  imgnum:process  (CLK_24, RESETn)
    constant maxcount:integer := 1000000000;
  begin
    if (rising_edge(CLK_24)) then
      IMAGE_UP_old <= IMAGE_UP_cur;
      IMAGE_UP_cur <= IMAGE_UP;
      IMAGE_DOWN_old <= IMAGE_DOWN_cur;
      IMAGE_DOWN_cur <= IMAGE_DOWN;
      if (IMAGE_UP_cur = '0' and IMAGE_UP_old = '1') then
        IMAGE_NUMBER <= IMAGE_NUMBER + 1;
      end if;
      if (IMAGE_DOWN_cur = '0' and IMAGE_DOWN_old = '1') and IMAGE_NUMBER >0 then
        IMAGE_NUMBER <= IMAGE_NUMBER - 1;
      end if;
    end if;
  end process;
  
  
  -- PHI_2 edges
  phi_2_edges: process(CLK_24)
  begin
    if (rising_edge(CLK_24))then
      OLD_PHI_2 <= CUR_PHI_2;
      CUR_PHI_2 <= PHI_2;
    end if;
  end process;
  rising_PHI_2 <= CUR_PHI_2 and not OLD_PHI_2;
--  falling_PHI_2<= not CUR_PHI_2 and CUR_PHI_2;  
     
  
  --IO_CONTROL_SIGNAL
  IO_CONTROLn_int <= '0' when (A(15 downto 8) = x"03")
                 and (A(7 downto 4) /= x"0")
                 and (IO_SELECTn = '0')
                     else '1';
  --disk_select signal
  disk_select <= '1'  when (A(15 downto 8) = x"03")
                 and (A(7 downto 4) = x"1")
                 and (IO_SELECTn = '0')
                 else '0';
  
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

-- multiplex output                          
  D_OUT <= rom_out when disk_select = '0' else disk_D_OUT;


-- indication                          
  disk_a_on <= not D1_ACTIVE;

  track_ok <= not TRACK_GOOD;
  
  disk : entity work.disk_ii port map (
    CLK        => CLK_24,
    PHI_2         => PHI_2,
    DEVICE_SELECT  => disk_select,      
    RESETn          => RESETn,
    A              => A(3 downto 0),
    D_IN           => D_IN,
    D_OUT          => disk_D_OUT,
    -- sd card
    D1_ACTIVE      => D1_ACTIVE, -- drive 1 on
    D2_ACTIVE      => D2_ACTIVE, -- drive 2 on

    -- to spi_controler
    TRACK          => TRACK, -- current track to read
    TRACK_ADDR     => TRACK_ADDR, -- current track_address
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE,
    TRACK_GOOD     => TRACK_GOOD
    );

  disk_cur_TRACK <= std_logic_vector(TRACK);
  disk_track_addr <= std_logic_vector(TRACK_ADDR);
  sdcard_interface : entity work.spi_controller port map (
    CLK_14M        => CLK_24,
    RESETn          => RESETn,

    CS_N           => SD_DAT3,
    MOSI           => SD_CMD,
    MISO           => SD_DAT,
    SCLK           => SD_CLK,
    
    track          => TRACK,
    image          => IMAGE_NUMBER,
    TRACK_GOOD     => TRACK_GOOD,

    -- from diskii
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE
    );

end imp;
