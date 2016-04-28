;=================================================================
; INT.INC
; #Axxx command interpreter
;=================================================================

.DEFINE NAME_VERSION    "FPGA UTILS V0.24"

;=================================================================
; Constant DECLARATION
;=================================================================

CLOCK		= 16000000

;=================================================================
; VARIABLE DECLARATION
;=================================================================

stackpointer	= $4		; Standard Atom address
stack1		= $16
stack2		= $25
stack3		= $34
stack4		= $43
tmp_ptr3	= $D5
tmp_ptr5	= $D6
tmp_ptr6	= $D7
cursor_hpos     = $E0		; Cursor horizontal position
shadowl     	= $FD		; Shadow ROM Latch


; Used by FLASH command
src         	= $80
dst         	= $82
bank        	= $84

; Used by UPLOAD/DNLOAD/CRC commands

start           = $80
mem         	= $82
ptr		= $84
mycrc         	= $86
fcrc	    	= $88
tmpa        	= $8a

dlg_buffer	= $140

wrcvec		= $208
rdcvec		= $20A

;; TODO: Probaly need to change these....
relocate    	= $2800
ramCrcTableLo 	= $3A00
ramCrcTableHi 	= $3B00

romstart    	= $A000
romend      	= $B000

PORTC       	= $b002
DATA        	= $bdb0
STATUS      	= $bdb1
DIVIDER_LO  	= $bdb2
DIVIDER_HI  	= $bdb3
romlatch    	= $BFFF

next_param	= $C231		; OS calls
read_text	= $CEB1
read_param	= $C8BC
no_com		= $C558
command_error	= $F926

skip_spc	= $F876

prtdec		= $C589
prttxt		= $F7D1
prtspc		= $F7FD
prthex		= $F802
prtdigit	= $F80B

OSRDCH          = $FFE3
OSWRCH		= $FFF4
OSCRLF          = $FFED


;=================================================================
; Constants used by oswrch80
;=================================================================

NUMROWS = 40
NUMCOLS = 80

SCREEN = $8000
SCREENEND = SCREEN + (NUMROWS - 1) * NUMCOLS

; Send character in accumulator to the VIA
LFEFB = $FEFB

; Wait 0.1 second for debounce
LFB8A = $fB8A
	
; Scan keyboard	
LFE71 = $FE71

; Keyboard Control Code Handlers
; use Kernel for all except cursor handling (FDA2)
LFD9A = $FD9A
LFDC0 = $FDC0
LFDC2 = $FDC2
LFDC6 = $FDC6
LFDC8 = $FDC8
LFDD2 = $FDD2
LFDD6 = $FDD6
LFDD8 = $FDD8
LFDDF = $FDDF
LFDE2 = $FDE2

; Flyback
LFE66 = $FE66
LFE6B = $FE6B

;=================================================================
; ROM IDENTIFIER
;=================================================================

romid:
	.byte $40,$BF

;=================================================================
; COMMAND INTERPRETER
;=================================================================

comint:
	LDX #$FF		; Set up pointers
comint1:
	LDY $5E
	DEY
comint2:
	INX
	INY
comint3:
	LDA com_tab,X		; Lookup command
	BMI comint5
	CMP ($05),Y
	BEQ comint2
comint4:
	INX
	LDA com_tab-1,X
	BPL comint4
	LDA  ($05),Y
	CMP #'.'
	BNE comint1
	INY
	DEX
	BCS comint3
comint5:
	STY $3			; Store addresspointer
	STA $53
	LDA com_tab+1,X
	STA $52
	LDX #0
	STX $4
	JSR comint6		; Execute command
	LDX #0
	STX $4
	JMP no_com
comint6:
	JMP ($0052)


;=================================================================
; COMMAND TABLE
;=================================================================

com_tab:

	.byte "FHELP"
	.byte >fpgahelp,<fpgahelp

	.byte "BAUD"
	.byte >baud,<baud

	.byte "SINOUT"
	.byte >sinout,<sinout

	.byte "SIN"
	.byte >sin,<sin

	.byte "SOUT"
	.byte >sout,<sout

	.byte "UPLOAD"
	.byte >upload,<upload

	.byte "DNLOAD"
	.byte >download,<download

	.byte "CRC"
	.byte >atomCRC,<atomCRC

	.byte "RLIST"
	.byte >roms,<roms

	.byte "FLASH"
	.byte >flash,<flash

	.byte "BEEB"
	.byte >beeb,<beeb

	.byte "VGA80"
	.byte >vga80,<vga80

	.byte >no_com,<no_com 	; No command

;=================================================================
; HELP TABLE
;=================================================================

help_tab:
	; FHELP
    	.byte 0

	; Baud
	.byte "<BAUD RATE>",0

	; Sinout
	.byte 0

	; Sin
	.byte 0

	; Sout
	.byte 0

	; Upload
	.byte "<START>,<END>",0

	; Download
	.byte "<START>",0

    	; Crc
	.byte "<START>,<END>",0

	; Roms
	.byte 0

	; Flash
	.byte "<START>,<BANK>",0

	; Beeb
	.byte 0

	; Vga80
	.byte 0

;=================================================================
; Command parser helper routines
;=================================================================

read_start_end:
	JSR read_param
	JSR next_param
	JSR read_param
	JSR next_param

	LDA stack1
	STA start
	LDA stack2
	STA start + 1

	LDA stack1 + 1
	STA mem
	LDA stack2 + 1
	STA mem + 1
	RTS

;=================================================================
; Print out own version
;=================================================================

print_name_version:
	JSR prttxt
	.byte NAME_VERSION
	NOP
	RTS

