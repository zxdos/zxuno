`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:40:55 03/05/2014
// Design Name:   spi
// Module Name:   C:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/test11/tb_spi.v
// Project Name:  zxuno
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spi
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_spi;

	// Inputs
	reg clk;
	reg enviar_dato;
	reg recibir_dato;
	reg [7:0] din;
	reg spi_do;

	// Outputs
	wire [7:0] dout;
	wire oe_n;
	wire spi_clk;
	wire spi_di;

	// Instantiate the Unit Under Test (UUT)
	spi uut (
		.clk(clk), 
		.enviar_dato(enviar_dato), 
		.recibir_dato(recibir_dato), 
		.din(din), 
		.dout(dout), 
		.oe_n(oe_n), 
		.spi_clk(spi_clk), 
		.spi_di(spi_di), 
		.spi_do(spi_do)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		enviar_dato = 0;
		recibir_dato = 0;
		din = 0;
		spi_do = 0;

		// Wait 100 ns for global reset to finish
		#300;
      
      din = 8'b11001011;
      enviar_dato = 1;
      #700;
      enviar_dato = 0;
        
      #2000;  
      
      recibir_dato = 1;

      spi_do = 1;
      @(negedge spi_clk);
      spi_do = 0;
      @(negedge spi_clk);
      spi_do = 1;
      @(negedge spi_clk);
      spi_do = 1;
      @(negedge spi_clk);
      spi_do = 0;
      @(negedge spi_clk);
      spi_do = 0;
      @(negedge spi_clk);
      spi_do = 1;
      @(negedge spi_clk);
      spi_do = 1;
      @(negedge spi_clk);
      
      #200;
      recibir_dato = 0;
      #100;
      $finish;
	end
   
   always begin
      clk = #71.428571428571428571428571428571 ~clk;
   end
      
endmodule

