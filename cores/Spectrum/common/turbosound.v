`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 11:33:13 2014-04-27 by Miguel Angel Rodriguez Jodar
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

module turbosound (
    input wire clk,
		input wire clk35en,
		input wire clk175en,
    input wire reset_n,
    input wire disable_ay,
    input wire disable_turboay,
    input wire bdir,
    input wire bc1,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe,
    output reg midi_out,
    output wire [7:0] audio_out_ay1,
    output wire [7:0] audio_out_ay2,
    output wire [23:0] audio_out_ay1_splitted,
    output wire [23:0] audio_out_ay2_splitted
    );

  // TurboSound AY selection logic: uses non-existent AY reg addresses 0xFF and 0xFE 
  // (actually, address 0b1111111x where x=1 for first AY, x=0 for second AY)
	reg ay_select = 1'b1;
	always @(posedge clk) begin
		if (reset_n==1'b0)
			ay_select <= 1'b1;    
		else if (disable_ay == 1'b0 && disable_turboay == 1'b0 && bdir && bc1 && din[7:1]==7'b1111111)  // AY address selection
			ay_select <= din[0];  // 1: select first AY, 0: select second AY
	end

	wire oe_n_ay1, oe_n_ay2;
	wire [7:0] dout_ay1, dout_ay2;
  wire [7:0] port_a_ay1, port_a_ay2;
  
  // MUX for selecting data and signals from AY 1 or AY 2
  always @* begin
    if (ay_select == 1'b0) begin
      midi_out = port_a_ay2[2];
      dout = dout_ay2;
      if (!disable_ay && !disable_turboay)
        oe = ~oe_n_ay2;
      else
        oe = 1'b0;
    end
    else begin
      midi_out = port_a_ay1[2];
      dout = dout_ay1;
      if (!disable_ay)
        oe = ~oe_n_ay1;
      else
        oe = 1'b0;
    end
  end

  ay_3_8192 ay1 (
    .clk(clk),
	  .clken(~disable_ay & clk175en),
	  .rst_n(reset_n),
	  .a8(ay_select),
	  .bdir(bdir),
	  .bc1(bc1),
	  .bc2(1'b1),
	  .din(din),
	  .dout(dout_ay1),
	  .oe_n(oe_n_ay1),
	  .channel_a(audio_out_ay1_splitted[23:16]),
	  .channel_b(audio_out_ay1_splitted[15:8]),
	  .channel_c(audio_out_ay1_splitted[7:0]),
    .port_a_din(8'h00),
	  .port_a_dout(port_a_ay1),
	  .port_a_oe_n()
  );

  ay_3_8192 ay2 (
    .clk(clk),
	  .clken(~disable_ay & ~disable_turboay & clk175en),
	  .rst_n(reset_n),
	  .a8(~ay_select),
	  .bdir(bdir),
	  .bc1(bc1),
	  .bc2(1'b1),
	  .din(din),
	  .dout(dout_ay2),
	  .oe_n(oe_n_ay2),
	  .channel_a(audio_out_ay2_splitted[23:16]),
	  .channel_b(audio_out_ay2_splitted[15:8]),
	  .channel_c(audio_out_ay2_splitted[7:0]),
    .port_a_din(8'h00),
	  .port_a_dout(port_a_ay2),
	  .port_a_oe_n()
  );
endmodule
