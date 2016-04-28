`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:11:22 10/17/2012 
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

module pal_sync_generator_sinclair (
    input wire clk,
    input wire timming,
    input wire [2:0] ri,
    input wire [2:0] gi,
    input wire [2:0] bi,
    output wire [8:0] hcnt,
    output wire [8:0] vcnt,
    output reg [2:0] ro,
    output reg [2:0] go,
    output reg [2:0] bo,
    output reg csync
    );

    parameter
      END_COUNT_H_48K  = 447,
      END_COUNT_V_48K  = 311,
      END_COUNT_H_128K = 455,
      END_COUNT_V_128K = 310,
      BHBLANK          = 320,
      EHBLANK          = 415,
      BHSYNC           = 344,
      EHSYNC           = 375,
      BVPERIOD         = 248,
      EVPERIOD         = 255,
      BVSYNC           = 248,
      EVSYNC           = 251;

	reg [8:0] hc = 9'h000;
	reg [8:0] vc = 9'h137;  // linea 311

	assign hcnt = hc;
	assign vcnt = vc;
	
	always @(posedge clk) begin
		if ( (hc == END_COUNT_H_48K && !timming) || (hc == END_COUNT_H_128K && timming) ) begin
			hc <= 0;
			if ( (vc == END_COUNT_V_48K && !timming) || (vc == END_COUNT_V_128K && timming) )
				vc <= 0;
			else
				vc <= vc + 1;
		end
		else
			hc <= hc + 1;
	end

    always @* begin
        ro = ri;
        go = gi;
        bo = bi;
        csync = 1'b1;
        if ( (hc>=BHBLANK && hc<=EHBLANK) || (vc>=BVPERIOD && vc<=EVPERIOD) ) begin
            ro = 3'b000;
            go = 3'b000;
            bo = 3'b000;
            if ( (hc>=BHSYNC && hc<=EHSYNC) || (vc>=BVSYNC && vc<=EVSYNC) ) begin
                csync = 1'b0;
            end
        end
     end
        
endmodule
