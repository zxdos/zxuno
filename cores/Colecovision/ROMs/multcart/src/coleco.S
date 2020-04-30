	.module coleco_funcs
	.optsdcc -mz80
	.globl	nmi_flag

	.area	_CODE

;***************************************
; de = string ptr
; returns len in hl (max 255)
strlen0:
	ld		hl, #0
again:
	ld		a, (de)
	or		a
	ret	z
	inc		hl
	inc		de
	jr		again

;*********** CALC_OFFSET ************
; INPUT : d = y, e = x;
; OUTPUT : de = NAME + y * 32 + x;
calc_offset:
	call	0x08C0						; calc offset by Coleco bios
	ld		hl, (0x73f6)				; hl = Name Table Offset
	add		hl, de
	ex		de, hl						; de = NAME + y * 32 + x
	ret

;---------------------------------------
; void vdp_init()
;---------------------------------------
_vdp_init::
	push  ix
	call     0x18e9
	pop ix
	ret

;---------------------------------------
; void cls()
;---------------------------------------
_cls::
	push	ix
	ld		hl, (0x73F6)
	ld		de, #0x0300					; de = 300h
	ld   	a, #32						;a = chr(32)
	call	0x1F82
	pop		ix
	ret

;---------------------------------------
; void delay (unsigned icount)
;---------------------------------------
_delay::
	ld		iy, #0
	add		iy, sp
	ld		e, 2(iy)	; icount<
	ld		d, 3(iy)	; icount>

	ld      a, (0x73c4)       ; check if NMI enabled
	and     #0x20
	jr z,	s3
s1:
	ld      a, e             ; NMI enabled, check _nmi_flag
	or      d
	jr z,	exit
	xor     a
	ld      (nmi_flag), a
s2:
	ld      a, (nmi_flag)
	or      a
	jr z,	s2
	dec     de
	jr      s1
s3:
	call    0x1fdc           ; NMI disabled, check VDP status
s4:
	ld      a, e
	or      d
	;ret    z
	jr z,	exit
s5:
	call    0x1fdc
	rlca
	jr nc,	s5
	dec     de
	jr      s4
exit:
	ret

;---------------------------------------
; void load_ascii()
;---------------------------------------
_load_ascii::
	push  ix
	call  0x1f7f
	pop   ix
	ret

;---------------------------------------
; void enable_nmi()
;---------------------------------------
_enable_nmi::
	push  	ix
	ld      a, (0x73c4)
	or      #0x20
	ld      c, a
	ld      b, #1
	call    0x1fd9
	call    0x1fdc
	pop   	ix
	ret

;---------------------------------------
; void disable_nmi()
;---------------------------------------
_disable_nmi::
	push	ix
	ld      a,(0x73c4)
	and     #0xdf
	ld      c, a
	ld      b, #1
	call    0x1fd9
	pop	ix
	ret

;---------------------------------------
;void print_at(unsigned char x, unsigned char y, char *text);
;---------------------------------------
_print_at::
	ld		iy, #0
	add		iy, sp
	ld		e, 2(iy)	; x
	ld		d, 3(iy)	; y

	; E=X, D=Y
	; DE = YX before enter calclc_offset
	call	calc_offset					; de = offset
	push    de
	ld		e, 4(iy)	; text
	ld		d, 5(iy)	; text
	call	strlen0
	ld		b, #0
	ld		c, l						; bc=count
	ld		l, 4(iy)	; text
	ld		h, 5(iy)	; text
	pop		de
	ld		a, c
	call	0x1fdf
	ret

;---------------------------------------
; Read a joystick or keypad controller and a fire button
;
; ENTRY	H = 0 for left control, 1 for right control
; 	L = 0 for joystick/left fire, 1 for keypad/right fire
; EXIT:	H = left right fire button in 40H bit and 80H bit
;	L = joystick directionals or key code
;	E = old pulse counter (only if L=0)
;---------------------------------------
; unsigned int read_joy(unsigned char H)
;---------------------------------------
_read_joy::
	ld		iy, #0
	add		iy, sp
	call    0x1f76						; readctl_raw
	ld		h, 2(iy)
	ld      l, #0						; check left fire button
	call    0x1f79
	push    hl
	ld      h, 2(iy)
	ld      l, #1						; check right fire button
	call    0x1f79
	ld      a, h
	rla									; make right fire button 0x80
	pop     hl
	or      h
	ld      h, a
	ret

;---------------------------------------
; void screen_on()
;---------------------------------------
_screen_on::
	push	ix
	ld		a, (0x73c4)
	or		#0x40
	ld      c, a
	ld      b, #1
	call	0x1fd9
	pop		ix
	ret

;---------------------------------------
; void screen_off()
;---------------------------------------
_screen_off::
	push	ix
	ld		a, (0x73c4)
	and		#0xBF
	ld      c, a
	ld      b, #1
	call	0x1fd9
	pop		ix
	ret

;---------------------------------------
; void set_mode1()
;---------------------------------------
_set_mode1::
	push	ix
	call	0x1f85
	pop		ix
	ret

;---------------------------------------
; void set_color(unsigned char color)
;---------------------------------------
_set_color::
	ld		iy, #0
	add		iy, sp
	ld		a, 2(iy)
	ld		hl, #0x2000
	ld		de, #32
	call	0x1f82
	ret

;---------------------------------------
; void fill_vram(unsigned char x)
;---------------------------------------
_fill_vram::
	ld		iy, #0
	add		iy, sp
	ld		a, 2(iy)
	ld		hl, #0
	ld		de, #0x4000
	call	0x1f82
	ret

;---------------------------------------
; void init_sound(sound_t *snd_table)
;---------------------------------------
_init_sound::
	push	ix
	ld		iy, #0
	add		iy, sp
	ld		l, 2(iy)
	ld		h, 3(iy)
	ld		(snd_table), hl
	ld		b, #7
	call	0x1fee						; init snd_areas and snd_addr + all sound off
	pop		ix
	ret

;---------------------------------------
; void play_sound(unsigned char sound_number)
;---------------------------------------
_play_sound::
	push	ix
	ld		iy, #0
	add		iy, sp
	ld		b, 2(iy)
	call	0x1ff1
	pop		ix
	ret

;---------------------------------------
; void stop_sound(unsigned char sound_number)
;---------------------------------------
_stop_sound::
	push	ix
	ld		iy, #0
	add		iy, sp
	ld		a, 2(iy)
	ld		b, a						; b = song#
	ld		hl, (snd_table)
	dec		hl
	dec		hl
	ld		de, #4						; calculate the right sound slot
$1:
	add		hl, de
	djnz	$1
	ld		b, a						; b = song#
	ld		e, (hl)
	inc		hl
	ld		d, (hl)
	ex		de, hl
	ld		a, (hl)						; get the song# currently in the sound slot
	and		#7
	cp		b							; compare with the song# we are looking for
	jr nz,	$2							; if not the same song# -> do nothing
	ld		(hl), #0xFF
$2:
	pop		ix
	ret


	.area _DATA

snd_table:
	.ds		2
