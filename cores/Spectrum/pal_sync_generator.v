`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:02:15 03/12/2015 
// Design Name: 
// Module Name:    pal_generator 
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

module pal_sync_generator (
    input wire clk,
    input wire [1:0] mode,  // 00: 48K, 01: 128K, 10: Pentagon, 11: Reserved

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
    output wire int_n
    );

	reg [8:0] hc = 9'h000;
	reg [8:0] vc = 9'h000;

	reg [8:0] hc_sync = 9'd104;
	reg [8:0] vc_sync = 9'd0;

    reg [8:0] end_count_h = 9'd447;
    reg [8:0] end_count_v = 9'd311;
    reg [8:0] begin_hblank = 9'd320;
    reg [8:0] end_hblank = 9'd415;
    reg [8:0] begin_hsync = 9'd344;
    reg [8:0] end_hsync = 9'd375;
    reg [8:0] begin_vblank = 9'd248;
    reg [8:0] end_vblank = 9'd255;
    reg [8:0] begin_vsync = 9'd248;
    reg [8:0] end_vsync = 9'd251;
    reg [8:0] begin_vcint = 9'd248;
    reg [8:0] end_vcint = 9'd248;
    reg [8:0] begin_hcint = 9'd2;
    reg [8:0] end_hcint = 9'd65;
    
    //reg [1:0] old_mode = 2'b11;

	assign hcnt = hc;
	assign vcnt = vc;
  
	always @(posedge clk) begin
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
                       begin_vcint <= 9'd248;
                       end_vcint <= 9'd248;
                       begin_hcint <= 9'd2;
                       end_hcint <= 9'd65;
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
                       begin_vcint <= 9'd248;
                       end_vcint <= 9'd248;
                       begin_hcint <= 9'd4;
                       end_hcint <= 9'd67;
                    end
             2'b10,
             2'b11: begin // timings for Pentagon 128
                       end_count_h <= 9'd447;
                       end_count_v <= 9'd319;
                       hc_sync <= hinitpen;
                       vc_sync <= vinitpen;
                       begin_hblank <= 9'd336; // 9'd328;
                       end_hblank <= 9'd399; // 9'd391;
                       begin_hsync <= 9'd336; // 9'd328;
                       end_hsync <= 9'd367; // 9'd359;
                       begin_vblank <= 9'd240;
                       end_vblank <= 9'd271; // 9'd255;
                       begin_vsync <= 9'd240;
                       end_vsync <= 9'd255; // 9'd243;
                       begin_vcint <= 9'd239;
                       end_vcint <= 9'd239;
                       begin_hcint <= 9'd323; // 9'd323;
                       end_hcint <= 9'd386; //9'd386;
                    end
           endcase
        end
        else
          vc <= vc + 9'd1;
      end
      else
        hc <= hc + 9'd1;
	 end

    // INT generation
    reg vretrace_int_n, raster_int_n;
    assign int_n = vretrace_int_n & raster_int_n;
    assign raster_int_in_progress = ~raster_int_n;
    always @* begin
      vretrace_int_n = 1'b1;
      if (vretraceint_disable == 1'b0 && (hc >= begin_hcint && vc == begin_vcint) && (hc <= end_hcint && vc == end_vcint))
        vretrace_int_n = 1'b0;
        
      raster_int_n = 1'b1;
      if (rasterint_enable == 1'b1 && hc >= 256 && hc <= 319) begin
        if (raster_line == 9'd0 && vc == end_count_v) 
          raster_int_n = 1'b0;
        if (raster_line != 9'd0 && vc == (raster_line - 9'd1))
          raster_int_n = 1'b0;
      end
    end
   
    always @* begin
        ro = ri;
        go = gi;
        bo = bi;
        hsync = 1'b1;
        vsync = 1'b1;
        if ( (hc >= begin_hblank && hc <= end_hblank) || (vc >= begin_vblank && vc <= end_vblank) ) begin
            ro = 3'b000;
            go = 3'b000;
            bo = 3'b000;
            if (hc >= begin_hsync && hc <= end_hsync)
                hsync = 1'b0;
            if (vc >= begin_vsync && vc <= end_vsync) 
                vsync = 1'b0;
        end
     end    

    always @* begin
      csync = 1'b1;
      if (csync_option == 1'b1) begin
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
      else begin
         if ((hc_sync >= 9'd0 && hc_sync <= 9'd27) || (vc_sync >= 9'd248 && vc_sync <= 9'd251))
            csync = 1'b0;
      end
    end
endmodule
