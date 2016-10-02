`define MSBI 9 // Most significant Bit of DAC input

// this is a delta-sigma digital to analog converter

module dac (o, i, clock, reset);

	output o;          // this is the average output that feeds low pass filter
	input [`MSBI:0] i; // dac input (excess 2**msbi)
	input clock;
	input reset;

	reg o; // for optimum performance, ensure that this ff is in IOB
	reg [`MSBI+2:0] DeltaAdder; // Output of Delta adder
	reg [`MSBI+2:0] SigmaAdder; // Output of Sigma adder
	reg [`MSBI+2:0] SigmaLatch = 1'b1 << (`MSBI+1); // Latches output of Sigma adder
	reg [`MSBI+2:0] DeltaB; // B input of Delta adder

	always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
	always @(i or DeltaB) DeltaAdder = i + DeltaB;
	always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;
	always @(posedge clock or posedge reset)
	begin
		if(reset)
		begin
			SigmaLatch <= #1 1'b1 << (`MSBI+1);
			o <= #1 1'b0;
		end
		else
		begin
			SigmaLatch <= #1 SigmaAdder;
			o <= #1 SigmaLatch[`MSBI+2];
		end
	end
endmodule
