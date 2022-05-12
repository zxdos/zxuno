`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:50:06 22/05/2021 
// Design Name: 
// Module Name:    monochrome
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

module monochrome (
  input wire [1:0] monochrome_selection,
  input wire [2:0] ri,
  input wire [2:0] gi,
  input wire [2:0] bi,
  output reg [2:0] ro,
  output reg [2:0] go,
  output reg [2:0] bo  
  );
  
  reg [2:0] monochrome_scale_spectrum;
  
  always @* begin
    ro = ri;
    go = gi;
    bo = bi;
	 
	 // Escala monocromatica especifica para la paleta original 
	 // de Spectrum. Los colores brillantes no son diferenciados 
	 // respecto a los no brillantes por limitacion del DAC.
	 
	 // No se representan colores adicionales como los del ULAPlus
	 
	 if (monochrome_selection > 2'b00) begin
	 
	 	if (ri == 1'b0 && gi == 1'b0 && bi == 1'b0) begin // Negro
			monochrome_scale_spectrum = 'd0;
		end
		else if (ri == 1'b0 && gi == 1'b0 && bi > 1'b0) begin // Azul
			if (bi >= 3'b110) begin //Azul brillante
				monochrome_scale_spectrum = 'd2;
			end
			else begin
				monochrome_scale_spectrum = 'd1;
			end
		end
		else if (ri > 1'b0 && gi == 1'b0 && bi == 1'b0) begin // Rojo
			if (ri >= 3'b110) begin //Rojo brillante
				monochrome_scale_spectrum = 'd3;
			end
			else begin
				monochrome_scale_spectrum = 'd2;
			end
		end
		else if (ri > 1'b0 && gi == 1'b0 && bi > 1'b0) begin // Magenta
			if (ri >= 3'b110 && bi >= 3'b110) begin //Magenta brillante
				monochrome_scale_spectrum = 'd4;
			end
			else begin
				monochrome_scale_spectrum = 'd3;
			end
		end
		else if (ri == 1'b0 && gi > 1'b0 && bi == 1'b0) begin // Verde
			if (gi >= 3'b110) begin // Verde brillante
				monochrome_scale_spectrum = 'd5;
			end
			else begin
				monochrome_scale_spectrum = 'd4;
			end
		end
		else if (ri == 1'b0 && gi > 1'b0 && bi > 1'b0) begin // Cian
			if (gi >= 3'b110 && bi >= 3'b110) begin // Cian brillante
				monochrome_scale_spectrum = 'd6;
			end
			else begin
				monochrome_scale_spectrum = 'd5;
			end
		end
		else if (ri > 1'b0 && gi > 1'b0 && bi == 1'b0) begin // Amarillo
			if (ri >= 3'b110 && gi >= 3'b110) begin // Amarillo brillante
				monochrome_scale_spectrum = 'd7; 
			end
			else begin
				monochrome_scale_spectrum = 'd6;
			end
		end
		else if (ri > 1'b0 && gi > 1'b0 && bi > 1'b0) begin // Blanco
			monochrome_scale_spectrum = 'd7;
		end			
		
		// Seleccion de tipos de colores monocromaticos
		
		if (monochrome_selection == 3'b01) begin // Verde
			ro = 3'b000;
			go = monochrome_scale_spectrum;
			bo = 3'b000;
		end
		else if (monochrome_selection == 3'b10) begin // Ambar
			ro = monochrome_scale_spectrum;
			go = monochrome_scale_spectrum >> 1;
			bo = 3'b000;
		end
		else if (monochrome_selection == 3'b11) begin // Blanco y negro
			ro = monochrome_scale_spectrum;
			go = monochrome_scale_spectrum;
			bo = monochrome_scale_spectrum;
		end
		
	 end	 
	 
  end
endmodule
