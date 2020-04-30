
	.module joy
	.optsdcc -mz80

	.area	_CODE

; Acesso a 0x80 seleciona leitura do keypad
; Acesso a 0xC0 seleciona leiura do joystick
; Ler 0xFC faz leitura do joy 1
; Ler 0xFF faz leitura do joy 2
;
; Ao ler um joy, retorna:
; 7  6  5  4  3  2  1  0
; 0  p6 p7 1  p3 p2 p4 p1
;
; Para joystick:
; p7 = Quadratura, sempre '1'
; p6 = Tiro 1
; p4 = RIGHT
; p3 = LEFT
; p2 = DOWN
; p1 = UP
;
; Para keypad:
; p7 = Quadratura, sempre '1'
; p6 = Tiro 2
; p4 = codigo tecla
; p3 =   "      "
; p2 =   "      "
; p1 =   "      "
;

IO_KP_Select = 0x80			; Keypad select output port
IO_Joy_Select = 0xC0		; Joystick select output port
IO_Joy1 = 0xFC				; Joystick 1 input port
IO_Joy2 = 0xFF				; Joystick 2 input port

; ------------------------------------------------
; Ler joystick
; ------------------------------------------------
; unsigned char ReadJoy()

_ReadJoy::
	out		(IO_Joy_Select), a 			; Select joystick mode
	in		a, (IO_Joy1)				; Read joystick 1
	cpl
	and		#0x4F
	ld		l, a
	ret
