
/* Memory Definitions for a ZPU program running from remapped Boot ROM / Stack RAM. */


/* Section Definitions */

SECTIONS
{
  /* first section is .fixed_vectors which is used for startup code */
  . = 0x40000000;
  .fixed_vectors :
  {
	KEEP(*(.fixed_vectors)) /* Seed section - allows -gc-sections */
  }

  /* Remaining code sections */
  . = ALIGN(4);
  .text :
  {
    *(.text)                   /* remaining code */
    *(.text.*)                   /* remaining code */
  } 

  /* .rodata section which is used for read-only data (constants) */
  . = ALIGN(4);
  .rodata :
  {
    *(.rodata)
    *(.rodata.*)
  } 
  . = ALIGN(4);

  /* .data section which is used for initialized data. */
  . = ALIGN(4);
  .data :
  {
    _data = . ;
    *(.data)
    *(.data.*)
    SORT(CONSTRUCTORS)
	. = ALIGN(4);
	_romend = . ;
  } 

  /* .bss section which is used for uninitialized data */
  . = ALIGN(4);
  .bss :
  {
    __bss_start = . ;
    __bss_start__ = . ;
    *(.bss)
    *(.bss.*)
    *(COMMON)
	__bss_end__ = . ;
	_end = . ;
  }
	/* Debug information */
  .debug_loc 0 : { *(.debug_loc) }
  .debug_abbrev 0 : { *(.debug_abbrev) }
  .debug_str 0 : { *(.debug_str) }
  .debug_info 0 : { *(.debug_info) }
  .debug_line 0 : { *(.debug_line) }
  .debug_frame 0 : { *(.debug_frame) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  .debug_aranges 0 : { *(.debug_aranges) }
  .comment : { *(.comment) }
}
