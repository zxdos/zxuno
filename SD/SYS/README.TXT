; =============================================================================
; FUNCTIONS
; =============================================================================

; -----------------------------------------------------------------------------
; waitKey   wait for key or mouse
;
; input:    -
; output:   a = key pressed
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; readKey   read key
;
; input:    -
; output:   a = key pressed, 0 if none
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; clrScr    clear screen lines
;
; input:    a = attribute
;           b = number of lines to clear
;           c = start line
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; utoa      Converts to asciiz and print at cursor position an unsigned int
;           Skips '0' on the left
;           Updates cursor coordinates
;
; input:    hl = unigned int to convert
; output:   -
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; prtDec    Print a asciiz string representing a number at cursor position
;           Skips '0' on the left
;			Updates cursor coordinates
;
; input:    hl = pointer to asciiz string
; output:   hl = pointer to end of string
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; prStr     Print a asciiz string at cursor position
;           Updates cursor coordinates
;
; input:    hl = pointer to asciiz string
; output:   hl = pointer to end of string
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; prChr     Print a character at cursor
;           Updates cursor coordinates
;
; 			Based on code by Andrew Owen in a thread on WoSF.
; 			Based on code by Tony Samuels from Your Spectrum issue 13, April
;			1985. A channel wrapper for the 64-column display driver.
;
; input:    a = char to print
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------

; =============================================================================
; VARIABLES
; =============================================================================

NMIbuf		word	pointer to NMI_BUFFER
savedSP		word	SP register saved on NMI navigator entry
divRAM		word	number of 8k RAM pages found on divXXX
esxDOSv		byte	version of esxDOS
					'5' version is 0.8.5
					'6' version is 0.8.6
flg128k		byte	copy of NMI_BUFFER RAM Size (0=16k,1=48k,2=128k)

bDName		bytes	selected (at cursor) file/dirname asciiz string
bDAttr		byte	selected (at cursor) file/dirname attributes (like MS-DOS)
					bit 4 (1=directory, 0=file)

ovrBuf		word	address of overlay buffer

; =============================================================================
; CONSTANTS
; =============================================================================

SIZ_OVR		size of overlay buffer

COL_MID		attributes of mid zone
COL_TOP		attributes of top line
COL_BOT		attributes of bottom line
COL_CUR		attributes of cursor line
COL_ERR		attributes of error message

; =============================================================================
; esxDOS STRUCTURES
; =============================================================================

; ----------
; NMI_BUFFER
; ----------
;
; Offset   Size   Description
; ----------------------------------------------------------------------------
; 0        1      byte   I                              <- 48k SNA, 27 bytes
; 1        8      word   HL',DE',BC',AF'
; 9        10     word   HL,DE,BC,IY,IX
; 19       1      byte   Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
; 20       1      byte   R
; 21       4      words  AF,SP
; 25       1      byte   IntMode (0=IM0/1=IM1/2=IM2)
; 26       1      byte   BorderColor (0..7)
;
; v0.8.0, v0.8.5
;
; 27       2      word   PC (Program Counter)           <- 128k SNA, 4 bytes
; 29       1      byte   RAM bank paged in @ $c000
; 30       1      byte   TR-DOS (SNA file format)
; 30       1      byte   RAM Size (0=16k,1=48k,2=128k)  <- CONFLICT !!!
;
; v0.8.6
;
; 27       1      byte   RAM Size (0=16k,1=48k,2=128k)
; 28       2      word   PC (Program Counter)           <- 128k SNA, 4 bytes
; 30       1      byte   RAM bank paged in @ $c000
; 31       1      byte   TR-DOS (SNA file format)
;
