;****************************************************************************;
;**                                                                        **;
;**                                cadam.as                                **;
;**                                                                        **;
;** Coleco ADAM Cosmo Trainer/Cosmo Challenge startup module               **;
;**                                                                        **;
;** Copyright (C) Marcel de Kogel 1997                                     **;
;**     You are not allowed to distribute this software commercially       **;
;**     Please, notify me, if you make any changes to this file            **;
;****************************************************************************;

read_block      equ     0fcf3h
switch_mem      equ     0fd14h
query_file      equ     0fccch
fill_vram       equ     1f82h
vdp_out         equ     1fd9h
all_sound_off   equ     1fd6h

                psect   text,global,pure
                psect   data,global,pure
                psect   bss,global

                psect   bss
OurDevice:      defs    1
OptionsFileInfo:        defs    23
ChallengeFileInfo:      defs    23
TrainerFileInfo:        defs    23
                defs    1024
Stack           equ     $-16
LoaderBuffer:

                psect   data
                defm    'This program is copyright (C) M. de Kogel, 1997'
OptionsFile:    defm    'COSMO_OP'
                defb    2,3,32,32,10h
ChallengeFile:  defm    'COSMO_CH'
                defb    2,3,32,32,10h
TrainerFile:    defm    'COSMO_TR'
                defb    2,3,32,32,10h
vdp_regs:       defb    02h,0c2h,0ch,9fh,00h,3ah,07h,0f0h

                psect   text

                global  start

start:          im      1
                di
                ld      sp,Stack
                ld      a,b
                ld      (OurDevice),a           ; save device ID
                ld      a,3
                call    switch_mem              ; switch in OS7
                ld      hl,0
                ld      de,4000h
                xor     a
                call    fill_vram               ; clear video RAM
                ld      hl,vdp_regs
                ld      b,0
                ld      e,8
init_vdp_loop:  ld      c,(hl)                  ; set VDP registers
                call    vdp_out
                inc     b
                inc     hl
                dec     e
                jr      nz,init_vdp_loop
1:              ld      a,(OurDevice)
                ld      de,OptionsFile
                ld      hl,OptionsFileInfo
                call    query_file
                jr      nz,1b
1:              ld      a,(OurDevice)
                ld      de,ChallengeFile
                ld      hl,ChallengeFileInfo
                call    query_file
                jr      nz,1b
1:              ld      a,(OurDevice)
                ld      de,TrainerFile
                ld      hl,TrainerFileInfo
                call    query_file
                jr      nz,1b
                ld      hl,LoaderStart
                ld      de,LoaderBuffer
                ld      bc,LoaderEnd-LoaderStart
                ldir                            ; copy loader to unused RAM
                jp      LoaderBuffer            ; jump to it

LoaderStart:    ld      de,0
Loader:         ld      ix,OptionsFileInfo
                call    LoadFile-LoaderStart+LoaderBuffer
                ld      ix,TrainerFileInfo
                ld      a,e
                or      a
                jr      z,1f
                ld      ix,ChallengeFileInfo
1:              push    de
                call    LoadFile-LoaderStart+LoaderBuffer
                pop     de
                jr      Loader

LoadFile:       push    de
                ld      e,(ix+13)               ; BCDE=start block
                ld      d,(ix+14)
                ld      c,(ix+15)
                ld      b,(ix+16)
                ld      l,(ix+19)               ; IY=number of blocks
                ld      h,(ix+20)
                push    hl
                pop     iy
                ld      hl,8000h                ; HL=load address
1:              push    bc
                push    de
                push    hl
                push    iy
                ld      a,(OurDevice)
                call    read_block
                pop     iy
                pop     hl
                pop     de
                pop     bc
                jr      nz,1b
                inc     h                       ; HL+=1024
                inc     h
                inc     h
                inc     h
                inc     de                      ; BCDE++
                ld      a,e
                or      d
                jr      nz,2f
                inc     bc
2:              dec     iy                      ; IY--
                push    iy
                exx
                pop     hl
                ld      a,l
                or      h
                exx
                jr      nz,1b
                pop     bc                      ; main() argument
                ld      hl,(800ah)
                push    hl
                ld      hl,LoaderRet-LoaderStart+LoaderBuffer
                ret
LoaderRet:      ld      bc,01c2h                ; disable interrupts
                call    vdp_out
                di
                call    all_sound_off
                ret
LoaderEnd:

                end
