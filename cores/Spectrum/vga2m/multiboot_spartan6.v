//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is UNKNOWN by Miguel Angel Rodriguez Jodar
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

module multiboot (
    input wire clk,
    //input wire clk_icap,   // WARNING: this clock must not be greater than 20MHz (50ns period)
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire regaddr_changed,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe
    );
    
`include "../common/config.vh"
              
    localparam GOLDEN_CORE = 24'h058000; // posición del core de Spectrum en la flash
              
    reg [23:0] spi_addr = GOLDEN_CORE;   // default value
    reg writting_to_spi_addr = 1'b0;
    reg writting_to_bootcore = 1'b0;
    reg boot_core = 1'b0;

    reg reading_from_spi_addr = 1'b0;
    reg [1:0] spi_addr_chunk = 2'b00; // which part of COREADDR to output
    reg [7:0] addrout = 8'h00;
    
    always @* begin
      dout = addrout;
      oe = 1'b0;
      if (zxuno_addr == ADDR_COREADDR && zxuno_regrd ==1'b1)
        oe = 1'b1;
    end  

    always @(posedge clk) begin
        if (rst_n == 1'b0 || (regaddr_changed && zxuno_addr == ADDR_COREADDR)) begin
          writting_to_spi_addr <= 1'b0;
          writting_to_bootcore <= 1'b0;
          reading_from_spi_addr <= 1'b0;
          spi_addr_chunk <= 2'b00;
          boot_core <= 1'b0;
        end				
        else begin
            if (zxuno_addr == ADDR_COREADDR) begin
              if (zxuno_regwr == 1'b1 && writting_to_spi_addr == 1'b0) begin
                  spi_addr <= {spi_addr[15:0], din};
                  writting_to_spi_addr <= 1'b1;
              end
              if (zxuno_regwr == 1'b0) begin
                  writting_to_spi_addr <= 1'b0;
              end
              if (zxuno_regrd == 1'b1 && reading_from_spi_addr == 1'b0) begin
                addrout <= (spi_addr_chunk == 2'b00)? spi_addr[23:16] :
                           (spi_addr_chunk == 2'b01)? spi_addr[15:8] :
                                                      spi_addr[7:0];
                spi_addr_chunk <= (spi_addr_chunk == 2'b10)? 2'b00 : spi_addr_chunk + 2'b01;
                reading_from_spi_addr <= 1'b1;
              end   
              if (zxuno_regrd == 1'b0) begin
                reading_from_spi_addr <= 1'b0;
              end                  
            end
            else begin
              writting_to_spi_addr <= 1'b0;
              reading_from_spi_addr <= 1'b0;
            end
            
            if (zxuno_addr == ADDR_COREBOOT) begin
                if (zxuno_regwr == 1'b1 && din[0] == 1'b1 && writting_to_bootcore == 1'b0) begin
                    boot_core <= 1'b1;
                    writting_to_bootcore <= 1'b1;
                end
                if (zxuno_regwr == 1'b0) begin
                    writting_to_bootcore <= 1'b0;
                end
            end
            else begin
                boot_core <= 1'b0;
                writting_to_bootcore <= 1'b0;
            end
        end
    end

   reg regclkicap = 1'b0;
	 wire clk_icap;
	 always @(posedge clk)
	   regclkicap <= ~regclkicap;
	 BUFG bufclkicap (.I(regclkicap), .O(clk_icap) );

    wire icap_ce_n, icap_we_n;
    wire [15:0] icap_data;
    seq_multiboot_spartan6 secuenciador_multiboot (
      .clk(clk_icap),
      .spi_address(spi_addr),
      .reboot(boot_core),
      .icap_ce(icap_ce_n),
      .icap_we(icap_we_n),
      .icap_data(icap_data)
    );
    
    icap el_icap (
      .clk(clk_icap),
      .ce_n(icap_ce_n),
      .we_n(icap_we_n),
      .din(icap_data)
    );  
endmodule            
    
module seq_multiboot_spartan6 (
  input wire clk,
  input wire [23:0] spi_address,
  input wire reboot,
  output reg icap_ce,
  output reg icap_we,
  output reg [15:0] icap_data
  );
  
  reg [17:0] icap_command[0:15];
  localparam CYCLE_SPI_ADDRESS_LOW = 4'd6;
	localparam CYCLE_SPI_ADDRESS_HIGH = 4'd8;
  initial begin  
    icap_command[ 0] = {1'b1, 1'b1, 16'hFFFF};
    icap_command[ 1] = {1'b0, 1'b0, 16'hAA99};
    icap_command[ 2] = {1'b0, 1'b0, 16'h5566};
    icap_command[ 3] = {1'b0, 1'b0, 16'h30A1};
    icap_command[ 4] = {1'b0, 1'b0, 16'h0000};
    icap_command[ 5] = {1'b0, 1'b0, 16'h3261};
    icap_command[ 6] = {1'b0, 1'b0, 16'h0000};  // en este ciclo hay que poner la dirección SPI baja
    icap_command[ 7] = {1'b0, 1'b0, 16'h3281};
    icap_command[ 8] = {1'b0, 1'b0, 16'h6B00};  // en este ciclo hay que poner la dirección SPI alta
    icap_command[ 9] = {1'b0, 1'b0, 16'h3301};
    icap_command[10] = {1'b0, 1'b0, 16'h3100};
    icap_command[11] = {1'b0, 1'b0, 16'h30A1};
    icap_command[12] = {1'b0, 1'b0, 16'h000E};
    icap_command[13] = {1'b0, 1'b0, 16'h2000};  // nop
    icap_command[14] = {1'b0, 1'b0, 16'h2000};  // nop
    icap_command[15] = {1'b0, 1'b0, 16'h2000};  // nop
  end
  
	always @(posedge clk) begin
	  icap_command[CYCLE_SPI_ADDRESS_LOW] <= {2'b00, spi_address[15:0]};
		icap_command[CYCLE_SPI_ADDRESS_HIGH] <= {2'b00, 8'h6B, spi_address[23:16]};
  end
	
  reg [4:0] indx = 5'b00000;
  always @(posedge clk) begin
    if (reboot == 1'b1 && indx[4] == 1'b0)
      indx <= 5'b10000;  // el bit 4 a 1 hace que se habilite la cuenta
    else begin
      {icap_ce, icap_we, icap_data} <= icap_command[indx[3:0]];
      indx <= indx + {4'b0000, indx[4]};
    end
  end      
endmodule

module icap (
  input wire clk,
  input wire ce_n,
  input wire we_n,
  input wire [15:0] din
  );

  wire [15:0] swapped;
  genvar j;
  generate
    for(j=0; j<16; j=j+1) begin : swap
	    assign swapped[j] = din[15-j];
	  end
  endgenerate

  ICAP_SPARTAN6 ICAP_SPARTAN6_inst (
  
    .CE        (ce_n),   // Clock enable input
    .CLK       (clk),         // Clock input
    .I         ({swapped[7:0], swapped[15:8]}),  // 16-bit data input
    .WRITE     (we_n)    // Write input
  );
      
endmodule
