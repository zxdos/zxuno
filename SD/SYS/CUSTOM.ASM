;==============================================================================
; Project: custom.zdsp
; Main File: custom.asm
; Date: 27/10/2017 12:00:00
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin custom.asm custom
;
;==============================================================================

        include nmi.inc
        include nmi.publics

        org     ovrBuf

; --------------
; custom overlay
; --------------
;
custom  ld      bc, 24*256+0
        ld      a, COL_MID
        call    clrScr

        ld      bc, 3*256+11
        ld      a, BRIGHT+MAGENTA*8+WHITE
        call    clrScr

        ld      hl, msg0001
        call    prStr

        call    waitKey

        ;
        ; return values
        ;
        ; 1 - reload dir and reprint all
        ; 2 - reprint all (top, mid, bottom and cursor)
        ; 3 - reprint mid, bottom and cursor
        ; 4 - reprint bottom and cursor
        ; 5 - reprint nothing
        ;
        ld      a, 2
        ret

; --------
; messages
; --------
;
msg0001 db      $16,12,64/2-12/2,'Hello world!', 0

;------------------------------------------------------------------------------
IF $ > ovrBuf+SIZ_OVR
        .ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

