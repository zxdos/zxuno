-------------------------------------------------------------------------------
--
-- Disk II emulator
--
-- This is read-only and only feeds "pre-nibblized" data to the processor
-- It has a single-track buffer and only supports one drive (1).
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
--
-------------------------------------------------------------------------------
--
-- Each track is represented as 0x1A00 bytes
-- Each disk image consists of 35 * 0x1A00 bytes = 0x38A00 (227.5 K)
--
-- X = $60 for slot 6
--
--  Off          On
-- C080,X      C081,X		Phase 0  Head Stepper Motor Control
-- C082,X      C083,X		Phase 1
-- C084,X      C085,X		Phase 2
-- C086,X      C087,X		Phase 3
-- C088,X      C089,X           Motor On
-- C08A,X      C08B,X           Select Drive 2 (select drive 1 when off)
-- C08C,X      C08D,X           Q6  (Shift/load?)
-- C08E,X      C08F,X           Q7  (Write request to drive)
--
--
-- Q7 Q6
-- 0  0  Read
-- 0  1  Sense write protect
-- 1  0  Write
-- 1  1  Load Write Latch
--
-- Reading a byte:
--        LDA $C08E,X  set read mode
-- ...
-- READ   LDA $C08C,X
--        BPL READ
--
-- Sense write protect:
--   LDA $C08D,X
--   LDA $C08E,X
--   BMI PROTECTED
--
-- Writing
--   STA $C08F,X   set write mode
--   ..
--   LDA DATA
--   STA $C08D,X   load byte to write
--   STA $C08C,X   write byte to disk
--
-- Data bytes must be written in 32 cycle loops.
--
-- There are 70 phases for the head stepper and and 35 tracks,
-- i.e., two phase changes per track.
--
-- The disk spins at 300 rpm; one new bit arrives every 4 us
-- The processor's clock is 1 MHz = 1 us, so it takes 8 * 4 = 32 cycles
-- for a new byte to arrive
--
-- This corresponds to dividing the 2 MHz signal by 64 to get the byte clock
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity disk_ii is  
  port (
    CLK_14M        : in std_logic;
    CLK_2M         : in std_logic;   
    PRE_PHASE_ZERO : in std_logic;
    IO_SELECT      : in std_logic;      -- e.g., C600 - C6FF ROM
    DEVICE_SELECT  : in std_logic;      -- e.g., C0E0 - C0EF I/O locations
    RESET          : in std_logic;
    A              : in unsigned(15 downto 0);
    D_IN           : in unsigned(7 downto 0);  -- From 6502
    D_OUT          : out unsigned(7 downto 0);  -- To 6502
    TRACK          : out unsigned(5 downto 0);  -- Current track (0-34)
    track_addr     : out unsigned(13 downto 0);
    D1_ACTIVE      : out std_logic;     -- Disk 1 motor on
    D2_ACTIVE      : out std_logic;     -- Disk 2 motor on
    ram_write_addr : in unsigned(13 downto 0);  -- Address for track RAM
    ram_di         : in unsigned(7 downto 0);  -- Data to track RAM
    ram_we         : in std_logic              -- RAM write enable
    );
end disk_ii;

architecture rtl of disk_ii is

  signal motor_phase : std_logic_vector(3 downto 0);
  signal drive_on : std_logic;
  signal drive2_select : std_logic;
  signal q6, q7 : std_logic;

  signal rom_dout : unsigned(7 downto 0);

  -- Current phase of the head.  This is in half-steps to assign
  -- a unique position to the case, say, when both phase 0 and phase 1 are
  -- on simultaneously.  phase(7 downto 2) is the track number
  signal phase : unsigned(7 downto 0);  -- 0 - 139

  -- Storage for one track worth of data in "nibblized" form
  type track_ram is array(0 to 6655) of unsigned(7 downto 0);
  -- Double-ported RAM for holding a track
  signal track_memory : track_ram;
  signal ram_do : unsigned(7 downto 0);

  -- Lower bit indicates whether disk data is "valid" or not
  -- RAM address is track_byte_addr(14 downto 1)
  -- This makes it look to the software like new data is constantly
  -- being read into the shift register, which indicates the data is
  -- not yet ready.
  signal track_byte_addr : unsigned(14 downto 0);
  signal read_disk : std_logic;         -- When C08C accessed

begin

  interpret_io : process (CLK_2M)
  begin
    if rising_edge(CLK_2M) then
      if reset = '1' then
        motor_phase <= (others => '0');
        drive_on <= '0';
        drive2_select <= '0';
        q6 <= '0';
        q7 <= '0';
      else
        if PRE_PHASE_ZERO = '1' and DEVICE_SELECT = '1' then
          if A(3) = '0' then                      -- C080 - C087
            motor_phase(TO_INTEGER(A(2 downto 1))) <= A(0);
          else
            case A(2 downto 1) is
              when "00" => drive_on <= A(0);      -- C088 - C089
              when "01" => drive2_select <= A(0); -- C08A - C08B
              when "10" => q6 <= A(0);            -- C08C - C08D
              when "11" => q7 <= A(0);            -- C08E - C08F
              when others => null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  D1_ACTIVE <= drive_on and not drive2_select;
  D2_ACTIVE <= drive_on and drive2_select;

  -- There are two cases:
  --
  --  Current phase is odd (between two poles)
  --        |
  --        V
  -- -3-2-1 0 1 2 3 
  --  X   X   X   X
  --  0   1   2   3
  --
  --
  --  Current phase is even (under a pole)
  --          |
  --          V
  -- -4-3-2-1 0 1 2 3 4
  --  X   X   X   X   X
  --  0   1   2   3   0
  --
  
  update_phase : process (CLK_14M)
    variable phase_change : integer;
    variable new_phase : integer;
    variable rel_phase : std_logic_vector(3 downto 0);
  begin
    if rising_edge(CLK_14M) then
      if reset = '1' then
        phase <= TO_UNSIGNED(70, 8);    -- Deliberately odd to test reset
      else        
        phase_change := 0;
        new_phase := TO_INTEGER(phase);
        rel_phase := motor_phase;
        case phase(2 downto 1) is
          when "00" =>
            rel_phase := rel_phase(1 downto 0) & rel_phase(3 downto 2);
          when "01" =>
            rel_phase := rel_phase(2 downto 0) & rel_phase(3);
          when "10" => null;
          when "11" =>
            rel_phase := rel_phase(0) & rel_phase(3 downto 1);
          when others => null;
        end case;
        
        if phase(0) = '1' then            -- Phase is odd
          case rel_phase is
            when "0000" => phase_change := 0;
            when "0001" => phase_change := -3;
            when "0010" => phase_change := -1;
            when "0011" => phase_change := -2;
            when "0100" => phase_change := 1;
            when "0101" => phase_change := -1;
            when "0110" => phase_change := 0;
            when "0111" => phase_change := -1;
            when "1000" => phase_change := 3;
            when "1001" => phase_change := 0;
            when "1010" => phase_change := 1;
            when "1011" => phase_change := -3;
            when "1111" => phase_change := 0;
            when others => null;
          end case;
        else                              -- Phase is even
          case rel_phase is
            when "0000" => phase_change := 0;
            when "0001" => phase_change := -2;
            when "0010" => phase_change := 0;
            when "0011" => phase_change := -1;
            when "0100" => phase_change := 2;
            when "0101" => phase_change := 0;
            when "0110" => phase_change := 1;
            when "0111" => phase_change := 0;
            when "1000" => phase_change := 0;
            when "1001" => phase_change := 1;
            when "1010" => phase_change := 2;
            when "1011" => phase_change := -2;
            when "1111" => phase_change := 0;
            when others => null;
          end case;
        end if;

        if new_phase + phase_change <= 0 then
          new_phase := 0;
        elsif new_phase + phase_change > 139 then
          new_phase := 139;
        else
          new_phase := new_phase + phase_change;
        end if;
        phase <= TO_UNSIGNED(new_phase, 8);
      end if;      
    end if;
  end process;

  TRACK <= phase(7 downto 2);

  -- Dual-ported RAM holding the contents of the track
  track_storage : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if ram_we = '1' then
        track_memory(to_integer(ram_write_addr)) <= ram_di;
      end if;
      ram_do <= track_memory(to_integer(track_byte_addr(14 downto 1)));
    end if;
  end process;

  -- Go to the next byte when the disk is accessed or if the counter times out
  read_head : process (CLK_2M)
  variable byte_delay : unsigned(5 downto 0);  -- Accounts for disk spin rate
  begin
    if rising_edge(CLK_2M) then
      if reset = '1' then
        track_byte_addr <= (others => '0');
        byte_delay := (others => '0');
      else
        byte_delay := byte_delay - 1;
        if (read_disk = '1' and PRE_PHASE_ZERO = '1') or byte_delay = 0 then
          byte_delay := (others => '0');
          if track_byte_addr = X"33FE" then
            track_byte_addr <= (others => '0');
          else
            track_byte_addr <= track_byte_addr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  rom : entity work.disk_ii_rom port map (
    addr => A(7 downto 0),
    clk  => CLK_14M,
    dout => rom_dout);

  read_disk <= '1' when DEVICE_SELECT = '1' and A(3 downto 0) = x"C" else
               '0';  -- C08C

  D_OUT <= rom_dout when IO_SELECT = '1' else
           ram_do when read_disk = '1' and track_byte_addr(0) = '0' else
           (others => '0');

  track_addr <= track_byte_addr(14 downto 1);
  
end rtl;
