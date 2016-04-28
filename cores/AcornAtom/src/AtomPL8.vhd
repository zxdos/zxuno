library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity AtomPL8 is
  port (

    -- Atom side
    clk : in std_logic;
    enable : in std_logic;
    nRST  : in std_logic;                          -- Reset from 6502
    RW : in std_logic;                             -- R/W
    Addr : in std_logic_vector(2 downto 0);        -- CPU Address bus
    DataIn : in std_logic_vector(7 downto 0);      -- CPU Data bus (in)
    DataOut : out std_logic_vector(7 downto 0);    -- CPU Data bus (out)

    -- AVR side

    AVRDataIn : in std_logic_vector(7 downto 0);  -- AVR 'Data bus' PC0..7 on AVR
    AVRDataOut : out std_logic_vector(7 downto 0);  -- AVR 'Data bus' PC0..7 on AVR
    nARD : in std_logic;                           -- Read strobe from AVR PB0 on AVR
    nAWR : in std_logic;                           -- Write strobe from AVR PB1 on AVR
    AVRA0 : in std_logic;                          -- Address line from AVR
    AVRINTOut : out std_logic;                         -- Inturrupt to AVR PB2 on AVR
    
    -- Test
    
    AtomIORDOut : out std_logic;
    AtomIOWROut : out std_logic

    );
end AtomPL8;

architecture Behavioral of AtomPL8 is

    -- Combinatorial signals
    signal RDS         : std_logic;
    signal WDS         : std_logic;
    signal AtomRD      : std_logic;
    signal AtomWR      : std_logic;
    signal AtomIO      : std_logic;
    signal AtomIORD    : std_logic;
    signal AtomIOWR    : std_logic;
    signal AVRStatus   : std_logic;
    signal AVRStatusRD : std_logic;
    signal AtomCMDWR   : std_logic;
    signal nAVRRDData  : std_logic;
    signal AtomDataOut : std_logic_vector(7 downto 0);
    signal Test1   : std_logic;
    signal Test2   : std_logic;

    -- Atom to AVR and AVR to Atom registers
    signal AtomToAVR   : std_logic_vector(7 downto 0);
    signal AVRToAtom   : std_logic_vector(7 downto 0);
    signal AddrLatch   : std_logic_vector(2 downto 0);
    signal AtomRW      : std_logic;
    signal AVRINT      : std_logic;

    -- Handshake bits
    signal AtomW_AVRR : std_logic; -- Set by Atom write, cleared by AVR read.
    signal AVRW_AtomR : std_logic; -- Set by AVR write, cleared by Atom read.
    signal AVRBusy    : std_logic; -- Set by Atom write, cleard by AVR write

    -- Edge detection bits
    signal AtomIORD1  : std_logic;
    signal AtomIOWR1  : std_logic;
    signal nAVRRDData1: std_logic;
    signal AVRINT1    : std_logic;
    signal nAWR1      : std_logic;
    signal AtomCMDWR1 : std_logic;

begin

    -- ==========================================================
    -- Combinatorial logic
    -- ==========================================================

    -- Atom read strobes and address decodes
    RDS         <= RW;
    WDS         <= not RW;
    AtomRD      <= RDS and enable;
    AtomWR      <= WDS and enable;
    AtomIO	    <= '1' when (Addr >= "000" and Addr <= "011") else '0';
    AtomCMDWR	<= '1' when (Addr = "000" and AtomWR = '1') else '0';
    AVRStatus	<= '1' when (Addr = "100") else '0';
    Test1	    <= '1' when (Addr = "101") else '0';
    Test2	    <= '1' when (Addr = "110") else '0';
    AVRStatusRD	<= AVRStatus and AtomRD;
    AtomIORD	<= AtomIO and AtomRD;
    AtomIOWR	<= AtomIO and AtomWR;

    -- goes low when AVR reads data.
    nAVRRDData	<= nARD or AVRA0;

    -- Signal to the AVR that the Atom has read or written
    AVRINT	    <= AtomIORD or AtomIOWR;
    AVRINTOut	<= AVRInt;

    -- Assign AtomDataOut, depending on if reading staus or data
    AtomDataOut	<= ("00000" & AVRW_AtomR & AtomW_AVRR & AVRBusy) when AVRStatus = '1' else
                   (           "000" & AtomRW & "0" & AddrLatch) when Test1     = '1' else 
                   AtomToAVR                                     when Test2     = '1' else 
                   AVRToAtom;

    -- When the Atom reads give it the AVR data
    -- Data = AtomRD ? AtomDataOut : 8'bz;
    DataOut <= AtomDataOut;

    -- Assign AVRDataOut, depending on if reading staus or data
    AVRDataOut <= ("000" & AtomRW & "0" & AddrLatch) when AVRA0 = '1' else AtomToAVR;

    AtomIORDOut <= AtomIORD;
    AtomIOWROut <= AtomIOWR;
    
    -- ==========================================================
    -- Synchronous logic
    -- ==========================================================

    EdgeProcess : process (nRST, clk)
    begin
        if nRST = '0' then
            AtomIORD1   <= '0';
            AtomIOWR1   <= '0';
            nAVRRDData1 <= '0';
            AVRINT1     <= '0';
            nAWR1       <= '0';
            AtomCMDWR1  <= '0';
        elsif rising_edge(clk) then
            AtomIORD1   <= AtomIORD;
            AtomIOWR1   <= AtomIOWR;
            nAVRRDData1 <= nAVRRDData;
            AVRINT1     <= AVRINT;
            nAWR1       <= nAWR;
            AtomCMDWR1  <= AtomCMDWR;
        end if;
    end process;

    -- Capture the bottom 3 address lines on a write by the Atom.
    AddrLatchProcess : process (nRST, clk)
    begin
        if nRST = '0' then
            AddrLatch <= "000";
        elsif rising_edge(clk) and (AtomIOWR = '1' and AtomIOWR1 = '0') then
            AddrLatch <= Addr;
        end if;
    end process;

    -- Latch read or write
    AtomRWProcess : process (clk)
    begin
        if rising_edge(clk) and ((AtomIOWR = '1' and AtomIOWR1 = '0') or (AtomIORD = '1' and AtomIORD1 = '0')) then
           AtomRW <= RW;
        end if;
    end process;

    -- Latch Atom to AVR reg on atom write
    -- This may be dodgy on this edge!!
    AtomToAVRProcess : process (clk)
    begin
        if rising_edge(clk) and (AtomIOWR = '1' and AtomIOWR1 = '0') then
            AtomToAVR <= DataIn;
        end if;
    end process;

    -- Latch AVR to Atom on AVR write
    AVRToAtomProcess : process (clk)
    begin
        if rising_edge(clk) and nAWR = '0' and nAWR1 = '1' then
            AVRToAtom <= AVRDataIn;
        end if;
    end process;

    -- Handshake lines.
    -- AtomW_AVRR set by a write from the Atom, cleared by a read by the AVR.
    -- Cleared on reset.
    AtomW_AVRRProcess : process (nRST, clk)
    begin
        if nRST = '0' then
            AtomW_AVRR <= '0';
        elsif rising_edge(clk) then
            if (AtomIOWR = '1' and AtomIOWR1 = '0') then
                AtomW_AVRR <= '1';
            elsif (nAVRRDData = '1' and nAVRRDData1 = '0') then
                AtomW_AVRR <= '0';
            end if;
        end if;
    end process;


    -- AVRW_AtomR set by a write from the AVR, cleared by a read by the Atom.
    -- Cleared on reset.
    AVRW_AtomRLatch : process (nRST, clk)
    begin
        if nRST = '0' then
            AVRW_AtomR <= '0';
        elsif rising_edge(clk) then
            if (AtomIORD = '1' and AtomIORD1 = '0') then
                AVRW_AtomR <= '0';
            elsif (nAWR = '1' and nAWR1 = '0') then
                AVRW_AtomR <= '1';
            end if;
        end if;
    end process;

    -- AVRBusy set by Atom write to command register, reset by AVR write, as all
    -- commands should return at least one byte (status or data)
    -- We use posedge nAVRW, so that busy is not reset until the data has been written
    -- by the AVR, and is ready to be read by the Atom.
    AVRBusyProcess : process (nRST, clk)
    begin
        if nRST = '0' then
            AVRBusy <= '0';
        elsif rising_edge(clk) then
            if (AtomCMDWR = '1' and AtomCMDWR1 = '0') then
                AVRBusy <= '1';
            elsif (nAWR = '1' and nAWR1 = '0') then
                AVRBusy <= '0';
            end if;
        end if;
    end process;

end Behavioral;
