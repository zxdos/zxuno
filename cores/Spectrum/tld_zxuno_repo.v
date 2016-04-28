`timescale 1ns / 1ns
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:28:18 02/06/2014 
// Design Name: 
// Module Name:    test1 
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

module tld_zxuno (
   input wire clk50mhz,

   output wire [2:0] r,
   output wire [2:0] g,
   output wire [2:0] b,
   output wire csync,
   input wire ear,
   input wire clkps2,
   input wire dataps2,
   output wire audio_out_left,
   output wire audio_out_right,
   
   output wire [18:0] sram_addr,
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
   
//   output wire ss,
//   output wire sclk,
//   output wire mosi,
//   output wire miso,
   
   output wire testled   // nos servirá como testigo de uso de la SPI
   );

   wire wssclk,sysclk;
   relojes los_relojes_del_sistema (
    .CLKIN_IN(clk50mhz), 
    .CLKDV_OUT(wssclk), //  5MHz
    .CLKFX_OUT(sysclk), // 28MHz 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(), 
    .LOCKED_OUT()
    );

   wire audio_out;
   assign audio_out_left = audio_out;
   assign audio_out_right = audio_out;
   
   zxuno la_maquina (
    .clk(sysclk),         // 28MHz, reloj base para la memoria de doble puerto, y de ahí, para el resto del circuito
    .wssclk(wssclk),      //  5MHz, reloj para el WSS
    .power_on_reset_n(1'b1),  // sólo para simulación. Para implementacion, dejar a 1
    .r(r),
    .g(g),
    .b(b),
    .csync(csync),
    .clkps2(clkps2),
    .dataps2(dataps2),
    .ear(~ear),  // negada porque el hardware tiene un transistor inversor
    .audio_out(audio_out),

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
    .sd_miso(sd_miso)
    );
    
//    assign ss = sd_cs_n;
//    assign sclk = sd_clk;
//    assign mosi = sd_mosi;
//    assign miso = sd_miso;
    
    assign testled = (!flash_cs_n || !sd_cs_n);

endmodule
