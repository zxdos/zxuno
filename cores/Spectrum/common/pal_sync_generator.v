`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 18:02:15 2015-03-12 by Miguel Angel Rodriguez Jodar
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

module pal_sync_generator (
    input wire clk,
    input wire clken,
    input wire [1:0] mode,  // 00: 48K, 01: 128K, 10: Pentagon, 11: NTSC

    input wire rasterint_enable,
    input wire vretraceint_disable,
    input wire [8:0] raster_line,
    output wire raster_int_in_progress,
    input wire csync_option,
    
    input wire [8:0] hinit48k,
    input wire [8:0] vinit48k,
    input wire [8:0] hinit128k,
    input wire [8:0] vinit128k,
    input wire [8:0] hinitpen,
    input wire [8:0] vinitpen,    
	 
//    input wire button_up,
//    input wire button_down,
//    output wire [7:0] posint,
    
    input wire [2:0] ri,
    input wire [2:0] gi,
    input wire [2:0] bi,
    output wire [8:0] hcnt,
    output wire [8:0] vcnt,
    output reg [2:0] ro,
    output reg [2:0] go,
    output reg [2:0] bo,
    output reg hsync,
    output reg vsync,
    output reg csync,
    output wire int_n,
    output reg [8:0] end_count_v = 9'd311
    );

`include "config.vh"

    reg [8:0] hc = 9'h000;
    reg [8:0] vc = 9'h000;

    reg [8:0] hc_sync = 9'd104;
    reg [8:0] vc_sync = 9'd0;

    reg [8:0] end_count_h = 9'd447;
    reg [8:0] begin_hblank = 9'd320;
    reg [8:0] end_hblank = 9'd415;
    reg [8:0] begin_hsync = 9'd344;
    reg [8:0] end_hsync = 9'd375;
    reg [8:0] begin_vblank = 9'd248;
    reg [8:0] end_vblank = 9'd255;
    reg [8:0] begin_vsync = 9'd248;
    reg [8:0] end_vsync = 9'd251;
    reg [8:0] vcint = 9'd248;
    reg [8:0] begin_hcint = 9'd0;
    reg [8:0] end_hcint = 9'd63;
    
    reg [1:0] old_mode = 2'b11;
    reg previous_button_up = 1'b0, previous_button_down = 1'b0;

    assign hcnt = hc;
    assign vcnt = vc;
	
//  assign posint = begin_hcint[7:0];
  
	always @(posedge clk) begin
	  if (clken) begin
      if (hc_sync == end_count_h) begin
         hc_sync <= 9'd0;
         if (vc_sync == end_count_v) begin
            vc_sync <= 9'd0;
         end
         else begin
            vc_sync <= vc_sync + 9'd1;
         end
      end
      else begin
         hc_sync <= hc_sync + 9'd1;
      end
      
      if (hc == end_count_h) begin
        hc <= 9'd0;
        if (vc == end_count_v) begin
          vc <= 9'd0;
          case (mode)
					  2'b00: begin // timings for Sinclair 48K
								  end_count_h <= 9'd447;
								  end_count_v <= 9'd311;
								  hc_sync <= hinit48k;
								  vc_sync <= vinit48k;
								  begin_hblank <= 9'd320;
								  end_hblank <= 9'd415;
								  begin_hsync <= 9'd344;
								  end_hsync <= 9'd375;
								  begin_vblank <= 9'd248;
								  end_vblank <= 9'd255;
								  begin_vsync <= 9'd248;
								  end_vsync <= 9'd251;
								  vcint <= 9'd248;
								  begin_hcint <= 9'd4;
								  end_hcint <= 9'd67;
							  end
            2'b01: begin // timings for Sinclair 128K/+2 grey
								  end_count_h <= 9'd455;
								  end_count_v <= 9'd310;
								  hc_sync <= hinit128k;
								  vc_sync <= vinit128k;
								  begin_hblank <= 9'd320;
								  end_hblank <= 9'd415;
								  begin_hsync <= 9'd344;
								  end_hsync <= 9'd375;
								  begin_vblank <= 9'd248;
								  end_vblank <= 9'd255;
								  begin_vsync <= 9'd248;
								  end_vsync <= 9'd251;
								  vcint <= 9'd248;
								  begin_hcint <= 9'd6;
								  end_hcint <= 9'd69;
							  end
					  2'b10: begin // timings for Pentagon 128
								  end_count_h <= 9'd447;
								  end_count_v <= 9'd319;
								  hc_sync <= hinitpen;
								  vc_sync <= vinitpen;
								  begin_hblank <= 9'd320;
								  end_hblank <= 9'd383;
								  begin_hsync <= 9'd320;
								  end_hsync <= 9'd351;
								  begin_vblank <= 9'd240;
								  end_vblank <= 9'd271;
								  begin_vsync <= 9'd240;
								  end_vsync <= 9'd255;
								  vcint <= 9'd239;
								  begin_hcint <= 9'd326;
								  end_hcint <= 9'd397;
							  end
					  2'b11: begin // timings for Sinclair 48K NTSC
								  end_count_h <= 9'd447;
								  end_count_v <= 9'd261;
								  hc_sync <= 9'd112;
								  vc_sync <= 9'd508;
								  begin_hblank <= 9'd320;
								  end_hblank <= 9'd415;
								  begin_hsync <= 9'd344;
								  end_hsync <= 9'd375;
								  begin_vblank <= 9'd216;
								  end_vblank <= 9'd223;
								  begin_vsync <= 9'd216;
								  end_vsync <= 9'd219;
								  vcint <= 9'd216;
								  begin_hcint <= 9'd4;
								  end_hcint <= 9'd67;
							  end
				  endcase
        end
        else
          vc <= vc + 9'd1;
      end
      else
        hc <= hc + 9'd1;
     end
//	  else begin
//	    previous_button_up <= button_up;
//		 previous_button_down <= button_down;
//	    if (button_up == 1'b1 && previous_button_up == 1'b0)
//		   begin_hcint <= begin_hcint + 9'd1;
//		 else if (button_down == 1'b1 && previous_button_down == 1'b0)
//		   begin_hcint <= begin_hcint - 9'd1;
//	  end
	 end

    // INT generation
    reg vretrace_int_n, raster_int_n;
    assign int_n = vretrace_int_n & raster_int_n;
    assign raster_int_in_progress = ~raster_int_n;

    always @* begin
      vretrace_int_n = 1'b1;
      if (vretraceint_disable == 1'b0) begin
        if (vc == vcint && hc >= begin_hcint && hc <= end_hcint) 
            vretrace_int_n = 1'b0;
      end
    end

    always @* begin
      raster_int_n = 1'b1;
`ifdef RASTER_INTERRUPT_SUPPORT
      if (rasterint_enable == 1'b1 && hc >= 256 && hc <= 319) begin
        if (raster_line == 9'd0 && vc == end_count_v) 
          raster_int_n = 1'b0;
        if (raster_line != 9'd0 && vc == (raster_line - 9'd1))
          raster_int_n = 1'b0;
      end
`endif      
    end

    reg hblank; // = 1'b0;
    reg vblank; // = 1'b0;
    always @* begin
      if (hc >= begin_hblank && hc <= end_hblank)
        hblank = 1'b1;
      else
        hblank = 1'b0; 

      if (vc >= begin_vblank && vc <= end_vblank)
        vblank = 1'b1;
      else
        vblank = 1'b0;

      if (hc >= begin_hsync && hc <= end_hsync)
        hsync = 1'b0;
      else
        hsync = 1'b1;

      if (vc >= begin_vsync && vc <= end_vsync)
        vsync = 1'b0;
      else
        vsync = 1'b1;
    end
        
    always @* begin
      if (hblank == 1'b1 || vblank == 1'b1) begin
        ro = 3'b000;
        go = 3'b000;
        bo = 3'b000;
      end
      else begin
        ro = ri;
        go = gi;
        bo = bi;
      end
    end

    always @* begin
      csync = 1'b1;
      if (csync_option == 1'b1 && mode != 2'b11) begin  // sincronismo PAL vertical progresivo "según norma"
         if (vc_sync < 9'd248 || vc_sync > 9'd255) begin
            if (hc_sync >= 9'd0 && hc_sync <= 9'd27)
               csync = 1'b0;
         end
         else if (vc_sync == 9'd248 || vc_sync == 9'd249 || vc_sync == 9'd250 || vc_sync == 9'd254 || vc_sync == 9'd255) begin
            if ((hc_sync >= 9'd0 && hc_sync <= 9'd13) || (hc_sync >= 9'd224 && hc_sync <= 9'd237))
               csync = 1'b0;
         end
         else if (vc_sync == 9'd251 || vc_sync == 9'd252) begin
            if ((hc_sync >= 9'd0 && hc_sync <= 9'd210) || (hc_sync >= 9'd224 && hc_sync <= 9'd433))
               csync = 1'b0;
         end
         else begin // linea 253
            if ((hc_sync >= 9'd0 && hc_sync <= 9'd210) || (hc_sync >= 9'd224 && hc_sync <= 9'd237))
               csync = 1'b0;
         end
      end
      else if (mode != 2'b11) begin
         if ((hc_sync >= 9'd0 && hc_sync <= 9'd27) || (vc_sync >= 9'd248 && vc_sync <= 9'd251))  // sincronismo PAL vertical tipo Spectrum
            csync = 1'b0;
      end
      else begin
         if ((hc_sync >= 9'd0 && hc_sync <= 9'd27) || (vc_sync >= 9'd216 && vc_sync <= 9'd219))  // sincronismo NTSC vertical tipo Spectrum
            csync = 1'b0;
      end
    end    
endmodule
