`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 00:52:19 2014-03-03 by Miguel Angel Rodriguez Jodar
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

module flash_and_sd (
   input wire clk,         //
   input wire [15:0] a,    //
   input wire iorq_n,      // Señales de control de E/S estándar
   input wire rd_n,        // para manejar los puertos ZXMMC y DIVMMC
   input wire wr_n,        //
   input wire [7:0] addr,  // numero de registro almacenado en puerto ZXUNOADDR. Este módulo atiende a $02 y $03
   input wire ior,         // lectura a un registro ZXUNO
   input wire iow,         // escritura a un registro ZXUNO
   input wire [7:0] din,   // del bus de datos de salida de la CPU
   output wire [7:0] dout, // al bus de datos de entrada de la CPU
   output wire oe,         // el dato en dout es válido
   output wire wait_n,     // pausa para la CPU. Mejora estabilidad
   
   input wire in_boot_mode,// Esta interfaz sólo es válida en modo boot
   output wire flash_cs_n, //
   output wire flash_clk,  // Interface SPI con la Flash
   output wire flash_di,   //
   input wire flash_do,    //
   
   input wire disable_spisd,
   output wire sd_cs_n,    //
   output wire sd_clk,     // Interface SPI con la SD/MMC
   output wire sd_mosi,    // 
   input wire sd_miso      //
   );

`include "config.vh"

   wire sclk,miso,mosi;
   wire spi_transfer_in_progress;
   assign wait_n = ~spi_transfer_in_progress;
   
   reg flashpincs = 1'b1;
   assign flash_cs_n = flashpincs;
   reg sdpincs = 1'b1;
   assign sd_cs_n = sdpincs;

   assign flash_clk = sclk;
   assign flash_di = mosi;   
   assign sd_clk = sclk;
   assign sd_mosi = mosi;
   
   assign miso = (sd_cs_n == 1'b0)? sd_miso : flash_do;

   // Control del pin CS de la flash y de la SD
   always @(posedge clk) begin
      if (addr == CSPIN && iow && in_boot_mode) begin
         flashpincs <= din[0];
         sdpincs <= 1'b1;   // si accedemos a la flash para cambiar su estado CS, automaticamente deshabilitamos la SD
      end
      else if (!disable_spisd && !iorq_n && (a[7:0]==SDCS || a[7:0]==DIVCS) && !wr_n) begin
         sdpincs <= din[0];
         flashpincs <= 1'b1; // y lo mismo hacemos si es la SD a la que estamos accediendo
      end
   end
   
   // Control del modulo SPI
   reg enviar_dato;
   reg recibir_dato;
   always @* begin
      if ((addr==SPIPORT && ior && in_boot_mode) || (!disable_spisd && !iorq_n && (a[7:0]==SDSPI || a[7:0]==DIVSPI) && !rd_n))
         recibir_dato = 1'b1;
      else
         recibir_dato = 1'b0;
      if ((addr==SPIPORT && iow && in_boot_mode) || (!disable_spisd && !iorq_n && (a[7:0]==SDSPI || a[7:0]==DIVSPI) && !wr_n))
         enviar_dato = 1'b1;
      else
         enviar_dato = 1'b0;
   end
   
   // Instanciación del modulo SPI   

   spi mi_spi (
      .clk(clk),
      .clken(1'b1),
      .enviar_dato(enviar_dato),
      .recibir_dato(recibir_dato),
      .din(din),
      .dout(dout),
      .oe(oe),
      .spi_transfer_in_progress(spi_transfer_in_progress),
   
      .sclk(sclk),
      .mosi(mosi),
      .miso(miso)
      );

    
endmodule
