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
                global  _no_nmi,_vdp_status,_spinner_1,_spinner_2,_nmi_flag
                global  _joypad_1,_joypad_2,_keypad_1,_keypad_2
_no_nmi:        defs    1
_vdp_status:    defs    1
_spinner_1:     defs    1
_spinner_2:     defs    1
_nmi_flag:      defs    1
_joypad_1:      defs    1
_keypad_1:      defs    1
_joypad_2:      defs    1
_keypad_2:      defs    1

                psect   text

                global  start,_nmi,_main,__Lbss,__Hbss

start:          defb    55h,0aah                ; no title screen
                defw    0                       ; copy of sprite table, etc.
                defw    0                       ;  all unused
                defw    0
                defw    0
                defw    start_program
                defb    0c9h,0,0                ; no RST support
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                defb    0c9h,0,0
                jp      spinner_int             ; RST38 - spinner interrupt

_nmi_asm:       push    af
                ld      a,(73ebh)               ; update spinner position
                ld      (_spinner_1),a
                ld      a,(73ech)
                ld      (_spinner_2),a
                xor     a
                ld      (73ebh),a
                ld      (73ech),a
                inc     a                       ; set NMI flag
                ld      (_nmi_flag),a
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
                ei                              ; enable spinner interrupt
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
                ei
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
; 4     button 4
; 5     button 3
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
                ld      b,a
                ld      a,c
                cpl
                and     0fh
                cp      8
                jr      nz,no_button_3
                ex      af,af'
                ld      a,b
                or      20h
                ld      b,a
                ex      af,af'
no_button_3:    cp      4
                jr      nz,no_button_4
                ex      af,af'
                ld      a,b
                or      10h
                ld      b,a
                ex      af,af'
no_button_4:    ld      (ix+0),b
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

spinner_int:    push    af
                push    hl
                call    1f88h
                pop     hl
                pop     af
                ei
                reti

start_program:  push    hl                      ; save hl
                push    bc                      ; main() argument
                call    1fd6h                   ; all sound off
                ld      de,__Lbss               ; start of bss
                ld      hl,__Hbss               ; end of bss
                xor     a                       ; clear carry
                sbc     hl,de
                ld      b,h
                ld      c,l
                dec     bc
                ld      h,d
                ld      l,e
                inc     de
                ld      (hl),a
                ldir                            ; zero-fill bss
                ld      hl,0033h                ; initialise random generator
                ld      (73c8h),hl
                call    1f85h                   ; set default VDP regs
                ld      bc,0002h
                call    1fd9h
                ld      bc,0182h
                call    1fd9h
                ld      de,4000h                ; clear VRAM
                xor     a
                ld      l,a
                ld      h,a
                call    1f82h
                call    _main
                ld      d,h                     ; get return code in de
                ld      e,l
                pop     bc                      ; restore bc and hl
                pop     hl
                jp      (hl)                    ; should jump to start_program
                                                ; an ADAM loader can supply
                                                ; a different address

                end     start
