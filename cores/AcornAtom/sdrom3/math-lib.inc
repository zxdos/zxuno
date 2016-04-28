;------------------------------------------------
; MATH-LIB.INC
; v00.00
;------------------------------------------------

;------------------------------------------------
; 6502 Standard Macro Library
;------------------------------------------------
; Copyright (C),1999 Andrew John Jacobs.
; All rights reserved.
;------------------------------------------------

;------------------------------------------------
; Revision History:
;
; 16-Aug-99 AJJ	Initial version.
;
; 14-Nov-01 AJJ Finally got around to filling in
;		some missing comments.
;
;------------------------------------------------

; Notes:
;
; This file contains a number of useful 6502
; algorithms for number, string and memory
; operations. The code is written in the form of
; macros rather than subroutines to make them
; more flexible.
;
; The routines in the library assume that 16 and
; 32 bit numbers are represented in little endian
; order, that is the least significant byte in
; the lowest memory location, so that they can
; be applied to addresses as well as pure
; numbers.
;
; The string routines assume that they are
; working with null terminated 'C' style strings.
;
; The main routines sacrifice code size for speed
; and are coded without any iteration. Compact
; versions which use iteration are provided for
; some algorithms and have the same name as the
; original routine with a 'C' suffix (eg. _XFR32
; => _XFR32C).
;
; Some of the macros use 65SC02 instructions for
; speed or to reduce the amount code generated if
; the assembler will accept them.
;
; Where possible the macros detect optimizable
; cases and generate more efficient code.
;
; Bugs & Enhancments:
;
; If you find a bug I missed or have a new
; routine you would like to submit to the library
; then mail me at:
;
; Andrew@obelisk.demon.co.uk

;------------------------------------------------
; Basic Operations
;------------------------------------------------

; Clear 2 bytes of memory at any location by
; setting it to zero. If 65SC02 instructions are
; available then STZ is used.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CLR16	MEM
		 LDA #0
		 STA MEM+0
		 STA MEM+1
.endmacro

; Clear 4 bytes of memory at any location by
; setting it to zero. If 65SC02 instructions are
; available then STZ is used.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CLR32	MEM
		 LDA #0
		 STA MEM+0
		 STA MEM+1
		 STA MEM+2
		 STA MEM+3
.endmacro

; Clear 4 bytes of memory at any location by
; setting it to zero iteratively. If 65SC02
; instructions are available then STZ is used.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _CLR32C	MEM
		 LDA #0
		 LDX #3
_LOOP#	 STA MEM,X
		 DEX
		 BPL _LOOP#
.endmacro

; Transfer 2 bytes of memory from one location to
; another using the accumulator. The order in
; which the bytes are moved depends on the
; relative positions of SRC and DST. If SRC and
; DST are the same then no code is generated.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _XFR16	 SRC,DST
	.IF (SRC-DST)==0
    .ELSE
		 .IF (SRC-DST)>>0
		  LDA SRC+0
		  STA DST+0
		  LDA SRC+1
		  STA DST+1
		 .ELSE
		  LDA SRC+1
		  STA DST+1
		  LDA SRC+0
		  STA DST+0
		 .ENDIF
	.ENDIF
.endmacro

; Transfer 2 bytes of memory from one location to
; another 4 bytes location using the accumulator.
; If SRC and DST are the same then no code is
; generated.
; On exit: A = ??, X & Y are unchanged.

.MACRO _XFR16X	 SRC,DST
	.IF (SRC-DST)==0
    .ELSE
		  LDA SRC+0
		  STA DST+0
		  LDA SRC+1
		  STA DST+1
		  LDA #0
		  STA DST+2
		  STA DST+3
	.ENDIF
.endmacro

; Transfer 4 bytes of memory from one location to
; another using the accumulator. The order in
; which the bytes are moved depends on the
; relative positions of SRC and DST. If SRC and
; DST are the same then no code is generated.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _XFR32	 SRC,DST
	.IF (SRC-DST)==0
    .ELSE
		.IF (SRC-DST)>>0
		  LDA SRC+0
		  STA DST+0
		  LDA SRC+1
		  STA DST+1
		  LDA SRC+2
		  STA DST+2
		  LDA SRC+3
		  STA DST+3
		.ELSE
		  LDA SRC+3
		  STA DST+3
		  LDA SRC+2
		  STA DST+2
		  LDA SRC+1
		  STA DST+1
		  LDA SRC+0
		  STA DST+0
		.ENDIF
 	.ENDIF
.endmacro

; Transfer 4 bytes of memory from one location to
; another iteratively using the accumulator. The
; transfer may fail if SRC and DST overlap. If
; SRC and DST are the same then no code is
; generated.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _XFR32C	 SRC,DST
	.IF (SRC-DST)==0
    .ELSE
		 LDX #3
_LOOP#	 LDA SRC,X
		 STA DST,X
		 DEX
		 BPL _LOOP#
	.ENDIF
.endmacro

; Set the value of a 16 bit location DST with
; the given constant value.
;
; On exit: A = ??, X & Y unchanged.

.MACRO _SET16I	 NUM,DST
		.IF NUM != 0
		 LDA #<NUM
		 STA DST+0
		 LDA #>NUM
		 STA DST+1
		.ELSE
		 _CLR16 DST
		.ENDIF

.endmacro


; Set the value of a 32 bit location DST with
; the given constant value.
;
; On exit: A = ??, X & Y unchanged.

.MACRO _SET32I	 NUM,DST
		.IF NUM != 0
		 LDA #<NUM
		 STA DST+0
		 LDA #<(NUM/$100)
		 STA DST+1
		 LDA #<(NUM/$10000)
		 STA DST+2
		 LDA #<(NUM/$1000000)
		 STA DST+3
		.ELSE
		 _CLR32 DST
		.ENDIF

.endmacro

;------------------------------------------------
; Logical Operations
;------------------------------------------------

; Calculate the logical NOT of the 16 bit value
; at location VLA and stores it in location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _NOT16	 VLA,RES
		LDA VLA+0
		EOR #$FF
		STA RES+0
		LDA VLA+1
		EOR #$FF
		STA RES+1
.endmacro

; Calculate the logical NOT of the 32 bit value
; at location VLA and stores it in location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _NOT32	 VLA,RES
		LDA VLA+0
		EOR #$FF
		STA RES+0
		LDA VLA+1
		EOR #$FF
		STA RES+1
		LDA VLA+2
		EOR #$FF
		STA RES+2
		LDA VLA+3
		EOR #$FF
		STA RES+3
.endmacro

; Calculate the logical NOT of the 32 bit value
; at location VLA iteratively and stores it in
; location RES.
;
; On exit: A = ??, X = $FF, Y are unchanged.

.MACRO _NOT32C	 VLA,RES
		LDX #3
_LOOP#		LDA VLA,X
		EOR #$FF
		STA RES,X
		DEX
		BPL _LOOP#
.endmacro

; Calculate the logical OR of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR16.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ORA16	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _XFR16 VLA,RES
    .ELSE
		 LDA VLA+0
		 ORA VLB+0
		 STA RES+0
		 LDA VLA+1
		 ORA VLB+1
		 STA RES+1
	.ENDIF
.endmacro

; Calculate the logical OR of a 16 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ORA16I	 VLA,NUM,RES
		 LDA VLA+0
		 ORA #<NUM
		 STA RES+0
		 LDA VLA+1
		 ORA #>NUM
		 STA RES+1
.endmacro

; Calculate the logical OR of the two 32 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR32.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ORA32	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _XFR32 VLA,RES
	.ELSE
		 LDA VLA+0
		 ORA VLB+0
		 STA RES+0
		 LDA VLA+1
		 ORA VLB+1
		 STA RES+1
		 LDA VLA+2
		 ORA VLB+2
		 STA RES+2
		 LDA VLA+3
		 ORA VLB+3
		 STA RES+3
	.ENDIF
.endmacro

; Calculate the logical OR of the two 32 bit
; values at locations VLA and VLB iteratively.
; The result is stored in location RES. If VLA
; and VLB are the same the macro expands to a
; _XFR32C.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _ORA32C	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _XFR32C VLA,RES
	.ELSE
		 LDX #3
_LOOP#	 LDA VLA,X
		 ORA VLB,X
		 STA RES,X
		 DEX
		 BPL _LOOP#
	.ENDIF
.endmacro

; Calculate the logical OR of a 32 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ORA32I	 VLA,NUM,RES
		 LDA VLA+0
		 ORA #<NUM
		 STA RES+0
		 LDA VLA+1
		 ORA #<(NUM/$100)
		 STA RES+1
		 LDA VLA+2
		 ORA #<(NUM/$10000)
		 STA RES+2
		 LDA VLA+3
		 ORA #<(NUM/$1000000)
		 STA RES+3
.endmacro

; Calculate the logical AND of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR16.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _AND16	 VLA,VLB,RES
	.IF (VLA-VLB)
		 _XFR16 VLA,RES
	.ELSE
		 LDA VLA+0
		 AND VLB+0
		 STA RES+0
		 LDA VLA+1
		 AND VLB+1
		 STA RES+1
	.ENDIF
.endmacro

; Calculate the logical AND of a 16 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _AND16I	 VLA,NUM,RES
		 LDA VLA+0
		 AND #<NUM
		 STA RES+0
		 LDA VLA+1
		 AND #>NUM
		 STA RES+1
.endmacro

; Calculate the logical AND of the two 32 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR32.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _AND32	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _XFR32 VLA,RES
	.ELSE
		 LDA VLA+0
		 AND VLB+0
		 STA RES+0
		 LDA VLA+1
		 AND VLB+1
		 STA RES+1
		 LDA VLA+2
		 AND VLB+2
		 STA RES+2
		 LDA VLA+3
		 AND VLB+3
		 STA RES+3
	.ENDIF
.endmacro

; Calculate the logical AND of the two 32 bit
; values at locations VLA and VLB iteratively.
; The result is stored in location RES. If VLA
; and VLB are the same the macro expands to a
; _XFR32C.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _AND32C	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _XFR32C VLA,RES
	.ELSE
		 LDX #3
_LOOP#	 	LDA VLA,X
		 AND VLB,X
		 STA RES,X
		 DEX
		 BPL _LOOP#
	.ENDIF
.endmacro

; Calculate the logical AND of a 32 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _AND32I	 VLA,NUM,RES
		 LDA VLA+0
		 AND #<NUM
		 STA RES+0
		 LDA VLA+1
		 AND #<(NUM/$100)
		 STA RES+1
		 LDA VLA+2
		 AND #<(NUM/$10000)
		 STA RES+2
		 LDA VLA+3
		 AND #<(NUM/$1000000)
		 STA RES+3
.endmacro

; Calculate the exclusive OR of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _CLR16.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _EOR16	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _CLR16 RES
	.ELSE
		 LDA VLA+0
		 EOR VLB+0
		 STA RES+0
		 LDA VLA+1
		 EOR VLB+1
		 STA RES+1
	.ENDIF
.endmacro

; Calculate the exclusive OR of a 16 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _EOR16I	 VLA,NUM,RES
		 LDA VLA+0
		 EOR #<NUM
		 STA RES+0
		 LDA VLA+1
		 EOR #>NUM
		 STA RES+1
.endmacro

; Calculate the exclusive OR of the two 32 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _CLR32.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _EOR32	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _CLR32 RES
	.ELSE
		 LDA VLA+0
		 EOR VLB+0
		 STA RES+0
		 LDA VLA+1
		 EOR VLB+1
		 STA RES+1
		 LDA VLA+2
		 EOR VLB+2
		 STA RES+2
		 LDA VLA+3
		 EOR VLB+3
		 STA RES+3
	.ENDIF
.endmacro

; Calculate the exclusive OR of the two 32 bit
; values at locations VLA and VLB iteratively.
; The result is stored in location RES. If VLA
; and VLB are the same the macro expands to a
; _XFR32C.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _EOR32C	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _CLR32C RES
	.ELSE
		 LDX #3
_LOOP#	 LDA VLA,X
		 EOR VLB,X
		 STA RES,X
		 DEX
		 BPL _LOOP#
	.ENDIF
.endmacro

; Calculate the exclusive OR of a 32 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _EOR32I	 VLA,NUM,RES
		 LDA VLA+0
		 EOR #<NUM
		 STA RES+0
		 LDA VLA+1
		 EOR #<(NUM/$100)
		 STA RES+1
		 LDA VLA+2
		 EOR #<(NUM/$10000)
		 STA RES+2
		 LDA VLA+3
		 EOR #<(NUM/$1000000)
		 STA RES+3
.endmacro

;------------------------------------------------
; Shift Operations
;------------------------------------------------

; Perform an arithmetic shift left on the 16 bit
; number at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ASL16	 VLA,RES
	.IF (VLA-RES)==0
		 ASL VLA+0
		 ROL VLA+1
	.ELSE
		 LDA VLA+0
		 ASL A
		 STA RES+0
		 LDA VLA+1
		 ROL A
		 STA RES+1
	.ENDIF
.endmacro

; Perform an arithmetic shift left on the 32 bit
; number at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ASL32	 VLA,RES
	.IF (VLA-RES)==0
		 ASL VLA+0
		 ROL VLA+1
		 ROL VLA+2
		 ROL VLA+3
	.ELSE
		 LDA VLA+0
		 ASL A
		 STA RES+0
		 LDA VLA+1
		 ROL A
		 STA RES+1
		 LDA VLA+2
		 ROL A
		 STA RES+2
		 LDA VLA+3
		 ROL A
		 STA RES+3
	.ENDIF
.endmacro

; Perform a left rotation on the 16 bit number at
; location VLA and store the result at location
; RES. If VLA and RES are the same then the
; operation is applied directly to the memory,
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ROL16	 VLA,RES
	.IF (VLA-RES)==0
		 ROL VLA+0
		 ROL VLA+1
	.ELSE
		 LDA VLA+0
		 ROL A
		 STA RES+0
		 LDA VLA+1
		 ROL A
		 STA RES+1
	.ENDIF
.endmacro

; Perform a left rotation on the 32 bit number at
; location VLA and store the result at location
; RES. If VLA and RES are the same then the
; operation is applied directly to the memory,
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ROL32	 VLA,RES
	.IF (VLA-RES)==0
		 ROL VLA+0
		 ROL VLA+1
		 ROL VLA+2
		 ROL VLA+3
	.ELSE
		 LDA VLA+0
		 ROL A
		 STA RES+0
		 LDA VLA+1
		 ROL A
		 STA RES+1
		 LDA VLA+2
		 ROL A
		 STA RES+2
		 LDA VLA+3
		 ROL A
		 STA RES+3
	.ENDIF
.endmacro

; Perform an logical shift right on the 16 bit
; number at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _LSR16	 VLA,RES
	.IF (VLA-RES)==0
		 LSR VLA+1
		 ROR VLA+0
	.ELSE
		 LDA VLA+1
		 LSR A
		 STA RES+1
		 LDA VLA+0
		 ROR A
		 STA RES+0
	.ENDIF
.endmacro

; Perform an logical shift right on the 32 bit
; number at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _LSR32	 VLA,RES
	.IF (VLA-RES)==0
		 LSR VLA+3
		 ROR VLA+2
		 ROR VLA+1
		 ROR VLA+0
	.ELSE
		 LDA VLA+3
		 LSR A
		 STA RES+3
		 LDA VLA+2
		 ROR A
		 STA RES+2
		 LDA VLA+1
		 ROR A
		 STA RES+1
		 LDA VLA+0
		 ROR A
		 STA RES+0
	.ENDIF
.endmacro

; Perform a right rotation on the 16 bit number
; at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ROR16	 VLA,RES
	.IF (VLA-RES)==0
		 ROR VLA+1
		 ROR VLA+0
	.ELSE
		 LDA VLA+1
		 ROR A
		 STA RES+1
		 LDA VLA+0
		 ROR A
		 STA RES+0
	.ENDIF
.endmacro

; Perform a right rotation on the 32 bit number
; at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ROR32 VLA,RES
	.IF (VLA-RES)==0
		 ROR VLA+3
		 ROR VLA+2
		 ROR VLA+1
		 ROR VLA+0
	.ELSE
		 LDA VLA+3
		 ROR A
		 STA RES+3
		 LDA VLA+2
		 ROR A
		 STA RES+2
		 LDA VLA+1
		 ROR A
		 STA RES+1
		 LDA VLA+0
		 ROR A
		 STA RES+0
	.ENDIF
.endmacro

;------------------------------------------------
; Arithmetic Operations
;------------------------------------------------

; Increment the 16 bit value at location MEM
; by one.
;
; On exit: A, X & Y are unchanged.

.MACRO _INC16	 MEM
		INC MEM+0
		BNE _DONE#
		INC MEM+1
_DONE#	EQU *
.endmacro

; Increment the 32 bit value at location MEM
; by one.
;
; On exit: A, X & Y are unchanged.

.MACRO _INC32	 MEM
		INC MEM+0
		BNE _DONE#
		INC MEM+1
		BNE _DONE#
		INC MEM+2
		BNE _DONE#
		INC MEM+3
_DONE#	EQU *
.endmacro

; Decrement the 16 bit value at location MEM
; by one.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _DEC16	 MEM
		LDA MEM+0
		BNE _DONE#
		DEC MEM+1
_DONE#	DEC MEM+0
.endmacro

; Decrement the 32 bit value at location MEM
; by one.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _DEC32	 MEM
		LDA MEM+0
		BNE _DEC0#
		LDA MEM+1
		BNE _DEC1#
		LDA MEM+2
		BNE _DEC2#
		DEC MEM+3
_DEC2#	DEC MEM+2
_DEC1#	DEC MEM+1
_DEC0#	DEC MEM+0
.endmacro

; Add two 16 bit numbers together and store the
; result in another memory location. RES may be
; the same as either VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ADD16	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _ASL16 VLA,RES
	.ELSE
	 	 CLC
	 	 LDA VLA+0
		 ADC VLB+0
		 STA RES+0
		 LDA VLA+1
		 ADC VLB+1
		 STA RES+1
	.ENDIF
.endmacro

; Add a 16 bit constant NUM together with VLA
; and store the result in another memory location.
; RES may be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ADD16I	 VLA,NUM,RES
	 	 CLC
	 	 LDA VLA+0
		 ADC #<NUM
		 STA RES+0
		 LDA VLA+1
		 ADC #>NUM
		 STA RES+1
.endmacro

; Add a 32 bit memory var VLA together with a 
; 16 bit memory var VLB and store the result in
; another 32 bit memory location.
; RES may be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ADD16X	 VLA,VLB,RES
	 	 CLC
	 	 LDA VLA+0
		 ADC VLB+0
		 STA RES+0
		 LDA VLA+1
		 ADC VLB+1
		 STA RES+1
	 	 LDA VLA+2
		 ADC #0
		 STA RES+2
		 LDA VLA+3
		 ADC #0
		 STA RES+3
.endmacro

; Add two 32 bit numbers together and store the
; result in another memory location. RES may be
; the same as either VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ADD32	 VLA,VLB,RES
	.IF (VLA-VLB)==0
		 _ASL32 VLA,RES
	.ELSE
		 CLC
		 LDA VLA+0
		 ADC VLB+0
		 STA RES+0
		 LDA VLA+1
		 ADC VLB+1
		 STA RES+1
		 LDA VLA+2
		 ADC VLB+2
		 STA RES+2
		 LDA VLA+3
		 ADC VLB+3
		 STA RES+3
	.ENDIF
.endmacro

; Add a 32 bit constant to VLA and store the
; result in another memory location. RES may be
; the same as either VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ADD32I	 VLA,NUM,RES
		 CLC
		 LDA VLA+0
		 ADC #<NUM
		 STA RES+0
		 LDA VLA+1
		 ADC #<(NUM/$100)
		 STA RES+1
		 LDA VLA+2
		 ADC #<(NUM/$10000)
		 STA RES+2
		 LDA VLA+3
		 ADC #<(NUM/$1000000)
		 STA RES+3
.endmacro

; Subtract two 16 bit numbers and store the
; result in another memory location. RES may be
; the same as VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _SUB16	 VLA,VLB,RES
		SEC
		LDA VLA+0
		SBC VLB+0
		STA RES+0
		LDA VLA+1
		SBC VLB+1
		STA RES+1
.endmacro

; Subtract a 16 bit constant NUM from VLA and
; store the result in another memory location.
; RES may be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _SUB16I	 VLA,NUM,RES
		SEC
		LDA VLA+0
		SBC #<NUM
		STA RES+0
		LDA VLA+1
		SBC #>NUM
		STA RES+1
.endmacro

; Subtract a 16 bit number VLB from a 32 bit
; number VVA and store the result in a 32 bit
; another memory location.
; RES may be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _SUB16X		 VLA,VLB,RES
		SEC
		LDA VLA+0
		SBC VLB+0
		STA RES+0
		LDA VLA+1
		SBC VLB+1
		STA RES+1
		LDA VLA+2
		SBC #0
		STA RES+2
		LDA VLA+3
		SBC #0
		STA RES+3
.endmacro

; Subtract two 32 bit numbers and store the
; result in another memory location. RES may be
; the same as VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _SUB32	 VLA,VLB,RES
		SEC
		LDA VLA+0
		SBC VLB+0
		STA RES+0
		LDA VLA+1
		SBC VLB+1
		STA RES+1
		LDA VLA+2
		SBC VLB+2
		STA RES+2
		LDA VLA+3
		SBC VLB+3
		STA RES+3
.endmacro

; Subtract a 32 bit constant NUM from VLA and
; store the result in another memory location.
; RES may be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _SUB32I	 VLA,NUM,RES
		SEC
		LDA VLA+0
		SBC #<NUM
		STA RES+0
		LDA VLA+1
		SBC #<(NUM/$100)
		STA RES+1
		LDA VLA+2
		SBC #<(NUM/$10000)
		STA RES+2
		LDA VLA+3
		SBC #<(NUM/$1000000)
		STA RES+3
.endmacro

; Negate the signed 16 bit number at location VLA
; and stored the result at location RES. RES may
; be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _NEG16	 VLA,RES
		SEC
		LDA #0
		SBC VLA+0
		STA RES+0
		LDA #0
		SBC VLA+1
		STA RES+1
.endmacro

; Negate the signed 32 bit number at location VLA
; and stored the result at location RES. RES may
; be the same as VLA.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _NEG32	 VLA,RES
		SEC
		LDA #0
		SBC VLA+0
		STA RES+0
		LDA #0
		SBC VLA+1
		STA RES+1
		LDA #0
		SBC VLA+2
		STA RES+2
		LDA #0
		SBC VLA+3
		STA RES+3
.endmacro

; Calculates the absolute value of signed 16 bit
; number at location VLA and stores it in the RES
; location. Less code is generated if VLA and RES
; are the same location. If 65SC02 instructions
; are available a BRA is used to shorten the
; generated code.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ABS16	 VLA,RES
		BIT VLA+0
	.IF (VLA-RES)==0
		 BPL _DONE#
		 _NEG16 VLA,RES
	.ELSE
		 BPL _MOVE#
		 _NEG16 VLA,RES
		  JMP _DONE#
_MOVE#	 EQU *
		 _XFR16 VLA,RES
	.ENDIF
_DONE#	EQU *
.endmacro

; Calculates the absolute value of signed 32 bit
; number at location VLA and stores it in the RES
; location. Less code is generated if VLA and RES
; are the same location. If 65SC02 instructions
; are available a BRA is used to shorten the
; generated code.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _ABS32	 VLA,RES
		BIT VLA+0
	.IF (VLA-RES)==0
		 BPL _DONE#
		 _NEG32 VLA,RES
	.ELSE
		 BPL _MOVE#
		 _NEG32 VLA,RES
		  JMP _DONE#
_MOVE#	 EQU *
		 _XFR32 VLA,RES
	.ENDIF
_DONE#	EQU *
.endmacro

; Calculate the 16 bit product of two 16 bit
; unsigned numbers. Any overflow during the
; calculation is lost. The numbers at location
; VLA and VLB are destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _MUL16	 VLA,VLB,RES
		_CLR16 RES
		LDX #16
_LOOP#		EQU *
		_LSR16 VLA,VLA
		BCC _NEXT#
		_ADD16 VLB,RES,RES
_NEXT#		_ASL16 VLB,VLB
		DEX
		BPL _LOOP#
.endmacro

; Calculate the 32 bit product of two 16 bit
; unsigned numbers. The number at location VLA
; is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.
;
           
.MACRO _MUL16X	 VLA,VLB,RES
		LDA #$00		; clear p2 and p3 of product
		STA RES+2
		STA RES+3
		LDX #16		; multiplier bit count = 16
nxtbt#	LSR VLA+1		; shift two-byte multiplier right
		ROR VLA
		BCC align#		; multiplier = 1?
		LDA RES+2		; yes. fetch p2
		CLC
		ADC VLB		; and add m0 to it
		STA RES+2		; store new p2
		LDA RES+3		; fetch p3
		ADC VLB+1		; and add m1 to it
align#	ROR A			; rotate four-byte product right
		STA RES+3		; store new p3
		ROR RES+2
		ROR RES+1
		ROR RES
		DEX			; decrement bit count
		BNE nxtbt#		; loop until 16 bits are done
.endmacro

; Calculate the 32 bit product of two 32 bit
; unsigned numbers. Any overflow during the
; calculation is lost. The number at location
; VLA is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.

.MACRO _MUL32	 VLA,VLB,RES
		_CLR32 RES
		LDX #32
_LOOP#		EQU *
		_LSR32 VLA,VLA
		BCC _NEXT#
		_ADD32 VLB,RES,RES
_NEXT#		_ASL32 VLB,VLB
		DEX
		BPL _LOOP#
.endmacro

; Calculate the 32 bit product of a 16 bit number
; at location VLA with a 16 bit integer NUM.
; The number at location VLA is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.
;
           
.MACRO _MUL16I	 VLA,NUM,RES
		LDA #$00		; clear p2 and p3 of product
		STA RES+2
		STA RES+3
		LDX #16		; multiplier bit count = 16
nxtbt#	LSR VLA+1		; shift two-byte multiplier right
		ROR VLA
		BCC align#		; multiplier = 1?
		LDA RES+2		; yes. fetch p2
		CLC
		ADC #<NUM		; and add m0 to it
		STA RES+2		; store new p2
		LDA RES+3		; fetch p3
		ADC #>NUM		; and add m1 to it
align#	ROR A			; rotate four-byte product right
		STA RES+3		; store new p3
		ROR RES+2
		ROR RES+1
		ROR RES
		DEX			; decrement bit count
		BNE nxtbt#		; loop until 16 bits are done
.endmacro

; Calculate the 32 bit product of a 32 bits number at 
; location VLA with a 16 bits integer NUM.
; The number at location VLA is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.
;
           
.MACRO _MUL32I	 VLA,NUM,RES
		LDA #$00		; clear p2 and p3 of product
		STA RES+2
		STA RES+3
		LDX #32		; multiplier bit count = 16
nxtbt#	LSR VLA+3
		LSR VLA+2
		LSR VLA+1		; shift two-byte multiplier right
		ROR VLA
		BCC align#		; multiplier = 1?
		LDA RES+2		; yes. fetch p2
		CLC
		ADC #<NUM		; and add m0 to it
		STA RES+2		; store new p2
		LDA RES+3		; fetch p3
		ADC #>NUM		; and add m1 to it
align#	ROR A			; rotate four-byte product right
		STA RES+3		; store new p3
		ROR RES+2
		ROR RES+1
		ROR RES
		DEX			; decrement bit count
		BNE nxtbt#		; loop until 16 bits are done
.endmacro

; Calculate the 32 bit product of a 32 bits number at 
; location VLA with a 16 bits number at location VLB.
; The number at location VLA is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.
;
           
.MACRO _MUL32X	 VLA,VLB,RES
		LDA #$00		; clear p2 and p3 of product
		STA RES+2
		STA RES+3
		LDX #16		; multiplier bit count = 16
nxtbt#	LSR VLA+3
		LSR VLA+2
		LSR VLA+1		; shift two-byte multiplier right
		ROR VLA
		BCC align#		; multiplier = 1?
		LDA RES+2		; yes. fetch p2
		CLC
		ADC VLB		; and add m0 to it
		STA RES+2		; store new p2
		LDA RES+3		; fetch p3
		ADC VLB+1		; and add m1 to it
align#	ROR A			; rotate four-byte product right
		STA RES+3		; store new p3
		ROR RES+2
		ROR RES+1
		ROR RES
		DEX			; decrement bit count
		BNE nxtbt#		; loop until 32 bits are done
.endmacro

; Divide the 16 bit number at location VLA
; by the 16 bit number at location VLB
; leaving the 16 bit quotient at VLA and
; the 16 bit remainder in REM.
;
; On exit: A = ??, X = $FF, Y = ??.

.MACRO _DIV16	 VLA,VLB,REM
		_CLR16 REM
		LDX #16
_LOOP#	EQU *
		_ASL16 VLA,VLA
		_ROL16 REM,REM
		SEC
		LDA REM
		SBC VLB
		TAY
		LDA REM+1
		SBC VLB+1
		BCC _NEXT#
		STY REM
		STA REM+1
		INC VLA
_NEXT#	EQU *
		DEX
		BNE _LOOP#
.endmacro

; Divide the 32 bit number at location VLA
; by the 16 bit number at location VLB
; leaving the 16 bit quotient at VLA and
; the 16 bit remainder in REM.
;
; On exit: A = ??, X = $FF, Y = ??.

.MACRO _DIV16X	 VLA,VLB,REM
		_CLR16 REM
		LDX #32
_LOOP#	EQU *
		_ASL32 VLA,VLA
		_ROL16 REM,REM
		SEC
		LDA REM
		SBC VLB
		TAY
		LDA REM+1
		SBC VLB+1
		BCC _NEXT#
		STY REM
		STA REM+1
		INC VLA
_NEXT#	EQU *
		DEX
		BNE _LOOP#
.endmacro

; Divide the 16 bit number at location VLA
; by the 16 bit constant NUM leaving the
; 16 bit quotient at VLA and the 16 bit
; remainder in REM.
;
; On exit: A = ??, X = $FF, Y = ??.

.MACRO _DIV16I	 VLA,NUM,REM
		_CLR16 REM
		LDX #16
_LOOP#	EQU *
		_ASL16 VLA,VLA
		_ROL16 REM,REM
		SEC
		LDA REM
		SBC #<NUM
		TAY
		LDA REM+1
		SBC #>NUM
		BCC _NEXT#
		STY REM
		STA REM+1
		INC VLA
_NEXT#	EQU *
		DEX
		BNE _LOOP#
.endmacro

; Divide the 32 bit number at location VLA
; by the 32 bit number at location VLB
; leaving the 32 bit quotient at VLA and
; the 32 bit remainder in REM. 
;
; On exit: A = ??, X = $FF, Y is unchanged.
;

.MACRO _DIV32		 VLA,VLB,REM
		_CLR32 REM				;LDA #0
							;STA ZTMP9
							;STA ZTMP10
							;STA ZTMP11
		LDY #32
DIV320#		_ASL32 VLA,VLA			;ASL ZTMP0
							;ROL ZTMP1
							;ROL ZTMP2
							;ROL ZTMP3

		ROL A
		ROL REM+1				;ROL ZTMP9
		ROL REM+2				;ROL ZTMP10
		ROL REM+3				;ROL ZTMP11

	;do a subtraction
		PHA
		CMP VLB				;CMP ZTMP4
		LDA REM+1				;LDA ZTMP9
		SBC VLB+1				;SBC ZTMP5
		LDA REM+2				;LDA ZTMP10
		SBC VLB+2				;SBC ZTMP6
		LDA REM+3				;LDA ZTMP11
		SBC VLB+3				;SBC ZTMP7
		BCC DIV321#

	;overflow, do the subtraction again, this time store the result
		STA VLB+3				;STA ZTMP7		;we have the high byte already
		PLA
		SBC VLB				;SBC ZTMP4		;byte 0
		PHA
		LDA REM+1				;LDA ZTMP9
		SBC VLB+1				;SBC ZTMP5
		STA REM+1				;STA ZTMP9		;byte 1
		LDA REM+2				;LDA ZTMP10
		SBC VLB+2				;SBC ZTMP6
		STA REM+2				;STA ZTMP10	;byte 2
		INC VLA				;INC ZTMP0		;set result bit

DIV321#	PLA
		DEY
		BNE DIV320#
		STA REM				;STA ZTMP8
.endmacro

;------------------------------------------------
; Comparative Operations
;------------------------------------------------

; Compares two 16 bit values in memory areas VLA
; and VLB. The carry is set if VLA=VLB else the
; carry is cleared on return.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CMP16	 VLA,VLB
		LDA VLA+1
		CMP VLB+1
		BNE _DONE#
		LDA VLA+0
		CMP VLB+0
		BNE _DONE#
		SEC
		RTS
_DONE#		CLC
.endmacro

; Compares 16 bit value in memory VLA and a 
; 16 bit constant NUM . The carry is set if
; VLA=NUM else the carry is cleared on return.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CMP16I	 VLA,NUM
		LDA VLA+1
		CMP #>NUM
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BNE _DONE#
		SEC
		RTS
_DONE#		CLC
.endmacro

; Compares two 32 bit values in memory areas VLA
; and VLB. The carry is set if VLA=VLB else the
; carry is cleared on return.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CMP32	 VLA,VLB
		LDA VLA+3
		CMP VLB+3
		BNE _DONE#
		LDA VLA+2
		CMP VLB+2
		BNE _DONE#
		LDA VLA+1
		CMP VLB+1
		BNE _DONE#
		LDA VLA+0
		CMP VLB+0
		BNE _DONE#
		SEC
		RTS
_DONE#		CLC
.endmacro

; Compares 32 bit value in memory VLA and a
; 32 bit constant NUM . The carry is set if
; VLA=NUM else the carry is cleared on return.
;
; On exit: A = ??, X & Y are unchanged.

.MACRO _CMP32I	 VLA,NUM
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BNE _DONE#
		LDA VLA+2
		CMP #<(NUM/$10000)
		BNE _DONE#
		LDA VLA+1
		CMP #<(NUM/$100)
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BNE _DONE#
		SEC
		RTS
_DONE#		CLC
.endmacro

;------------------------------------------------
; Memory Operations
;------------------------------------------------

; Transfers a block of memory from one place to
; another by copying the bytes starting at the
; front of the block and going forward. SRC and
; DST are destroyed during the copy.
;
; On exit: A, X & Y = ??.

.MACRO _MEMFWD	  SRC,DST,LEN
		LDY #0
		LDX #LEN+1
		BEQ _FRAG#
_PAGE#		LDA (SRC),Y
		STA (DST),Y
		INY
		BNE _PAGE#
		INC SRC+1
		INC DST+1
		DEX
		BNE _PAGE#
_FRAG#		CPY #LEN+0
		BEQ _DONE#
		LDA (SRC),Y
		STA (DST),Y
		INY
		BNE _FRAG#
_DONE#		EQU *
.endmacro

; Transfers a block of memory from one place to
; another by copying the bytes starting at the
; end of the block and going backwards.

.MACRO _MEMREV	  SRC,DST,LEN
		NOP
.endmacro

; Tranfers a block of memory from one location to
; another. Depending on the relative positions of
; the blocks an appropriate transfer method is
; used.

.MACRO _MEMCPY	  SRC,DST,LEN
		_CMP16 SRC,DST
		BCC _SAFE#
		_MEMFWD SRC,DST,LEN
		 JMP _DONE#
_SAFE#		_MEMREV SRC,DST,LEN
_DONE#		EQU *
.endmacro

;------------------------------------------------
; String Operations
;------------------------------------------------

; Calculates length of a null terminated string
; by searching for its end. The address of the
; string in STR is destroyed during the search.
;
; On exit: A & Y = ??, X is unchanged.

.MACRO _STRLEN	  STR,LEN
		LDY #0
		STY LEN+1
_LOOP#	LDA (STR),Y
		BEQ _DONE#
		INY
		BNE _LOOP#
		INC LEN+1
		INC STR+1
		JMP _LOOP#
_DONE#	STY LEN+0
.endmacro

; Copies a null terminated string from one memory
; location to another. The source and destination
; addresses are destroyed during the copy process.
;
; On exit: A & Y = ??, X is unchanged.

.MACRO _STRCPY	 SRC,DST
		LDY #0
_LOOP#	LDA (SRC),Y
		STA (DST),Y
		BEQ _DONE#
		INY
		BNE _LOOP#
		INC SRC+1
		INC DST+1
		JMP _LOOP#
_DONE#		EQU *
.endmacro

;

.MACRO _STRCMP	 VLA,VLB
		LDY #0
_LOOP#	LDA (VLA),Y
		CMP (VLB),Y
		BNE _DONE#
		LDA (VLA),Y
		BEQ _DONE#
		INY
		BNE _LOOP#
		INC VLA+1
		INC VLB+1
		JMP _LOOP#
_DONE#		EQU *
.endmacro

;

.MACRO _STRNCMP	 VLA,VLB,LEN
.endmacro

;------------------------------------------------
; Branch Operations
;------------------------------------------------

; Branch to label LAB if 16 bits vars VLA >= VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BGE16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BCC _DONE#
		BNE LAB
		LDA VLA+0
		CMP VLB+0
		BCS LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA <= VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BLE16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP VLB+0
		BCC LAB
		BEQ LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA < VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BLT16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP VLB+0
		BCC LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA > VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BGT16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BCC _DONE#
		BNE LAB
		LDA VLA+0
		CMP VLB+0
		BCC _DONE#
		BNE LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA = VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BEQ16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BNE _DONE#
		LDA VLA
		CMP VLB
		BNE _DONE#
		JMP LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA <> VLB
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BNE16	  VLA,VLB,LAB
		LDA VLA+1
		CMP VLB+1
		BNE LAB
		LDA VLA
		CMP VLB
		BNE LAB
.endmacro

; Branch to label LAB if 32 bits vars VLA < VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BLT32	  VLA,VLB,LAB
		LDX #3
_LOOP#		LDA VLA,X
		CMP VLB,X
		BCC LAB
		BNE _DONE#
		DEX
		BNE _LOOP#
		LDA VLA+0
		CMP VLB+0
		BCC LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA >= VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BGE32	  VLA,VLB,LAB
		LDX #3
_LOOP#	LDA VLA,X
		CMP VLB,X
		BCC _DONE#
		BNE LAB
		DEX
		BNE _LOOP#
		LDA VLA+0
		CMP VLB+0
		BCS LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA <= VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BLE32	  VLA,VLB,LAB
		LDX #3
_LOOP#	LDA VLA,X
		CMP VLB,X
		BCC LAB
		BNE _DONE#
		DEX
		BNE _LOOP#
		LDA VLA+0
		CMP VLB+0
		BCC LAB
		BEQ LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA > VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BGT32	  VLA,VLB,LAB
		LDX #3
_LOOP#	LDA VLA,X
		CMP VLB,X
		BCC _DONE#
		BNE LAB
		DEX
		BNE _LOOP#
		LDA VLA+0
		CMP VLB+0
		BCC _DONE#
		BNE LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA = VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BEQ32	  VLA,VLB,LAB
		LDX #3
_LOOP#	LDA VLA,X
		CMP VLB,X
		BNE _DONE#
		DEX
		BPL _LOOP#
		JMP LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA <> VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BNE32	  VLA,VLB,LAB
		LDX #3
_LOOP#	LDA VLA,X
		CMP VLB,X
		BNE LAB
		DEX
		BPL _LOOP#
.endmacro

; Branch to label LAB if 16 bits var VLA >= NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BGE16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BCC _DONE#
		BNE LAB
		LDA VLA+0
		CMP #<NUM
		BCS LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA <= NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BLE16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BCC LAB
		BEQ LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA < NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BLT16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BCC LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA > NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BGT16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BCC _DONE#
		BNE LAB
		LDA VLA+0
		CMP #<NUM
		BCC _DONE#
		BNE LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA = NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BEQ16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BNE _DONE#
		JMP LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 16 bits vars VLA <> NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BNE16I	  VLA,NUM,LAB
		LDA VLA+1
		CMP #>NUM
		BNE LAB
		LDA VLA+0
		CMP #<NUM
		BNE LAB
.endmacro

; Branch to label LAB if 32 bits vars VLA >= NUM
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BGE32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BCC _DONE#
		BNE LAB
		LDA VLA+2
		CMP #<(NUM/$10000)
		BCC _DONE#
		BNE LAB
		LDA VLA+1
		CMP #<(NUM/$100)
		BCC _DONE#
		BNE LAB
		LDA VLA
		CMP #<NUM
		BCS LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA <= NUM
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BLE32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BCC LAB
		BNE _DONE#
		LDA VLA+2
		CMP #<(NUM/$10000)
		BCC LAB
		BNE _DONE#
		LDA VLA+1
		CMP #<(NUM/$100)
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BCC LAB
		BEQ LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA < VLB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BLT32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BCC LAB
		BNE _DONE#
		LDA VLA+2
		CMP #<(NUM/$10000)
		BCC LAB
		BNE _DONE#
		LDA VLA+1
		CMP #<(NUM/$100)
		BCC LAB
		BNE _DONE#
		LDA VLA
		CMP #<NUM
		BCC LAB
_DONE#		EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA > NUM
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BGT32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BCC _DONE#
		BNE LAB
		LDA VLA+2
		CMP #<(NUM/$10000)
		BCC _DONE#
		BNE LAB
		LDA VLA+1
		CMP #<(NUM/$100)
		BCC LAB
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BCC _DONE#
		BNE LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA = NUM
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BEQ32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BNE _DONE#
		LDA VLA+2
		CMP #<(NUM/$10000)
		BNE _DONE#
		LDA VLA+1
		CMP #<(NUM/$100)
		BNE _DONE#
		LDA VLA+0
		CMP #<NUM
		BNE _DONE#
		JMP LAB
_DONE#	EQU *
.endmacro

; Branch to label LAB if 32 bits vars VLA <> NUM
;
; On exit: A = ????, X and Y are unchanged.

.MACRO _BNE32I	  VLA,NUM,LAB
		LDA VLA+3
		CMP #<(NUM/$1000000)
		BNE LAB
		LDA VLA+2
		CMP #<(NUM/$10000)
		BNE LAB
		LDA VLA+1
		CMP #<(NUM/$100)
		BNE LAB
		LDA VLA+0
		CMP #<NUM
		BNE LAB
.endmacro

; Branch if 16 bits var VLA = 0 to label LAB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO _BZR16	  VLA,LAB
		LDA VLA+1
		ORA VLA
		BEQ LAB
.endmacro

; Branch if 32 bits var VLA = 0 to label LAB
;
; On exit: A = ????, X = 0 and Y is unchanged.

.MACRO  _BZR32 VLA,LAB
		LDA VLA+3
		ORA VLA+2
		ORA VLA+1
		ORA VLA
		BEQ LAB
.endmacro

