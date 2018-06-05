// ZXUNO port by DistWave (2016)
// fpganes
// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

`timescale 1ns / 1ps

module NES_ZXUNO(
  input CLOCK_50,
  // VGA
  output vga_v,
  output vga_h,
  output [2:0] vga_r,
  output [2:0] vga_g,
  output [2:0] vga_b,
  output dvga_v,
  output dvga_h,
  output [2:0] dvga_r,
  output [2:0] dvga_g,
  output [2:0] dvga_b,
  // Memory
  output ram_WE_n,          // Write Enable. WRITE when Low.
  output [18:0] ram_a,
  inout [7:0] ram_d,
  output AUDIO_R,
  output AUDIO_L,
  input P_A,
  input P_tr,
  input P_U,
  input P_D,
  input P_L,
  input P_R,
  input PS2_CLK,
  input PS2_DAT,
  input SPI_MISO,
  output SPI_MOSI,
  output SPI_CLK,
  output SPI_CS,
  output led//,
//input reset,
//input set,
//output [6:0] sseg_a_to_dp,	// cathode of seven segment display( a,b,c,d,e,f,g,dp )
//output [3:0] sseg_an			// anaode of seven segment display( AN3,AN2,AN1,AN0 )
  );

  wire osd_window;
  wire osd_pixel;
  wire [15:0] dipswitches;
  wire scanlines;
  wire hq_enable;
  wire border;
  
  assign scanlines = dipswitches[0];
  assign hq_enable = dipswitches[1];
  
  wire host_reset_n;
  wire host_reset_loader;
  wire host_divert_sdcard;
  wire host_divert_keyboard;
  wire host_select;
  wire host_start;
  
  wire master_reset;
  
  reg boot_state = 1'b0;
 
  wire [31:0] bootdata;
  wire bootdata_req;
  reg bootdata_ack = 1'b0;
  
  wire AUD_MCLK;
  wire AUD_LRCK;
  wire AUD_SCK;
  wire AUD_SDIN;
  
  wire [3:0] vga_blue;
  wire [3:0] vga_green;
  wire [3:0] vga_red;
  
  wire vga_hsync;
  wire vga_vsync;
  wire [7:0] vga_osd_r;
  wire [7:0] vga_osd_g;
  wire [7:0] vga_osd_b;
  assign vga_h = vga_hsync;
  assign vga_v = vga_vsync;
  assign vga_r = vga_osd_r[7:5];
  assign vga_g = vga_osd_g[7:5];
  assign vga_b = vga_osd_b[7:5];

  assign dvga_h = vga_hsync;
  assign dvga_v = vga_vsync;
  assign dvga_r = vga_osd_r[7:5];
  assign dvga_g = vga_osd_g[7:5];
  assign dvga_b = vga_osd_b[7:5];

  assign led = loader_fail;
  
  wire clock_locked;
  wire clk;
  reg clk_loader;
  wire clk_gameloader;
  wire clk_fifo;

  wire clk_ctrl;
  reg[15:0] data;
  reg [7:0] loader_input;
    
  wire joypad_data;
  
  nes_clk clock_21mhz(
    .CLK_IN1(CLOCK_50), 
	 .CLK_OUT1(clk), 
	 .CLK_OUT2(clk_ctrl), 
	 /*.CLK_OUT3(clk4),*/ 
	 .LOCKED(clock_locked)
	);

  // NES Palette -> RGB332 conversion
  reg [14:0] pallut[0:63];
  initial $readmemh("nes_palette.txt", pallut);

  wire [8:0] cycle;
  wire [8:0] scanline;
  wire [15:0] sample;
  wire [5:0] color;
  wire joypad_strobe;
  wire [1:0] joypad_clock;
  wire [21:0] memory_addr;
  wire memory_read_cpu, memory_read_ppu;
  wire memory_write;
  wire [7:0] memory_din_cpu, memory_din_ppu;
  wire [7:0] memory_dout;
  reg [7:0] joypad_bits, joypad_bits2;
  reg [1:0] last_joypad_clock;
  wire [31:0] dbgadr;
  wire [1:0] dbgctr;

  reg [1:0] nes_ce;

  reg [13:0] debugaddr;
  wire [15:0] debugdata;

  wire [7:0] joystick1, joystick2;
  wire p_sel = !host_select;
  wire p_start = !host_start;
  assign joystick1 = {~P_R & P_L, ~P_L & P_R, ~P_D & P_U, ~P_U & P_D, ~p_start | (~P_R & ~P_L), ~p_sel | (~P_D & ~P_U), ~P_tr, ~P_A};  
 
  always @(posedge clk) begin
    if (joypad_strobe) begin
      joypad_bits <= joystick1;
      joypad_bits2 <= joystick2;
    end
    if (!joypad_clock[0] && last_joypad_clock[0])
      joypad_bits <= {1'b0, joypad_bits[7:1]};
    if (!joypad_clock[1] && last_joypad_clock[1])
      joypad_bits2 <= {1'b0, joypad_bits2[7:1]};
    last_joypad_clock <= joypad_clock;
  end
  
  wire [21:0] loader_addr;
  wire [7:0] loader_write_data;
  wire loader_reset = host_reset_loader;// &&  uart_loader_conf[0];
  wire loader_write;
  wire [31:0] mapper_flags;
  wire loader_done, loader_fail;
  wire empty_fifo;
  
  GameLoader loader(
    clk_gameloader, 
    loader_reset, 
	 loader_input, 
	 clk_loader,
	 loader_addr, 
	 loader_write_data, 
	 loader_write,
	 mapper_flags,
	 loader_done,
	 loader_fail
	);

  wire reset_nes = (!host_reset_n || !loader_done);
  wire run_mem = (nes_ce == 0) && !reset_nes;
  wire run_nes = (nes_ce == 3) && !reset_nes;


  // NES is clocked at every 4th cycle.
  always @(posedge clk)
    nes_ce <= nes_ce + 1;
    
  NES nes(clk, reset_nes, run_nes,
          mapper_flags,
          sample, color,
          joypad_strobe, joypad_clock, {joypad_bits2[0], joypad_bits[0]},
          5'b11111,
          memory_addr,
          memory_read_cpu, memory_din_cpu,
          memory_read_ppu, memory_din_ppu,
          memory_write, memory_dout,
          cycle, scanline,
          dbgadr,
          dbgctr
   );

  // This is the memory controller to access the board's SRAM
  wire ram_busy;
  
  MemoryController memory(clk,
                          memory_read_cpu && run_mem, 
                          memory_read_ppu && run_mem,
                          memory_write && run_mem || loader_write,
                          loader_write ? loader_addr : memory_addr,
                          loader_write ? loader_write_data : memory_dout,
                          memory_din_cpu,
                          memory_din_ppu,
                          ram_busy,
								  ram_WE_n,
                          ram_a,
                          ram_d,
								  debugaddr,
								  debugdata);
								  
  reg ramfail;
  always @(posedge clk) begin
    if (loader_reset)
      ramfail <= 0;
    else
      ramfail <= ram_busy && loader_write || ramfail;
  end

  wire [14:0] doubler_pixel;
  wire doubler_sync;
  wire [9:0] vga_hcounter, doubler_x;
  wire [9:0] vga_vcounter;
  
  VgaDriver vga(
		clk, 
		vga_hsync, 
		vga_vsync, 
		vga_red, 
		vga_green, 
		vga_blue, 
		vga_hcounter, 
		vga_vcounter, 
		doubler_x, 
		doubler_pixel, 
		doubler_sync, 
		1'b0);
  
  wire [14:0] pixel_in = pallut[color];
  
  Hq2x hq2x(clk, pixel_in, !hq_enable, 
            scanline[8],        // reset_frame
            (cycle[8:3] == 42), // reset_line
            doubler_x,          // 0-511 for line 1, or 512-1023 for line 2.
            doubler_sync,       // new frame has just started
            doubler_pixel);     // pixel is outputted

	assign AUDIO_R = audio;
	assign AUDIO_L = audio;
   wire audio;
	
	sigma_delta_dac sigma_delta_dac (
        .DACout         (audio),
        .DACin          (sample[15:8]),
        .CLK            (clk),
        .RESET          (reset_nes)
	);

wire [31:0] rom_size;

	CtrlModule control (
			.clk(clk_ctrl), 
			.reset_n(1'b1), 
			.vga_hsync(vga_hsync), 
			.vga_vsync(vga_vsync), 
			.osd_window(osd_window), 
			.osd_pixel(osd_pixel), 
			.ps2k_clk_in(PS2_CLK), 
			.ps2k_dat_in(PS2_DAT),
			.spi_miso(SPI_MISO), 
			.spi_mosi(SPI_MOSI), 
			.spi_clk(SPI_CLK), 
			.spi_cs(SPI_CS), 
			.dipswitches(dipswitches), 
			.size(rom_size), 
			.host_divert_sdcard(host_divert_sdcard), 
			.host_divert_keyboard(host_divert_keyboard), 
			.host_reset_n(host_reset_n), 
			.host_select(host_select), 
			.host_start(host_start),
			.host_reset_loader(host_reset_loader),
			.host_bootdata(bootdata), 
			.host_bootdata_req(bootdata_req), 
			.host_bootdata_ack(bootdata_ack),
			.host_master_reset(master_reset)
	);
	
	OSD_Overlay osd (
			.clk(clk_ctrl),
			.red_in({vga_red, 4'b0000}),
			.green_in({vga_green, 4'b0000}),
			.blue_in({vga_blue, 4'b0000}),
			.window_in(1'b1),
			.hsync_in(vga_hsync),
			.osd_window_in(osd_window),
			.osd_pixel_in(osd_pixel),
			.red_out(vga_osd_r),
			.green_out(vga_osd_g),
			.blue_out(vga_osd_b),
			.window_out(),
			.scanline_ena(scanlines)
	);
/*
  SSEG_Driver debugboard ( .clk( clk ),
						  .reset( 1'b0 ), 
						  .data( data ),
						  .sseg( sseg_a_to_dp ), 
						  .an( sseg_an ) );
*/
reg write_fifo;
reg read_fifo;
wire full_fifo;
reg skip_fifo = 1'b0;
wire [7:0] dout_fifo;
reg [31:0] bytesloaded;

reg [12:0] counter_fifo;
assign clk_fifo = counter_fifo[7]; 
assign clk_gameloader = counter_fifo[6]; 

  fifo_loader loaderbuffer (
         .wr_clk(clk_ctrl),
         .rd_clk(clk_fifo), 
			.din(bootdata), 
			.wr_en(write_fifo), 
			.rd_en(read_fifo), 
			.dout(dout_fifo),
			.full(full_fifo), 
			.empty(empty_fifo)
  );
 
always@( posedge clk_ctrl )
begin
	if (host_reset_loader == 1'b1) begin
		bootdata_ack <= 1'b0;
		boot_state <= 1'b0;
		write_fifo <= 1'b0;
		read_fifo <= 1'b0;
		skip_fifo <= 1'b0;
		bytesloaded <= 32'h00000000;
	end else begin
		if (dout_fifo == 8'h4E) skip_fifo <= 1'b1;

		case (boot_state)
			1'b0:
				if (bootdata_req == 1'b1) begin
					if (full_fifo == 1'b0) begin
						boot_state <= 1'b1;
						bootdata_ack <= 1'b1;
						write_fifo <= (bytesloaded < rom_size) ? 1'b1 : 1'b0;
					end else read_fifo <= 1'b1;
				end else begin
					bootdata_ack <= 1'b0;
					end
			1'b1: 
 				begin
					if (write_fifo == 1'b1) begin
						write_fifo <= 1'b0;
						bytesloaded <= bytesloaded + 4;
					end
					boot_state <= 1'b0;
					bootdata_ack <= 1'b0;
				end
		endcase;
	end
end

always@( posedge clk )
begin
/*
   data <= debugdata;

	if (set == 1'b0)
		if (reset == 1'b1) debugaddr <= 14'b00000000000010;
      else debugaddr <= 14'b00000000000000;
	else 

    debugaddr <= 14'b00000000000001;
*/

//  if (reset == 1'b1)
//     data <= {3'b000, empty_fifo, 3'b000, full_fifo, 3'b000, clk_loader, 3'b000, skip_fifo};
//		data <= rom_size[19:4];

	counter_fifo <= counter_fifo + 1'b1;
	clk_loader <= !clk_fifo && skip_fifo;
end

always@( posedge clk_loader)
begin
	loader_input <= dout_fifo;
//	data <= bytesloaded[19:4];
end

//-----------------Multiboot-------------
    multiboot el_multiboot (
        .clk_icap(clk),
        .REBOOT(master_reset | (~P_R & ~P_L & ~P_D & ~P_U))
    );


endmodule
