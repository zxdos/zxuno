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
   output wire stdn,
   output wire stdnb,
   
   output wire [20:0] sram_addr,
   inout wire [7:0] sram_data,
   output wire sram_we_n
   );

   assign stdn = 1'b0;  // PAL
   assign stdnb = 1'b1;   

   // Generación de relojes
   reg [1:0] divs = 2'b00;
   wire wssclk,sysclk;
   wire clk14 = divs[0];
   wire clk7 = divs[1];
   always @(posedge sysclk)
      divs <= divs + 1;

   relojes los_relojes_del_sistema (
    .CLKIN_IN(clk50mhz), 
    .CLKDV_OUT(wssclk), 
    .CLKFX_OUT(sysclk), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(), 
    .LOCKED_OUT()
    );

   // Instanciación del sistema
   zxuno la_maquina (
    .clk(clk7),
    .sramclk(sysclk),
    .wssclk(wssclk),
    .r(r),
    .g(g),
    .b(b),
    .csync(csync),

    .sram_addr(sram_addr),
    .sram_data(sram_data),
    .sram_we_n(sram_we_n)
    );

endmodule
