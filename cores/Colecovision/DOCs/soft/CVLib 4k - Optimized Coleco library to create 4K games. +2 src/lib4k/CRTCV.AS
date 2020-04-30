;****************************************************************************;
;**                                                                        **;
;**                                crtcv.as                                **;
;**                                                                        **;
;** ColecoVision startup module                                            **;
;**                                                                        **;
;** Copyright (C) Marcel de Kogel 1997                                     **;
;**     You are not allowed to distribute this software commercially       **;
;**     Please, notify me, if you make any changes to this file            **;
;****************************************************************************;

                psect   text,global,pure
                psect   data,global,pure
                psect   bss,global

                psect   bss
                global  _nmi
                global  _no_nmi,_vdp_status,_nmi_flag
                global  _joypad_1,_joypad_2,_keypad_1,_keypad_2
                global  _snd_table,_buffer32
_buffer32:      defs    32 ; buffer space 32    [7000-701F]
snd_addr:       defs    11 ; sound addresses    [7020-702A]
snd_areas:      defs    71 ; 7 sound slots + NULL (00h) [702B-...]
_no_nmi:        defs    1
_vdp_status:    defs    1
_nmi_flag:      defs    1
_joypad_1:      defs    1
_keypad_1:      defs    1
_joypad_2:      defs    1
_keypad_2:      defs    1

                psect   text

                global  start,_main

start:          defb    55h,0aah        ; no title screen
                defw    0               ; copy of sprite table, etc.
                defw    0               ;  all unused
                defw    _buffer32       ; Work Buffer
                defw    0
                defw    start_program
                defb    0c9h,0,0                ; no RST support
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0

_nmi_asm:       push    af
                ld	a,1
                ld      (_nmi_flag),a           ; set NMI flag
                ld      a,(_no_nmi)             ; check if nmi() should be
                or      a                       ;  called
                jp      nz,nmi_exit
                inc     a
                ld      (_no_nmi),a
                call    1fdch                   ; get VDP status
                ld      (_vdp_status),a
                push    bc
                push    de
                push    hl
                push    ix
                push    iy
                ex      af,af'
                push    af
                exx
                push    bc
                push    de
                push    hl
                call    1ff4h                   ; update snd_addr with snd_areas
                call    1f61h                   ; play sounds
                call    1f76h                   ; update controllers
                ld      a,(73eeh)
                and     4fh
                ld      (_joypad_1),a
                ld      a,(73efh)
                and     4fh
                ld      (_joypad_2),a
                ld      a,(73f0h)
                and     4fh
                ld      (_keypad_1),a
                ld      a,(73f1h)
                and     4fh
                ld      (_keypad_2),a
                call    decode_controllers
                call    _nmi                    ; call C function
                pop     hl
                pop     de
                pop     bc
                exx
                pop     af
                ex      af,af'
                pop     iy
                pop     ix
                pop     hl
                pop     de
                pop     bc
                xor     a
                ld      (_no_nmi),a
                pop     af
                ret
nmi_exit:       call    1fdch
                ld      (_vdp_status),a
                pop     af
                ret

                psect   data
keypad_table:   defb    0ffh,8,4,5,0ffh,7,11,2,0ffh,10,0,9,3,1,6,0ffh

                psect   text
; joypads will be decoded as follows:
; bit
; 0     left
; 1     down
; 2     right
; 3     up
; 4     --------
; 5     --------
; 6     button 2
; 7     button 1
; keypads will hold key pressed (0-11), or 0xff
decode_controllers:
                ld      ix,_joypad_1
                call    decode_controller
                inc     ix
                inc     ix
decode_controller:
                ld      a,(ix+0)
                ld      b,a
                and     40h
                rlca
                ld      c,a
                ld      a,b
                and     0fh
                or      c
                ld      b,a
                ld      a,(ix+1)
                ld      c,a
                and     40h
                or      b
                ld      (ix+0),a
                ld      a,c
                cpl
                and     0fh
                ld      e,a
                ld      d,0
                ld      hl,keypad_table
                add     hl,de
                ld      a,(hl)
                ld      (ix+1),a
                ret

start_program:
                im       1                      ; interrupt mode -> rst 38h
                di

                xor     a                       ; clear carry
                ld      bc,3b8h
                ld      hl,7000h
                ld      de,7001h
                ld      (hl),a
                ldir                            ; zero-fill bss

                ld	b,7
                ld	hl,_snd_table
                call    1feeh                   ; init snd_areas and snd_addr + all sound off

                ld      hl,0033h                ; initialise random generator
                ld      (73c8h),hl
                                                ; set screen mode 2 text
                call    1f85h                   ; set default VDP regs 16K
                ld      a,082h                  ; 16K, blank screen, no NMI, reset M1 & M3, sprites 16x16
                ld      c,a
                ld      b,1
                call    1fd9h
                ld      bc,039fh                ; vdp_out(3,9fh)
                call    1fd9h
                ld      bc,0400h                ; vdp_out(4,0)
                call    1fd9h
                ld      bc,0002h                ; vdp_out(0,2) ; set mode 2
                call    1fd9h
                ld      de,4000h                ; clear VRAM
                xor     a
                ld      l,a
                ld      h,a
                call    1f82h
                                                ; call main rountine
                jp      _main
                end     start
