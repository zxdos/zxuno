`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 16:40:14 2016-05-04 by Miguel Angel Rodriguez Jodar
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

module new_memory (
   // Relojes y reset
   input wire clk,        // Reloj de la CPU
   input wire mrst_n,
   input wire rst_n,
   
   // Interface con la CPU
   input wire [15:0] a,
   input wire [7:0] din,  // proveniente del bus de datos de salida de la CPU
   output reg [7:0] dout, // hacia el bus de datos de entrada de la CPU
   output reg oe,         // el dato es valido
   input wire mreq_n,
   input wire iorq_n,
   input wire rd_n,
   input wire wr_n,
   input wire m1_n,
   input wire rfsh_n,
   input wire busak_n,
   output wire enable_nmi_n,
   input wire page_configrom_active,

   // Interface con la ULA
   input wire [13:0] vramaddr,
   output wire [7:0] vramdout,
   input wire doc_ext_option,
   output wire issue2_keyboard_enabled,
   output reg [1:0] timing_mode,
   output wire disable_contention,
   output reg access_to_screen,
   output reg ioreqbank,

   // Interface con el bus externo
   input wire inhibit_rom,
   input wire [7:0] din_external,

   // Interface para registros ZXUNO
   input wire [7:0] addr,
   input wire ior,
   input wire iow,
   output wire in_boot_mode,
   
   // Interface con modulo de habilitacion de opciones
   input wire disable_7ffd,
   input wire disable_1ffd,
   input wire disable_romsel7f,
   input wire disable_romsel1f,
   input wire enable_timexmmu,
   
   // Interface con el módulo lector PZX
   input wire [20:0] pzx_addr,
   output wire enable_pzx,
   output wire in48kmode,
   input wire [7:0] data_from_pzx,
   output wire [7:0] data_to_pzx,
   input wire write_data_pzx,

   // Interface con la SRAM
   output wire [20:0] sram_addr,
   inout wire [7:0] sram_data,
   output wire sram_we_n
   );

`include "config.vh"

   reg initial_boot_mode = 1'b1;
   reg divmmc_is_enabled = 1'b0;
   reg divmmc_nmi_is_disabled = 1'b0;
   reg issue2_keyboard = 1'b0;
   initial timing_mode = 2'b01;
   reg disable_cont = 1'b0;
   reg masterconf_frozen = 1'b0;
   reg [1:0] negedge_configrom = 2'b00;
   reg rom48k_selected = 1'b1;  // forced to 1 so Derby++ can work, as it maps 48K ROM into ROM 1, not ROM 3.

   assign issue2_keyboard_enabled = issue2_keyboard;
   assign in_boot_mode = ~masterconf_frozen;
   assign disable_contention = disable_cont;

   always @(posedge clk) begin
      negedge_configrom <= {negedge_configrom[0], page_configrom_active};
      if (!mrst_n) begin
         {timing_mode[1],disable_cont,timing_mode[0],issue2_keyboard,divmmc_nmi_is_disabled,divmmc_is_enabled,initial_boot_mode} <= 7'b0000001;
         masterconf_frozen <= 1'b0;
      end
      else if (page_configrom_active == 1'b1) begin
        masterconf_frozen <= 1'b0;
        initial_boot_mode <= 1'b1;
      end
      else if (negedge_configrom == 2'b10) begin
        masterconf_frozen <= 1'b1;
        initial_boot_mode <= 1'b0;
      end
      else if (addr==MASTERCONF && iow) begin
         {timing_mode[1],disable_cont,timing_mode[0],issue2_keyboard,divmmc_nmi_is_disabled,divmmc_is_enabled} <= din[6:1];
         if (!masterconf_frozen) begin
            masterconf_frozen <= din[7];
            initial_boot_mode <= din[0];
         end
      end
   end

   reg [6:0] mastermapper = 7'h00;
   always @(posedge clk) begin
      if (!mrst_n)
         mastermapper <= 7'h00;
      else if (addr==MASTERMAPPER && iow && initial_boot_mode)
         mastermapper <= din[6:0];
   end
   
   // DIVMMC control register
   reg [7:0] divmmc_ctrl = 8'h00;
   wire [5:0] divmmc_sram_page = divmmc_ctrl[5:0];
   wire divmmc_sram_page_is_valid = (divmmc_sram_page[5:4] == 2'b00);  // solo admito 128K de SRAM para DivMMC
   wire mapram_mode = divmmc_ctrl[6];
   wire conmem = divmmc_ctrl[7];
   always @(posedge clk) begin
      if (!mrst_n)
         divmmc_ctrl <= 8'h00;
      else if (!rst_n)
         divmmc_ctrl <= {1'b0, mapram_mode, 6'b000000};
      else if (a[7:0]==8'he3 && !iorq_n && !wr_n) begin
         if (mapram_mode == 1'b0)
            divmmc_ctrl <= din;
         else
            divmmc_ctrl <= {din[7], 1'b1, din[5:0]};
      end
   end

   // DIVMMC automapper
   reg divmmc_is_paged = 1'b0;
   reg divmmc_status_after_m1 = 1'b0;
   assign enable_nmi_n = divmmc_is_enabled & divmmc_is_paged & ~divmmc_nmi_is_disabled;
   wire divmmc_rom_active = divmmc_is_enabled && (divmmc_is_paged || conmem);

   always @(posedge clk) begin
      if (!mrst_n || !rst_n) begin
         divmmc_is_paged <= 1'b0;
         divmmc_status_after_m1 <= 1'b0;
      end
      else begin
         if (!mreq_n && !rd_n && !m1_n && (a==16'h0000 || 
                                           a==16'h0008 && rom48k_selected ||
                                           a==16'h0038 && rom48k_selected ||
                                          (a==16'h0066 && rom48k_selected && divmmc_nmi_is_disabled==1'b0 && page_configrom_active==1'b0) ||
                                           a==16'h04C6 && rom48k_selected ||
                                           a==16'h0562 && rom48k_selected)) begin  // automapper diferido (siguiente ciclo)
           divmmc_status_after_m1 <= 1'b1;
         end
         else if (!mreq_n && !rd_n && !m1_n && a[15:8]==8'h3D && rom48k_selected) begin  // automapper no diferido (ciclo actual)
            divmmc_is_paged <= 1'b1;
            divmmc_status_after_m1 <= 1'b1;
         end
         else if (!mreq_n && !rd_n && !m1_n && a[15:3]==13'b0001_1111_1111_1) begin  // desconexión de automapper diferido
            divmmc_status_after_m1 <= 1'b0;
         end
      end
      if (m1_n==1'b1) begin  // tras el ciclo M1, aquí es cuando realmente se hace el mapping
         divmmc_is_paged <= divmmc_status_after_m1;
      end
   end
    
   wire ADDR_7FFD_PLUS2A = (!a[1] && a[15:14]==2'b01 && (!enable_timexmmu || a[7:0]!=8'hF4));
   wire ADDR_7FFD_SP128  = (!a[1] && !a[15] && (!enable_timexmmu || a[7:0]!=8'hF4));
   wire ADDR_1FFD        = (!a[1] && a[15:12]==4'b0001 && (!enable_timexmmu || a[7:0]!=8'hF4));
   wire ADDR_TIMEX_MMU   = (a[7:0] == 8'hF4);

   localparam PAGE0 = 3'b000,
              PAGE1 = 3'b001,
              PAGE2 = 3'b010,
              PAGE3 = 3'b011,
              PAGE4 = 3'b100,
              PAGE5 = 3'b101,
              PAGE6 = 3'b110,
              PAGE7 = 3'b111;

   // Standard 128K memory manager and Timex MMU manager
   reg [7:0] bank128 = 8'h00;
   reg [7:0] bankplus3 = 8'h00;
   reg [7:0] timex_mmu = 8'h00;
   wire puerto_bloqueado = bank128[5];
   wire [2:0] banco_ram = bank128[2:0];
   wire [1:0] banco_extendido_512k = bank128[7:6];
   wire vrampage = bank128[3];
   wire [1:0] banco_rom = {bankplus3[2] & (~disable_romsel1f), bank128[4] & (~disable_romsel7f)};
   wire amstrad_allram_page_mode = bankplus3[0];
   wire [1:0] plus3_memory_arrangement = bankplus3[2:1];
   
   assign in48kmode = puerto_bloqueado | disable_7ffd;

   always @(posedge clk) begin
      if (!mrst_n || !rst_n) begin
         bank128 <= 8'h00;
         bankplus3 <= 8'h00;
         timex_mmu <= 8'h00;
      end
      else begin
        if (!disable_1ffd && !disable_7ffd) begin
            if (!iorq_n && !wr_n && ADDR_1FFD && !puerto_bloqueado) begin
                bankplus3[7:3] <= din[7:3];
                bankplus3[1:0] <= din[1:0];
                bankplus3[2] <= din[2];
            end
            else if (!iorq_n && !wr_n && ADDR_7FFD_PLUS2A && !puerto_bloqueado) begin
                bank128[7:5] <= din[7:5];
                bank128[3:0] <= din[3:0];
                bank128[4] <= din[4];
            end
        end
        else if (!disable_7ffd && disable_1ffd && !iorq_n && !wr_n && ADDR_7FFD_SP128 && !puerto_bloqueado) begin
            bank128[7:5] <= din[7:5];
            bank128[3:0] <= din[3:0];
            bank128[4] <= din[4];
        end
        else if (enable_timexmmu && !iorq_n && !wr_n && ADDR_TIMEX_MMU)
            timex_mmu <= din;
      end
   end

   always @* begin
      if (!disable_7ffd && disable_1ffd && !iorq_n && (!wr_n || !rd_n) && ADDR_7FFD_SP128)
         ioreqbank = 1'b1;
      else
         ioreqbank = 1'b0;
   end

   reg [20:0] addr_port2;
   reg oe_memory_n;
   reg oe_bootrom_n;
   reg we2_n;
   reg ram_busy;
   assign enable_pzx = ~ram_busy;

//   always @* begin
//    rom48k_selected = 1'b0;
//    if (banco_rom == 2'b11 ||
//        banco_rom == 2'b01 && disable_romsel1f == 1'b1 && disable_romsel7f == 1'b0 ||
//        banco_rom == 2'b00 && disable_romsel1f == 1'b1 && disable_romsel7f == 1'b1)
//        rom48k_selected = 1'b1;
//   end

   // Calculo de la dirección en la SRAM a la que se va a acceder
   // y señales de acceso de lectura y escritura

   always @* begin
      oe_memory_n = mreq_n | rd_n;
      we2_n = mreq_n | wr_n;
      oe_bootrom_n = 1'b1;
      addr_port2 = 21'h000000;
      
      if (busak_n == 1'b1 && (rfsh_n == 1'b0 || iorq_n == 1'b0))
        ram_busy = 1'b0;
      else
        ram_busy = 1'b1;

      //------------------------------------------------------------------------------------------------------------------
      if (!mreq_n && a[15:14]==2'b00) begin   // la CPU quiere acceder al espacio de ROM, $0000-$3FFF
         if (initial_boot_mode) begin   // en el modo boot, sólo se accede a la ROM interna
            oe_memory_n = 1'b1;
            oe_bootrom_n = 1'b0;
            we2_n = 1'b1;
            ram_busy = 1'b0;
         end
         else begin  // estamos en modo normal de ejecución
            // Lo que mas prioridad tiene es la linea externa ROMCS. Si esta activa, no se tiene en cuenta nada mas
            if (inhibit_rom == 1'b0) begin
                // DIVMMC tiene más prioridad que la MMU del Timex, así que se evalua primero.
                if (divmmc_rom_active) begin  // DivMMC ha entrado en modo automapper o está mapeado a la fuerza
                   if (a[13]==1'b0) begin // Si estamos en los primeros 8K
                      if (mapram_mode == 1'b0 || conmem == 1'b1) begin
                         addr_port2 = {8'b00011000,a[12:0]};
                         we2_n = 1'b1;  // en este modo, la ROM es intocable
                      end
                      else begin  // mapram mode
                         addr_port2 = {8'b00100011,a[12:0]};  // pagina 3 de la SRAM del DIVMMC
                         we2_n = 1'b1;
                      end
                   end
                   else begin  // Si estamos en los segundos 8K
                      if (mapram_mode == 1'b0 || conmem == 1'b1) begin
                         addr_port2 = {4'b0010,divmmc_sram_page[3:0],a[12:0]};
                         if (divmmc_sram_page_is_valid == 1'b0)
                           we2_n = 1'b1;
                      end
                      else begin  // mapram mode
                         addr_port2 = {4'b0010,divmmc_sram_page[3:0],a[12:0]};
                         if (mapram_mode && divmmc_sram_page==6'b000011 || divmmc_sram_page_is_valid == 1'b0)
                            we2_n = 1'b1;  // en este modo, la ROM es intocable
                      end
                   end
                end

                // DivMMC no está activo, asi que comprobamos qué página toca de HOME. Luego comprobamos si hay que paginar DOC
                // o EXT y se hace un override a lo que haya definido en HOME
                else begin
                    if (!amstrad_allram_page_mode) begin   // en el modo normal de paginación, hay 4 bancos de ROMs
                       addr_port2 = {5'b00010,banco_rom,a[13:0]}; // que vienen de los bancos de SRAM del 8 al 11
                       we2_n = 1'b1;
                    end
                    else begin   // en el modo especial de paginación, tenemos el all-RAM
                       case (plus3_memory_arrangement)
                          2'b00 : addr_port2 = {4'b0000,PAGE0,a[13:0]};
                          2'b01,
                          2'b10,
                          2'b11 : addr_port2 = {4'b0000,PAGE4,a[13:0]};
                       endcase
                    end
                    
                    // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
                    if (a[13] == 1'b0 && timex_mmu[0] == 1'b1) begin
                        addr_port2 = {4'b0011,doc_ext_option,3'b000,a[12:0]};
                        we2_n = mreq_n | wr_n;
                    end
                    if (a[13] == 1'b1 && timex_mmu[1] == 1'b1) begin
                        addr_port2 = {4'b0011,doc_ext_option,3'b001,a[12:0]};
                        we2_n = mreq_n | wr_n;
                    end
                end
             end // del modo normal de ejecución
          end // de la comprobacion de ROMCS
      end // de a[15:14] == 2'b00
      
      //------------------------------------------------------------------------------------------------------------------
      else if (!mreq_n && a[15:14]==2'b01) begin   // la CPU quiere acceder al espacio de RAM de $4000-$7FFF
         if (initial_boot_mode || !amstrad_allram_page_mode) begin   // en modo normal de paginación, o en modo boot, hacemos lo mismo, que es
            addr_port2 = {4'b0000,PAGE5,a[13:0]};      // paginar el banco 5 de RAM aquí
         end
         else begin   // en el modo especial de paginación del +3...
            case (plus3_memory_arrangement)
               2'b00 : addr_port2 = {4'b0000,PAGE1,a[13:0]};
               2'b01,
               2'b10 : addr_port2 = {4'b0000,PAGE5,a[13:0]};
               2'b11 : addr_port2 = {4'b0000,PAGE7,a[13:0]};
            endcase
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[2] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b010,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[3] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b011,a[12:0]};
                end
         end
      end // de a[15:14] == 2'b01
      
      //------------------------------------------------------------------------------------------------------------------
      else if (!mreq_n && a[15:14]==2'b10) begin   // la CPU quiere acceder al espacio de RAM de $8000-$BFFF
         if (initial_boot_mode || !amstrad_allram_page_mode) begin
            addr_port2 = {4'b0000,PAGE2,a[13:0]};
         end
         else begin   // en el modo especial de paginación del +3...
            case (plus3_memory_arrangement)
               2'b00 : addr_port2 = {4'b0000,PAGE2,a[13:0]};
               2'b01,
               2'b10,
               2'b11 : addr_port2 = {4'b0000,PAGE6,a[13:0]};
            endcase
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[4] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b100,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[5] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b101,a[12:0]};
                end
         end
      end // de a[15:14] == 2'b10

      //------------------------------------------------------------------------------------------------------------------
      else if (!mreq_n && a[15:14]==2'b11) begin   // la CPU quiere acceder al espacio de RAM de $C000-$FFFF
         if (initial_boot_mode) begin  // en el modo de boot, este area contiene una página de 16K de la SRAM, la que sea
            addr_port2 = {mastermapper,a[13:0]};
         end
         else begin
            if (!amstrad_allram_page_mode) begin
`ifdef PENTAGON_512K_SUPPORT
               addr_port2 = {banco_extendido_512k,2'b00,banco_ram,a[13:0]}; // para soportar Pentagon 512.
`else
               addr_port2 = {4'b0000,banco_ram,a[13:0]};
`endif               
            end
            else begin
               case (plus3_memory_arrangement)
                  2'b00,
                  2'b10,
                  2'b11 : addr_port2 = {4'b0000,PAGE3,a[13:0]};
                  2'b01 : addr_port2 = {4'b0000,PAGE7,a[13:0]};
               endcase
            end
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[6] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b110,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[7] == 1'b1) begin
                    addr_port2 = {4'b0011,doc_ext_option,3'b111,a[12:0]};
                end
         end
      end // de a[15:14] == 2'b11
      
      else begin  // realmente a esta parte nunca se habría de llegar, pero para completar la cadena de if-else if...
        oe_memory_n = 1'b1;
        oe_bootrom_n = 1'b1;
      end
   end
   
   always @* begin
     access_to_screen = 1'b0;
     if (!initial_boot_mode) begin
        if (a[15:13]==3'b010 && timex_mmu[2]==1'b1 ||  // si se ha paginado memoria de DOC o EXT, no hay contienda
            a[15:13]==3'b011 && timex_mmu[3]==1'b1 ||
            a[15:13]==3'b110 && timex_mmu[6]==1'b1 ||
            a[15:13]==3'b111 && timex_mmu[7]==1'b1)
                access_to_screen = 1'b0;
        else if (!amstrad_allram_page_mode) begin
           if (a[15:14]==2'b01 || (a[15:14]==2'b11 && banco_ram[0]==1'b1) ) begin // Hay contienda en las páginas impares de memoria
               access_to_screen = 1'b1;
           end
        end
     end
   end

   // Conexiones internas
   wire [7:0] bootrom_dout;
   wire [7:0] ram_dout;

   sram_and_mirror toda_la_ram (  // Nuevo controlador de SRAM usando BRAM de doble puerto para evitar la contienda
      .clk(clk),
      .a1({vrampage,vramaddr}),
      .a2(addr_port2),
      .we2_n(we2_n),
      .dout1(vramdout),
      .din2(din),
      .dout2(ram_dout),

      .pzx_addr(pzx_addr),
      .enable_pzx(~ram_busy),
      .data_from_pzx(data_from_pzx),
      .data_to_pzx(data_to_pzx),
      .write_data_pzx(write_data_pzx),
      
      .a(sram_addr),  // Interface con la SRAM real
      .d(sram_data),
      .we_n(sram_we_n)
      );

   rom boot_rom (
      .clk(clk),
      .a(a[13:0]),
      .dout(bootrom_dout)
    );    

   // Elección del dato a entregar a la CPU
   always @* begin
      if (!oe_bootrom_n) begin
         dout = bootrom_dout;
         oe = 1'b1;
      end
      else if (!initial_boot_mode && inhibit_rom && a[15:14]==2'b00) begin
         oe = 1'b1;
         dout = din_external;
      end
      else if (!oe_memory_n) begin
         dout = ram_dout;
         oe = 1'b1;
      end
      else if (enable_timexmmu && iorq_n == 1'b0 && rd_n == 1'b0 && ADDR_TIMEX_MMU) begin
         oe = 1'b1;
         dout = timex_mmu;
      end
      else if (addr==MASTERCONF && ior) begin
         dout = {masterconf_frozen,timing_mode[1],disable_cont,timing_mode[0],issue2_keyboard,divmmc_nmi_is_disabled,divmmc_is_enabled,initial_boot_mode};
         oe = 1'b1;
      end
      else if (addr==MASTERMAPPER && ior) begin
         dout = {1'b0,mastermapper};
         oe = 1'b1;
      end
      else begin
         dout = 8'hFF;
         oe = 1'b0;
      end
   end

endmodule

module sram_and_mirror (
    input wire clk,          // 28MHz
    input wire [14:0] a1,    // to BRAM addr bus
    input wire [20:0] a2,    // to SRAM addr bus
    input wire we2_n,        // to SRAM WE enable
    input wire [7:0] din2,   // to SRAM data bus in
    output reg [7:0] dout1,  // from BRAM data bus out
    output wire [7:0] dout2, // from SRAM data bus out

    input wire [20:0] pzx_addr,
    input wire enable_pzx,
    input wire write_data_pzx,
    input wire [7:0] data_from_pzx,
    output wire [7:0] data_to_pzx,
    
    output wire [20:0] a,    // SRAM addr bus
    inout wire [7:0] d,      // SRAM bidirectional data bus
    output wire we_n         // SRAM WE enable
    );
    
    // BRAM to implement a dual port 32KB memory buffer
    // First 16KB mirrors page 5, second 16KB mirrors page 7
    reg [7:0] vram[0:32767];
    integer i;
    initial begin
        for (i=0;i<32768;i=i+1)
            vram[i] = 8'h00;
`ifdef LOAD_ROM_FROM_FLASH_OPTION
        $readmemh("initial_bootscreen.hex", vram, 0);
`else
        $readmemh(`DEFAULT_SYSTEM_ROM, vram, 0);
`endif        
    end
    
    // BRAM manager
    reg [7:0] data_from_bram;
    always @(posedge clk) begin
        if (a2[20:16] == 5'b00001 && a2[14] == 1'b1) begin
          if (we2_n == 1'b0)
            vram[{a2[15],a2[13:0]}] <= din2;
          else
            data_from_bram <= vram[{a2[15],a2[13:0]}];
        end
        dout1 <= vram[a1];
    end
    
    reg we2_n_dly = 1'b1;
    always @(negedge clk)
      we2_n_dly <= we2_n;
    
    // SRAM manager. Easy, isn't it? :D
`ifdef PZX_PLAYER_OPTION
    assign a =    (enable_pzx)? pzx_addr : a2;
    assign we_n = (enable_pzx)? ~write_data_pzx : we2_n & we2_n_dly;  // pulso de escritura ligeramente ensenchado
    assign dout2 = (a2[20:16] == 5'b00001 && a2[14] == 1'b1)? data_from_bram : d;
    assign data_to_pzx = d;
    assign d = (we2_n_dly == 1'b0 && write_data_pzx == 1'b0)? din2 :  // dejo medio ciclo de reloj a Z antes de poner el dato
               (enable_pzx == 1'b1 && write_data_pzx == 1'b1)? data_from_pzx :
               8'hZZ;
`else
    assign a = a2;
    assign we_n = we2_n & we2_n_dly;
    assign dout2 = (a2[20:16] == 5'b00001 && a2[14] == 1'b1)? data_from_bram : d;
    assign data_to_pzx = 8'h00;
    assign d = (we2_n_dly == 1'b0)? din2 : 8'hZZ;
`endif               
endmodule
