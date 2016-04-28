`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   04:14:03 03/17/2011
// Design Name:   jace
// Module Name:   C:/proyectos_xilinx/cpld_jace/test_cpld_ace.v
// Project Name:  cpld_jace
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: jace
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_jace_en_fpga;

	// Inputs
	reg clk;

	// Outputs
	wire mic,spk,sync,video;

	// Instantiate the Unit Under Test (UUT)

   jace_en_fpga uut (
		clk,
	   0,
	   spk,
	   mic,
	   video,
	   sync
		);

	always #77 clk = !clk;
	initial
		begin
			clk = 0;
		end		
endmodule

module test_cpld_ace;

	// Inputs
	reg clk;
	reg [15:0] a;
	reg mreq;

	// Outputs
	wire cpuclk,intr;
	wire [5:0] db;
	wire cpuwait;
	wire romce,ramce,sramce,cramce,scramoe,scramwr;
	wire [9:0] sramab;
	wire [9:0] cramab;
	wire mic,spk,sync,video;

	// Instantiate the Unit Under Test (UUT)
	jace uut (clk, cpuclk, a, db, mreq, 1, 1, 1, intr, cpuwait,
	romce,      /* Habilitación ROM */
	ramce,      /* Habilitación RAM de usuario */
	sramce,     /* Habilitación de la RAM de pantalla */
	cramce,     /* Habilitación de la RAM de caracteres */
	scramoe,    /* OE de ambas RAM's: de pantalla y de caracteres */
	scramwr,    /* WE de ambas RAM's: de pantalla y de caracteres */
	8'hF0,  /* Entrada paralelo al registro de desplazamiento. Viene del bus de datos de la RAM de caracteres */
	0,      /* Bit 7 leído de la RAM de pantalla. Indica si el caracter debe invertirse o no */
	sramab,  /* Al bus de direcciones de la RAM de pantalla */
	cramab,  /* Al bus de direcciones de la RAM de caracteres */
	5'b11111, /* Teclado */
	0, /* EAR */
	mic,
	spk,
	sync,
	video       /* Señal de video, sin sincronismos */
	);

	always #77 clk = !clk;
	initial
		begin
			clk = 0;
			a = 0;
			#16000
			a = 16'h27FF;
			mreq = 0;
			#24000
			mreq = 1;
			#40000
			a = 16'h2FFF;
			mreq = 0;
			#24000
			mreq = 1;			
		end		
endmodule
