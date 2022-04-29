`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 17:57:54 2015-09-11 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module vga_scandoubler (
  input wire clk,
  input wire clkcolor4x,
  input wire clk14en,
  input wire enable_scandoubling,
  input wire disable_scaneffect,  // 1 to disable scanlines
  input wire [5:0] ri,
  input wire [5:0] gi,
  input wire [5:0] bi,
  input wire hsync_ext_n,
  input wire vsync_ext_n,
  input wire hblank_ext_n,
  input wire vblank_ext_n,
  input wire csync_ext_n,
  output reg [5:0] ro,
  output reg [5:0] go,
  output reg [5:0] bo,
  output reg hsync,
  output reg vsync,
  output reg hblank,
  output reg vblank
  
  );
 
  parameter [31:0] CLKVIDEO = 12000;
 
  // http://www.epanorama.net/faq/vga2rgb/calc.html
  // SVGA 800x600
  // HSYNC = 3.36us  VSYNC = 114.32us

//[*User-Defined_mode,(800X600)]
//PIXEL_CLK   =   38100
//H_DISP   =   800
//H_FPORCH   =   32
//H_SYNC   =   128
//H_BPORCH   =   128
//H_SYNC_POL   =   0
//V_DISP   =   600
//V_FPORCH   =   1
//V_SYNC   =   4
//V_BPORCH   =   14
//V_SYNC_POL   =   0
//INTERLACE_ENABLE  =  0
  
  parameter [63:0] HSYNC_COUNT = (CLKVIDEO * 3360 * 2)/1000000;
  parameter [63:0] VSYNC_COUNT = (CLKVIDEO * 114320 * 2)/1000000;
 
  parameter [63:0] HBLANK_COUNT = 128+128; // H_FPORCH + HSYNC + H_BPORCH -> el H_FPORCH (32 en este caso) lo controlamos fuera de esta variable
  parameter [63:0] VBLANK_COUNT = 1+4+14; // V_FPORCH + VSYNC + V_BPORCH

  reg [10:0] addrvideo = 11'd0, addrvga = 11'b00000000000;
  reg [9:0] totalhor = 10'd0;

  wire [5:0] rout, gout, bout;
  // Memoria de doble puerto que guarda la informaci�n de dos scans
  // Cada scan puede ser de hasta 1024 puntos, incluidos aqu� los
  // puntos en negro que se pintan durante el HBlank

  vgascanline_dport memscan (
    .clk(clk),
    .addrwrite(addrvideo),
    .addrread(addrvga),
    .we(clk14en),
    .din({ri,gi,bi}),
    .dout({rout,gout,bout})
  );

  // Para generar scanlines:
  reg scaneffect = 1'b0;
  wire [5:0] rout_dimmed, gout_dimmed, bout_dimmed;
  color_dimmed apply_to_red   (rout, rout_dimmed);
  color_dimmed apply_to_green (gout, gout_dimmed);
  color_dimmed apply_to_blue  (bout, bout_dimmed);
  wire [5:0] ro_vga = (scaneffect | disable_scaneffect)? rout : rout_dimmed;
  wire [5:0] go_vga = (scaneffect | disable_scaneffect)? gout : gout_dimmed;
  wire [5:0] bo_vga = (scaneffect | disable_scaneffect)? bout : bout_dimmed;
  
  // Voy alternativamente escribiendo en una mitad o en otra del scan buffer
  // Cambio de mitad cada vez que encuentro un pulso de sincronismo horizontal
  // En "totalhor" mido el n�mero de ciclos de reloj que hay en un scan
  reg hsync_ext_n_prev = 1'b1;
  always @(posedge clk) begin
    if (clk14en == 1'b1) begin
      hsync_ext_n_prev <= hsync_ext_n;
      if (hsync_ext_n == 1'b0 && hsync_ext_n_prev == 1'b1) begin
        totalhor <= addrvideo[9:0];
        addrvideo <= {~addrvideo[10],10'b0000000000};
      end
      else
        addrvideo <= addrvideo + 11'd1;
    end
  end
 
  // Recorro el scanbuffer al doble de velocidad, generando direcciones para
  // el scan buffer. Cada vez que el video original ha terminado una linea,
  // cambio de mitad de buffer. Cuando termino de recorrerlo pero a�n no
  // estoy en un retrazo horizontal, simplemente vuelvo a recorrer el scan buffer
  // desde el mismo origen
  // Cada vez que termino de recorrer el scan buffer basculo "scaneffect" que
  // uso despu�s para mostrar los p�xeles a su brillo nominal, o con su brillo
  // reducido para un efecto chachi de scanlines en la VGA
 
  reg hsync_ext_n_prev2 = 1'b1;
  always @(posedge clk) begin
      hsync_ext_n_prev2 <= hsync_ext_n;
      if (addrvga[9:0] == totalhor && hsync_ext_n == 1'b1 && hsync_ext_n_prev2 == 1'b1) begin
         addrvga <= {addrvga[10], 10'b000000000};
         scaneffect <= ~scaneffect;
      end
      else if (hsync_ext_n == 1'b0 && hsync_ext_n_prev2 == 1'b1 /*&& addrvga[9] == 1'b0*/) begin
        addrvga <= {addrvideo[10],10'b000000000};
        scaneffect <= ~scaneffect;
      end
      else
        addrvga <= addrvga + 11'd1;
  end

  // El HSYNC de la VGA est� bajo s�lo durante HSYNC_COUNT ciclos a partir del comienzo
  // del barrido de un scanline
  reg hsync_vga, vsync_vga;
    
  always @* begin
    if (addrvga[9:0] < HSYNC_COUNT[9:0])
       hsync_vga = 1'b0;
    else
       hsync_vga = 1'b1;
  end


  reg hblank_vga, vblank_vga;
always @(posedge clk) begin
    if (addrvga[9:0] < HBLANK_COUNT[9:0] || addrvga[9:0] > totalhor - 32 ) //H_FPORCH (32 en este caso)
       hblank_vga = 1'b0;
    else
       hblank_vga = 1'b1;
  end

  
  // El VSYNC de la VGA est� bajo s�lo durante VSYNC_COUNT ciclos a partir del flanco de
  // bajada de la se�al de sincronismo vertical original
  reg [15:0] cntvsync = 16'hFFFF;
  initial vsync_vga = 1'b1;
  always @(posedge clk) begin
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

  
  // El VBLANK de la VGA est� bajo s�lo durante VBLANK_COUNT ciclos a partir del flanco de
  // bajada de la se�al de Blank vertical original
  reg [15:0] cntvblank = 16'hFFFF;
  initial vblank_vga = 1'b1;
  always @(posedge clk) begin
      if (vblank_ext_n == 1'b0) begin
        if (cntvblank == 16'hFFFF) begin
          cntvblank <= 16'd0;
          vblank_vga <= 1'b0;
        end
        else if (cntvblank != 16'hFFFE) begin
          if (cntvblank == VSYNC_COUNT[15:0]) begin
            vblank_vga <= 1'b1;
            cntvblank <= 16'hFFFE;
          end
          else
            cntvblank <= cntvblank + 16'd1;
        end
      end
      else if (vblank_ext_n == 1'b1)
        cntvblank <= 16'hFFFF;
  end
  
  
  always @* begin
    if (enable_scandoubling == 1'b0) begin // 15kHz output
      ro = ri;
      go = gi;
      bo = bi;
      hsync = csync_ext_n;
      vsync = clkcolor4x;
      hblank = hblank_ext_n;
      vblank = vblank_ext_n;
    end
    else begin  // VGA output
      ro = ro_vga;
      go = go_vga;
      bo = bo_vga;
      hsync = hsync_vga;
      vsync = vsync_vga;
      hblank = hblank_vga;
      vblank = vblank_vga;
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
 input wire [17:0] din,
 output reg [17:0] dout
 );
 
reg [17:0] scan[0:2047]; // two scanlines
    always @(posedge clk) begin
        dout <= scan[addrread];
        if (we == 1'b1)
            scan[addrwrite] <= din;
    end
endmodule

module color_dimmed (
  input wire [5:0] in,
  output wire [5:0] out // out se escala siendo alrededor del 70% de in (70% = 0.7 = .1011 aprox.)
  );
    
  assign out = {1'b0, in[5:1]} + {3'b000, in[5:3]} + {4'b0000, in[5:4]};
endmodule

        