                psect   text

                global  _snd_table

                global  _stop_sound
                ; stop_sound (byte sound_number);
_stop_sound:    pop     bc
                pop     de
                push    de
                push    bc

                ld      a,e   ; a = song#
                
                ld      b,a   ; b = song#
                ld      hl,_snd_table-2   ; calcul the right sound slot
                ld      de,0004h
1:              add	hl,de
                djnz	1b

                ld      b,a   ; b = song#

                ld      e,(hl)           ; get the sound slot addr.
                inc	hl
                ld      d,(hl)
                ex      de,hl

                ld      a,(hl)           ; get the song# currently in the sound dlot
                and	7

                cp	b                ; compare with the song# we are looking for
                jr	nz,2f            ; if not the same song# -> do nothing

                ld      (hl),0ffh
2:
                ret

