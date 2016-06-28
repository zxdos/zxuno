`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:40:14 05/04/2016 
// Design Name: 
// Module Name:    new_memory 
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

module new_memory (
   // Relojes y reset
   input wire clk,        // Reloj de la CPU
   input wire mclk,       // Reloj para la BRAM
   input wire mrst_n,
   input wire rst_n,
   
   // Interface con la CPU
   input wire [15:0] a,
   input wire [7:0] din,  // proveniente del bus de datos de salida de la CPU
   output reg [7:0] dout, // hacia el bus de datos de entrada de la CPU
   output reg oe_n,       // el dato es valido
   input wire mreq_n,
   input wire iorq_n,
   input wire rd_n,
   input wire wr_n,
   input wire m1_n,
   input wire rfsh_n,
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

   // Interface con la SRAM
   output wire [18:0] sram_addr,
   inout wire [7:0] sram_data,
   output wire sram_we_n
   );

   parameter
      MASTERCONF = 8'h00,
      MASTERMAPPER = 8'h01;

   reg initial_boot_mode = 1'b1;
   reg divmmc_is_enabled = 1'b0;
   reg divmmc_nmi_is_disabled = 1'b0;
   reg issue2_keyboard = 1'b0;
   initial timing_mode = 2'b00;
   reg disable_cont = 1'b0;
   reg masterconf_frozen = 1'b0;
   reg [1:0] negedge_configrom = 2'b00;

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
         {timing_mode[1],disable_cont,timing_mode[0],issue2_keyboard} <= din[6:3];
         if (!masterconf_frozen) begin
            masterconf_frozen <= din[7];
            {divmmc_nmi_is_disabled,divmmc_is_enabled,initial_boot_mode} <= din[2:0];
         end
      end
   end

   reg [4:0] mastermapper = 5'h00;
   always @(posedge clk) begin
      if (!mrst_n)
         mastermapper <= 5'h00;
      else if (addr==MASTERMAPPER && iow && initial_boot_mode)
         mastermapper <= din[4:0];
   end
   
   // DIVMMC control register
   reg [7:0] divmmc_ctrl = 8'h00;
   wire [3:0] divmmc_sram_page = divmmc_ctrl[3:0];
   wire mapram_mode = divmmc_ctrl[6];
   wire conmem = divmmc_ctrl[7];
   always @(posedge clk) begin
      if (!mrst_n || !rst_n)
         divmmc_ctrl <= 8'h00;
      else if (a[7:0]==8'he3 && !iorq_n && !wr_n)
         divmmc_ctrl <= din;
   end

   // DIVMMC automapper
   reg divmmc_is_paged = 1'b0;
   reg divmmc_status_after_m1 = 1'b0;
   assign enable_nmi_n = divmmc_is_enabled & divmmc_is_paged & ~divmmc_nmi_is_disabled;
   always @(posedge clk) begin
      if (!mrst_n || !rst_n) begin
         divmmc_is_paged <= 1'b0;
         divmmc_status_after_m1 <= 1'b0;
      end
      else begin
         if (!mreq_n && !rd_n && !m1_n && (a==16'h0000 || 
                                           a==16'h0008 ||
                                           a==16'h0038 ||
                                           (a==16'h0066 && divmmc_nmi_is_disabled==1'b0 && page_configrom_active==1'b0) ||
                                           a==16'h04C6 ||
                                           a==16'h0562)) begin  // automapper diferido (siguiente ciclo)
           divmmc_status_after_m1 <= 1'b1;
         end
         else if (!mreq_n && !rd_n && !m1_n && a[15:8]==8'h3D) begin  // automapper no diferido (ciclo actual)
            divmmc_is_paged <= 1'b1;
            divmmc_status_after_m1 <= 1'b1;
         end
         else if (!mreq_n && !rd_n && !m1_n && a[15:3]==13'b0001111111111) begin  // desconexión de automapper diferido
            divmmc_status_after_m1 <= 1'b0;
         end
      end
      if (m1_n==1'b1) begin  // tras el ciclo M1, aquí es cuando realmente se hace el mapping
         divmmc_is_paged <= divmmc_status_after_m1;
      end
   end
    
`define ADDR_7FFD_PLUS2A (a[0] && !a[1] && a[15:14]==2'b01)
`define ADDR_7FFD_SP128 (a[0] && !a[1] && !a[15])
`define ADDR_1FFD (a[0] && !a[1] && a[15:12]==4'b0001)
`define ADDR_TIMEX_MMU (a[7:0] == 8'hF4)

`define PAGE0 3'b000
`define PAGE1 3'b001
`define PAGE2 3'b010
`define PAGE3 3'b011
`define PAGE4 3'b100
`define PAGE5 3'b101
`define PAGE6 3'b110
`define PAGE7 3'b111

   // Standard 128K memory manager and Timex MMU manager
   reg [7:0] bank128 = 8'h00;
   reg [7:0] bankplus3 = 8'h00;
   reg [7:0] timex_mmu = 8'h00;
   wire puerto_bloqueado = bank128[5];
   wire [2:0] banco_ram = bank128[2:0];
   wire vrampage = bank128[3];
   wire [1:0] banco_rom = {bankplus3[2] & (~disable_romsel1f), bank128[4] & (~disable_romsel7f)};
   wire amstrad_allram_page_mode = bankplus3[0];
   wire [1:0] plus3_memory_arrangement = bankplus3[2:1];
   
   always @(posedge clk) begin
      if (!mrst_n || !rst_n) begin
         bank128 <= 8'h00;
         bankplus3 <= 8'h00;
         timex_mmu <= 8'h00;
      end
      else begin
        if (!disable_1ffd && !disable_7ffd) begin
            if (!iorq_n && !wr_n && `ADDR_1FFD && !puerto_bloqueado)
                bankplus3 <= din;
            else if (!iorq_n && !wr_n && `ADDR_7FFD_PLUS2A && !puerto_bloqueado)
                bank128 <= din;
        end
        else if (!disable_7ffd && disable_1ffd && !iorq_n && !wr_n && `ADDR_7FFD_SP128 && !puerto_bloqueado)
            bank128 <= din;
        else if (enable_timexmmu && !iorq_n && !wr_n && `ADDR_TIMEX_MMU)
            timex_mmu <= din;
      end
   end
   
   reg [18:0] addr_port2;
   reg oe_memory_n;
   reg oe_bootrom_n;
   reg we2_n;
   
   // Calculo de la dirección en la SRAM a la que se va a acceder
   
   always @* begin
      oe_memory_n = mreq_n | rd_n;
      we2_n = mreq_n | wr_n;
      oe_bootrom_n = 1'b1;
      addr_port2 = 19'h00000;
      
      //------------------------------------------------------------------------------------------------------------------
      if (!mreq_n && a[15:14]==2'b00) begin   // la CPU quiere acceder al espacio de ROM, $0000-$3FFF
         if (initial_boot_mode) begin   // en el modo boot, sólo se accede a la ROM interna
            oe_memory_n = 1'b1;
            oe_bootrom_n = 1'b0;
            we2_n = 1'b1;
         end
         else begin  // estamos en modo normal de ejecución
            // Lo que mas prioridad tiene es la linea externa ROMCS. Si esta activa, no se tiene en cuenta nada mas
            if (inhibit_rom == 1'b0) begin
                // DIVMMC tiene más prioridad que la MMU del Timex, así que se evalua primero.
                if (divmmc_is_enabled && (divmmc_is_paged || conmem)) begin  // DivMMC ha entrado en modo automapper o está mapeado a la fuerza
                   if (a[13]==1'b0) begin // Si estamos en los primeros 8K
                      if (conmem || !mapram_mode) begin
                         addr_port2 = {6'b011000,a[12:0]};
                         we2_n = 1'b1;  // en este modo, la ROM es intocable
                      end
                      else begin  // mapram mode
                         addr_port2 = {6'b100011,a[12:0]};  // pagina 3 de la SRAM del DIVMMC
                         we2_n = 1'b1;
                      end
                   end
                   else begin  // Si estamos en los segundos 8K
                      if (conmem || !mapram_mode) begin
                         addr_port2 = {2'b10,divmmc_sram_page,a[12:0]};
                      end
                      else begin  // mapram mode
                         addr_port2 = {2'b10,divmmc_sram_page,a[12:0]};
                         if (mapram_mode && divmmc_sram_page==4'b0011)
                            we2_n = 1'b1;  // en este modo, la ROM es intocable
                      end
                   end
                end
                
                // DivMMC no está activo, asi que comprobamos qué página toca de HOME. Luego comprobamos si hay que paginar DOC
                // o EXT y se hace un override a lo que haya definido en HOME
                else begin
                    if (!amstrad_allram_page_mode) begin   // en el modo normal de paginación, hay 4 bancos de ROMs
                       addr_port2 = {3'b010,banco_rom,a[13:0]}; // que vienen de los bancos de SRAM del 8 al 11
                       we2_n = 1'b1;
                    end
                    else begin   // en el modo especial de paginación, tenemos el all-RAM
                       case (plus3_memory_arrangement)
                          2'b00 : addr_port2 = {2'b00,`PAGE0,a[13:0]};
                          2'b01,
                          2'b10,
                          2'b11 : addr_port2 = {2'b00,`PAGE4,a[13:0]};
                       endcase
                    end
                    
                    // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
                    if (a[13] == 1'b0 && timex_mmu[0] == 1'b1) begin
                        addr_port2 = {2'b11,doc_ext_option,3'b000,a[12:0]};
                        we2_n = mreq_n | wr_n;
                    end
                    if (a[13] == 1'b1 && timex_mmu[1] == 1'b1) begin
                        addr_port2 = {2'b11,doc_ext_option,3'b001,a[12:0]};
                        we2_n = mreq_n | wr_n;
                    end
                end
             end // del modo normal de ejecución
          end // de la comprobacion de ROMCS
      end // de a[15:14] == 2'b00
      
      //------------------------------------------------------------------------------------------------------------------
      else if (!mreq_n && a[15:14]==2'b01) begin   // la CPU quiere acceder al espacio de RAM de $4000-$7FFF
         if (initial_boot_mode || !amstrad_allram_page_mode) begin   // en modo normal de paginación, o en modo boot, hacemos lo mismo, que es
            addr_port2 = {2'b00,`PAGE5,a[13:0]};      // paginar el banco 5 de RAM aquí
         end
         else begin   // en el modo especial de paginación del +3...
            case (plus3_memory_arrangement)
               2'b00 : addr_port2 = {2'b00,`PAGE1,a[13:0]};
               2'b01,
               2'b10 : addr_port2 = {2'b00,`PAGE5,a[13:0]};
               2'b11 : addr_port2 = {2'b00,`PAGE7,a[13:0]};
            endcase
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[2] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b010,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[3] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b011,a[12:0]};
                end
         end
      end // de a[15:14] == 2'b01
      
      //------------------------------------------------------------------------------------------------------------------
      else if (!mreq_n && a[15:14]==2'b10) begin   // la CPU quiere acceder al espacio de RAM de $8000-$BFFF
         if (initial_boot_mode || !amstrad_allram_page_mode) begin
            addr_port2 = {2'b00,`PAGE2,a[13:0]};
         end
         else begin   // en el modo especial de paginación del +3...
            case (plus3_memory_arrangement)
               2'b00 : addr_port2 = {2'b00,`PAGE2,a[13:0]};
               2'b01,
               2'b10,
               2'b11 : addr_port2 = {2'b00,`PAGE6,a[13:0]};
            endcase
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[4] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b100,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[5] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b101,a[12:0]};
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
               addr_port2 = {2'b00,banco_ram,a[13:0]};
            end
            else begin
               case (plus3_memory_arrangement)
                  2'b00,
                  2'b10,
                  2'b11 : addr_port2 = {2'b00,`PAGE3,a[13:0]};
                  2'b01 : addr_port2 = {2'b00,`PAGE7,a[13:0]};
               endcase
            end
         end

         // Miramos si hay que paginar DOC o EXT y actualizamos addr_port2 y we2_n segun sea el caso
         if (!initial_boot_mode) begin
                if (a[13] == 1'b0 && timex_mmu[6] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b110,a[12:0]};
                end
                if (a[13] == 1'b1 && timex_mmu[7] == 1'b1) begin
                    addr_port2 = {2'b11,doc_ext_option,3'b111,a[12:0]};
                end
         end
      end // de a[15:14] == 2'b11
      
      else begin  // realmente a esta parte nunca se habría de llegar, pero para completar la cadena de if-else if...
         oe_memory_n = 1'b1;
         oe_bootrom_n = 1'b1;
      end
   end

   // Hay contienda en las páginas 5 y 7 de memoria, que son las dos páginas de pantalla
   always @* begin
     access_to_screen = 1'b0;
     if (!initial_boot_mode) begin
        if (a[15:13]==2'b010 && timex_mmu[2]==1'b1 ||  // si se ha paginado memoria de DOC o EXT, no hay contienda
            a[15:13]==2'b011 && timex_mmu[3]==1'b1 ||
            a[15:13]==2'b110 && timex_mmu[6]==1'b1 ||
            a[15:13]==2'b111 && timex_mmu[7]==1'b1)
                access_to_screen = 1'b0;
        else if (!amstrad_allram_page_mode) begin
           if (a[15:14]==2'b01 || (a[15:14]==2'b11 && (banco_ram==3'd5 || banco_ram==3'd7))) begin
               access_to_screen = 1'b1;
           end
        end
     end
   end

   // Conexiones internas
   wire [7:0] bootrom_dout;
   wire [7:0] ram_dout;

   sram_and_mirror toda_la_ram (  // Nuevo controlador de SRAM usando BRAM de doble puerto para evitar la contienda
      .clk(mclk),
      .a1({vrampage,vramaddr}),
      .a2(addr_port2),
      .we2_n(we2_n),
      .dout1(vramdout),
      .din2(din),
      .dout2(ram_dout),
      
      .a(sram_addr),  // Interface con la SRAM real
      .d(sram_data),
      .we_n(sram_we_n)
      );

   rom boot_rom (
      .clk(mclk),
      .a(a[13:0]),
      .dout(bootrom_dout)
    );    

   // Elección del dato a entregar a la CPU
   always @* begin
      if (!oe_bootrom_n) begin
         dout = bootrom_dout;
         oe_n = 1'b0;
      end
      else if (!initial_boot_mode && inhibit_rom && a[15:14]==2'b00) begin
         oe_n = 1'b0;
         dout = din_external;
      end
      else if (!oe_memory_n) begin
         dout = ram_dout;
         oe_n = 1'b0;
      end
      else if (enable_timexmmu && iorq_n == 1'b0 && rd_n == 1'b0 && `ADDR_TIMEX_MMU) begin
         oe_n = 1'b0;
         dout = timex_mmu;
      end
      else if (addr==MASTERCONF && ior) begin
         dout = {masterconf_frozen,timing_mode[1],disable_cont,timing_mode[0],issue2_keyboard,divmmc_nmi_is_disabled,divmmc_is_enabled,initial_boot_mode};
         oe_n = 1'b0;
      end
      else if (addr==MASTERMAPPER && ior) begin
         dout = {3'b000,mastermapper};
         oe_n = 1'b0;
      end
      else begin
         dout = 8'hZZ;
         oe_n = 1'b1;
      end
   end

endmodule

module sram_and_mirror (
    input wire clk,          // 28MHz
    input wire [14:0] a1,    // to BRAM addr bus
    input wire [18:0] a2,    // to SRAM addr bus
    input wire we2_n,        // to SRAM WE enable
    input wire [7:0] din2,   // to SRAM data bus in
    output reg [7:0] dout1, // from BRAM data bus out
    output wire [7:0] dout2, // from SRAM data bus out
    
    output wire [18:0] a,     // SRAM addr bus
    inout wire [7:0] d,      // SRAM bidirectional data bus
    output wire we_n          // SRAM WE enable
    );
    
    // BRAM to implement a dual port 32KB memory buffer
    // First 16KB mirrors page 5, second 16KB mirrors page 7
    reg [7:0] vram[0:32767];
    integer i;
    initial begin
        $readmemh("initial_bootscreen.hex", vram, 0, 6912);
        for (i=6912;i<32768;i=i+1)
            vram[i] = 8'h00;
    end
    
    // BRAM manager
    always @(posedge clk) begin
        if (we2_n == 1'b0 && a2[18:16] == 3'b001 && a2[14] == 1'b1)
            vram[{a2[15],a2[13:0]}] <= din2;
        dout1 <= vram[a1];
    end
    
    // SRAM manager. Easy, isn't it? :D
//    reg [7:0] data_to_sram;
//    always @(posedge clk) begin
//        a <= a2;
//        we_n <= we2_n;
//        dout2 <= d;
//        data_to_sram <= (we_n == 1'b0)? din2 : 8'hZZ;
//    end
//    assign d = data_to_sram;
    assign a = a2;
    assign we_n = we2_n;
    assign dout2 = d;
    assign d = (we_n == 1'b0)? din2 : 8'hZZ;

endmodule
