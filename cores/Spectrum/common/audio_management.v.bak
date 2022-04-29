`timescale 1ns / 1ps

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 04:04:00 2012-04-01 by Miguel Angel Rodriguez Jodar
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

`define MSBI 8 // Most significant Bit of DAC input

//This is a Delta-Sigma Digital to Analog Converter
module dac (DACout, DACin, Clk, Reset);
	output DACout; // This is the average output that feeds low pass filter
	input [`MSBI:0] DACin; // DAC input (excess 2**MSBI)
	input Clk;
	input Reset;

	reg DACout; // for optimum performance, ensure that this ff is in IOB
	reg [`MSBI+2:0] DeltaAdder; // Output of Delta adder
	reg [`MSBI+2:0] SigmaAdder; // Output of Sigma adder
	reg [`MSBI+2:0] SigmaLatch = 1'b1 << (`MSBI+1); // Latches output of Sigma adder
	reg [`MSBI+2:0] DeltaB; // B input of Delta adder

	always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
	always @(DACin or DeltaB) DeltaAdder = DACin + DeltaB;
	always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;
	always @(posedge Clk)
	begin
		if(Reset)
		begin
			SigmaLatch <= #1 1'b1 << (`MSBI+1);
			DACout <= #1 1'b0;
		end
		else
		begin
			SigmaLatch <= #1 SigmaAdder;
			DACout <= #1 SigmaLatch[`MSBI+2];
		end
	end
endmodule


/*
The sound mix is controlled by port #F7 (sets the mix for the
currently selected PSG). There are two channels for the beeper.
When one channel is active the beeper is at the same volume level as
a single PSG channel at full volume. When both are active and have
the same pan it is then double the volume of a single PSG channel.
This approximates the relative loudness of the beeper on 128K
machines.

D6-7:	channel A
D4-5:	channel B
D3-2:	channel C 
D1-0:	channel D (beeper)

Panning is limited to switching a channel on or off for a given
speaker. The bits are decoded as follows:

00 = mute
10 = left
01 = right
11 = both

The default port value on reset is zero (all channels off).
*/
module panner_and_mixer (
  input wire clk,
  input wire mrst_n,
  input wire [7:0] a,
  input wire iorq_n,
  input wire rd_n,
  input wire wr_n,
  input wire [7:0] din,
  output reg [7:0] dout,
  output reg oe,
  //--- SOUND SOURCES ---
  input wire mic,
  input wire ear,
  input wire spk,
  input wire [7:0] ay1_cha,
  input wire [7:0] ay1_chb,
  input wire [7:0] ay1_chc,
  input wire [7:0] ay2_cha,
  input wire [7:0] ay2_chb,
  input wire [7:0] ay2_chc,
  input wire [7:0] specdrum,
  input wire [15:0] midi_left,
  input wire [15:0] midi_right,
 
  // --- OUTPUTs ---
  output wire output_left,
  output wire output_right
  );

`include "config.vh"

  // Register accepts data from CPU
  reg [7:0] mixer = 8'b10_01_11_11; // ACB mode, Specdrum and beeper on both channels
  always @(posedge clk) begin
    if (mrst_n == 1'b0)
      mixer <= 8'b10_01_11_11;
    else if (a == AUDIOMIXER && iorq_n == 1'b0 && wr_n == 1'b0)
      mixer <= din;
  end
   
  // CPU reads register
  always @* begin
    dout = mixer;
    if (a == 8'hF7 && iorq_n == 1'b0 && rd_n == 1'b0)
      oe = 1'b1;
    else
      oe = 1'b0;
  end
   
  // Mixer for EAR, MIC and SPK
  reg [7:0] beeper;
  always @(posedge clk) begin
    case ({ear,spk,mic})
      3'b000: beeper <= 8'd0;
      3'b001: beeper <= 8'd36;
      3'b010: beeper <= 8'd184;
      3'b011: beeper <= 8'd192;
      3'b100: beeper <= 8'd64;
      3'b101: beeper <= 8'd100;
      3'b110: beeper <= 8'd248;
      3'b111: beeper <= 8'd255;      
    endcase
  end
  
  reg [10:0] mixleft = 11'h000;
  reg [10:0] mixright = 11'h000;
  reg [8:0] left, right;
//  reg [7:0] compressor[0:2047];
//  initial $readmemh ("curva_compress.hex", compressor);
  
//  always @(posedge clk) begin
////    mixleft  <= ((mixer[7])? {4'b0000,ay1_cha[7:1]} + {4'b0000,ay2_cha[7:1]} : 11'h000 ) +
////                ((mixer[5])? {4'b0000,ay1_chb[7:1]} + {4'b0000,ay2_chb[7:1]} : 11'h000 ) +
////                ((mixer[3])? {4'b0000,ay1_chc[7:1]} + {4'b0000,ay2_chc[7:1]} : 11'h000 ) +
////                ((mixer[1])? {3'b000,beeper} + midi_left[15:5] + {{3{specdrum_left[7]}},specdrum_left}: 11'h000 );
////    mixright <= ((mixer[6])? {4'b0000,ay1_cha[7:1]} + {4'b0000,ay2_cha[7:1]} : 11'h000 ) +
////                ((mixer[4])? {4'b0000,ay1_chb[7:1]} + {4'b0000,ay2_chb[7:1]} : 11'h000 ) +
////                ((mixer[2])? {4'b0000,ay1_chc[7:1]} + {4'b0000,ay2_chc[7:1]} : 11'h000 ) +
////                ((mixer[0])? {3'b000,beeper} + midi_right[15:5] + {{3{specdrum_right[7]}},specdrum_right}: 11'h000 );
//    mixleft  <= ((mixer[7])? {3'b000,ay1_cha} + {3'b000,ay2_cha} : 11'h000 ) +
//                ((mixer[5])? {3'b000,ay1_chb} + {3'b000,ay2_chb} : 11'h000 ) +
//                ((mixer[3])? {3'b000,ay1_chc} + {3'b000,ay2_chc} : 11'h000 ) +
//                ((mixer[1])? {2'b00,beeper,beeper[7]} + midi_left[15:5] + {specdrum_left[7],specdrum_left,2'b00}: 11'h000 );
//    mixright <= ((mixer[6])? {3'b000,ay1_cha} + {3'b000,ay2_cha} : 11'h000 ) +
//                ((mixer[4])? {3'b000,ay1_chb} + {3'b000,ay2_chb} : 11'h000 ) +
//                ((mixer[2])? {3'b000,ay1_chc} + {3'b000,ay2_chc} : 11'h000 ) +
//                ((mixer[0])? {2'b00,beeper,beeper[7]} + midi_right[15:5] + {specdrum_right[7],specdrum_right,2'b00}: 11'h000 );
//    left <= compressor[mixleft];
//    right <= compressor[mixright];
//  end

  reg [10:0] ay1_cha_signed, ay1_chb_signed, ay1_chc_signed;
  reg [10:0] ay2_cha_signed, ay2_chb_signed, ay2_chc_signed;
  reg [10:0] beeper_signed, specdrum_signed;
  reg [10:0] midi_left_signed, midi_right_signed;
  always @(posedge clk) begin
    // extender a 11 bits
    ay1_cha_signed  <= {3'b000, ay1_cha};
    ay1_chb_signed  <= {3'b000, ay1_chb};
    ay1_chc_signed  <= {3'b000, ay1_chc};
    ay2_cha_signed  <= {3'b000, ay2_cha};
    ay2_chb_signed  <= {3'b000, ay2_chb};
    ay2_chc_signed  <= {3'b000, ay2_chc};
    beeper_signed   <= {3'b000, beeper};
    specdrum_signed <= {2'b00, specdrum, specdrum[7]};
    midi_left_signed <= midi_left[15:5] ^ 11'b10000000000;
    midi_right_signed <= midi_right[15:5] ^ 11'b10000000000;
    
    mixleft  <= ((mixer[7])? ay1_cha_signed + ay2_cha_signed : 11'h000 ) +
                ((mixer[5])? ay1_chb_signed + ay2_chb_signed : 11'h000 ) +
                ((mixer[3])? ay1_chc_signed + ay2_chc_signed : 11'h000 ) +
                ((mixer[1])? beeper_signed + midi_left_signed + specdrum_signed: 11'h000 );
    mixright <= ((mixer[6])? ay1_cha_signed + ay2_cha_signed : 11'h000 ) +
                ((mixer[4])? ay1_chb_signed + ay2_chb_signed : 11'h000 ) +
                ((mixer[2])? ay1_chc_signed + ay2_chc_signed : 11'h000 ) +
                ((mixer[0])? beeper_signed + midi_right_signed + specdrum_signed: 11'h000 );
    left <= mixleft[10:2];
    right <= mixright[10:2];
  end

   // DACs
	dac audio_dac_left (
		.DACout(output_left),
		.DACin(left),
		.Clk(clk),
		.Reset(!mrst_n)
		);
   
	dac audio_dac_right (
		.DACout(output_right),
		.DACin(right),
		.Clk(clk),
		.Reset(!mrst_n)
		);
endmodule
