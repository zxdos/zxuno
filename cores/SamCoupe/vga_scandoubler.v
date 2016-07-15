`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:57:54 11/09/2015 
// Design Name: 
// Module Name:    vga_scandoubler 
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
module vga_scandoubler (
	input wire clkvideo,
	input wire clkvga,
    input wire enable_scandoubling,
    input wire disable_scaneffect,  // 1 to disable scanlines
	input wire [2:0] ri,
	input wire [2:0] gi,
	input wire [2:0] bi,
	input wire hsync_ext_n,
	input wire vsync_ext_n,
	output reg [2:0] ro,
	output reg [2:0] go,
	output reg [2:0] bo,
	output reg hsync,
	output reg vsync
   );
	
	parameter [31:0] CLKVIDEO = 12000;
	
	// http://www.epanorama.net/faq/vga2rgb/calc.html
	// SVGA 800x600
	// HSYNC = 3.36us  VSYNC = 114.32us
	
	parameter [63:0] HSYNC_COUNT = (CLKVIDEO * 3360 * 2)/1000000;
	parameter [63:0] VSYNC_COUNT = (CLKVIDEO * 114320 * 2)/1000000;
	
	reg [10:0] addrvideo = 11'd0, addrvga = 11'b00000000000;
	reg [9:0] totalhor = 10'd0;

	wire [2:0] rout, gout, bout;
	// Memoria de doble puerto que guarda la información de dos scans
	// Cada scan puede ser de hasta 1024 puntos, incluidos aquí los
	// puntos en negro que se pintan durante el HBlank
	vgascanline_dport memscan (
		.clk(clkvga),
		.addrwrite(addrvideo),
		.addrread(addrvga),
		.we(1'b1),
		.din({ri,gi,bi}),
		.dout({rout,gout,bout})
	);

	// Para generar scanlines:
	reg scaneffect = 1'b0;
    wire [2:0] rout_dimmed, gout_dimmed, bout_dimmed;
    color_dimmed apply_to_red   (rout, rout_dimmed);
    color_dimmed apply_to_green (gout, gout_dimmed);
    color_dimmed apply_to_blue  (bout, bout_dimmed);
	wire [2:0] ro_vga = (scaneffect | disable_scaneffect)? rout : rout_dimmed;
	wire [2:0] go_vga = (scaneffect | disable_scaneffect)? gout : gout_dimmed;
	wire [2:0] bo_vga = (scaneffect | disable_scaneffect)? bout : bout_dimmed;
		
	// Voy alternativamente escribiendo en una mitad o en otra del scan buffer
	// Cambio de mitad cada vez que encuentro un pulso de sincronismo horizontal
	// En "totalhor" mido el número de ciclos de reloj que hay en un scan
	always @(posedge clkvideo) begin
//        if (vsync_ext_n == 1'b0) begin
//            addrvideo <= 11'd0;
//        end    
		if (hsync_ext_n == 1'b0 && addrvideo[9:7] != 3'b000) begin
			totalhor <= addrvideo[9:0];
			addrvideo <= {~addrvideo[10],10'b0000000000};
		end
		else
			addrvideo <= addrvideo + 11'd1;
	end
	
	// Recorro el scanbuffer al doble de velocidad, generando direcciones para
	// el scan buffer. Cada vez que el video original ha terminado una linea,
	// cambio de mitad de buffer. Cuando termino de recorrerlo pero aún no
	// estoy en un retrazo horizontal, simplemente vuelvo a recorrer el scan buffer
	// desde el mismo origen
	// Cada vez que termino de recorrer el scan buffer basculo "scaneffect" que
	// uso después para mostrar los píxeles a su brillo nominal, o con su brillo
	// reducido para un efecto chachi de scanlines en la VGA
	always @(posedge clkvga) begin
//        if (vsync_ext_n == 1'b0) begin
//            addrvga <= 11'b10000000000;
//            scaneffect <= 1'b0;
//        end    
		if (addrvga[9:0] == totalhor && hsync_ext_n == 1'b1) begin
			addrvga <= {addrvga[10], 10'b000000000};
			scaneffect <= ~scaneffect;
		end
		else if (hsync_ext_n == 1'b0 && addrvga[9:7] != 3'b000) begin
			addrvga <= {~addrvga[10],10'b000000000};
			scaneffect <= ~scaneffect;
		end
		else
			addrvga <= addrvga + 11'd1;
	end

	// El HSYNC de la VGA está bajo sólo durante HSYNC_COUNT ciclos a partir del comienzo
	// del barrido de un scanline
    reg hsync_vga, vsync_vga;
    
	always @* begin
		if (addrvga[9:0] < HSYNC_COUNT[9:0])
			hsync_vga = 1'b0;
		else
			hsync_vga = 1'b1;
	end
	
	// El VSYNC de la VGA está bajo sólo durante VSYNC_COUNT ciclos a partir del flanco de
	// bajada de la señal de sincronismo vertical original
	reg [15:0] cntvsync = 16'hFFFF;
	initial vsync_vga = 1'b1;
	always @(posedge clkvga) begin
		if (vsync_ext_n == 1'b0) begin
			if (cntvsync == 16'hFFFF) begin
				cntvsync <= 16'd0;
				vsync_vga <= 1'b0;
			end
			else if (cntvsync != 16'hFFFE) begin
				if (cntvsync == VSYNC_COUNT[15:0]) begin
					vsync_vga <= 1'b1;
					cntvsync <= 16'hFFFE;
				end
				else
					cntvsync <= cntvsync + 16'd1;
			end
		end
		else if (vsync_ext_n == 1'b1)
			cntvsync <= 16'hFFFF;
	end

    always @* begin
        if (enable_scandoubling == 1'b0) begin // 15kHz output
            ro = ri;
            go = gi;
            bo = bi;
            hsync = hsync_ext_n ^ ~vsync_ext_n;
            vsync = 1'b1;
        end
        else begin  // VGA output
            ro = ro_vga;
            go = go_vga;
            bo = bo_vga;
            hsync = hsync_vga;
            vsync = vsync_vga;
        end
    end
    
endmodule

// Una memoria de doble puerto: uno para leer, y otro para
// escribir. Es de 2048 direcciones: 1024 se emplean para
// guardar un scan, y otros 1024 para el siguiente scan
module vgascanline_dport (
	input wire clk,
	input wire [10:0] addrwrite,
	input wire [10:0] addrread,
	input wire we,
	input wire [8:0] din,
	output reg [8:0] dout
	);
	
	reg [8:0] scan[0:2047]; // two scanlines
	always @(posedge clk) begin
		dout <= scan[addrread];
		if (we == 1'b1)
			scan[addrwrite] <= din;
	end
endmodule

module color_dimmed (
    input wire [2:0] in,
    output reg [2:0] out // out is scaled to roughly 70% of in
    );
    
    always @* begin  // a LUT
        case (in)  
            3'd0 : out = 3'd0;
            3'd1 : out = 3'd1;
            3'd2 : out = 3'd1;
            3'd3 : out = 3'd2;
            3'd4 : out = 3'd3;
            3'd5 : out = 3'd3;
            3'd6 : out = 3'd4;
            3'd7 : out = 3'd5;
            default: out = 3'd0;
        endcase
    end
endmodule
        