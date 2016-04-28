
	.file "premain.s"

; Define weak linkage for _premain, so that it can be overridden
	.section ".text","ax"
	.weak _premain
_premain:
	;	clear BSS data, then call main.

	im __bss_start__	; bssptr
.clearloop:
	loadsp 0			; bssptr bssptr 
	im __bss_end__		; __bss_end__  bssptr bssptr
	ulessthanorequal	; (bssptr<=__bss_end__?) bssptr
	impcrel .done		; &.done (bssptr<=__bss_end__?) bssptr
	neqbranch			; bssptr
	im 0				; 0 bssptr
	loadsp 4			; bssptr 0 bssptr
	loadsp 0			; bssptr bssptr 0 bssptr
	im 4				; 4 bssptr bssptr 0 bssptr
	add					; bssptr+4 bssptr 0 bssptr
	storesp 12			; bssptr 0 bssptr+4
	store				; (write 0->bssptr)  bssptr+4
	im .clearloop		; &.clearloop bssptr+4
	poppc				; bssptr+4
.done:
	im _break			; &_break bssptr+4
	storesp 4			; &_break
	im main				; &main &break
	poppc				; &break
	

