`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 00:52:19 2014-03-04 by Miguel Angel Rodriguez Jodar
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
   input wire enviar_dato, // a 1 para indicar que queremos enviar un dato por SPI
   input wire recibir_dato,// a 1 para indicar que queremos recibir un dato
   input wire [7:0] din,   // del bus de datos de salida de la CPU
   output reg [7:0] dout,  // al bus de datos de entrada de la CPU
   output reg oe,        // el dato en dout es válido
   output reg spi_transfer_in_progress,
   
   output wire spi_clk,    // Interface SPI
   output wire spi_di,     //
   input wire spi_do       //
   );

   // Modulo SPI.
   reg ciclo_lectura = 1'b0;       // ciclo de lectura en curso
   reg ciclo_escritura = 1'b0;     // ciclo de escritura en curso
   reg [4:0] contador = 5'b00000;  // contador del FSM (ciclos)
   reg [7:0] data_to_spi;          // dato a enviar a la spi por DI
   reg [7:0] data_from_spi;        // dato a recibir desde la spi
   reg [7:0] data_to_cpu;          // ultimo dato recibido correctamente
   
   assign spi_clk = contador[0];   // spi_CLK es la mitad que el reloj del módulo
   assign spi_di = data_to_spi[7]; // la transmisión es del bit 7 al 0
   
   initial spi_transfer_in_progress = 1'b0;
   
   always @(posedge clk) begin
      if (enviar_dato && !ciclo_escritura) begin  // si ha sido señalizado, iniciar ciclo de escritura
         ciclo_escritura <= 1'b1;
         ciclo_lectura <= 1'b0;
         contador <= 5'b00000;
         data_to_spi <= din;
         spi_transfer_in_progress <= 1'b1;         
      end
      else if (recibir_dato && !ciclo_lectura) begin // si no, si mirar si hay que iniciar ciclo de lectura
         ciclo_lectura <= 1'b1;
         ciclo_escritura <= 1'b0;
         contador <= 5'b00000;
         data_to_cpu <= data_from_spi;
         data_from_spi <= 8'h00;
         data_to_spi <= 8'hFF;  // mientras leemos, MOSI debe estar a nivel alto!       
         spi_transfer_in_progress <= 1'b1;         
      end
      
      // FSM para enviar un dato a la spi
      else if (ciclo_escritura==1'b1) begin
         if (contador!=5'b10000) begin
            if (contador == 5'b01000)
                spi_transfer_in_progress <= 1'b0;            
            if (spi_clk==1'b1) begin
               data_to_spi <= {data_to_spi[6:0],1'b0};
               data_from_spi <= {data_from_spi[6:0],spi_do};
            end
            contador <= contador + 1;
         end
         else begin
            if (!enviar_dato)
               ciclo_escritura <= 1'b0;
         end
      end
      
      // FSM para leer un dato de la spi
      else if (ciclo_lectura==1'b1) begin
         if (contador!=5'b10000) begin
            if (contador == 5'b01000)
                spi_transfer_in_progress <= 1'b0;            
            if (spi_clk==1'b1)
               data_from_spi <= {data_from_spi[6:0],spi_do};
            contador <= contador + 1;
         end
         else begin
            if (!recibir_dato)
               ciclo_lectura <= 1'b0;
         end
      end
   end
   
   always @* begin
      if (recibir_dato) begin
         dout = data_to_cpu;
         oe = 1'b1;
      end
      else begin
         dout = 8'hZZ;
         oe = 1'b0;
      end
   end   
endmodule
