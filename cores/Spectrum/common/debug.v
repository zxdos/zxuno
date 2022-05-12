`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 21:14:58 2019-03-30 by Miguel Angel Rodriguez Jodar
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

module debug (
  input wire clk, 
  input wire visible,
  input wire [8:0] hc,
  input wire [8:0] vc,
  input wire [2:0] ri,
  input wire [2:0] gi,
  input wire [2:0] bi,
  output reg [2:0] ro,
  output reg [2:0] go,
  output reg [2:0] bo,
  //////////////////////////
  input wire [15:0] v16_a,
  input wire [15:0] v16_b,
  input wire [15:0] v16_c,
  input wire [15:0] v16_d,
  input wire [15:0] v16_e,
  input wire [15:0] v16_f,
  input wire [15:0] v16_g,
  input wire [15:0] v16_h,
  input wire [7:0] v8_a,
  input wire [7:0] v8_b,
  input wire [7:0] v8_c,
  input wire [7:0] v8_d,
  input wire [7:0] v8_e,
  input wire [7:0] v8_f,
  input wire [7:0] v8_g,
  input wire [7:0] v8_h  
  );
  
  parameter OFFX = 9'd16;
  parameter OFFY = 9'd200;
  
  reg [1:0] divclk = 2'b00;
  wire clken = divclk[0];
  wire clk7 = divclk[1];
  
  reg [3:0] digito;
  wire [7:0] bitmap;
  reg [7:0] sr = 8'h00;
  reg espacio = 1'b0;
  reg [5:0] charpos = 6'd0;
  reg [4:0] nxt_espacio_digito;
  
  charset_rom hexchars (
    .clk(clk),
    .digito(digito),
    .scan(vc[2:0]),
    .espacio(espacio),
    .bitmap(bitmap)
    );
    
  always @(posedge clk) begin
    divclk <= divclk + 2'd1;
    if (clken == 1'b1 && visible == 1'b1) begin
      if (hc[1:0] == 2'd3 && clk7 == 1'b1)
        sr <= bitmap;
      else
        sr <= {sr[6:0], 1'b0};
      if (vc >= OFFY && vc < (OFFY+9'd8) && hc >= (OFFX-9'd4) && hc < (OFFX+9'd256-9'd4)) begin
        if (hc[1:0] == 2'd2 && clk7 == 1'b1) begin
          charpos <= charpos + 6'd1;
          espacio <= nxt_espacio_digito[4];
          digito <= nxt_espacio_digito[3:0];        
        end
      end
      else if (hc == 9'd0)
        charpos <= 6'd0;
    end
  end

  always @* begin
    case (charpos)
      6'd0 : nxt_espacio_digito = {1'b0, v16_a[15:12]};
      6'd1 : nxt_espacio_digito = {1'b0, v16_a[11:8]};
      6'd2 : nxt_espacio_digito = {1'b0, v16_a[7:4]};
      6'd3 : nxt_espacio_digito = {1'b0, v16_a[3:0]};
      6'd4 : nxt_espacio_digito = {1'b1, 4'h0};
  
      6'd5 : nxt_espacio_digito = {1'b0, v16_b[15:12]};
      6'd6 : nxt_espacio_digito = {1'b0, v16_b[11:8]};
      6'd7 : nxt_espacio_digito = {1'b0, v16_b[7:4]};
      6'd8 : nxt_espacio_digito = {1'b0, v16_b[3:0]};
      6'd9 : nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd10: nxt_espacio_digito = {1'b0, v16_c[15:12]};
      6'd11: nxt_espacio_digito = {1'b0, v16_c[11:8]};
      6'd12: nxt_espacio_digito = {1'b0, v16_c[7:4]};
      6'd13: nxt_espacio_digito = {1'b0, v16_c[3:0]};
      6'd14: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd15: nxt_espacio_digito = {1'b0, v16_d[15:12]};
      6'd16: nxt_espacio_digito = {1'b0, v16_d[11:8]};
      6'd17: nxt_espacio_digito = {1'b0, v16_d[7:4]};
      6'd18: nxt_espacio_digito = {1'b0, v16_d[3:0]};
      6'd19: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd20: nxt_espacio_digito = {1'b0, v16_e[15:12]};
      6'd21: nxt_espacio_digito = {1'b0, v16_e[11:8]};
      6'd22: nxt_espacio_digito = {1'b0, v16_e[7:4]};
      6'd23: nxt_espacio_digito = {1'b0, v16_e[3:0]};
      6'd24: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd25: nxt_espacio_digito = {1'b0, v16_f[15:12]};
      6'd26: nxt_espacio_digito = {1'b0, v16_f[11:8]};
      6'd27: nxt_espacio_digito = {1'b0, v16_f[7:4]};
      6'd28: nxt_espacio_digito = {1'b0, v16_f[3:0]};
      6'd29: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd30: nxt_espacio_digito = {1'b0, v16_g[15:12]};
      6'd31: nxt_espacio_digito = {1'b0, v16_g[11:8]};
      6'd32: nxt_espacio_digito = {1'b0, v16_g[7:4]};
      6'd33: nxt_espacio_digito = {1'b0, v16_g[3:0]};
      6'd34: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd35: nxt_espacio_digito = {1'b0, v16_h[15:12]};
      6'd36: nxt_espacio_digito = {1'b0, v16_h[11:8]};
      6'd37: nxt_espacio_digito = {1'b0, v16_h[7:4]};
      6'd38: nxt_espacio_digito = {1'b0, v16_h[3:0]};
      6'd39: nxt_espacio_digito = {1'b1, 4'h0};
      
      6'd40: nxt_espacio_digito = {1'b1, 4'h0};
      6'd41: nxt_espacio_digito = {1'b0, v8_a[7:4]};
      6'd42: nxt_espacio_digito = {1'b0, v8_a[3:0]};
  
      6'd43: nxt_espacio_digito = {1'b1, 4'h0};
      6'd44: nxt_espacio_digito = {1'b0, v8_b[7:4]};
      6'd45: nxt_espacio_digito = {1'b0, v8_b[3:0]};
  
      6'd46: nxt_espacio_digito = {1'b1, 4'h0};
      6'd47: nxt_espacio_digito = {1'b0, v8_c[7:4]};
      6'd48: nxt_espacio_digito = {1'b0, v8_c[3:0]};
  
      6'd49: nxt_espacio_digito = {1'b1, 4'h0};
      6'd50: nxt_espacio_digito = {1'b0, v8_d[7:4]};
      6'd51: nxt_espacio_digito = {1'b0, v8_d[3:0]};
  
      6'd52: nxt_espacio_digito = {1'b1, 4'h0};
      6'd53: nxt_espacio_digito = {1'b0, v8_e[7:4]};
      6'd54: nxt_espacio_digito = {1'b0, v8_e[3:0]};
  
      6'd55: nxt_espacio_digito = {1'b1, 4'h0};
      6'd56: nxt_espacio_digito = {1'b0, v8_f[7:4]};
      6'd57: nxt_espacio_digito = {1'b0, v8_f[3:0]};
  
      6'd58: nxt_espacio_digito = {1'b1, 4'h0};
      6'd59: nxt_espacio_digito = {1'b0, v8_g[7:4]};
      6'd60: nxt_espacio_digito = {1'b0, v8_g[3:0]};
  
      6'd61: nxt_espacio_digito = {1'b1, 4'h0};
      6'd62: nxt_espacio_digito = {1'b0, v8_h[7:4]};
      6'd63: nxt_espacio_digito = {1'b0, v8_h[3:0]};
      
      default: nxt_espacio_digito = {1'b1, 4'h0};            
    endcase
  end

  wire pixel = sr[7];
  always @* begin
    if (visible == 1'b1 && hc >= OFFX && hc < (OFFX+9'd256) && vc >= OFFY && vc < (OFFY + 9'd8)) begin
      if (pixel == 1'b1)
        {ro,go,bo} = 9'b000_000_000;
      else
        {ro,go,bo} = 9'b111_111_111;
    end
    else
      {ro,go,bo} = {ri,gi,bi};
  end  
endmodule

module charset_rom (
  input wire clk,
  input wire [3:0] digito,
  input wire [2:0] scan,
  input wire espacio,
  output reg [7:0] bitmap
  );
  
  reg [7:0] charset[0:127];
  initial $readmemh ("fuente_hexadecimal_ibm.hex", charset);

  always @(posedge clk) begin
    if (espacio == 1'b0)
      bitmap <= charset[{digito, scan}];
    else
      bitmap <= 8'h00;
  end
endmodule

`default_nettype wire