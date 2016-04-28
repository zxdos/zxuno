ZPUFlex
=======
A compact and flexible variant of the ZPU - the Zylin soft processor
core.  The aim of this project is to see just how far the "small" variant
of the core can be be taken while keeping it under 1000 logic elements.

While the regular ZPU-core is a simple general-purpose processor, the
zpu_small variant on which this project is based is limited by a fixed-size
BlockRAM-based stack which doubles as program ROM.  This makes it more
self-contained but limits the complexity of the programs that can be run.
The original zpu_small version could only run software from the internal
BlockRAM, but this project makes it possible to run from external RAM too,
so a boot ROM that loads firmware from SD card is perfectly possible.

I've tried to keep the project as configurable as possible, so there are a
number of generics which can be used to configure this ZPU variant.  A few
other parameters have been moved from zpucfg.vhd to generics, because this
makes it easier to include multiple ZPUs in a single project.

It's possible to enable or disable hardware implementations of
various instructions.  With all these disabled, the ZPU is a little under 600
LEs in size, but requires emulation "microcode" in the lower kilobyte of the
program ROM.  With these instructions enabled, the ZPU takes just under 1,000
LEs, but in combination with various GCC switches, can make do without
emulation code; thus how you set these switches will depend on whether you
need to limit use of LEs or of Block RAM.

With all the switches enabled the performance is surprisingly good for such
a tiny CPU, thanks largely to the stack being in Block RAM.

The switches for optional instructions are:
* IMPL_MULTIPLY - hardware mult
* IMPL_COMPARISON_SUB - hardware sub, lessthan, lessthanorequal,
  ulessthan, ulessthanorequal.
* IMPL_EQBRANCH - hardware eqbranch and neqbranch
* IMPL_STOREBH - hardware storeb and storeh  (CAUTION - only supported for
  external RAM, not internal Block RAM.  Can cause trouble with firmware!)
* IMPL_LOADBH - hardware loadb and loadh   (CAUTION - only supported for
  external RAM, not internal Block RAM.  Can cause trouble with firmware!)
* IMPL_CALL - hardware call
* IMPL_SHIFT - hardware lshiftright, ashiftright and ashiftleft
* IMPL_XOR - hardware xor

There are a couple of other switches too:
* EXECUTE_RAM - include support for executing code from outside the Boot ROM.
* REMAP_STACK - maps the stack / Boot ROM which usually appears at 0x00000000
  to an alternative address (0x40000000 by default).
  This is useful in combination with the EXECUTE_RAM switch if you want
  to bootstrap a larger program than will fit in the BlockRAM-based Boot ROM.

Finally there are a few integer parameters:
* stackbit - sets the base address for the stack, if using REMAP_STACK mode.
  if REMAP_STACK is not set this is ignored.  The default value is 30, which
  maps the STACK to 2**30, or 0x40000000.
  If you adjust this, you'll need to adjust the base address in your linkscript
  to match.
* maxAddrBitBRAM - the highest valid address bit for the Stack RAM / ROM.

