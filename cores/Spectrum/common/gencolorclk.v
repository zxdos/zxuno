//////////////////////////////////////////////////////////////////////////////////
//    This file is gencolorclk
//    Creation date is 21:39:48 07/31/2020 by Miguel Angel Rodriguez Jodar
//    (c)2020 Miguel Angel Rodriguez Jodar. ZXProjects
//
//    This core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this core.  If not, see <https://www.gnu.org/licenses/>.
//
//    All copies of this file must keep this notice intact.
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns
`default_nettype none

module gencolorclk (
  input wire clk,        // reloj lo más rápido posible (ahora mismo, 140 MHz o 165 Mhz segun valor de altern)
  input wire mode,       // 0=PAL, 1=NTSC
  input wire altern,     // 0=140 MHz, 1=165 MHz
  output wire clkcolor4x // (17.734475 MHz PAL ó 14.31818 MHz NTSC)
  );

  // Fout = Fclk * prescaler / (2^nbits)
  // prescaler = Fdesired * (2^nbits) / Fclk
  localparam PHASEACUMPAL0  = 29'd68008027;
  localparam PHASEACUMPAL1  = 29'd57703780;
  localparam PHASEACUMNTSC0 = 29'd54907245;
  localparam PHASEACUMNTSC1 = 29'd46587966;

  reg [28:0] cnt = 29'h00000000;
  reg [28:0] prescaler = PHASEACUMPAL0;
  assign clkcolor4x = cnt[28];
  always @(posedge clk) begin
    case ( {altern, mode} )
      2'b00 : prescaler <= PHASEACUMPAL0;
      2'b01 : prescaler <= PHASEACUMNTSC0;
      2'b10 : prescaler <= PHASEACUMPAL1;
      2'b11 : prescaler <= PHASEACUMNTSC1;
      default : prescaler <= PHASEACUMPAL0;
    endcase
    cnt <= cnt + prescaler;
  end
endmodule
