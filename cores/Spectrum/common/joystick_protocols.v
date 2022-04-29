`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 15:52:26 2015-06-07 by Miguel Angel Rodriguez Jodar
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

module joystick_protocols (
    input wire clk,
    //-- cpu interface
    input wire [15:0] a,
    input wire iorq_n,
    input wire rd_n,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe,
    //-- interface with ZXUNO reg bank
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    //-- actual joystick and keyboard signals
    input wire [5:0] kbdjoy_in,
    input wire [5:0] db9joy1_in,
    input wire [5:0] db9joy2_in,
    output wire joy1fire3,
    input wire [4:0] kbdcol_in,
    output reg [4:0] kbdcol_out,
    input wire vertical_retrace_int_n, // this is used as base clock for autofire
	 input wire joy_splitter
    );

`include "config.vh"

    localparam
      SINCLAIRP1ADDR  = 12,
      SINCLAIRP2ADDR  = 11,
      SINCLAIRADDRE 	= 8, 	//sinclair extendido, semifila ZXCV
      DISABLED        = 3'h0,
      KEMPSTON        = 3'h1,
      SINCLAIRP1      = 3'h2,
      SINCLAIRP2      = 3'h3,
      CURSOR          = 3'h4,
      FULLER          = 3'h5,
      // Protocolo OPQASPACEM
  		KMAPOPQA        = 3'h6,
      KMAPOP		      = 13,
      KMAPQ			      = 10,
      KMAPA			      = 9,
      KMAPSPACEM	    = 15;

`ifdef JOYSPLITTER_SUPPORT

    // Joystick multiplex (hardware joystick splitter)

    reg joySelector = 1'b0;
    assign joy1fire3 = (joy_splitter == 1'b1) ? joySelector : 1'b1;
    reg [5:0] db9joy1_muxed = 6'b111111;
    reg [5:0] db9joy2_muxed = 6'b111111;
    reg [18:0] joyMuxerCounter = 19'd0;
    always @(posedge clk) begin
        if ( joyMuxerCounter == 19'd0 ) begin
            // 28 MHz / 140000 = 200 Hz, 100 Hz for each joystick.
            joyMuxerCounter <= 19'd140000;
            if ((joy_splitter == 1'b0) || (joySelector == 1'b1)) begin
                db9joy1_muxed <= db9joy1_in;
            end
            else begin
                db9joy2_muxed <= db9joy1_in;
            end
            joySelector <= ~joySelector;
        end
        else begin
            joyMuxerCounter <= joyMuxerCounter - 19'd1;
        end
    end
`else
    assign joy1fire3 = 1'b1;
`endif

    // Input format: FUDLR . 0=pressed, 1=released
    reg db9joyup;
    reg db9joydown;
    reg db9joyleft;
    reg db9joyright;
    reg db9joyfire1;
    reg db9joyfire2;
    reg kbdjoyup;
    reg kbdjoydown;
    reg kbdjoyleft;
    reg kbdjoyright;
    reg kbdjoyfire1;
    reg kbdjoyfire2;


`ifdef JOYSPLITTER_SUPPORT
    always @* begin
        {db9joyfire2,db9joyfire1,db9joyup,db9joydown,db9joyleft,db9joyright} <= ~db9joy1_muxed;
        {kbdjoyfire2,kbdjoyfire1,kbdjoyup,kbdjoydown,kbdjoyleft,kbdjoyright} <= kbdjoy_in | ~db9joy2_muxed | ~db9joy2_in;
    end
`else
    always @* begin
        {db9joyfire2,db9joyfire1,db9joyup,db9joydown,db9joyleft,db9joyright} <= ~db9joy1_in;
        {kbdjoyfire2,kbdjoyfire1,kbdjoyup,kbdjoydown,kbdjoyleft,kbdjoyright} <= kbdjoy_in | ~db9joy2_in;
    end
`endif

    // Update JOYCONF from CPU
    reg [7:0] joyconf = {1'b0,SINCLAIRP1, 1'b0,KEMPSTON};
    always @(posedge clk) begin
        if (zxuno_addr==JOYCONFADDR && zxuno_regwr==1'b1)
            joyconf <= din;
    end

    // Autofire stuff
    reg [2:0] cont_autofire = 3'b000;
    reg edge_detect = 1'b0;
    wire autofire = cont_autofire[2];
    always @(posedge clk) begin
      edge_detect <= vertical_retrace_int_n;
      if ({edge_detect,vertical_retrace_int_n} == 2'b01)
          cont_autofire <= cont_autofire + 3'd1;  // count only on raising edge of vertical retrace int
    end
    wire kbdjoyfire_processed = (joyconf[3]==1'b0)? kbdjoyfire1 : kbdjoyfire1 & autofire;

/*
    // Config bit joyconf[7] is db9 joystick autofire enable. Except if splitter supported, where it is 'splitter enabled' bit.
	// In that case joyconf[3] is autofire enable for both joysticks.
`ifdef JOYSPLITTER_SUPPORT
    wire db9joyfire_processed = (joyconf[3]==1'b0)? db9joyfire1 : db9joyfire1 & autofire;
`else
    wire db9joyfire_processed = (joyconf[7]==1'b0)? db9joyfire1 : db9joyfire1 & autofire;
`endif
*/		
		
	 wire db9joyfire_processed = (joyconf[7]==1'b0)? db9joyfire1 : db9joyfire1 & autofire;

    always @* begin
      oe = 1'b0;
      dout = 8'hFF;
      kbdcol_out = kbdcol_in;
      if (zxuno_addr==JOYCONFADDR && zxuno_regrd==1'b1) begin  // lectura específica de I/O de ZXUNO
        oe = 1'b1;
        dout = joyconf;
      end
      else if (iorq_n == 1'b0 && rd_n == 1'b0) begin  // lectura genérica de I/O
        if ((a[7:0] == KEMPSTONADDR1) || (a[7:0] == KEMPSTONADDR2)) begin
          dout = 8'h00;
          oe = 1'b1;
          if (joyconf[2:0] == KEMPSTON) begin
              dout = dout | {2'b00, kbdjoyfire2, kbdjoyfire_processed, kbdjoyup, kbdjoydown, kbdjoyleft, kbdjoyright};
          end
          if (joyconf[6:4] == KEMPSTON) begin
              dout = dout | {2'b00, db9joyfire2, db9joyfire_processed, db9joyup, db9joydown, db9joyleft, db9joyright};
          end
          if ((joyconf[2:0] != KEMPSTON) && (joyconf[6:4] != KEMPSTON)) begin
            dout = 8'hFF;
          end
        end
        else if (a[7:0] == FULLERADDR) begin
          dout = 8'hFF;
          oe = 1'b1;
          if (joyconf[2:0] == FULLER) begin
              dout = dout & {~kbdjoyfire_processed, ~kbdjoyfire2, 2'b11, ~kbdjoyright, ~kbdjoyleft, ~kbdjoydown, ~kbdjoyup};
          end
          if (joyconf[6:4] == FULLER) begin
              dout = dout & {~db9joyfire_processed, ~db9joyfire2, 2'b11, ~db9joyright, ~db9joyleft, ~db9joydown, ~db9joyup};
          end
        end
        else if (a[0] == 1'b0) begin  // lectura de I/O de teclado
          if (a[SINCLAIRP1ADDR]==1'b0) begin
            if (joyconf[2:0]==SINCLAIRP1)
                kbdcol_out = kbdcol_out & {~kbdjoyleft,~kbdjoyright,~kbdjoydown,~kbdjoyup,~kbdjoyfire_processed};
            if (joyconf[6:4]==SINCLAIRP1)
                kbdcol_out = kbdcol_out & {~db9joyleft,~db9joyright,~db9joydown,~db9joyup,~db9joyfire_processed};
            if (joyconf[2:0]==CURSOR)
                kbdcol_out = kbdcol_out & {~kbdjoydown,~kbdjoyup,~kbdjoyright,~kbdjoyfire2,~kbdjoyfire_processed};
            if (joyconf[6:4]==CURSOR)
                kbdcol_out = kbdcol_out & {~db9joydown,~db9joyup,~db9joyright,~db9joyfire2,~db9joyfire_processed};
          end
          if (a[SINCLAIRP2ADDR]==1'b0) begin
            if (joyconf[2:0]==SINCLAIRP2)
                kbdcol_out = kbdcol_out & {~kbdjoyfire_processed,~kbdjoyup,~kbdjoydown,~kbdjoyright,~kbdjoyleft};
            if (joyconf[6:4]==SINCLAIRP2)
                kbdcol_out = kbdcol_out & {~db9joyfire_processed,~db9joyup,~db9joydown,~db9joyright,~db9joyleft};
            if (joyconf[2:0]==CURSOR)
                kbdcol_out = kbdcol_out & {~kbdjoyleft,4'b1111};
            if (joyconf[6:4]==CURSOR)
                kbdcol_out = kbdcol_out & {~db9joyleft,4'b1111};
          end
          //Sinclair extendido,Z-X
          if (a[SINCLAIRADDRE]==1'b0) begin
            if (joyconf[6:4]==SINCLAIRP1)
               kbdcol_out = kbdcol_out & {2'b11, ~db9joyfire2, 2'b11};
            if (joyconf[6:4]==SINCLAIRP2)
               kbdcol_out = kbdcol_out & {3'b111, ~db9joyfire2, 1'b1};
            if (joyconf[2:0]==SINCLAIRP1)
               kbdcol_out = kbdcol_out & {2'b11, ~kbdjoyfire2, 2'b11};
            if (joyconf[2:0]==SINCLAIRP2)
               kbdcol_out = kbdcol_out & {3'b111, ~kbdjoyfire2, 1'b1};
          end
          //
          //Protocolo OPQASPACEM
          if (a[KMAPOP]==1'b0) begin
            if (joyconf[6:4]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {3'b111,  ~db9joyleft, ~db9joyright};
            if (joyconf[2:0]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {3'b111,  ~kbdjoyleft, ~kbdjoyright};
          end
          if (a[KMAPQ]==1'b0) begin
            if (joyconf[6:4]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {4'b1111, ~db9joyup};
			if (joyconf[2:0]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {4'b1111, ~kbdjoyup};
          end
          if (a[KMAPA]==1'b0) begin
            if (joyconf[6:4]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {4'b1111,  ~db9joydown};
            if (joyconf[2:0]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {4'b1111,  ~kbdjoydown};
          end
          if (a[KMAPSPACEM]==1'b0) begin
            if (joyconf[6:4]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {2'b11, ~db9joyfire2,  1'b1, ~db9joyfire_processed};
            if (joyconf[2:0]==KMAPOPQA)
               kbdcol_out = kbdcol_out & {2'b11, ~kbdjoyfire2,  1'b1, ~kbdjoyfire_processed};
          end
          //
        end  // fin de lectura de I/O de teclado
      end    // fin lectura genérica de I/O
    end
endmodule
