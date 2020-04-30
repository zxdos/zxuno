                psect   bss

sound_off:      defs    1
sound_1:
sound_1_delay:  defs    1
sound_1_unused: defs    1
sound_1_ptr:    defs    2
sound_2:
sound_2_delay:  defs    1
sound_2_unused: defs    1
sound_2_ptr:    defs    2
sound_3:
sound_3_delay:  defs    1
sound_3_unused: defs    1
sound_3_ptr:    defs    2
sound_4:
sound_4_delay:  defs    1
sound_4_unused: defs    1
sound_4_ptr:    defs    2
sound_fsweep:   defs    16
sound_vsweep:   defs    16
sound_regs:     defs    16

                psect   text

                global  _sound_out
                ; sound_out (byte);
_sound_out:     pop     bc
                pop     de
                push    de
                push    bc
                ld      a,e
send_sound_byte:
;               jp      335h
                out     (0ffh),a
                ret

                global  _update_sound
_update_sound:  push    ix
                push    iy
                ld      ix,sound_fsweep+0
                ld      iy,sound_regs+0
                ld      e,80h
                call    check_fsweep
                ld      ix,sound_fsweep+4
                ld      iy,sound_regs+4
                ld      e,0a0h
                call    check_fsweep
                ld      ix,sound_fsweep+8
                ld      iy,sound_regs+8
                ld      e,0c0h
                call    check_fsweep
                ld      ix,sound_vsweep+0
                ld      iy,sound_regs+0
                ld      e,90h
                call    check_vsweep
                ld      ix,sound_vsweep+4
                ld      iy,sound_regs+4
                ld      e,0b0h
                call    check_vsweep
                ld      ix,sound_vsweep+8
                ld      iy,sound_regs+8
                ld      e,0d0h
                call    check_vsweep
                ld      ix,sound_vsweep+12
                ld      iy,sound_regs+12
                ld      e,0f0h
                call    check_vsweep
                ld      ix,sound_1
                ld      iy,sound_regs+0
                xor     a
                call    update_sound_1
                ld      ix,sound_2
                ld      iy,sound_regs+4
                ld      a,1
                call    update_sound_1
                ld      ix,sound_3
                ld      iy,sound_regs+8
                ld      a,2
                call    update_sound_1
                ld      ix,sound_4
                ld      iy,sound_regs+12
                ld      a,3
                call    update_sound_1
                pop     iy
                pop     ix
                ret

update_sound_1: dec     (ix+0)
                ret     nz
                ex      af,af'
                ld      l,(ix+2)
                ld      h,(ix+3)
                ld      a,l
                or      h
                ret     z
update_sound_again:
                ld      a,(hl)
                inc     hl
                or      a
                jp      m,update_sound_reg
                jr      z,new_sound_pointer
                bit     6,a
                jr      z,new_sound_delay
                push    iy
                bit     5,a
                ld      iy,sound_vsweep
                jr      nz,1f
                ld      iy,sound_fsweep
1:              ex      af,af'
                ld      e,a
                ex      af,af'
                ld      d,0
                add     iy,de
                add     iy,de
                add     iy,de
                add     iy,de
                ld      a,(hl)
                inc     hl
                ld      (iy+0),a
                ld      (iy+1),a
                ld      a,(hl)
                inc     hl
                ld      (iy+2),a
                pop     iy
                jr      update_sound_again
new_sound_delay:
                ld      (ix+0),a
                jr      update_sound_done
update_sound_reg:
                ex      af,af'
                ld      b,a
                ex      af,af'
                rrc     b
                rrc     b
                rrc     b
                and     1fh
                or      b
                or      80h
                ld      b,a
                and     70h
                cp      00h
                jr      z,1f
                cp      20h
                jr      z,1f
                cp      40h
                jr      z,1f
                call    sound_out_1
                jr      update_sound_again
1:              ld      c,(hl)
                inc     hl
                call    sound_out_2
                jr      update_sound_again
new_sound_pointer:
                ld      e,(hl)
                inc     hl
                ld      d,(hl)
                ex      de,hl
                ld      a,1
                ld      (ix+0),a                ; reset delay
                ld      a,l
                or      h
                jr      nz,update_sound_done
                ex      af,af'                  ; turn sound off
                ld      b,a
                ex      af,af'
                ld      a,b
                rrca
                rrca
                rrca
                or      9fh
                ld      b,a
                call    sound_out_1
                ex      af,af'                  ; reset sweeps
                ld      e,a
                ex      af,af'
                ld      d,0
                ld      iy,sound_vsweep
                add     iy,de
                add     iy,de
                add     iy,de
                add     iy,de
                xor     a
                ld      (iy+0),a
                ld      (iy+1),a
                ld      (iy+2),a
                ld      (iy+sound_fsweep-sound_vsweep+0),a
                ld      (iy+sound_fsweep-sound_vsweep+1),a
                ld      (iy+sound_fsweep-sound_vsweep+2),a
                ld      (ix+1),a                ; reset priority
update_sound_done:
                ld      (ix+2),l
                ld      (ix+3),h
                ret

check_vsweep:   ld      a,(ix+2)
                or      a
                scf
                ret     z
                dec     (ix+0)
                ret     nz
                ld      a,(ix+1)
                ld      (ix+0),a
                ld      a,(iy+2)
                add     a,(ix+2)
                jp      p,1f
                xor     a
1:              cp      10h
                jr      c,1f
                ld      a,0fh
1:              or      e
                ld      b,a

; b=byte to send
; iy=pointer to sound register structure
sound_out_1:    ld      a,b
                and     0fh
                ld      (iy+2),a
                ld      a,(sound_off)
                or      a
                ret     nz
                ld      a,b
                jp      send_sound_byte

check_fsweep:   ld      a,(ix+2)
                or      a
                scf
                ret     z
                dec     (ix+0)
                ret     nz
                ld      a,(ix+1)
                ld      (ix+0),a
                ld      b,(iy+0)
                ld      c,(iy+1)
                ld      a,(ix+2)
                ld      h,0
                or      a
                jp      p,fsweep_up
                dec     h
fsweep_up:      ld      l,a
                add     hl,bc
                ld      a,h
                or      a
                jp      p,fsweep_no_underflow
                ld      hl,0
                xor     a
fsweep_no_underflow:
                cp      4
                jr      c,fsweep_no_overflow
                ld      hl,3ffh
fsweep_no_overflow:
                ld      a,e
                or      h
                ld      b,a
                ld      c,l
; b = first byte
; c = second byte
; iy=pointer to sound register structure
sound_out_2:    ld      a,b
                and     0fh
                ld      (iy+0),a
                ld      (iy+1),c
                push    hl
                ld      a,b
                and     0f0h
                ld      h,a
                ld      a,c
                and     0fh
                or      h
                call    send_sound_byte
                ld      a,b
                and     0fh
                rlca
                rlca
                rlca
                rlca
                ld      b,a
                ld      a,c
                and     0f0h
                rrca
                rrca
                rrca
                rrca
                or      b
                call    send_sound_byte
                pop     hl
                ret

; input:  a=channel (0=melodic, 1=noise)
; output: ix=pointer to sound table
;         iy=pointer to sound registers
;         a=priority of sound pointed to by ix
;         b=code to turn sound off
allocate_sound_channel:
                or      a
                ld      ix,sound_4
                ld      iy,sound_regs+12
                ld      b,0ffh
                ld      a,(sound_4+1)
                ret     nz                      ; use noise channel
                push    hl
                ld      ix,sound_1+0            ; look for lowest priority
                ld      iy,sound_regs+0
                ld      a,(sound_1+1)
                ld      b,9fh
                ld      hl,sound_2+1
                cp      (hl)
                jr      c,allocate_sound_channel_1
                ld      ix,sound_2
                ld      iy,sound_regs+4
                ld      a,(sound_2+1)
                ld      b,0bfh
allocate_sound_channel_1:
                ld      hl,sound_3+1
                cp      (hl)
                jr      c,allocate_sound_channel_2
                ld      ix,sound_3
                ld      iy,sound_regs+8
                ld      a,(sound_3+1)
                ld      b,0dfh
allocate_sound_channel_2:
                pop     hl
                ret

                global  _start_sound
                ; void *start_sound (void *data,byte priority);
_start_sound:   pop     de
                pop     hl
                pop     bc
                push    bc
                push    hl
                push    de
                ld      b,c
                push    ix
                push    iy
                ld      ix,0
                ld      a,l
                or      h
                jr      z,9f
                ld      d,b
                ld      a,(hl)
                inc     hl
                call    allocate_sound_channel
                ld      e,a                     ; check priority
                ld      a,d
                cp      e
                jr      c,9f
                ld      (ix+0),1                ; set sound data
                ld      (ix+1),a
                ld      (ix+2),l
                ld      (ix+3),h
                xor     a
                ld      (ix+sound_vsweep-sound_1+0),a
                ld      (ix+sound_vsweep-sound_1+1),a
                ld      (ix+sound_vsweep-sound_1+2),a
                ld      (ix+sound_fsweep-sound_1+0),a
                ld      (ix+sound_fsweep-sound_1+1),a
                ld      (ix+sound_fsweep-sound_1+2),a
                call    sound_out_1             ; turn off volume
9:              push    ix
                pop     hl
                pop     iy
                pop     ix
                ret

                global  _stop_sound
                ; stop_sound (void *channel)
_stop_sound:    pop     de
                pop     hl
                push    hl
                push    de
                ld      a,l
                or      h
                ret     z
                push    ix
                push    hl
                pop     ix
                xor     a
                ld      (ix+0),1
                ld      (ix+1),a
                ld      (ix+2),a
                ld      (ix+3),a
                ld      (ix+sound_vsweep-sound_1+0),a
                ld      (ix+sound_vsweep-sound_1+1),a
                ld      (ix+sound_vsweep-sound_1+2),a
                ld      (ix+sound_fsweep-sound_1+0),a
                ld      (ix+sound_fsweep-sound_1+1),a
                ld      (ix+sound_fsweep-sound_1+2),a
                pop     ix
                ret

                global  _sound_on
_sound_on:      xor     a
                ld      (sound_off),a
                ld      a,(sound_regs+0+2)
                or      90h
                call    send_sound_byte
                ld      a,(sound_regs+4+2)
                or      0b0h
                call    send_sound_byte
                ld      a,(sound_regs+8+2)
                or      0d0h
                call    send_sound_byte
                ld      a,(sound_regs+12+2)
                or      0f0h
                jp      send_sound_byte

                global  _sound_off
_sound_off:     ld      a,1
                ld      (sound_off),a
                jp      1fd6h
