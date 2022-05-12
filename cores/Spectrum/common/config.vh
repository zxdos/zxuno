//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 18:39:21 2020-02-09 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.


// Build options (comment out to disable a specific option)

`define LOAD_ROM_FROM_FLASH_OPTION
// The following two defines are taken into account only if LOAD_ROM_FROM_FLASH_OPTION is not defined
`define DEFAULT_SYSTEM_ROM "128en.hex"
`define DEFAULT_DIVMMC_ROM "esxdos088.hex"
`define MIDI_SYNTH_OPTION
`define UART_ESP8266_OPTION
`define F11_ESP8266_FEATURE
`define PZX_PLAYER_OPTION
`define VGA_OUTPUT_OPTION
`define CPU_TURBO_OPTION
`define DIVMMC_SUPPORT
`define ZXUNO_DMA_SUPPORT
`define ULA_TIMEX_SUPPORT

// Radastan mode needs ULAplus support enabled
`define ULAPLUS_SUPPORT
`define ULA_RADASTAN_SUPPORT
`define ULA_SNOW_SUPPORT
`define RASTER_INTERRUPT_SUPPORT
`define TURBOSUND_SUPPORT
`define SPECDRUM_COVOX_SUPPORT
`define MULTIBOOT_SUPPORT
//`define PENTAGON_512K_SUPPORT
`define JOYSPLITTER_SUPPORT

// FPGA color clock generation needs AD724 control support enabled
//`define AD724_CONTROL_SUPPORT
//`define FPGA_GENERATES_COLOR_CLOCK_OPTION
`define MONOCHROMERGB
//`define SAA1099
`define INITIAL_KB_RESET
// ZXUNO core ID string. Must be padded with zero bytes to the right (16 bytes total)
  localparam COREID_STRING = {"EXP27-030422", 8'h00, 8'h00, 8'h00, 8'h00};

// Power-on/FPGA PROG video configuration
  localparam
    VSYNC_OPTION     = 1'b0,   // 0=Sinclair simple vertical sync, 1=proper PAL vsync
    FREQ_OPTION      = 3'b000, // 0 to 7 (50 to almost 60 Hz)
    SCANLINES_OPTION = 1'b0,   // 0=no scanlines, 1=scanlines
    VIDEO_OPTION     = 1'b1;   // 0=RGB, 1=VGA
  localparam INITIAL_VIDEO_VALUE = {2'b00, VSYNC_OPTION, FREQ_OPTION, SCANLINES_OPTION, VIDEO_OPTION};

// ZXUNO address/data I/O ports for indirect access to ZXUNO registers
  localparam
    IOADDR = 16'hFC3B,
    IODATA = 16'hFD3B;

// ULAplus I/O ports
  localparam
    ULAPLUSADDR  = 16'hBF3B,
    ULAPLUSDATA  = 16'hFF3B;

// TIMEX I/O ports
  localparam
    TIMEXPORT    = 8'hFF,
    TIMEXMMU     = 8'hF4;

// ZXUNO registers for master configuration and memory handling
  localparam
    MASTERCONF   = 8'h00,
    MASTERMAPPER = 8'h01;

// ZXUNO registers for SPI devices (flash)
  localparam
      SPIPORT = 8'h02,     // registro de lectura/escritura SPI
      CSPIN   = 8'h03;     // bit 0: estado/control de la señal FLASH_CS

// ZXUNO registers for PS/2 keyboard handling
  localparam
    SCANCODE = 8'h04,
    KBSTATUS = 8'h05,
    KEYMAP   = 8'h07;

// ZXUNO registers for joystick configuration
  localparam
   JOYCONFADDR     = 8'h06;

// ZXUNO register to enable Antonio's special NMI
  localparam NMIEVENT = 8'h08;

// ZXUNO registers for PS/2 mouse handling
  localparam MOUSEDATA = 8'h09,
             MOUSESTATUS = 8'h0A;

// I/O ports for Kempston and Fuller joystick interfaces
  localparam
   KEMPSTONADDR1    = 8'h1F,
   KEMPSTONADDR2    = 8'hDF,
   FULLERADDR      = 8'h7F;

// I/O ports for SD card (ZXMMC and DIVMMC)
  localparam
      SDCS    = 8'h1F,     //
      SDSPI   = 8'h3F,     // Puertos de la ZXMMC
      DIVCS   = 8'he7,     //
      DIVSPI  = 8'heb;     // Puertos del DIVMMC

// ZXUNO register for scandoubler/CPU speed options
  localparam SCANDBLCTRL = 8'h0B;

// I/O port	for CPU speed option (Prism compatible)
  localparam PRISMSPEEDCTRL = 16'h8e3b;  // PRISM speed control: bits D3-D0. Bits D7-D4 must be 0000

// ZXUNO registers for raster interrupt
  localparam RASTERLINE = 8'h0C,
             RASTERCTRL = 8'h0D;

// ZXUNO registers for enabling/disabling integrated addons
  localparam
  	DEVOPTIONS = 8'h0E,
    DEVOPTS2   = 8'h0F;

// ZXUNO register for memory capacity reporting
  localparam MEMREPORT = 8'h10;

// ZXUNO registers for Radastan mode control and options
  localparam
    RADASCTRL    = 8'h40,
    RADASOFFSET  = 8'h41,
    RADASPADDING = 8'h42,
    RADASPALBANK = 8'h43;

// ZXUNO registers for screen location (composite & RGB) fine adjust
  localparam
    HOFFS48K     = 8'h80,
    VOFFS48K     = 8'h81,
    HOFFS128K    = 8'h82,
    VOFFS128K    = 8'h83,
    HOFFSPEN     = 8'h84,
    VOFFSPEN     = 8'h85;

// ZXUNO registers for DMA
  localparam
    DMACTRL = 8'hA0,
    DMASRC  = 8'hA1,
    DMADST  = 8'hA2,
    DMAPRE  = 8'hA3,
    DMALEN  = 8'hA4,
    DMAPROB = 8'hA5,
    DMASTAT = 8'hA6;

// ZXUNO registers for UART (wifi module) handling
  localparam UARTDATA = 8'hC6,
             UARTSTAT = 8'hC7;

// ZXUNO registers for PZX/real tape handling
  localparam SRAMADDR      = 8'hF0,
             SRAMADDRINC   = 8'hF1,
             SRAMDATA      = 8'hF2,
             VDECKCTRL     = 8'hF3;

// ZXUNO register for AD724 control (NTSC/PAL option)
  localparam CTRLAD724 = 8'hFB;

// ZXUNO registers for multiboot handling
  localparam ADDR_COREADDR = 8'hFC,
             ADDR_COREBOOT = 8'hFD;

// ZXUNO register for never resetted scratch register (test for initial hardware reset)
  localparam SCRATCH = 8'hFE;

// ZXUNO register for reading core ID string
  localparam
	  IDSTRING = 8'hFF;

// I/O port for audio mixer
  localparam AUDIOMIXER	= 8'hF7;  // Andrew Owen
