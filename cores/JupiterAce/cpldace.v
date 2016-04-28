`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:50:47 03/17/2011 
// Design Name: 
// Module Name:    contador_a 
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

/* Contador de 9 bits. Cuenta desde 000h hasta 19Fh.
Toma como entrada la señal de reloj maestro, y su salida más
lenta es de 64us. Cuenta píxeles dentro de una línea */
module clineas(
    input wire clk,
    output wire [8:0] cnt
	 );

	reg [8:0] contador = 9'b0;
	
	assign cnt = contador;
	always @(negedge clk)
		contador <= (contador==9'h19f)? 9'b0 : contador+1;
endmodule

/* Contador de 9 bits, cuyo reloj es la salida mas lenta del contador anterior.
Cuenta líneas dentro de un campo. Su salida más lenta es de 50Hz. */
module cframes(
    input wire clk,
    output wire [8:0] cnt
    );

	reg [8:0] contador = 9'b0;
	
	assign cnt = contador;
	always @(negedge clk)
		contador <= (contador==9'h137)? 9'b0 : contador+1;
endmodule

/* El contador maestro consta de los dos contadores anteriores, en cascada (ripple). */
module master_cnt(
	input wire clk,
	output wire [17:0] cnt
	);
	
	wire [8:0] ca;
	wire [8:0] cb;
	
	assign cnt = {cb,ca};
	clineas cnta (clk, ca);
	cframes cntb (ca[8], cb);
endmodule

/* El generador de sincronismos toma algunas de las salidas del contador maestro
para implementar los pulsos de sincronismo de línea y cuadro. */
module gensync(
	input wire c5,
	input wire c6,
	input wire c7,
	input wire c8,
	input wire c12,
	input wire c13,
	input wire c14,
	input wire c15,
	input wire c16,
	output wire intr,
	output wire sync);
	
	wire line, field;
	
	assign line = ~(c5 | c7) & c6 & c8;
	assign field = c12 & c13 & c14 & c15 & c16;
	assign sync = ~(line | field);
	assign intr = ~field;
endmodule

/* Control del teclado, altavoz, micrófono y señal EAR */
module io(
   input wire clk, 
	input wire en254r,
	input wire en254w,
	input wire [4:0] kbd,
	input wire ear,
	input wire d3,
	output wire [5:0] dout,
	output wire mic,
	output wire spk
	);
	
	reg ffmic;
	reg ffspk;
	reg [5:0] ear_y_teclado;
	
	assign dout = (!en254r)? ear_y_teclado : 6'bzzzzzz;
	assign mic = ffmic;
	assign spk = ffspk;
	
	always @(posedge clk)
		ear_y_teclado <= {ear,kbd};
	
	/* El micrófono se activa con el bit D3 en escritura */
	always @(posedge clk)
		if (!en254w)
			ffmic <= d3;

	/* Implementación del comportamiento del altavoz. */
	always @(posedge clk)
		if (!en254r)
			ffspk <= 1;
		else if (!en254w)
			ffspk <= 0;
endmodule

module decodificador(
	input wire [15:0] a,
	input wire mreq,
	input wire iorq,
	input wire rd,
	input wire wr,
	output wire romce,
	output wire ramce,
	output wire xramce,
	output wire vramdec,
	output wire en254r,
	output wire en254w
	);

	wire en254;
	
   /* Ecuaciones del 74LS138 */
	assign romce = mreq | a[15] | a[14] | a[13] | rd;
	assign ramce = mreq | a[15] | a[14] | ~a[13] | ~a[12]; /* modelo básico con 1K de RAM */
	assign xramce = mreq | a[15] | ~a[14];  /* ampliación de 16K de user RAM */
	assign vramdec = mreq | a[15] | a[14] | ~a[13] | a[12]; 
	assign en254 = iorq | a[0]; /* Decodificación parcial del puerto 254 */
	assign en254r = en254 | rd;
	assign en254w = en254 | wr;
endmodule

/* Módulo de generación de video y arbitrador de acceso a memoria */
module videogen_and_cpuctrl(
	input wire clk,
	input wire [15:0] a,  /* bus de direcciones CPU */
	input wire wr,
	input wire vramdec,     /* El procesador quiere acceder a la VRAM */
	input wire [17:0] cnt,  /* Las salidas del contador maestro */
	input wire [7:0] DinShiftR,  /* Entrada paralelo al registro de desplazamiento. Viene del bus de datos de la RAM de caracteres */
	input wire videoinverso,      /* Bit 7 leído de la RAM de pantalla. Indica si el caracter debe invertirse o no */
	output wire cpuwait,    /* Salida WAIT al procesador */
	output wire [9:0] ASRAMVideo,  /* Al bus de direcciones de la RAM de pantalla */
	output wire [2:0] ACRAMVideo,  /* Al bus de direcciones de la RAM de caracteres */
	output wire sramce,     /* Habilitación de la RAM de pantalla */
	output wire cramce,     /* Habilitación de la RAM de caracteres */
	output wire scramoe,    /* OE de ambas RAM's: de pantalla y de caracteres */
	output wire scramwr,    /* WE de ambas RAM's: de pantalla y de caracteres */
	output wire video       /* Señal de video, sin sincronismos */
	);
	
	wire vhold;
	wire viden;
	wire shld;
	reg ffvideoi;     /* biestable para guardar el estado de pixel invertido */
	reg envramab;    /* señal resultante del lío con la resistencia y el diodo */
	reg [7:0] shiftreg;

	assign viden = ~(cnt[16] & cnt[15]) & (~(cnt[17] | cnt[8]));
	assign vhold = ~(a[10] & viden);
	assign cpuwait = vhold | vramdec;

	/* Esto implementa lo del diodo y la resistencia para el 74LS367 */
	always @(posedge clk)
		if (vhold)
			envramab <= vramdec;
		else
			envramab <= vramdec | envramab;

	assign cramce = ~(a[11] | envramab);
	assign sramce = ~(envramab | cramce);
	assign scramwr = envramab | wr;
	assign scramoe = ~scramwr;

	assign ASRAMVideo = {cnt[16:12],cnt[7:3]};
	assign ACRAMVideo = cnt[11:9];
	
	always @(posedge clk)
		if (&cnt[2:0])
			ffvideoi <= (videoinverso & viden);

	assign shld = ~(&cnt[2:0] & viden);
	/* 74LS166. Registro serializador */
	always @(posedge clk)
		if (shld)
			shiftreg <= shiftreg<<1;
		else
			shiftreg <= DinShiftR;
	/* La señal serializada se pasa por una puerta XOR que la invierte o no */
	assign video = (shiftreg[7] ^ ffvideoi);
endmodule	
			
module jace(
   input wire clkm,
	input wire clk,
	output wire cpuclk,
	input wire [15:0] a,  /* bus de direcciones CPU */
	input wire d3,
	output wire [5:0] dout,   /* bus de datos de la CPU */	
	input wire wr,
	input wire vramdec,
	output wire intr,
	output wire cpuwait,    /* Salida WAIT al procesador */
	input wire en254r,
	input wire en254w,
	output wire sramce,     /* Habilitación de la RAM de pantalla */
	output wire cramce,     /* Habilitación de la RAM de caracteres */
	output wire scramoe,    /* OE de ambas RAM's: de pantalla y de caracteres */
	output wire scramwr,    /* WE de ambas RAM's: de pantalla y de caracteres */
	input wire [7:0] DinShiftR,  /* Entrada paralelo al registro de desplazamiento. Viene del bus de datos de la RAM de caracteres */
	input wire videoinverso,      /* Bit 7 leído de la RAM de pantalla. Indica si el caracter debe invertirse o no */
	output wire [9:0] ASRAMVideo,  /* Al bus de direcciones de la RAM de pantalla */
	output wire [2:0] ACRAMVideo,  /* Al bus de direcciones de la RAM de caracteres */
	input wire [4:0] kbd,
	input wire ear,
	output wire mic,
	output wire spk,
	output wire sync,
	output wire video       /* Señal de video, sin sincronismos */
	);
	
	wire [17:0] c;
	
	assign cpuclk = c[0];

	master_cnt cont (clk, c);
	gensync gsync (c[5],c[6],c[7],c[8],c[12],c[13],c[14],c[15],c[16],intr,sync);
	io modulo_io (
		.clk(clkm),
		.en254r(en254r),
		.en254w(en254w),
		.kbd(kbd),
		.ear(ear),
		.d3(d3),
		.dout(dout),
		.mic(mic),
		.spk(spk)
	);
	
   videogen_and_cpuctrl arbitrador(
		.clk(clk),
		.a(a),  /* bus de direcciones CPU */
		.wr(wr),
		.vramdec(vramdec),     /* El procesador quiere acceder a la VRAM */
		.cnt(c),  /* Las salidas del contador maestro */
		.DinShiftR(DinShiftR),  /* Entrada paralelo al registro de desplazamiento. Viene del bus de datos de la RAM de caracteres */
		.videoinverso(videoinverso),      /* Bit 7 leído de la RAM de pantalla. Indica si el caracter debe invertirse o no */
		.cpuwait(cpuwait),    /* Salida WAIT al procesador */
		.ASRAMVideo(ASRAMVideo),  /* Al bus de direcciones de la RAM de pantalla */
		.ACRAMVideo(ACRAMVideo),  /* Al bus de direcciones de la RAM de caracteres */
		.sramce(sramce),     /* Habilitación de la RAM de pantalla */
		.cramce(cramce),     /* Habilitación de la RAM de caracteres */
		.scramoe(scramoe),    /* OE de ambas RAM's: de pantalla y de caracteres */
		.scramwr(scramwr),    /* WE de ambas RAM's: de pantalla y de caracteres */
		.video(video)       /* Señal de video, sin sincronismos */
		);
endmodule
