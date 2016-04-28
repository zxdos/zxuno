`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:45:29 02/13/2014
// Design Name:   zxuno
// Module Name:   C:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/test8/tb_zxuno.v
// Project Name:  zxuno
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: zxuno
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_zxuno;

	// Inputs
	reg clk;
	reg wssclk;
   reg ramclk;
   reg power_on_reset_n;
	reg clkps2;
	reg dataps2;
	reg ear;

	// Outputs
	wire [2:0] r;
	wire [2:0] g;
	wire [2:0] b;
	wire csync;
	wire audio_out;
	wire [13:0] addr_rom_16k;
	wire [18:0] sram_addr;
	wire sram_we_n;

	// Bidirs
	wire [7:0] sram_data;

   // Instanciación del sistema
   wire [7:0] rom_dout;

	// Instantiate the Unit Under Test (UUT)
	zxuno uut (
		.clk(clk), 
		.wssclk(wssclk),
      .power_on_reset_n(power_on_reset_n),
		.r(r), 
		.g(g), 
		.b(b), 
		.csync(csync), 
		.clkps2(clkps2), 
		.dataps2(dataps2), 
		.ear(ear), 
		.audio_out(audio_out), 
		.addr_rom_16k(addr_rom_16k), 
		.rom_dout(rom_dout), 
		.sram_addr(sram_addr), 
		.sram_data(sram_data), 
		.sram_we_n(sram_we_n)
	);

    rom rom_inicial (
      .clk(clk),
      .a(addr_rom_16k),
      .dout(rom_dout)
    );

   ram512kb ram_simulada (
      .a(sram_addr),
      .d(sram_data),
      .we_n(sram_we_n)
    );

	initial begin
		// Initialize Inputs
		clk = 0;
		wssclk = 0;
      ramclk = 0;
		clkps2 = 0;
		dataps2 = 0;
		ear = 0;
      power_on_reset_n = 0;

		// Wait 500 ns for global reset to finish
      #500 power_on_reset_n = 1;  

		// Add stimulus here

	end

   always begin  // reloj de 28MHz para todo el sistema
      clk = #17.857142857142857142857142857143 ~clk;
   end
   
   always begin  // reloj de 5MHz para el WSS
      wssclk = #100 ~wssclk;
   end
   
   always begin  // reloj de 20MHz, para la SRAM
      ramclk = #25 ~ramclk;
   end
      
endmodule

module ram512kb (
   input wire [18:0] a,
   inout wire [7:0] d,
   input wire we_n
   );
   
   reg [7:0] ram[0:524287];
   integer i;
   initial begin
      for (i=0;i<524288;i=i+1)
         ram[i] = 0;
   end

   reg [7:0] dout;
   assign d = (we_n==1'b0)? 8'hZZ : dout;
   
   always @* begin
      if (we_n==1'b0)
         ram[a] = d;
      else
         dout = ram[a];
   end
endmodule
