`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    10:30:33 07/23/2015 
// Design Name:    SAM Coupé clone
// Module Name:    asic 
// Project Name:   SAM Coupé clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module asic (
    input wire clk,
    input wire rst_n,
    // CPU interface
    input wire mreq_n,
    input wire iorq_n,
    input wire rd_n,
    input wire wr_n,
    input wire [15:0] cpuaddr,
    input wire [7:0] data_from_cpu,
    output reg [7:0] data_to_cpu,
    output reg data_enable_n,
    output reg wait_n,
    // RAM/ROM interface
    output reg [18:0] vramaddr,
    output reg [18:0] cpuramaddr,
    input wire [7:0] data_from_ram,    
    output reg ramwr_n,
    output reg romcs_n,
    output reg ramcs_n,
    output wire asic_is_using_ram,
    // audio I/O
    input wire ear,
    output wire mic,
    output wire beep,
    // keyboard I/O
    input wire [7:0] keyboard,
    output wire rdmsel,
    // disk I/O
    output reg disc1_n,
    output reg disc2_n,
    // video output
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b,
    output wire bright,
    output reg csync,
    output wire int_n
    );

    parameter HACTIVEREGION = 512,
              RBORDER       = 64,
              HFPORCH       = 16,
              HSYNC         = 64,
              HBPORCH       = 64,
              LBORDER       = 48;
              
    parameter HTOTAL = HACTIVEREGION + 
                       RBORDER + 
                       HFPORCH + 
                       HSYNC + 
                       HBPORCH + 
                       LBORDER;
    
    parameter VACTIVEREGION = 192,
              BBORDER       = 48,
              VFPORCH       = 4,
              VSYNC         = 4,
              VBPORCH       = 16,
              TBORDER       = 48;
              
    parameter VTOTAL = VACTIVEREGION + 
                       BBORDER + 
                       VFPORCH + 
                       VSYNC + 
                       VBPORCH + 
                       TBORDER;
    
    parameter BEGINVSYNCH = HACTIVEREGION + RBORDER + HFPORCH + HSYNC + HBPORCH;
    parameter BEGINVINTH  = HACTIVEREGION + RBORDER + HFPORCH;
    parameter BEGINVINTV  = VACTIVEREGION + BBORDER + VFPORCH - 1;
    parameter ENDVINTV    = VACTIVEREGION + BBORDER + VFPORCH;
    parameter ENDVINTH    = (BEGINVINTH + 256)%HTOTAL;
    parameter BEGINHINTH  = HACTIVEREGION + RBORDER + HFPORCH;
    parameter ENDHINTH    = (BEGINHINTH + 256)%HTOTAL;

    parameter IOADDR_VMPR     = 8'd252,
              IOADDR_HMPR     = 8'd251,
              IOADDR_LMPR     = 8'd250,
              IOADDR_BORDER   = 8'd254,
              IOADDR_LINEINT  = 8'd249,
              IOADDR_STATUS   = 8'd249,
              IOADDR_BASECLUT = 8'd248,
              IOADDR_ATTRIB   = 8'd255;
    
    //////////////////////////////////////////////////////////////////////////
    // IO regs
`ifdef SYNTH
    reg [7:0] vmpr = 8'h00;  // port 252. bit 7 is not used. R/W  
`else
    reg [7:0] vmpr = 8'b01100000;  // port 252. bit 7 is not used. R/W. Mode 4 for simulation
      
`endif
    wire [1:0] screen_mode = vmpr[6:5];
    wire [4:0] screen_page = vmpr[4:0];
    
    reg [7:0] lmpr = 8'h00;  // port 250. R/W
    wire [4:0] low_page = lmpr[4:0];
    wire rom_in_section_a = ~lmpr[5];
    wire rom_in_section_d = lmpr[6];
    wire write_protect_section_a = lmpr[7];
    
    reg [7:0] hmpr = 8'h02;  // port 251. Bit 7 is not used for now. R/W
    wire [4:0] high_page = hmpr[4:0];
    wire [1:0] clut_mode_3_hi = hmpr[6:5];
    
    reg [7:0] border = 8'h00;  // port 254. Bit 6 not implemented. Write only. 
    wire [3:0] clut_border = {border[5],border[2:0]};
    assign mic = border[3];
    assign beep = border[4];
    wire screen_off = border[7] & screen_mode[1];
    
    reg [7:0] lineint = 8'hFF;   // port 249 write only
    
    reg [6:0] clut[0:15];  // Port xF8h where x=0..F 
    initial begin
        clut[ 0] = 7'b000_0_000;
        clut[ 1] = 7'b001_0_001;
        clut[ 2] = 7'b010_0_010;
        clut[ 3] = 7'b011_0_011;
        clut[ 4] = 7'b100_0_100;
        clut[ 5] = 7'b101_0_101;
        clut[ 6] = 7'b110_0_110;
        clut[ 7] = 7'b111_0_111;
        clut[ 8] = 7'b000_0_000;
        clut[ 9] = 7'b001_1_001;
        clut[10] = 7'b010_1_010;
        clut[11] = 7'b011_1_011;
        clut[12] = 7'b100_1_100;
        clut[13] = 7'b101_1_101;
        clut[14] = 7'b110_1_110;
        clut[15] = 7'b111_1_111;
    end
        
    //////////////////////////////////////////////////////////////////////////
    // Pixel counter and scan counter
    reg [9:0] hc = 10'h000;
    reg [8:0] vc = 9'h000;
    
    always @(posedge clk) begin
        if (hc != (HTOTAL-1))
            hc <= hc + 1;
        else begin
            hc <= 10'h000;
            if (vc != (VTOTAL-1))
                vc <= vc + 1;
            else
                vc <= 9'h000;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////
    // Syncs and vertical retrace/raster line int generation
    reg vint_n;
    reg rint_n;
    
    always @* begin
        csync = 1'b1;
        vint_n = 1'b1;
        rint_n = 1'b1;
        if (hc >= (HACTIVEREGION + RBORDER + HFPORCH) && 
            hc < (HACTIVEREGION + RBORDER + HFPORCH + HSYNC))
                csync = 1'b0;
        if ( (vc > BEGINVINTV && vc < (BEGINVINTV+4)) ||
             (vc == BEGINVINTV && hc >= BEGINVSYNCH) ||
             (vc == (BEGINVINTV+4) && hc < BEGINVSYNCH) )
                csync = ~csync;
        if ( (vc == BEGINVINTV && hc >= BEGINVINTH) ||
             (vc == ENDVINTV && hc < ENDVINTH) )
                vint_n = 1'b0;
        if (lineint >= 8'd0 && lineint <= 8'd191) begin
            if (lineint == 8'd0) begin
                if (vc == VTOTAL-1 && hc >= BEGINHINTH ||
                    vc == 9'd0 && hc < ENDHINTH)
                        rint_n = 1'b0;
            end
            else begin
                if ({1'b0, lineint} == vc-1 && hc >= BEGINHINTH ||
                    {1'b0, lineint} == vc && hc < ENDHINTH)
                        rint_n = 1'b0;
            end
        end
    end
    assign int_n = vint_n & rint_n;
    
    //////////////////////////////////////////////////////////////////////////
    // fetching_pixels = 1 when pixels should be fetched from memory
    reg fetching_pixels;
    
    always @* begin
        if (vc>=0 && vc<VACTIVEREGION && hc>=0 && hc<HACTIVEREGION)
            fetching_pixels = ~screen_off;
        else
            fetching_pixels = 1'b0;
    end

    //////////////////////////////////////////////////////////////////////////
    // Blanking time
    reg blank_time;

    always @* begin
        if ( (hc >= (HACTIVEREGION + RBORDER) && 
              hc < (HACTIVEREGION + RBORDER + HFPORCH + HSYNC + HBPORCH) ) ||
             (vc >= (VACTIVEREGION + BBORDER) &&
              vc < (VACTIVEREGION + BBORDER + VFPORCH + VSYNC + VBPORCH) ) ||
              (screen_off == 1'b1) )
                 blank_time = 1'b1;
        else
                 blank_time = 1'b0;
    end
    
    //////////////////////////////////////////////////////////////////////////
    // Contention signal (risk of)
    reg contention;
    
    always @* begin
        contention = 1'b0;
        if (fetching_pixels == 1'b1 && hc[3:0]<4'd10)
            contention = 1'b1;
        else if (fetching_pixels == 1'b0 && (hc[3:0]==4'd0 ||
                                            hc[3:0]==4'd1 ||
                                            hc[3:0]==4'd8 ||
                                            hc[3:0]==4'd9) )
            contention = 1'b1;
        if (screen_mode == 2'b00 && hc[3:0]<4'd10 && hc[9:4]<6'd40)
            contention = 1'b1;
    end
    assign asic_is_using_ram = contention & fetching_pixels;
    
    //////////////////////////////////////////////////////////////////////////
    // WAIT signal with contention applied
    always @* begin
        wait_n = 1'b1;
        if (cpuaddr<16'h4000 && rom_in_section_a==1'b1)
            wait_n = 1'b1;
        else if (cpuaddr>=16'hC000 && rom_in_section_d==1'b1)
            wait_n = 1'b1;
        else if (contention == 1'b1) begin
            if (mreq_n == 1'b0)
                wait_n = 1'b0;
            else if (iorq_n == 1'b0)
                if (rd_n == 1'b0 || wr_n == 1'b0)
                    wait_n = 1'b0;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////
    // VRAM address generation    
    always @* begin
        if (screen_mode == 2'd0) begin
            if (hc[2] == 1'b0)
                vramaddr = {screen_page, 1'b0, vc[7:6], vc[2:0], vc[5:3], screen_column};
            else
                vramaddr = {screen_page, 4'b0110, vc[7:3], screen_column};
        end
        else if (screen_mode == 2'd1) begin
            if (hc[2] == 1'b0)
                vramaddr = {screen_page, 1'b0, screen_offs[12:0]};
            else
                vramaddr = {screen_page, 1'b1, screen_offs[12:0]};
        end
        else
            vramaddr = {screen_page[4:0], 14'b00000000000000} + {3'b000, screen_offs};
    end

    //////////////////////////////////////////////////////////////////////////
    // FSM for fetching pixels from RAM and shift registers
    reg [15:0] screen_offs = 16'h0000;
    reg [4:0] screen_column = 5'h00;
    reg [7:0] vram_byte1, vram_byte2, vram_byte3, vram_byte4;
    reg [7:0] sregm12 = 8'h00;
    reg [7:0] attrreg = 8'h00;
    reg [31:0] sregm3 = 32'h00000000;
    reg [31:0] sregm4 = 32'h00000000;
    reg [4:0] flash_counter = 5'h00;
    reg [1:0] hibits_clut_m3 = 2'b00;

    always @(posedge clk) begin
        // a good time to reset pixel address counters and advance flash counter for modes 1 and 2
        if (vc==(VTOTAL-1) && hc==(HTOTAL-1)) begin
            screen_offs <= 16'h0000;
            screen_column <= 5'h00;
            flash_counter <= flash_counter + 1;
        end
        if (hc[3:0] == 4'd1 ||
            hc[3:0] == 4'd3 ||
            hc[3:0] == 4'd5 ||
            hc[3:0] == 4'd7)
            begin
                if (fetching_pixels==1'b1) begin
                    case (hc[2:0])
                        3'd1: vram_byte1 <= data_from_ram;
                        3'd3: vram_byte2 <= data_from_ram;
                        3'd5: vram_byte3 <= data_from_ram;
                        3'd7: begin
                                vram_byte4 <= data_from_ram;
                                screen_column <= screen_column + 1;
                                if (screen_mode[1] == 1'b0)  // mode 1 and 2
                                    screen_offs <= screen_offs + 1;
                              end
                    endcase
                    if (screen_mode[1] == 1'b1)  // mode 3 and 4
                        screen_offs <= screen_offs + 1;
                end
            end
        if (hc[3:0] == 4'd9) begin
            // Transferir buffers al registro de desplazamiento
            if (fetching_pixels == 1'b1) begin  // showing paper
                sregm12 <= vram_byte1;
                attrreg <= vram_byte3;
                sregm3 <= {vram_byte1, vram_byte2, vram_byte3, vram_byte4};
                sregm4 <= {vram_byte1, vram_byte2, vram_byte3, vram_byte4};
                hibits_clut_m3 <= clut_mode_3_hi;
            end
            else begin // showing border
                sregm12 <= 8'h00;
                attrreg <= {1'b0, clut_border, 3'b000};
                sregm3 <= { {16{clut_border[1:0]}} };
                sregm4 <= { {8{clut_border}} };
                hibits_clut_m3 <= clut_border[3:2];
            end
        end
        else begin
            sregm3 <= {sregm3[29:0],2'b00};
            if (hc[0] == 1'b1) begin
                sregm12 <= {sregm12[6:0],1'b0};
                sregm4 <= {sregm4[27:0],4'h0};
            end
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // MUX to select current pixel colour depending upon the current mode
    reg [6:0] pixel;
    reg [3:0] index;
    reg pixel_with_flash;
    
    always @* begin
        index = 4'h0;
        case (screen_mode)
            2'd0,2'd1:
                begin
                    pixel_with_flash = sregm12[7] ^ (attrreg[7] & flash_counter[4]);
                    if (pixel_with_flash == 1'b1)
                        index = {attrreg[6],attrreg[2:0]};
                    else
                        index = {attrreg[6],attrreg[5:3]};
                end
            2'd2: index = {hibits_clut_m3, sregm3[31:30]};
            2'd3: index = sregm4[31:28];
        endcase
        if (blank_time == 1'b1)
            pixel = 7'h00;
        else
            pixel = clut[index];
    end
    assign g = {pixel[6], pixel[2]};
    assign r = {pixel[5], pixel[1]};
    assign b = {pixel[4], pixel[0]};
    assign bright = pixel[3];
    
    //////////////////////////////////////////////////////////////////////////
    // CPU memory address and control signal generation
    
    // Enables for ROM and RAM
    always @* begin
        romcs_n = 1'b1;
        ramcs_n = 1'b1;
        if (mreq_n == 1'b0 && cpuaddr<16'h4000 && rom_in_section_a==1'b1) begin
            romcs_n = 1'b0;
        end
        else if (mreq_n == 1'b0 && cpuaddr>=16'hC000 && rom_in_section_d==1'b1) begin
            romcs_n = 1'b0;
        end
        else if (mreq_n == 1'b0 /*&& (contention == 1'b0 || fetching_pixels == 1'b0)*/ ) begin
            ramcs_n = 1'b0;
        end        
    end
    
    // Write signal for RAM
    always @* begin
        ramwr_n = 1'b1;
        case (cpuaddr[15:14])
            2'b00:
                begin
                    cpuramaddr = {low_page, cpuaddr[13:0]};
                    if (write_protect_section_a == 1'b0)
                        ramwr_n = ramcs_n | wr_n;
                end
            2'b01:
                begin
                    cpuramaddr = {low_page+5'd1, cpuaddr[13:0]};
                    ramwr_n = ramcs_n | wr_n;
                end
            2'b10:
                begin
                    cpuramaddr = {high_page, cpuaddr[13:0]};
                    ramwr_n = ramcs_n | wr_n;
                end
            default: // 2'b11
                begin
                    cpuramaddr = {high_page+5'd1, cpuaddr[13:0]};
                    ramwr_n = ramcs_n | wr_n;
                end
        endcase
    end

    //////////////////////////////////////////////////////////////////////////
    // IO ports
    
    // Write to IO ports from CPU
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
`ifdef SYNTH            
            vmpr <= 8'h00;
`else            
            vmpr <= 8'b01100000;
`endif            
            lmpr <= 8'h00;
            hmpr <= 8'h02;
            border <= 8'h00;
            lineint <= 8'hFF;
        end
        else begin
            if (iorq_n == 1'b0 && wr_n == 1'b0) begin
                if (cpuaddr[7:0] == IOADDR_BORDER)
                    border <= data_from_cpu;
                else if (cpuaddr[7:0] == IOADDR_VMPR)
                    vmpr <= data_from_cpu;
                else if (cpuaddr[7:0] == IOADDR_HMPR)
                    hmpr <= data_from_cpu;
                else if (cpuaddr[7:0] == IOADDR_LMPR)
                    lmpr <= data_from_cpu;
                else if (cpuaddr[7:0] == IOADDR_LINEINT)
                    lineint <= data_from_cpu;
                else if (cpuaddr[7:0] == IOADDR_BASECLUT)
                    clut[cpuaddr[11:8]] <= data_from_cpu[6:0];
            end
        end
    end
    
    // Data available for CPU
    always @* begin
        data_enable_n = 1'b1;
        data_to_cpu = 8'hFF;
        disc1_n = 1'b1;
        disc2_n = 1'b1;
        if (iorq_n == 1'b0 && rd_n == 1'b0) begin
            data_enable_n = 1'b0;
            if (cpuaddr[7:0] == IOADDR_BORDER)
                data_to_cpu = {1'b0, ear, 1'b0, keyboard[4:0]};
            else if (cpuaddr[7:0] == IOADDR_ATTRIB)
                data_to_cpu = vram_byte3;
            else if (cpuaddr[7:0] == IOADDR_STATUS)
                data_to_cpu = {keyboard[7:5], 1'b1, vint_n, 2'b11, rint_n};
            else if (cpuaddr[7:0] == IOADDR_VMPR)
                data_to_cpu = vmpr;
            else if (cpuaddr[7:0] == IOADDR_HMPR)
                data_to_cpu = hmpr;
            else if (cpuaddr[7:0] == IOADDR_LMPR)
                data_to_cpu = lmpr;
            else if (cpuaddr[7:0]>=8'd224 && cpuaddr[7:0]<=8'd231) begin            
                disc1_n = 1'b0;
                data_enable_n = 1'b1;
            end
            else if (cpuaddr[7:0]>=8'd240 && cpuaddr[7:0]<=8'd247) begin
                disc2_n = 1'b0;
                data_enable_n = 1'b1;
            end
            else
                data_enable_n = 1'b1;
        end
    end
    
    assign rdmsel = (cpuaddr[15:8] == 8'hFF)? 1'b0 : 1'b1;
endmodule
