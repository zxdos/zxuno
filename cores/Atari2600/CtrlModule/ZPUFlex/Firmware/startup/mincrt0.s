/* Startup code for ZPU
   Copyright (C) 2005 Free Software Foundation, Inc.

This file is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2, or (at your option) any
later version.

In addition to the permissions in the GNU General Public License, the
Free Software Foundation gives you unlimited permission to link the
compiled version of this file with other programs, and to distribute
those programs without any restriction coming from the use of this
file.  (The General Public License restrictions do apply in other
respects; for example, they cover modification of the file, and
distribution when not linked into another program.)

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */
	.file	"mincrt0.S"

/* FIXME - add support for interrupts! */

/* Minimal startup code, usable where the core is complete enough not to require emulated instructions */
	

; KLUDGE!!! we remove the executable bit to avoid relaxation 
	.section ".fixed_vectors","a"

	.macro fixedim value
			im \value
	.endm

	.macro  jmp address
			fixedim \address
			poppc
	.endm

	.macro fast_neg
	not
	im 1
	add
	.endm

		.globl _start
_start:
	im _break
	nop
	fixedim _premain
	poppc

	.global _break;
_break:
	im	_break
	poppc ; infinite loop

	.global _boot
_boot:
	im -1
	popsp ;	Reset stack to 0x....ffff
	im 0
	poppc ; and jump to 0

_default_inthandler:
	poppc
	.global _inthandler_fptr
	.balign 4,0
_inthandler_fptr:
	.long _default_inthandler

; 4 bytes wasted here.

	.globl _zpu_interrupt_vector
	.balign 32,0	; Interrupt handler must be at location 32
_zpu_interrupt_vector:
			im _memreg+0		; save R0
			load
			im _memreg+4		; save R1
			load
			im _memreg+8		; save R2
			load
	
			fixedim	_inthandler_fptr
			load
			call
			
			im _memreg+8
			store		; restore R2
			im _memreg+4
			store		; restore R1
			im _memreg+0
			store		; restore R0
			poppc

;	After the interrupt vector alignment's no longer critical
	.section ".text","a"

	.global _loadh
_loadh:
	loadsp 4
	; by not masking out bit 0, we cause a memory access error 
	; on unaligned access
	im ~0x2
	and
	load

	; mult 8	
	loadsp 8
	im 3
	and
	fast_neg
	im 2
	add
	im 3
	ashiftleft
	; shift right addr&3 * 8
	lshiftright
	im 0xffff
	and
	storesp 8
	
	poppc


	.global _loadb
_loadb:
	loadsp 4
	im ~0x3
	and
	load

	loadsp 8
	im 3
	and
	fast_neg
	im 3
	add
	; x8
	addsp 0
	addsp 0
	addsp 0

	lshiftright

	im 0xff
	and
	storesp 8
	
	poppc


	.global _storeh
_storeh:
	loadsp 4
	; by not masking out bit 0, we cause a memory access error 
	; on unaligned access
	im ~0x2
	and
	load

	; mask
	im 0xffff
	loadsp 12
	im 3
	and
	fast_neg
	im 2
	add
	im 3
	ashiftleft
	ashiftleft
	not

	and

	loadsp 12
	im 0xffff
		
	and
	loadsp 12
	im 3
	and
	fast_neg
	im 2
	add
	im 3
	ashiftleft
	nop
	ashiftleft
	
	or
	
	loadsp 8
	im  ~0x3
	and

	store
	
	storesp 4
	storesp 4
	poppc


/* FIXME - can do storeb in hardware */
	.global _storeb
_storeb:
	loadsp 4
	im ~0x3
	and
	load

	; mask away destination
	im _mask
	loadsp 12
	im 3
	and
	addsp 0
	addsp 0
	add
	load

	and

	loadsp 12
	im 0xff
	and
	loadsp 12
	im 3
	and

	fast_neg
	im 3
	add
	; x8
	addsp 0
	addsp 0
	addsp 0

	ashiftleft
	 
	or
	
	loadsp 8
	im  ~0x3
	and

	store
	
	storesp 4
	storesp 4
	poppc

	.section ".rodata"
	.balign 4,0
_mask:
	.long 0x00ffffff
	.long 0xff00ffff
	.long 0xffff00ff
	.long 0xffffff00

	.section ".bss"
    .balign 4,0
	.globl _memreg
_memreg:
		.long 0
		.long 0
		.long 0
		.long 0

