`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:06:40 03/19/2011 
// Design Name: 
// Module Name:    jace_en_fpga 
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

module jupiter_ace (
    input wire clkram,
	input wire clk65,
	input wire reset,
	input wire ear,
	output wire [7:0] filas,
	input wire [4:0] columnas,
	output wire video,
	output wire sync,
    output wire mic,
    output wire spk
	);
	
	wire sramce;
    wire cramce;
	wire scramwr, scramoe;
	wire ramce, xramce, romce, vramdec;
	wire en254r, en254w;
	
	/* Los buses de memoria */
	wire [7:0] DoutROM;
	wire [7:0] DoutRAM;
	wire [7:0] DoutXRAM;
	wire [7:0] DoutSRAM;
	wire [7:0] DoutCRAM;
	wire [7:0] DoutIO;
	wire [7:0] DinZ80;
	wire [7:0] DoutZ80;
	wire [15:0] AZ80;
	wire [9:0] ASRAM;
	wire [9:0] ACRAM;
	wire [9:0] ASRAMVideo;
	wire [2:0] ACRAMVideo;
	
	wire iorq, mreq, intr, cpuclk, rd, wr, cpuwait;

	/* Copia del bus de direcciones para las filas del teclado */
    assign filas = AZ80[15:8];

	tri [7:0] Din; // bus de datos triestado. Todo lo que esta conectado a el...
	assign Din = (!romce)? DoutROM : 8'bzzzzzzzz;
	assign Din = DoutRAM;
	assign Din = DoutXRAM;
	assign Din[5:0] = DoutIO;
	assign Din = (!sramce && cpuwait && !vramdec)? DoutSRAM : 8'bzzzzzzzz;
	assign Din = (!cramce && cpuwait && !vramdec)? DoutCRAM : 8'bzzzzzzzz;
	assign DinZ80 = Din;	
	
	/* Arbitrador del bus de direcciones de entrada a la SRAM */
	assign ASRAM = (!vramdec && cpuwait)? AZ80[9:0] : ASRAMVideo;
	
	/* Arbitrador del bus de direccioens de entrada a la CRAM */
	assign ACRAM = (!vramdec && cpuwait)? AZ80[9:0] : {DoutSRAM[6:0],ACRAMVideo};

	/* La memoria RAM del equipo */
	ram1k sram (
       .clk(clkram),
	   .a(ASRAM),
	   .din(DoutZ80),
	   .dout(DoutSRAM),
	   .ce_n(sramce),
	   .oe_n(scramoe),
	   .we_n(scramwr)
		);
		
	ram1k cram( 
		.clk(clkram),
	   .a(ACRAM),
	   .din(DoutZ80),
	   .dout(DoutCRAM),
	   .ce_n(cramce),
	   .oe_n(scramoe),
	   .we_n(scramwr)
		);

	ram1k uram(
		.clk(clkram),
	   .a(AZ80[9:0]),
	   .din(DoutZ80),
	   .dout(DoutRAM),
	   .ce_n(ramce),
	   .oe_n(rd),
	   .we_n(wr)
		);
		
	ram16k xram(
		.clk(clkram),
	   .a(AZ80[13:0]),
	   .din(DoutZ80),
	   .dout(DoutXRAM),
	   .ce_n(xramce),
	   .oe_n(rd),
	   .we_n(wr)
		);
	

	/* La ROM */
	rom8k rom(
		.clka(clkram),
	   .addra(AZ80[12:0]),
	   .douta(DoutROM),
	   .ena(~romce)
		);
	
	/* Decodificador de acceso a memoria y E/S */
	decodificador deco(
		.a(AZ80),
		.mreq(mreq),
		.iorq(iorq),
		.rd(rd),
		.wr(wr),
		.romce(romce),
		.ramce(ramce),
		.xramce(xramce),
		.vramdec(vramdec),
		.en254r(en254r),
		.en254w(en254w)
		);
	
	/* Logica de arbitración de memoria y periféricos */
	jace glue_logic (
	.clkm(clkram),
	.clk(clk65),
	.cpuclk(cpuclk),
	.a(AZ80),  /* bus de direcciones CPU */
	.d3(DoutZ80[3]),
	.dout(DoutIO[5:0]),   /* bus de datos de la CPU */
	.wr(wr),
	.vramdec(vramdec),
	.intr(intr),
	.cpuwait(cpuwait),    /* Salida WAIT al procesador */
	.en254r(en254r),
	.en254w(en254w),
	.sramce(sramce),     /* Habilitación de la RAM de pantalla */
	.cramce(cramce),     /* Habilitación de la RAM de caracteres */
	.scramoe(scramoe),    /* OE de ambas RAM's: de pantalla y de caracteres */
	.scramwr(scramwr),    /* WE de ambas RAM's: de pantalla y de caracteres */
	.DinShiftR(DoutCRAM),  /* Entrada paralelo al registro de desplazamiento. Viene del bus de datos de la RAM de caracteres */
	.videoinverso(DoutSRAM[7]),      /* Bit 7 leído de la RAM de pantalla. Indica si el caracter debe invertirse o no */
	.ASRAMVideo(ASRAMVideo),  /* Al bus de direcciones de la RAM de pantalla */
	.ACRAMVideo(ACRAMVideo),  /* Al bus de direcciones de la RAM de caracteres */
	.kbd(columnas),
	.ear(ear),
	.mic(mic),
	.spk(spk),
	.sync(sync),
	.video(video)       /* Señal de video, sin sincronismos */
	);
	
	/* La CPU */
	tv80n cpu(
		// Outputs
		.m1_n(), .mreq_n(mreq), .iorq_n(iorq), .rd_n(rd), .wr_n(wr), .rfsh_n(), .halt_n(), .busak_n(), .A(AZ80), .do(DoutZ80),
		// Inputs
		.di(DinZ80), .reset_n(reset), .clk(cpuclk), .wait_n(cpuwait), .int_n(intr), .nmi_n(1'b1), .busrq_n(1'b1)
   );
endmodule

