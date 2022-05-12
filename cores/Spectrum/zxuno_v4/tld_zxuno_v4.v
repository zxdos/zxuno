`timescale 1ns / 1ns
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 02:28:18 2014-02-06 by Miguel Angel Rodriguez Jodar
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

module tld_zxuno_v4 (
   input wire clk50mhz,

   output wire [2:0] r,
   output wire [2:0] g,
   output wire [2:0] b,
   output wire hsync,
   output wire vsync,
   input wire ear,
   inout wire clkps2,
   inout wire dataps2,
   inout wire mouseclk,
   inout wire mousedata,
   output wire audio_out_left,
   output wire audio_out_right,

   output wire midi_out,
   input wire clkbd,
   input wire wsbd,
   input wire dabd,

   output wire uart_tx,
   input wire uart_rx,
   output wire uart_rts,
   output wire uart_reset,

   output wire stdn,
   output wire stdnb,

   output wire [20:0] sram_addr,
   inout wire [7:0] sram_data,
   output wire sram_we_n,

   output wire flash_cs_n,
   output wire flash_clk,
   output wire flash_mosi,
   input wire flash_miso,

   output wire sd_cs_n,
   output wire sd_clk,
   output wire sd_mosi,
   input wire sd_miso,
   output wire testled,   // nos servirá como testigo de uso de la SPI

   input wire joyup,
   input wire joydown,
   input wire joyleft,
   input wire joyright,
   input wire joyfire,
   input wire joybtn2,
   output wire joybtn3
   );

	wire [2:0] ri_monochrome, gi_monochrome, bi_monochrome;
	wire [1:0] monochrome_switcher;
	wire wifi_switcher;

`include "../common/config.vh"

   wire sysclk, mcolorclk;
   wire disable_genclk;
   wire [2:0] pll_frequency_option;

   clock_generator relojes_maestros
   (// Clock in ports
    .CLK_IN1            (clk50mhz),
    .pll_option         (pll_frequency_option),
    // Clock out ports
    .sysclk             (sysclk),
    .mcolorclk          (mcolorclk)
    );

   wire [2:0] ri, gi, bi;
   wire hsync_pal, vsync_pal, csync_pal;
   wire vga_enable, scanlines_enable;
   wire clk14en_tovga;
   wire clkcolor4x, ad724_enable_gencolorclk;

   zxuno #(.FPGA_MODEL(3'b001), .MASTERCLK(28000000)) la_maquina (
    .sysclk(sysclk),
    .power_on_reset_n(1'b1),  // sólo para simulación. Para implementacion, dejar a 1
    .r(ri),
    .g(gi),
    .b(bi),
    .hsync(hsync_pal),
    .vsync(vsync_pal),
    .csync(csync_pal),
    .monochrome_switcher(monochrome_switcher),
	 
    .clkps2(clkps2),
    .dataps2(dataps2),
    .ear_ext(~ear),  // negada porque el hardware tiene un transistor inversor
    .audio_out_left(audio_out_left),
    .audio_out_right(audio_out_right),

    .midi_out(midi_out),
    .clkbd(clkbd),
    .wsbd(wsbd),
    .dabd(dabd),

    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .uart_rts(uart_rts),
    .uart_reset(uart_reset),

    .sram_addr(sram_addr),
    .sram_data(sram_data),
    .sram_we_n(sram_we_n),

    .flash_cs_n(flash_cs_n),
    .flash_clk(flash_clk),
    .flash_di(flash_mosi),
    .flash_do(flash_miso),

    .sd_cs_n(sd_cs_n),
    .sd_clk(sd_clk),
    .sd_mosi(sd_mosi),
    .sd_miso(sd_miso),

    .joy1up(joyup),
    .joy1down(joydown),
    .joy1left(joyleft),
    .joy1right(joyright),
    .joy1fire1(joyfire),
    .joy1fire2(joybtn2),

    .joy2up(1'b1),
    .joy2down(1'b1),
    .joy2left(1'b1),
    .joy2right(1'b1),
    .joy2fire1(1'b1),
    .joy2fire2(1'b1),

    .joy1fire3(joybtn3),

    .mouseclk(mouseclk),
    .mousedata(mousedata),

    .clk14en_tovga(clk14en_tovga),
    .vga_enable(vga_enable),
    .scanlines_enable(scanlines_enable),
    .freq_option(pll_frequency_option),

    .ad724_xtal(stdnb),
    .ad724_mode(stdn),
    .ad724_enable_gencolorclk(ad724_enable_gencolorclk)
    );

`ifdef FPGA_GENERATES_COLOR_CLOCK_OPTION
  gencolorclk generador_reloj_color (
    .clk(mcolorclk),
    .mode(stdn),
    .altern(pll_frequency_option[0]),
    .clkcolor4x(clkcolor4x)
  );
`else
  assign clkcolor4x = 1'b1;   // VSYNC a 1 si no se genera el reloj de color
`endif

`ifdef MONOCHROMERGB
  monochrome monochromergb (
    .monochrome_selection(monochrome_switcher),
    .ri(ri),
    .gi(gi),
    .bi(bi),
    .ro(ri_monochrome),
    .go(gi_monochrome),
    .bo(bi_monochrome)
  );
 `else
   assign ri_monochrome = ri;
	assign gi_monochrome = gi;
	assign bi_monochrome = bi;
 `endif

	vga_scandoubler #(.CLKVIDEO(14000)) salida_vga (
		.clk(sysclk),
    .clkcolor4x(clkcolor4x | ~ad724_enable_gencolorclk),
    .clk14en(clk14en_tovga),
    .enable_scandoubling(vga_enable),
    .disable_scaneffect(~scanlines_enable),
		.ri(ri_monochrome),
		.gi(gi_monochrome),
		.bi(bi_monochrome),
		.hsync_ext_n(hsync_pal),
		.vsync_ext_n(vsync_pal),
    .csync_ext_n(csync_pal),
		.ro(r),
		.go(g),
		.bo(b),
		.hsync(hsync),
		.vsync(vsync)
   );

   assign testled = (!flash_cs_n || !sd_cs_n);

endmodule
