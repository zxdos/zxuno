
;
; todo - 
;

.include "atmmc2def.asm"

; OS overrides
;
TOP         =$0d
PAGE        =$12
ARITHWK     =$23

; these need to be in ZP
;
RWPTR       =$ac         ; W - data target vector
ZPTW        =$ae         ; [3] - general use temp vector, used by vechexs, RS, WS

LFNPTR      =$c9         ; W -pointer to filename (usually $140)
LLOAD       =$cb         ; W - load address
LEXEC       =$cd         ; W - execution address
LLENGTH     =$cf         ; W - byte length

SFNPTR      =$c9         ; W -pointer to filename (usually $140)
SLOAD       =$cb         ; W - reload address
SEXEC       =$cd         ; W - execute
SSTART      =$cf         ; W - data start
SEND        =$d1         ; W - data end + 1

CRC         =$c9         ; 3 bytes in ZP - should be ok as this addr only used for load/save??

RDCCNT      =$c9         ; B - bytes in pool - ie ready to be read from file
RDCLEN      =$ca         ; W - length of file supplying characters

tmp_ptr3    =$D5
tmp_ptr5    =$D6
tmp_ptr6    =$D7

MONFLAG     =$ea         ; 0 = messages on, ff = off

NAME       =$140         ; sits astride the BASIC input buffer and string processing area.

IRQVEC     =$204         ; we patch these (maybe more ;l)
COMVEC     =$206
RDCVEC     =$20a
LODVEC     =$20c
SAVVEC     =$20e

; DOS scratch RAM 3CA-3FC. As the AtoMMC interface effectively precludes the use of DOS..
;
FKIDX      =$3ca         ; B - fake key index
RWLEN      =$3cb         ; W - count of bytes to write
FILTER     =$3cd         ; B - dir walk filter 


; I/O register base
;

.ifdef ALTADDR
AREG_BASE			= $b408
.else
AREG_BASE			= $b400	
.endif

ACMD_REG			= AREG_BASE+CMD_REG
ALATCH_REG          = AREG_BASE+LATCH_REG             
AREAD_DATA_REG      = AREG_BASE+READ_DATA_REG             
AWRITE_DATA_REG     = AREG_BASE+WRITE_DATA_REG             
ASTATUS_REG			= AREG_BASE+STATUS_REG	

; FN       ADDR
;
OSWRCH     =$fff4
OSRDCH     =$ffe3
OSCRLF     =$ffed
COSSYN     =$fa7d
COSPOST    =$fa76
RDADDR     =$fa65
CHKNAME    =$f84f
SKIPSPC    =$f876
RDOPTAD    =$f893
BADNAME    =$f86c
WSXFER2    =$f85C
COPYNAME   =$f818
HEXOUT     =$f802
HEXOUTS    =$f7fa
STROUT     =$f7d1


.include "macros.asm"

.SEGMENT "CODE"


AtoMMC2:
   ; test ctrl - if pressed, don't initialise
   ;
   bit $b001
   bvs @initialise

   ; don't initialise the firmware
.IFNDEF EOOO
   ; - however we got an interrupt so we need to clear it
   ;
  ; lda   #30               ; as we've had an interrupt we want to wait longer
  ; sta   CRC               ; for the interface to respond
   jsr   irqgetcardtype
   pla
   rti
.ELSE
   ; the E000 build 
   jmp   $c2b2             ; set #2900 text space and enter command handler
.ENDIF

@initialise:
   tya
   pha
   txa
   pha

   ; forget VIA! - we got the interrupt so the PL8 interface is in the house!

   ; read card type
   ;
  ; lda   #7                   ; timeout value, ret when crc == -1
  ; sta   CRC
   jsr   irqgetcardtype
  ; bit   CRC
  ; bmi   @unpatched

   tay

   ldx   #0

   stx   FKIDX            ; fake key index for OSRDCH patch, just piggybacking

   lda   #43              ;'+'
   sta   $800b

@shorttitle:
   lda   version,x
   and   #$bf
   sta   $800d,x
   inx
   cmp   #$20
   bne   @shorttitle

   bit   $b002            ; is REPT pressed?
   bvs   @quiet

   dex

@announce:
   and   #$bf
   sta   $800d,x
   inx

   lda   version,x
   cmp   #$0d
   bne   @announce

   ; display appropriate type
   ; none = 0, mmc = 1, sdv1 = 2, sdv2 = 4
   ;
   tya
   jsr   bittoindex
   ldy   #0

@sctloop:
   lda   cardtypes,x
   and   #$bf
   sta   $801c,y
   inx
   iny
   cpy   #4
   bne   @sctloop


@quiet:
   jsr   installhooks

;    $b40f    $b001
;      0        0    [inv. sh, sh pressed]     0
;      0        1    [inv. sh, sh not pressed] 1
;      1        0    [norm sh, sh pressed]     1
;      1        1    [norm sh, sh not pressed] 0

	FASTCMDI	CMD_GET_CFG_BYTE             ; get config byte
						; 'normal shift' bit is 6
   asl   a              ;
   eor   $b001          ;
   bpl   @unpatched     ;
   

@patchosrdch:
   lda   #<osrdchcode
   sta   RDCVEC
   lda   #>osrdchcode
   sta   RDCVEC+1

@unpatched:
   pla
   tax
   pla
   tay

.IFDEF EOOO
   jmp   $c2b2             ; set #2900 text space and enter command handler
.ENDIF

irqveccode:
   pla                 ; pop the accumulator as saved by the irq handler
   rti



; takes a card type in A
; 0 = no card
; bit 1 = type 1 (MMC)
; bit 2 = type 2 (SD)
; etc etc
;
bittoindex:
   ora   #8             ; bit 3 -- 'no card available' - to ensure we stop 
   sta   ZPTW

   lda   #$fc           ; spot the bit
   clc
@add:
   adc   #4
   lsr   ZPTW
   bcc   @add

   tax
   rts




installhooks2:
   ldx   #0

@announce:
   lda   version,x
   jsr   OSWRCH
   inx
   cpx   #16
   bne   @announce

.IFNDEF EOOO
   jsr   ifen           ; interface enable interrupt, if at A000
.ENDIF
   
; install hooks. 6 vectors, 12 bytes
;
; !!! this is all you need to call if you're not using IRQs !!!
;
installhooks:
   ldx   #11+12

@initvectors:
   lda   fullvecdat,x
   sta   IRQVEC,x
   dex
   bpl   @initvectors

   rts





;igct_delay:
;   ldx   0
;   ldy   0
;igct_inner:
;   dey
;   bne   igct_inner
;   dex
;   bne   igct_inner
;
;   dec   CRC
;   bmi   igct_quit

irqgetcardtype:
   ; await the 0xaa,0x55,0xaa... sequence which shows that the interface
   ; is initialised and responding
   ;
	FASTCMDI 	CMD_GET_HEARTBEAT
   cmp   #$aa
   bne   irqgetcardtype

irqgetcardtype2:
	FASTCMDI 	CMD_GET_HEARTBEAT
   cmp   #$55
   bne   irqgetcardtype

   ; send read card type command - this also de-asserts the interrupt

   SLOWCMDI 	CMD_GET_CARD_TYPE

   
igct_quit:
   rts







; patched os input function
;
; streams fake keypresses to the system
; re-registers the bios' function when
; a> fake keys have all been sent or
; b> when no shift-key is detected
;
osrdchcode:
   php
   cld
   stx   $e4
   sty   $e5
	
   ldx   FKIDX
   lda   fakekeys,x
   cmp	#$0d
   beq   @unpatch

   inx
   stx   FKIDX

   ldx   $e4
   ldy   $e5
   plp
   rts

@unpatch:
   ; restore OSRDCH, continue on to read a char
   ;
 ;  ldx   $e4
 ;  ldy   $e5

osrdchcode_unhook:
   lda   #$94
   sta   RDCVEC
   lda   #$fe
   sta   RDCVEC+1
   
;   plp
   lda 	#$0d
   pha
   jmp 	$fe5c
;   jmp   (RDCVEC)








; Kees Van Oss' version of the CLI interpreter
;
osclicode:

;=================================================================
; STAR-COMMAND INTERPRETER
;=================================================================
star_com:
   LDX   #$ff             ; Set up pointers
   CLD
star_com1:
   LDY   #0
   JSR   SKIPSPC
   DEY
star_com2:
   INY
   INX

star_com3:
   LDA   com_tab,X        ; Look up star-command
   BMI   star_com5
   CMP   $100,Y
   BEQ   star_com2
   DEX
star_com4:
   INX
   LDA   com_tab,X
   BPL   star_com4
   INX
   LDA   $100,Y
   CMP   #46                 ; '.'
   BNE   star_com1
   INY
   DEX
   BCS   star_com3

star_com5:
   STY   $9a

   LDY   $3             ; Save command pointers
   STY   tmp_ptr3
   LDY   $5
   STY   tmp_ptr5
   LDY   $6
   STY   tmp_ptr6
   LDY    #<$100
   STY    $5
   LDY    #>$100
   STY   $6
   LDY   $9a
   STY   $3

   STA   $53            ; Execute star command
   LDA   com_tab+1,X
   STA   $52
   ldx   #0
   JSR   comint6

   LDY   tmp_ptr5         ; Restore command pointers
   STY   $5
   LDY   tmp_ptr6
   STY   $6
   LDY   tmp_ptr3
   STY   $3

   LDA   #$0D
   STA   ($5),Y

   RTS 

comint6:
   JMP   ($0052)








.include "cat.asm"
.include "cwd.asm"
.include "cfg.asm"
.include "crc.asm"
.include "delete.asm"
.include "exec.asm"
.include "fatinfo.asm"
.include "help.asm"
.include "info.asm"
.include "load.asm"
.include "run.asm"
;.include "urom.asm"
.include "save.asm"
.include "file.asm"
.include "util.asm"
.include "chain.asm"
.include "raf.asm"





cardtypes:
   .byte " MMC  SDSDHC N/A"
   ;      1111222244448888

fullvecdat:
   .word irqveccode	; 204 IRQVEC
   .word osclicode	; 206 COMVEC
   .word $fe52		; 208 WRCVEC
   .word $fe94		; 20A RDCVEC
   .word osloadcode	; 20C LODVEC
   .word ossavecode	; 20E SAVVEC
 
rafvecdat:
   .word osrdarcode	; 210 RDRVEC
   .word osstarcode	; 212 STRVEC
   .word osbgetcode	; 214 BGTVEC
   .word osbputcode	; 216 BPTVEC
   .word osfindcode	; 218 FNDVEC
   .word osshutcode	; 21A SHTVEC

fakekeys:
   .byte "*MENU"
   .byte $0d,0

com_tab:
   .byte "CAT"
   FNADDR STARCAT

   .byte "CWD"
   FNADDR STARCWD

   .byte "DELETE"
   FNADDR STARDELETE

   .byte "EXEC"
   FNADDR STAREXEC

   .byte "RUN"          ; in exec.asm
   FNADDR STARRUN

   .byte "HELP"
   FNADDR STARHELP

   .byte "INFO"
   FNADDR STARINFO

   .byte "LOAD"
   FNADDR STARLOAD

;   .byte "RLOAD"        ; in load.asm
;   FNADDR STARRLOAD

;   .byte "ROMLOAD"      ; in load.asm
;   FNADDR STARROMLOAD

;   .byte "UROM"
;   FNADDR STARUROM

   .byte "MON"
   FNADDR $fa1a

   .byte "NOMON"
   FNADDR $fa19

   .byte "CFG"
   FNADDR STARCFG

   .byte "PBD"          ; in cfg.asm
   FNADDR STARPBD

   .byte "PBV"          ; in cfg.asm
   FNADDR STARPBV

   .byte "SAVE"
   FNADDR STARSAVE

   .byte "FATINFO"
   FNADDR STARFATINFO

   .byte "CRC"
   FNADDR STARCRC

   .byte "CHAIN"
   FNADDR STARCHAIN

   FNADDR STARARBITRARY


SQ=34   ; "


diskerrortab:
   .byte $0d
   .byte "DISK FAULT",$0d
   .byte "INTERNAL ERROR",$0d
   .byte "NOT READY",$0d
   .byte "NOT FOUND",$0d
   .byte "NO PATH",$0d
   .byte "INVALID NAME",$0d
   .byte "ACCESS DENIED",$0d
   .byte "EXISTS",$0d
   .byte "INVALID OBJECT",$0d
   .byte "WRITE PROTECTED",$0d
   .byte "INVALID DRIVE",$0d
   .byte "NOT ENABLED",$0d
   .byte "NO FILESYSTEM",$0d
   .byte $0d                     ; mkfs error
   .byte "TIMEOUT",$0d
   .byte "EEPROM ERROR",$0d
   .byte "FAILED",$0d
   .byte "TOO MANY",$0d
   .byte "SILLY",$0d

errorhandler:
   .byte "@=8;P.$6$7'"
   .byte SQ
   .byte "ERROR - "
   .byte SQ
   .byte "$!#D5&#FFFF;"
   .byte "IF?1|?2P."
   .byte SQ
   .byte " - LINE "
   .byte SQ
   .byte "!1& #FFFF"
   .byte $0d,0,0
   .byte "P.';E."
   .byte $0d


.IFDEF EOOO
.include "BRAN.asm"
.ENDIF

.SEGMENT "WRMSTRT"

warmstart:
   jmp   installhooks2


.SEGMENT "VSN"

version:
   .byte "ATOMMC2 V2.97"
.IFNDEF EOOO
   .byte "A"
.ELSE
   .byte "E"
.ENDIF
   .byte $0d,$0a
   .byte " (C) 2008-2013  "
   .byte "CHARLIE ROBSON. "

   .end
