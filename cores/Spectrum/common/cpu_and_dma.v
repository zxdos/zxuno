`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 00:44:29 2017-03-07 by Miguel Angel Rodriguez Jodar
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

module cpu_and_dma (
  input wire reset_n,
  input wire clk,
  input wire clkcpuen,
  input wire clk28en,
  input wire wait_n,
  input wire int_n,
  input wire nmi_n,
  output wire m1_n,
  output wire mreq_n,
  output wire iorq_n,
  output wire rd_n,
  output wire wr_n,
  output wire rfsh_n,
  output wire halt_n,
  output wire busak_salida_n,
  output wire [15:0] A,
  input wire [7:0] di,
  output wire [7:0] dout,
  // DMA Control signals
  input wire [7:0] zxuno_addr,
  input wire regaddr_changed,
  input wire zxuno_regrd,
  input wire zxuno_regwr,
  input wire [7:0] dmadevicedin,
  output wire [7:0] dmadevicedout,
  output wire oe
  );

`include "config.vh"

  wire [15:0] dma_a, cpu_a;
  wire [7:0] dma_dout, cpu_dout;
  wire dma_mreq_n, dma_iorq_n, dma_rd_n, dma_wr_n;
  wire cpu_mreq_n, cpu_iorq_n, cpu_rd_n, cpu_wr_n, cpu_m1_n;
  wire busrq_n, busak_n;

//  assign mreq_n = cpu_mreq_n;
//  assign iorq_n = cpu_iorq_n;
//  assign rd_n   = cpu_rd_n;
//  assign wr_n   = cpu_wr_n;
//  assign m1_n   = cpu_m1_n;
//  assign A      = cpu_a;
//  assign dout   = cpu_dout;

  assign mreq_n = (busak_n == 1'b1)? cpu_mreq_n : dma_mreq_n;
  assign iorq_n = (busak_n == 1'b1)? cpu_iorq_n : dma_iorq_n;
  assign rd_n   = (busak_n == 1'b1)? cpu_rd_n   : dma_rd_n;
  assign wr_n   = (busak_n == 1'b1)? cpu_wr_n   : dma_wr_n;
  assign m1_n   = (busak_n == 1'b1)? cpu_m1_n   : 1'b1;
  assign A      = (busak_n == 1'b1)? cpu_a      : dma_a;
  assign dout   = (busak_n == 1'b1)? cpu_dout   : dma_dout;
  
  assign busak_salida_n = busak_n;

`ifdef ZXUNO_DMA_SUPPORT  
  dma la_dma (
    .clk(clk),  
    .rst_n(reset_n),
    .zxuno_addr(zxuno_addr),
    .regaddr_changed(regaddr_changed),
    .zxuno_regrd(zxuno_regrd),
    .zxuno_regwr(zxuno_regwr),
    .din(dmadevicedin),
    .dout(dmadevicedout),
    .oe(oe),
    //---- DMA bus -----
    .m1_n(m1_n),
    .busrq_n(busrq_n),
    .busak_n(busak_n),
    .dma_a(dma_a),
    .dma_din(di),
    .dma_dout(dma_dout),
    .dma_mreq_n(dma_mreq_n),
    .dma_iorq_n(dma_iorq_n),
    .dma_rd_n(dma_rd_n),
    .dma_wr_n(dma_wr_n)
  );
`else
  assign busrq_n = 1'b1;
  assign oe = 1'b0;
  assign dma_dout = 8'h00;
  assign dma_a = 16'h0000;
  assign dma_mreq_n = 1'b1;
  assign dma_iorq_n = 1'b1;
  assign dma_rd_n = 1'b1;
  assign dma_wr_n = 1'b1;
`endif

  tv80n_wrapper el_z80 (
    .m1_n(cpu_m1_n),
    .mreq_n(cpu_mreq_n),
    .iorq_n(cpu_iorq_n),
    .rd_n(cpu_rd_n),
    .wr_n(cpu_wr_n),
    .rfsh_n(rfsh_n),
    .halt_n(halt_n),
    .busak_n(busak_n),
    .A(cpu_a),
    .dout(cpu_dout),

    .reset_n(reset_n),
    .clk(clk),
    .clk_enable(clkcpuen),
    .wait_n(wait_n),
    .int_n(int_n),
    .nmi_n(nmi_n),
    .busrq_n(busrq_n),
    .di(di)
  );
endmodule
