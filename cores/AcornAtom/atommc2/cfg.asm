;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *PBD ([val])
;
; *PBD      - Print the current port B direction register in hex.
; *PBD 7F   - Set the direction register.
;
; Port B is 8 bits wide and each bit's direction is independently controllable.
; A set bit in the direction register indicates an 1nput and a clear bit represents
; an 0utput.
;
STARPBD:
   lda   #CMD_GET_PORT_DDR
   sta   $ce
   jmp   do_cfg_cmd


;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *PBV ([val])
;
; *PBV      - Print the state of port B in hex.
; *PBV 7F   - Write value to port B.
;
; If a port B bit is set as an input, you will read the value present on the port.
; If it is an output you will see the last value written to it.
;
STARPBV:
   lda   #CMD_READ_PORT
   sta   $ce
   jmp   do_cfg_cmd



;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~;~~
;
; *CFG ([val])
;
; *CFG      - Print the current port B direction register in hex.
; *CFG NN   - Set the config byte to the specified hex value.
;
; Bit 7 controls whether the boot loader is entered. 1 = enter, 0 = don't enter.
;     6 controls the action of the SHIFT key on boot. 1 = SHIFT+BREAK runs menu, 0 = menu runs unless SHIFT-BREAK pressed.
;     5 controls whether the interface generates an IRQ on reset. 1 = generate, 0 = don't.
;

STARCFG:
   lda   #CMD_GET_CFG_BYTE
   sta   $ce

   ; fall into ...

;
; do_cmd_cfg: is used by *CFG, *PBD and *PBV
;
; It rlies on the set port code having a function code one more than the get port code :
;
; get 				value		set					value
; CMD_GET_PORT_DDR 	$A0			CMD_SET_PORT_DDR	$A1
; CMD_READ_PORT		$A2			CMD_WRITE_PORT		$A3
; CMD_GET_CFG_BYTE	$F0			CMD_SET_CFG_BYTE	$F1
;

do_cfg_cmd:
   ldx   			#$cb             ; scan parameter - print existing val if none
   jsr   			RDOPTAD
   bne   			@param1valid

   lda   			$ce  			; read config register
   FASTCMD
   jsr   			HEXOUT
   jmp   			OSCRLF

@param1valid:
   lda   			$cb				; get read parameter
   writeportFAST   	ALATCH_REG		; $b40e ; latch the value
   jsr   			interwritedelay
   ldx   			$ce             ; Load function code
   inx								; change get code to put
   txa
   writeportFAST   	ACMD_REG		; $b40f
   rts
