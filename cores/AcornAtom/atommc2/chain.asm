;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CHAIN [filename]
;
; Loads specified Basic file to memory and runs it.
;
STARCHAIN:
  jsr STARLOAD

	jsr @findprogramend
	lda $70
	sta $0d
	sta $23
	lda $71
	sta $0e
	sta $24
	jmp $ce86

@findprogramend:
	lda $12
	sta $71
	ldy #0
	sty $70
LAEE1:
	ldy $3
LAEE3:
	lda ($70),y
	iny
	cmp #$0d
	bne LAEE3
	dey
	clc
	tya
	adc $70
	sta $70
	bcc LAEF5
	inc $71
LAEF5:
	ldy #1
	lda ($70),y
	bpl LAEE1
	clc
	lda $70
	adc #2
	sta $70
	bcc LAF06
	inc $71
LAF06:
	rts
