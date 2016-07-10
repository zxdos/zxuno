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

`define END_COUNT_H 447
`define END_COUNT_V 311

`define HOFFS 0 //328%448
`define VOFFS 0 //48%312

`define BEGIN_LONG_SYNC1 	(0   + `HOFFS)
`define END_LONG_SYNC1 		(190 + `HOFFS)
`define BEGIN_LONG_SYNC2 	(224 + `HOFFS)
`define END_LONG_SYNC2 		(414 + `HOFFS)
`define BEGIN_SHORT_SYNC1 	(0   + `HOFFS)
`define END_SHORT_SYNC1 	(15  + `HOFFS)
`define BEGIN_SHORT_SYNC2 	(224 + `HOFFS)
`define END_SHORT_SYNC2 	(239 + `HOFFS)
`define BEGIN_HSYNC			(0   + `HOFFS)
`define END_HSYNC 			(32  + `HOFFS)
`define BEGIN_HBLANK			(436 + `HOFFS)
`define END_HBLANK			(71  + `HOFFS)
`define BEGIN_WSSDATA		(77  + `HOFFS)

`define LINE1					(0   + `VOFFS)
`define LINE2					(1   + `VOFFS)
`define LINE3					(2   + `VOFFS)
`define LINE4					(3   + `VOFFS)
`define LINE5					(4   + `VOFFS)
`define LINE23					(22  + `VOFFS)
`define LINE310				(309 + `VOFFS)
`define LINE311				(310 + `VOFFS)
`define LINE312				(311 + `VOFFS)

module pal_sync_generator_progressive (
    input wire clk,
	 input wire wssclk,
	 input wire [2:0] ri,
	 input wire [2:0] gi,
	 input wire [2:0] bi,
	 output wire [8:0] hcnt,
	 output wire [8:0] vcnt,
    output wire [2:0] ro,
    output wire [2:0] go,
    output wire [2:0] bo,
    output wire csync
    );

	reg [8:0] hc = 9'h000;
	reg [8:0] vc = 9'h000;

	reg [8:0] rhcnt = 332; //344; //328;
	reg [8:0] rvcnt = 248; // era 250
	assign hcnt = rhcnt;
	assign vcnt = rvcnt;
	
	always @(posedge clk) begin
		if (rhcnt == `END_COUNT_H) begin
			rhcnt <= 0;
			if (rvcnt == `END_COUNT_V)
				rvcnt <= 0;
			else
				rvcnt <= rvcnt + 1;
		end
		else
			rhcnt <= rhcnt + 1;
	end
	
	always @(posedge clk) begin
		if (hc == `END_COUNT_H) begin
			hc <= 0;
			if (vc == `END_COUNT_V)
				vc <= 0;
			else
				vc <= vc + 1;
		end
		else
			hc <= hc + 1;
	end
	
	reg rsync = 1;
	reg in_visible_region = 1;
	assign csync = rsync;
	always @(posedge clk) begin
		if (hc == `BEGIN_LONG_SYNC1 && (vc == `LINE1 || 
		                                 vc == `LINE2 || 
													vc == `LINE3 ))
		begin
			rsync <= 0;
			in_visible_region <= 0;
		end
		else if (hc == `END_LONG_SYNC1 && (vc == `LINE1 || 
		                                    vc == `LINE2 || 
														vc == `LINE3 ))
		begin
			rsync <= 1;
			in_visible_region <= 0;
		end
		else if (hc == `BEGIN_LONG_SYNC2 && (vc == `LINE1 || 
		                                      vc == `LINE2 ))
		begin
			rsync <= 0;
			in_visible_region <= 0;
		end
		else if (hc == `END_LONG_SYNC2 && (vc == `LINE1 || 
		                                    vc == `LINE2 ))
		begin
			rsync <= 1;
			in_visible_region <= 0;
		end
		else if (hc == `BEGIN_SHORT_SYNC1 && (vc == `LINE4 || 
		                                       vc == `LINE5 ||  
		                                       vc == `LINE310 ||  
		                                       vc == `LINE311 ||  
		                                       vc == `LINE312 ))
		begin
			rsync <= 0;
			in_visible_region <= 0;
		end
		else if (hc == `END_SHORT_SYNC1 && (vc == `LINE4 || 
		                                       vc == `LINE5 ||  
		                                       vc == `LINE310 ||  
		                                       vc == `LINE311 ||  
		                                       vc == `LINE312 ))
		begin
			rsync <= 1;
			in_visible_region <= 0;
		end
		else if (hc == `BEGIN_SHORT_SYNC2 && (vc == `LINE3 ||
															vc == `LINE4 || 
		                                       vc == `LINE5 ||  
		                                       vc == `LINE310 ||  
		                                       vc == `LINE311 ||  
		                                       vc == `LINE312 ))
		begin
			rsync <= 0;
			in_visible_region <= 0;
		end
		else if (hc == `END_SHORT_SYNC2 && (vc == `LINE3 ||
															vc == `LINE4 || 
		                                       vc == `LINE5 ||  
		                                       vc == `LINE310 ||  
		                                       vc == `LINE311 ||  
		                                       vc == `LINE312 ))
		begin
			rsync <= 1;
			in_visible_region <= 0;
		end
		else if (vc != `LINE1 && 
		         vc != `LINE2 &&
		         vc != `LINE3 &&
		         vc != `LINE4 &&
		         vc != `LINE5 &&
					vc != `LINE310 &&
		         vc != `LINE311 &&
		         vc != `LINE312 ) begin
			if (hc == `BEGIN_HBLANK)
				in_visible_region <= 0;
			else if (hc == `BEGIN_HSYNC)
				rsync <= 0;
			else if (hc == `END_HSYNC)
				rsync <= 1;
			else if (hc == `END_HBLANK) begin
				in_visible_region <= 1;
			end
		end
	end

	// see WSS standard description PDF, by ETSI
	//                          v- Run-in code               v- Start code           v- Group 1              v- Group 2              v- Group 3        v- Group 4
	reg [136:0] wss_data = 137'b11111000111000111000111000111000111100011110000011111000111000111000111111000111000000111000111000111000111000111000111000111000111000111;
	reg wss_mstate = 0;
	reg [7:0] wss_cnt = 136;
	wire wss_output = (wss_mstate == 0)? 0 : wss_data[136];
	always @(posedge wssclk) begin
		case (wss_mstate)
			0: begin
					if (vc == `LINE23 && (hc == `BEGIN_WSSDATA || hc == `BEGIN_WSSDATA+1))
						wss_mstate <= 1;
				end
			1: begin
					wss_data <= {wss_data[135:0],wss_data[136]};
					if (wss_cnt != 0)
						wss_cnt <= wss_cnt - 1;
					else begin
						wss_cnt <= 136;
						wss_mstate <= 0;
					end
				end
		endcase
	end

	assign ro = (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : ri;
	assign go = (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : gi;
	assign bo = (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : bi;

//   (* IOB = "TRUE" *) reg [2:0] rro;
//	(* IOB = "TRUE" *) reg [2:0] rgo;
//	(* IOB = "TRUE" *) reg [2:0] rbo;
//	assign ro = rro;
//	assign go = rgo;
//	assign bo = rbo;
//   always @(posedge clk) begin
//		rro <= (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : ri;
//		rgo <= (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : gi;
//		rbo <= (wss_mstate == 1)? {wss_output,1'b0,wss_output} : (vc ==`LINE23 || !in_visible_region)? 3'b000 : bi;
//	end

endmodule
