genMenu 1
rcs screen.scr screen.rcs
fcut screen.rcs 0 1000 screen.cut
call compress b1 5b00 screen.cut
echo  define  LREG    61 >  define.asm
echo  define  LOFF    32 >> define.asm
sjasmplus genFlash.asm
