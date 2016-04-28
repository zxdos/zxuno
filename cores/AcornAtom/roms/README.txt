0x00000 - Atom #A000 Bank 0 - SDDOS v3.25
0x01000 - Atom #A000 Bank 1 - PCharme v1.73
0x02000 - Atom #A000 Bank 2 - Gags v2.3
0x03000 - Atom #A000 Bank 3 - AXR1
0x04000 - Atom #A000 Bank 4 - AtomFpga Utils v0.21 (was SALFAA v2.6)
0x05000 - Atom #A000 Bank 5 - Atomic Windows v1.1
0x06000 - Atom #A000 Bank 6 - WE ROM
0x07000 - Atom #A000 Bank 7 - Program Power Programmers Toolkit
0x08000 - BBC #6000 Bank 0 (ExtROM1)
0x09000 - BBC #6000 Bank 1 (ExtROM1)
0x0A000 - BBC #6000 Bank 2 (ExtROM1)
0x0B000 - BBC #6000 Bank 3 (ExtROM1)
0x0C000 - BBC #6000 Bank 4 (ExtROM1)
0x0D000 - BBC #6000 Bank 5 (ExtROM1)
0x0E000 - BBC #6000 Bank 6 (ExtROM1)
0x0F000 - BBC #6000 Bank 7 (ExtROM1)
0x10000 - Atom #C000 Basic  (DskRomEn=1)
0x11000 - Atom #D000 FP     (DskRomEn=1)
0x12000 - Atom #E000 MMC    (DskRomEn=1)
0x13000 - Atom #F000 Kernel (DskRomEn=1)
0x14000 - Atom #C000 Basic  (DskRomEn=0)
0x15000 - Atom #D000 FP     (DskRomEn=0)
0x16000 - Atom #E000 MMC    (DskRomEn=0) (unused on real Atom)
0x17000 - Atom #F000 Kernel (DskRomEn=0)
0x18000 - unused
0x19000 - BBC #7000 (ExtROM2)
0x1A000 - BBC Basic 1/4
0x1B000 - unused
0x1C000 - BBC Basic 2/4
0x1D000 - BBC Basic 3/4
0x1E000 - BBC Basic 4/4
0x1F000 - BBC MOS 3.0




Floating point patches:

CRC AAA1
D4AF  AD 00 A0  LDA $A000
D4B2  C9 40     CMP #$40
D4B4  D0 0A     BNE $D4C0
D4B6  AD 01 A0  LDA $A001
D4B9  C9 BF     CMP #$BF
D4BB  D0 03     BNE $D4C0
D4BD  4C 02 A0  JMP $A002
D4C0  4C 58 C5  JMP $C558

CRC 3353
D4AF   AD 04 E0   LDA $E004
D4B2   C9 BF      CMP #$BF
D4B4   F0 0A      BEQ $D4C0
D4B6   AD 00 A0   LDA $A000
D4B9   C9 40      CMP #$40
D4BB   D0 83      BNE $D440
D4BD   4C 02 A0   JMP $A002
D4C0   4C 05 E0   JMP $E005

CRC 4958
D4AF   AD 20 EB   LDA $EB20
D4B2   C9 40      CMP #$40
D4B4   F0 0A      BEQ $D4C0
D4B6   AD 01 A0   LDA $A001
D4B9   C9 BF      CMP #$BF
D4BB   D0 83      BNE $D440
D4BD   4C 02 A0   JMP $A002
D4C0   4C 22 EB   JMP $EB22
