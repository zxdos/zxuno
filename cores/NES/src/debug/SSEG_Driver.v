module SSEG_Driver( clk, reset, data, sseg, an );
														
input  wire clk;
input  wire reset;
input  wire[15:0] data;
output reg[6:0] sseg;
output reg[3:0] an;


wire[3:0] hex3,hex2,hex1,hex0;	

assign hex3 = data[15:12];
assign hex2 = data[11:8];
assign hex1 = data[7:4];
assign hex0 = data[3:0];

localparam N = 18;

reg[N-1:0] q_reg;
wire[N-1:0] q_next;
reg[3:0] hex_in;

always@( posedge clk or posedge reset )
	if( reset )
		q_reg <= 0;
	else
		q_reg <= q_next;
		
assign q_next = q_reg + 1;

always@( * )
	case( q_reg[N-1:N-2] )
		2'b00:
		begin
			an = 4'b1110;
			hex_in = hex0;
		end
		
		2'b01:
		begin
			an = 4'b1101;
			hex_in = hex1;
		end	

		2'b10:
		begin
			an = 4'b1011;
			hex_in = hex2;
		end		
		
		2'b11:
		begin
			an = 4'b0111;
			hex_in = hex3;
		end
	endcase
	
	always@( * )
	begin
		case( hex_in )
				0 : sseg[6:0] = 7'b1000000;  //'0'
				1 : sseg[6:0] = 7'b1111001;  //'1'
				2 : sseg[6:0] = 7'b0100100;  //'2'
				3 : sseg[6:0] = 7'b0110000;  //'3'
				4 : sseg[6:0] = 7'b0011001;  //'4'
				5 : sseg[6:0] = 7'b0010010;  //'5'
				6 : sseg[6:0] = 7'b0000010;  //'6'
				7 : sseg[6:0] = 7'b1111000;  //'7'
				8 : sseg[6:0] = 7'b0000000;  //'8'
				9 : sseg[6:0] = 7'b0010000;  //'9'
			 'hA : sseg[6:0] = 7'b0001000;  //'A'
			 'hB : sseg[6:0] = 7'b0000011;  //'b'
			 'hC : sseg[6:0] = 7'b1000110;  //'C'
			 'hD : sseg[6:0] = 7'b0100001;  //'d'
			 'hE : sseg[6:0] = 7'b0000110;  //'E'
			 'hF : sseg[6:0] = 7'b0001110;  //'F'
		default : sseg[6:0] = 7'b1111111;
		endcase
	end

endmodule
