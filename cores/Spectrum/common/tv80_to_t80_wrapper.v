`timescale 1ns / 1ns

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 03:39:55 2012-05-13 by Miguel Angel Rodriguez Jodar
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

`default_nettype wire

module tv80n_wrapper (
  // Outputs
  m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n, A, dout,
  // Inputs
  reset_n, clk, clk_enable, wait_n, int_n, nmi_n, busrq_n, di
  );

  input         reset_n; 
  input         clk; 
  input         clk_enable;
  input         wait_n; 
  input         int_n; 
  input         nmi_n; 
  input         busrq_n; 
  output        m1_n; 
  output        mreq_n; 
  output        iorq_n; 
  output        rd_n; 
  output        wr_n; 
  output        rfsh_n; 
  output        halt_n; 
  output        busak_n; 
  output [15:0] A;
  input [7:0]   di;
  output [7:0]  dout;

  wire [7:0] d;

  T80a TheCPU (
  	.RESET_n(reset_n),
		.CLK_n(clk),
    .CEN(clk_enable),
		.WAIT_n(wait_n),
		.INT_n(int_n),
		.NMI_n(nmi_n),
		.BUSRQ_n(busrq_n),
		.M1_n(m1_n),
		.MREQ_n(mreq_n),
		.IORQ_n(iorq_n),
		.RD_n(rd_n),
		.WR_n(wr_n),
		.RFSH_n(rfsh_n),
		.HALT_n(halt_n),
		.BUSAK_n(busak_n),
		.A(A),
		.DIN(di),
    .DOUT(dout)
	);
	
//	assign dout = d; 
//	assign d = ( (!mreq_n || !iorq_n) && !rd_n)? di : 
//               ( (!mreq_n || !iorq_n) && !wr_n)? 8'hZZ :
//               (busak_n == 1'b0)? 8'hZZ :
//               8'hFF;

endmodule

`default_nettype none