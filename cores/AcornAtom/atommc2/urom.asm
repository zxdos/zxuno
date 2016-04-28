;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *UROM [val]
;
; Set the current utility ROM, disable interface interrupts and await break..!
; Requires extension ROM board with latch at #BFFF.
;
STARUROM:
   ldx   #$cb             ; scan parameter fail if none
   jsr   RDOPTAD
   bne   selectrom

   jmp   COSSYN

; entry point for 3rd party usage such as ROMLOAD

selectrom:
   jsr   ifdi              ; interface disable interrupt
   
   ldx   #@rtn_end-@rtn

@movefn:
   lda   @rtn,x
   sta   NAME,x
   dex
   bpl   @movefn

   jsr   STROUT
   .byte "<PRESS BREAK>"
   nop

   lda   #0                ; ROM in $a000 please 
   sta   $cc

   jmp   NAME



@rtn:

   lda   $cc               ; option bits - 
   sta   $bffe

   lda   $cb               ; change the ROM
   sta   $bfff

   sec

@infinite:
   bcs   @infinite

@rtn_end:
