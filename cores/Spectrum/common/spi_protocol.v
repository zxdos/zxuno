`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 23:49:58 2020-02-27 by Miguel Angel Rodriguez Jodar
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

module spi (
  input wire clk,         // 
  input wire clken,       //
  input wire enviar_dato, // a 1 para indicar que queremos enviar un dato por SPI
  input wire recibir_dato,// a 1 para indicar que queremos recibir un dato
  input wire [7:0] din,   // del bus de datos de salida de la CPU
  output reg [7:0] dout,  // al bus de datos de entrada de la CPU
  output wire oe,         // el dato en dout es válido
  output wire spi_transfer_in_progress,
   
  output wire sclk,       // Interface SPI
  output wire mosi,       //
  input wire miso         //
  );
  
  reg enviar_dato_bf = 1'b0;
  reg recibir_dato_bf = 1'b0;
  wire enviar = ~enviar_dato_bf & enviar_dato;
  wire recibir =~recibir_dato_bf & recibir_dato;
  always @(posedge clk) begin
    enviar_dato_bf <= enviar_dato;
    recibir_dato_bf <= recibir_dato;
  end
  
  reg [7:0] spireg = 8'hFF;
  reg [4:0] count = 5'b10000;
  assign mosi = spireg[7];
  assign sclk = count[0];
  assign spi_transfer_in_progress = ~count[4];
  assign oe = recibir_dato;
  always @(posedge clk) begin
    if (enviar == 1'b1) begin
      spireg <= din;
      count <= 5'b00000;
    end
    else if (recibir == 1'b1) begin
      dout <= spireg;
      spireg <= 8'hFF;
      count <= 5'b00000;
    end
    else if (clken == 1'b1) begin
      if (count[4] == 1'b0) begin
        count <= count + 5'd1;
        if (sclk == 1'b1) begin  // tengo mis dudas sobre si usar 0 o 1 aquí. En principio, debería ser 0, pero funciona con 1 (???)
          spireg <= {spireg[6:0], miso};
        end
      end
    end
  end
endmodule
