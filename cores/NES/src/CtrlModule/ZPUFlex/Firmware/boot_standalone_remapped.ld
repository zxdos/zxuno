
/* Memory Definitions for a ZPU program running entirely from boot / stack RAM */

MEMORY
{
  BOOT (rx) : ORIGIN = 0x40000000, LENGTH = 0x00000060 /* Boot section contains just the initial jump */
  TRAP (rx) : ORIGIN = 0x40000060, LENGTH = 0x00000000 /* Dummy region to ensure we don't have any Initialized writable data */
  CODE (rx) : ORIGIN = 0x40000060, LENGTH = 0x0000ff98 /* Up to the end of the first 4K */
}


/* Section Definitions */

SECTIONS
{
  /* first section is .fixed_vectors which is used for startup code */
  . = 0x0000000;
  .fixed_vectors :
  {
	KEEP(*(.fixed_vectors)) /* Seed section - allows -gc-sections */
  }>BOOT

  /* Remaining code sections */
  .text :
  {
	. = ALIGN(4);
    *(.text)                   /* remaining code */
    *(.text.*)                   /* remaining code */
  } >CODE

  /* .rodata section which is used for read-only data (constants) */
  .rodata :
  {
    *(.rodata)
    *(.rodata.*)
  . = ALIGN(4);
  } >CODE
  _romend = . ;

  /* .data section which is used for initialized data.
     Since we don't want any writable data within the ROM
     itself, we put this stuff in a "trap" section. */
  .data :
  {
    _data = . ;
    *(.data)
    *(.data.*)
    SORT(CONSTRUCTORS)
    . = ALIGN(4);
  } >TRAP

  /* .bss section which is used for uninitialized data */
  .bss :
  {
    __bss_start = . ;
    __bss_start__ = . ;
    *(.bss)
    *(.bss.*)
    *(COMMON)
    . = ALIGN(4);
	__bss_end__ = . ;
  } >CODE
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
