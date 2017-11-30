How to program the cartrige?

Basically you have a 5 bit shift register connected to the high address
bits of the EEPROM IC. So you need to write these 5 bits one by one.
Every time you write a bit the ROM is changed. The ROM is paged
at $0000-$3FFF, so you need place the paging routine in the RAM area.

There is also a LOCK bit. When you write a 1 in the LOCK bit the paging
is locked. The cartridge has a LED indicating LOCK bit. To unlock paging
you must push the button in the cartridge, or power off the spectrum.
This also reset the page to 00000, where is the game selection menu.

There are 4 address to change these bits: $3FFC, $3FFD, $3FFE, $3FFF.
Both reads and writes to this address will work and data bus is
discarded. In this example I will use writes with LD (N), A instruction.
The LSB of address (A0) is inserted into the shift register from the right
to the left and the second bit (A1) is the LOCK bit.

So for example you want to go to the page 13 (pages are between 0 and 31)
by activating the LOCK bit in the last bit. In binary (5 bits) is 01101.
So you need to write 0, then 1, then 1, then 0 and finally 1. With the
last 1 you need also to set LOCK=1.

  LD  ($3FFC), A    ; Write 0. Now page is 00000 and LOCK=0
  LD  ($3FFD), A    ; Write 1. Now page is 00001 and LOCK=0
  LD  ($3FFD), A    ; Write 1. Now page is 00011 and LOCK=0
  LD  ($3FFC), A    ; Write 0. Now page is 00110 and LOCK=0
  LD  ($3FFF), A    ; Write 1. Now page is 01101 and LOCK=1

The locking mechanism is good for a game selection menu, when you want
to disable future accidental paging once game is selected. But if
you want create your own game (it can be up to 512K) is better avoid
locking.
