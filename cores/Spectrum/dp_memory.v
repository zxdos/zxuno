`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:35:26 02/07/2014 
// Design Name: 
// Module Name:    dp_memory 
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
module dp_memory (
    input wire clk,  // 28MHz
    input wire [18:0] a1,
    input wire [18:0] a2,
    input wire oe1_n,
    input wire oe2_n,
    input wire we1_n,
    input wire we2_n,
    input wire [7:0] din1,
    input wire [7:0] din2,
    output wire [7:0] dout1,
    output wire [7:0] dout2,
    
    output reg [18:0] a,
    inout wire [7:0] d,
    output reg ce_n,
    output reg oe_n,
    output reg we_n
    );

   parameter
		ACCESO_M1 = 1,
		READ_M1   = 2,
		WRITE_M1  = 3,
		ACCESO_M2 = 4,
		READ_M2   = 5,
		WRITE_M2  = 6;		

   reg [7:0] data_to_write;
	reg enable_input_to_sram;
	
	reg [7:0] doutput1;
	reg [7:0] doutput2;
	reg write_in_dout1;
	reg write_in_dout2;

	reg [2:0] state = ACCESO_M1;
	reg [2:0] next_state;
	
	always @(posedge clk) begin
		state <= next_state;
	end

	always @* begin
		a = 0;
		oe_n = 0;
		we_n = 1;
		ce_n = 0;
		enable_input_to_sram = 0;
		next_state = ACCESO_M1;
		data_to_write = 8'h00;
		write_in_dout1 = 0;
		write_in_dout2 = 0;
		
		case (state)
			ACCESO_M1: begin
					 		 a = a1;
							 if (we1_n == 1) begin								
								 next_state = READ_M1;
							 end
							 else begin
								 oe_n = 1;
								 next_state = WRITE_M1;
							 end
						  end
			READ_M1:   begin
			             if (we1_n == 1) begin
                        a = a1;
                        write_in_dout1 = 1;
                      end
							 next_state = ACCESO_M2;
						  end
			WRITE_M1:  begin
                      if (we1_n == 0) begin
 			               a = a1;
                        enable_input_to_sram = 1;
                        data_to_write = din1;
                        oe_n = 1;
                        we_n = 0;
                      end
							 next_state = ACCESO_M2;
						  end
			ACCESO_M2: begin
							 a = a2;
							 if (we2_n == 1) begin
							    next_state = READ_M2;
							 end
							 else begin
								 oe_n = 1;
								 next_state = WRITE_M2;
							 end
						  end
			READ_M2:   begin
                      if (we2_n == 1) begin
                        a = a2;
                        write_in_dout2 = 1;
                      end
                      next_state = ACCESO_M1;
						  end
			WRITE_M2:  begin
                      if (we2_n == 0) begin
                        a = a2;
                        enable_input_to_sram = 1;
                        data_to_write = din2;
                        oe_n = 1;
                        we_n = 0;
                      end
							 next_state = ACCESO_M1;
						  end
       endcase
	 end

    assign d = (enable_input_to_sram)? data_to_write : 8'hZZ;
	 assign dout1 = (oe1_n)? 8'hZZ : doutput1;
	 assign dout2 = (oe2_n)? 8'hZZ : doutput2;
	 
	 always @(posedge clk) begin
		if (write_in_dout1)
			doutput1 <= d;
		else if (write_in_dout2)
			doutput2 <= d;
	 end

endmodule
