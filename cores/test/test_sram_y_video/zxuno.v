`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:16:16 02/06/2014 
// Design Name: 
// Module Name:    zxuno 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module zxuno (
    input wire clk,     // 7MHz, reloj de pixel
    input wire sramclk, // 28MHz, reloj del controlador de la SRAM
    input wire wssclk,  // 5MHz, reloj de la señal WSS
    output wire [2:0] r,
    output wire [2:0] g,
    output wire [2:0] b,
    output wire csync,
    
    output wire [20:0] sram_addr,
    inout wire [7:0] sram_data,
    output wire sram_we_n
    );

   wire [8:0] h;
   wire [8:0] v;
   
   wire [7:0] pixel;
   reg [2:0] rojo;
   reg [2:0] verde;
   reg [2:0] azul;

   reg [15:0] vramaddr = 16'h0000;  // Puntero de lectura de memoria para generar imagen
   reg [3:0] vrampagina = 4'b000;  // Para usar una de las 16 posibles páginas de 64K
   always @(posedge clk) begin
      if (h>=0 && h<256 && v>=0 && v<192)
         vramaddr <= vramaddr + 16'd1;
      else if (v>=192)
         vramaddr <= 16'h0000;
   end

   reg [15:0] pokeaddr = 16'h0000;  // Puntero de escritura en memoria para generar patrón
   reg pokea;
   always @(posedge clk) begin
      if (v==192 && h>=0 && h<256 && h[1:0]==2'b01) begin  // Durante la linea 192, hago un poke por cada 4 pixeles (64 pokes en una linea)
         if (pokeaddr == 16'hBFFF) begin
            pokeaddr <= 16'h0000;
            vrampagina <= vrampagina + 4'd1;
         end
         else   
            pokeaddr <= pokeaddr + 16'd1;
      end
   end

   always @* begin
      if (h>=0 && h<256 && v>=0 && v<192) begin
         verde = pixel[7:5];             //
         rojo = pixel[4:2];              // Leo un pixel de memoria
         azul = {pixel[1:0],pixel[1]};   //
      end
      else begin
         verde = {{3{vrampagina[3]}}};  //
         rojo =  {{3{vrampagina[2]}}};   // Borde según valor de vrampagina
         azul =  {{3{vrampagina[1]}}};   //
      end
      if (v==192 && h>=0 && h<256 && h[1:0]==2'b00)  //
         pokea = 0;                                    // Activo escritura cada 4 pixeles en la línea 192
      else                                             // Primero se escribe, luego se incrementa la direccion
         pokea = 1;                                    //
   end

   dp_memory dos_memorias (  // Controlador de memoria, que convierte a la SRAM en una memoria de doble puerto
      .clk(sramclk),
      .a1({vrampagina,vramaddr}),
      .a2({vrampagina,pokeaddr}),
      .oe1_n(1'b0),
      .oe2_n(1'b1),
      .we1_n(1'b1),
      .we2_n(pokea),
      .din1(8'h00),
      .din2(pokeaddr[14:7]),
      .dout1(pixel),
      .dout2(),
      
      .a(sram_addr),  // Interface con la SRAM real
      .d(sram_data),
      .ce_n(),        // Estos pines ya están a GND en el esquemático
      .oe_n(),        // así que no los conecto.
      .we_n(sram_we_n)
      );

   pal_sync_generator_progressive syncs (
    .clk(clk),        // 7MHz, reloj de pixel
	 .wssclk(wssclk),  // 5MHz, reloj para la señal WSS
	 .ri(rojo),
	 .gi(verde),
	 .bi(azul),
	 .hcnt(h),
	 .vcnt(v),
    .ro(r),
    .go(g),
    .bo(b),
    .csync(csync)
    );

endmodule
