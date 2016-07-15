//
// TV80 8-Bit Microprocessor Core
// Based on the VHDL T80 core by Daniel Wallner (jesus@opencores.org)
//
// Copyright (c) 2004 Guy Hutchison (ghutchis@opencores.org)
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation 
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Negative-edge based wrapper allows memory wait_n signal to work
// correctly without resorting to asynchronous logic.

module tv80a (/*AUTOARG*/
  // Outputs
  m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n, A, dout,
  // Inputs
  reset_n, clk, wait_n, int_n, nmi_n, busrq_n, di
  );

  parameter Mode = 0;    // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
  parameter T2Write = 1; // 1 => wr_n active in T3, 0 => wr_n active in T2
  parameter IOWait  = 1; // 0 => Single cycle I/O, 1 => Std I/O cycle


  input         reset_n; 
  input         clk; 
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

  reg           mreq_n; 
  reg           iorq_n; 
  reg           rd_n; 
  reg           wr_n; 
  
  wire          cen;
  wire          intcycle_n;
  wire          no_read;
  wire          write;
  wire          iorq;
  reg [7:0]     di_reg;
  wire [6:0]    mcycle;
  wire [6:0]    tstate;

  assign    cen = 1;

  tv80_core #(Mode, IOWait) i_tv80_core
    (
     .cen (cen),
     .m1_n (m1_n),
     .iorq (iorq),
     .no_read (no_read),
     .write (write),
     .rfsh_n (rfsh_n),
     .halt_n (halt_n),
     .wait_n (wait_n),
     .int_n (int_n),
     .nmi_n (nmi_n),
     .reset_n (reset_n),
     .busrq_n (busrq_n),
     .busak_n (busak_n),
     .clk (clk),
     .IntE (),
     .stop (),
     .A (A),
     .dinst (di),
     .di (di_reg),
     .dout (dout),
     .mc (mcycle),
     .ts (tstate),
     .intcycle_n (intcycle_n)
     );  

    reg [6:0] tstate_r = 7'h00;
    reg [6:0] tstate_rr = 7'h00;
    always @(negedge clk) begin
        tstate_r <= tstate;
    end
    always @(posedge clk) begin
        tstate_rr <= tstate;
    end

    wire mreq_read  = ~iorq & ~no_read & ~write;
    wire mreq_write = ~iorq & ~no_read & write;
    wire iorq_read  = iorq & ~no_read & ~write;
    wire iorq_write = iorq & ~no_read & write;

    always @* begin
        mreq_n = 1;
        rd_n   = 1;
        iorq_n = 1;
        wr_n   = 1;
          
        if (mcycle[0]) begin
            if (intcycle_n == 1'b1) begin
                if (tstate_r[1] || tstate[2]) begin
                    mreq_n = 1'b0;
                    rd_n = 1'b0;
                end
                else if (rfsh_n == 1'b0 && tstate_r[3]) begin
                    mreq_n = 1'b0;
                end
            end
            else begin
                if (tstate[2]) begin
                    iorq_n = 1'b0;
                end
            end
        end
        else begin
            if (mreq_read == 1'b1) begin
                if (tstate_r[1] || tstate_r[2]) begin
                    mreq_n = 1'b0;
                    rd_n = 1'b0;
                end
            end
            else if (mreq_write == 1'b1) begin
                if (tstate_r[1] || tstate_r[2]) begin
                    mreq_n = 1'b0;
                    if (tstate_r[2]) begin
                        wr_n = 1'b0;
                    end 
                end
            end
            else if (iorq_read == 1'b1) begin
                if (tstate_rr[1] || tstate_r[2]) begin
                    iorq_n = 1'b0;
                    rd_n = 1'b0;
                end
            end
            else if (iorq_write == 1'b1) begin
                if (tstate_rr[1] || tstate_r[2]) begin
                    iorq_n = 1'b0;
                    wr_n = 1'b0;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            di_reg <= #1 0;
        end
        else begin
            if (tstate[2] && wait_n == 1'b1)
                di_reg <= #1 di;
        end // else: !if(!reset_n)
    end // always @ (posedge clk)
  
endmodule // t80n
