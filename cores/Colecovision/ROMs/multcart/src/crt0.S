;--------------------------------------------------------------------------
;  crt0.s - Generic crt0.s for a Z80
;
;  Copyright (C) 2000, Michael Hope
;
;  This library is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by the
;  Free Software Foundation; either version 2, or (at your option) any
;  later version.
;
;  This library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License 
;  along with this library; see the file COPYING. If not, write to the
;  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;
;  As a special exception, if you link this library with other files,
;  some of which are compiled with SDCC, to produce an executable,
;  this library does not by itself cause the resulting executable to
;  be covered by the GNU General Public License. This exception does
;  not however invalidate any other reasons why the executable file
;   might be covered by the GNU General Public License.
;--------------------------------------------------------------------------

	.module crt0
	.globl	_main
	.globl	_nmi
	.globl  l__INITIALIZER
	.globl  s__INITIALIZED
	.globl  s__INITIALIZER

	.area	_HEADER (ABS)

	.org 	0x8000

	; colecovision
	.db		0x55, 0xAA					; no default colecovision title screen => 55 AA
;	.db		0xAA, 0x55					; default colecovision title screen
	.dw		0							; no copy of sprite table, etc.
	.dw		0							; all unused
	.dw		buffer32					; work buffer
	.dw		0							; joystick?
	.dw		startpoint					; start address for game coding
	.db		0xC9, 0x00, 0x00			; no RST 08 support
	.db		0xC9, 0x00, 0x00			; no RST 10 support
	.db		0xC9, 0x00, 0x00			; no RST 18 support
	.db		0xC9, 0x00, 0x00			; no RST 20 support
	.db		0xC9, 0x00, 0x00			; no RST 28 support
	.db		0xC9, 0x00, 0x00			; no RST 30 support
	.db		0xC9, 0x00, 0x00			; no RST 38 support  (spinner)
	jp		nmi_asm
;	.ascii	"FBLABS/MULTICART/2016"

nmi_asm:
	push    ix        
	push    hl
	push    de
	push    bc
	push	af
	ld		a, #1
	ld      (nmi_flag), a				; set NMI flag
	call    0x1fdc						; get VDP status
	ld      (vdp_status),a
    ld      a, (no_nmi)					; check if nmi() should be
    or      a							;  called
    jp      nz, nmi_exit
    inc     a
    ld      (no_nmi), a
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
    call    0x1f76						; update controllers
    ld      a,(0x73ee)
    and		#0x4f
    ld      (joypad_1), a
    ld      a, (0x73ef)
    and		#0x4f
    ld      (joypad_2), a
    ld      a, (0x73f0)
    and		#0x4f
    ld      (keypad_1), a
    ld      a, (0x73f1)
    and		#0x4f
    ld      (keypad_2), a
    call    decode_controllers
    call    _nmi						; call C function
    call    0x1f61						; play sounds
    call    0x1ff4						; update snd_addr with snd_areas
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
    ld      (no_nmi), a
nmi_exit:
    pop     af
    pop     bc
    pop     de
    pop     hl
    pop     ix
    ret
    ;ei      ; optional
    ;reti    ; ret ?

keypad_table::
	.db		0xff,8,4,5,0xff,7,11,2,0xff,10,0,9,3,1,6,0xff

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
	ld      ix, #joypad_1
	call    decode_controller
	inc     ix
	inc     ix
decode_controller:
	ld      a, 0(ix)
	ld      b, a
	and     #0x40
	rlca
	ld      c, a
	ld      a, b
	and     #0x0f
	or      c
	ld      b, a
	ld      a, 1(ix)
	ld      c, a
	and     #0x40
	or      b
	ld      1(ix), a
	ld      a, c
	cpl
	and     #0x0f
	ld      e, a
	ld      d, #0
	ld      hl, #keypad_table
	add     hl, de
	ld      a, (hl)
	ld      1(ix), a
	ret

startpoint:
	ld		sp, #0x7FFF						;; Stack at the top of memory.
	di
	;; Initialise global variables
	call    gsinit
	call	_main
	jp		_exit

	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER

	.area   _GSINIT
	.area   _GSFINAL

	.area	_DATA

nmi_flag::
	.ds		1
no_nmi::
	.ds		1
vdp_status:
	.ds		1
joypad_1:
	.ds		1
keypad_1:
	.ds		1
joypad_2:
	.ds		1
keypad_2:
	.ds		1
buffer32:
	.ds		32

	.area	_INITIALIZED

	.area	_BSEG
	.area   _BSS
	.area   _HEAP

	.area   _CODE

_exit::
1$:
	halt
	jr	1$

	.area   _GSINIT
gsinit::
	ld	bc, #l__INITIALIZER
	ld	a, b
	or	a, c
	jr	z, gsinit_next
	ld	de, #s__INITIALIZED
	ld	hl, #s__INITIALIZER
	ldir
gsinit_next:
	.area   _GSFINAL
	ret
