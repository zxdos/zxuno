;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *HELP
;
; Shows some info
;
STARHELP:

   ldx   #0

@vers:
   lda   version,x
   jsr   OSWRCH
   inx
   cpx   #48
   bne   @vers

   jsr   OSCRLF

   jsr   STROUT
   .byte "INTERFACE F/W VERSION "
   nop

	FASTCMDI		CMD_GET_FW_VER
   jsr   			ndotn
   jsr   			OSCRLF


   jsr   STROUT
   .byte "BOOTLOADER VERSION "
   nop

	FASTCMDI		CMD_GET_BL_VER
   jsr   			ndotn
   jsr   			OSCRLF

   ; read and display card type
   ;
   jsr   STROUT
   .byte "CARD TYPE: "
   nop
;   lda   #CMD_GET_CARD_TYPE
   SLOWCMDI 		CMD_GET_CARD_TYPE

   jsr   bittoindex
   ldy   #4

@sctloop:
   lda   cardtypes,x
   cmp   #$20
   beq   @skipwhite
   jsr   OSWRCH
@skipwhite:
   inx
   dey
   bne   @sctloop

   jmp   OSCRLF
 


ndotn:
   pha
   lsr   a
   lsr   a
   lsr   a
   lsr   a
   jsr   $f80b             ; print major version
   lda   #'.'
   jsr   OSWRCH
   pla
   jmp   $f80b             ; print minor version
