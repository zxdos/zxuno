-------------------------------------------------------------------------------
--
-- Top level of an Apple ][+
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apple2 is
  port (
    CLK_14M        : in  std_logic;              -- 14.31818 MHz master clock
    CLK_2M         : out std_logic;
    PRE_PHASE_ZERO : out std_logic;
    FLASH_CLK      : in  std_logic;        -- approx. 2 Hz flashing char clock
    reset          : in  std_logic;
    ADDR           : out unsigned(15 downto 0);  -- CPU address
    ram_addr       : out unsigned(17 downto 0);  -- RAM address
    D              : out unsigned(7 downto 0);   -- Data to RAM
    ram_do         : in unsigned(7 downto 0);    -- Data from RAM
    PD             : in unsigned(7 downto 0);    -- Data to CPU from peripherals
    ram_we         : out std_logic;              -- RAM write enable
    VIDEO          : out std_logic;
    COLOR_LINE     : out std_logic;
    HBL            : out std_logic;
    VBL            : out std_logic;
    LD194          : out std_logic;
    K              : in unsigned(7 downto 0);    -- Keyboard data
    READ_KEY       : out std_logic;              -- Processor has read key
    AN             : out std_logic_vector(3 downto 0);  -- Annunciator outputs
    -- GAMEPORT input bits:
    --  7    6    5    4    3   2   1    0
    -- pdl3 pdl2 pdl1 pdl0 pb3 pb2 pb1 casette
    GAMEPORT       : in std_logic_vector(7 downto 0);
    PDL_STROBE     : out std_logic;         -- Pulses high when C07x read
    STB            : out std_logic;         -- Pulses high when C04x read
    IO_SELECT      : out std_logic_vector(7 downto 0);
    DEVICE_SELECT  : out std_logic_vector(7 downto 0);
    pcDebugOut     : out unsigned(15 downto 0);
    opcodeDebugOut : out unsigned(7 downto 0);
    speaker        : out std_logic              -- One-bit speaker output
    );
end apple2;

architecture rtl of apple2 is

  component ramcard is
    port ( mclk28: in std_logic;
           reset_in: in std_logic;
           addr: in std_logic_vector(15 downto 0);
           ram_addr: out std_logic_vector(17 downto 0);          
           we: in std_logic;  
           card_ram_we: out std_logic;
           card_ram_rd: out std_logic;
           bank1: out std_logic
    );
  end component;

  -- Clocks
  signal CLK_7M : std_logic;
  signal Q3, RAS_N, CAS_N, AX : std_logic;
  signal PHASE_ZERO, PRE_PHASE_ZERO_sig : std_logic;
  signal COLOR_REF : std_logic;

  -- From the timing generator
  signal VIDEO_ADDRESS : unsigned(15 downto 0);
  signal LDPS_N : std_logic;
  signal H0, VA, VB, VC, V2, V4 : std_logic;
  signal BLANK, LD194_I : std_logic;

  signal HIRES : std_logic;             -- from video generator B11 p6
  
  -- Soft switches
  signal soft_switches : std_logic_vector(7 downto 0) := "00000000";
  signal TEXT_MODE : std_logic;
  signal MIXED_MODE : std_logic;
  signal PAGE2 : std_logic;
  signal HIRES_MODE : std_logic;

  -- CPU signals
  signal D_IN : unsigned(7 downto 0);
  signal D_OUT: unsigned(7 downto 0); --q
  signal A : unsigned(15 downto 0);
  signal we : std_logic;

  -- Main ROM signals
  signal rom_out : unsigned(7 downto 0);
  signal rom_addr : unsigned(13 downto 0);

  -- Address decoder signals
  signal RAM_SELECT : std_logic := '1';
  signal KEYBOARD_SELECT : std_logic := '0';
  signal SPEAKER_SELECT : std_logic;
  signal SOFTSWITCH_SELECT : std_logic;
  signal ROM_SELECT : std_logic;
  signal GAMEPORT_SELECT : std_logic;
  signal IO_STROBE : std_logic;

  -- Speaker signal
  signal speaker_sig : std_logic := '0';        

  signal DL : unsigned(7 downto 0);     -- Latched RAM data
  
  -- Put 0 in 0x3F4 when reset to jump to the disk boot code (address part).
  signal ADDz : unsigned(17 downto 0) := "000000001111110100";
  
-- ramcard
  signal card_addr : unsigned(17 downto 0);
  signal card_ram_rd : std_logic;
  signal card_ram_we : std_logic;
  signal ram_card_read : std_logic;
  signal ram_card_write : std_logic;  

begin

  CLK_2M <= Q3;
  PRE_PHASE_ZERO <= PRE_PHASE_ZERO_sig;

    ram_addr <= ADDz when reset = '1' else card_addr when PHASE_ZERO = '1' else "00" & VIDEO_ADDRESS; --q
	 ram_we <= ((we and RAM_SELECT) or (we and ram_card_write)) and not RAS_N when PHASE_ZERO = '1' else '0';

  -- Latch RAM data on the rising edge of RAS
  RAM_data_latch : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if AX = '1' and CAS_N = '0' and RAS_N = '0' then
        DL <= ram_do;
      end if;
    end if;
  end process;

  ADDR <= A; 
  D <= D_OUT; 
  
  -- Address decoding
  rom_addr <= (A(13) and A(12)) & (not A(12)) & A(11 downto 0);

  address_decoder: process (A)
  begin
    ROM_SELECT <= '0';
    RAM_SELECT <= '0';
    KEYBOARD_SELECT <= '0';
    READ_KEY <= '0';
    SPEAKER_SELECT <= '0';
    SOFTSWITCH_SELECT <= '0';
    GAMEPORT_SELECT <= '0';
    PDL_STROBE <= '0';
    STB <= '0';
    IO_SELECT <= (others => '0');
    DEVICE_SELECT <= (others => '0');
    IO_STROBE <= '0';
    case A(15 downto 14) is
      when "00" | "01" | "10" =>         -- 0000 - BFFF
        RAM_SELECT <= '1';
      when "11" => -- C000 - FFFF
        case A(13 downto 12) is
          when "00" =>                  -- C000 - CFFF
            case A(11 downto 8) is
              when x"0" =>              -- C000 - C0FF
                case A(7 downto 4) is
                  when x"0" =>          -- C000 - C00F
                    KEYBOARD_SELECT <= '1';
                  when x"1" =>          -- C010 - C01F
                    READ_KEY <= '1';
                  when x"3" =>          -- C030 - C03F
                    SPEAKER_SELECT <= '1';
                  when x"4" =>
                    STB <= '1';
                  when x"5" =>          -- C050 - C05F
                    SOFTSWITCH_SELECT <= '1';
                  when x"6" =>          -- C060 - C06F
                    GAMEPORT_SELECT <= '1';
                  when x"7" =>          -- C070 - C07F
                    PDL_STROBE <= '1';
                  when x"8" | x"9" | x"A" |  -- C080 - C0FF
                       x"B" | x"C" | x"D" | x"E" | x"F" =>
                    DEVICE_SELECT(TO_INTEGER(A(6 downto 4))) <= '1';
                  when others => null;                
                end case;
              when x"1" | x"2" | x"3" |  -- C100 - C7FF
                   x"4" | x"5" | x"6" | x"7" =>
                IO_SELECT(TO_INTEGER(A(10 downto 8))) <= '1';
              when x"8" | x"9" | x"A" |  -- C800 - CFFF
                   x"B" | x"C" | x"D" | x"E" | x"F" =>
                IO_STROBE <= '1';
              when others => null;
            end case;
          when "01" | "10" | "11" =>    -- D000 - FFFF
            ROM_SELECT <= '1';
          when others =>
            null;
        end case;
      when others => null;
    end case;        
  end process address_decoder;

  speaker_ctrl: process (Q3)
  begin
    if rising_edge(Q3) then
      if PRE_PHASE_ZERO_sig = '1' and SPEAKER_SELECT = '1' then
        speaker_sig <= not speaker_sig;
      end if;
    end if;
  end process speaker_ctrl;

  softswitches: process (Q3)
  begin
    if rising_edge(Q3) then
      if PRE_PHASE_ZERO_sig = '1' and SOFTSWITCH_SELECT = '1' then
        soft_switches(TO_INTEGER(A(3 downto 1))) <= A(0);
      end if;
    end if;
  end process softswitches;

  TEXT_MODE <= soft_switches(0);
  MIXED_MODE <= soft_switches(1);
  PAGE2 <= soft_switches(2);
  HIRES_MODE <= soft_switches(3);
  AN <= soft_switches(7 downto 4);

  speaker <= speaker_sig;
  
  D_IN <= DL when RAM_SELECT = '1' or ram_card_read = '1' else -- RAM
          K when KEYBOARD_SELECT = '1' else  -- Keyboard
          GAMEPORT(TO_INTEGER(A(2 downto 0))) & "0000000"  -- Gameport
             when GAMEPORT_SELECT = '1' else
          rom_out when ROM_SELECT = '1' else  -- ROMs
          PD;                           -- Peripherals

  LD194 <= LD194_I;

  timing : entity work.timing_generator port map (
    CLK_14M        => CLK_14M,
    CLK_7M         => CLK_7M,
    CAS_N          => CAS_N,
    RAS_N          => RAS_N,
    Q3	           => Q3,
    AX             => AX,
    PHI0           => PHASE_ZERO,
    PRE_PHI0       => PRE_PHASE_ZERO_sig,
    COLOR_REF      => COLOR_REF,
    TEXT_MODE      => TEXT_MODE,
    PAGE2          => PAGE2,
    HIRES          => HIRES,
    VIDEO_ADDRESS  => VIDEO_ADDRESS,
    H0             => H0,
    VA             => VA,
    VB             => VB,
    VC             => VC,
    V2             => V2,
    V4             => V4,
    VBL            => VBL,
    HBL            => HBL,
    BLANK          => BLANK,
    LDPS_N         => LDPS_N,
    LD194          => LD194_I);

  video_display : entity work.video_generator port map (
    CLK_14M    => CLK_14M,
    CLK_7M     => CLK_7M,
    AX         => AX,
    CAS_N      => CAS_N,
    TEXT_MODE  => TEXT_MODE,
    PAGE2      => PAGE2,
    HIRES_MODE => HIRES_MODE,
    MIXED_MODE => MIXED_MODE,
    H0         => H0,
    VA         => VA,
    VB         => VB,
    VC         => VC,
    V2         => V2,
    V4         => V4,
    BLANK      => BLANK,
    DL         => DL,
    LDPS_N     => LDPS_N,
    LD194      => LD194_I,
    FLASH_CLK  => FLASH_CLK,
    HIRES      => HIRES,
    VIDEO      => VIDEO,
    COLOR_LINE => COLOR_LINE);

  cpu : entity work.cpu65xx
    generic map (
      pipelineOpcode => false,
      pipelineAluMux => false,
      pipelineAluOut => false)
    port map (
      clk            => Q3,
      enable         => not PRE_PHASE_ZERO_sig,
      reset          => reset,
      nmi_n          => '1',
      irq_n          => '1',
      di             => D_IN,
      do             => D_OUT,
      addr           => A,
      we             => we,
      debugPc     => pcDebugOut,
      debugOpcode => opcodeDebugOut
    );

  -- Original Apple had asynchronous ROMs.  We use a synchronous ROM
  -- that needs its address earlier, hence the odd clock.
  roms : entity work.main_roms port map (
    addr => rom_addr,
    clk  => CLK_14M,
    dout => rom_out);

  -- ramcard  16k + 128k
  ram_card_D: component ramcard
    port map
    (
      mclk28 => CLK_14M,
      reset_in => reset,
      addr => std_logic_vector(A),
      unsigned(ram_addr) => card_addr,
      we => we,
      card_ram_we => card_ram_we,
      card_ram_rd => card_ram_rd,
      bank1 => open
    );
    
    ram_card_read  <= ROM_SELECT and card_ram_rd;
    ram_card_write <= ROM_SELECT and card_ram_we;

end rtl;
