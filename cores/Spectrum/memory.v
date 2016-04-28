`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:07:14 03/03/2014 
// Design Name: 
// Module Name:    memory 
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
module memory (
   // Relojes y reset
   input wire clk,        // Reloj del sistema CLK7
   input wire mclk,       // Reloj para el modulo de memoria de doble puerto
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
   output wire issue2_keyboard_enabled,
   output reg [1:0] timing_mode,
   output wire disable_contention,
   output reg access_to_screen,

   // Interface para registros ZXUNO
   input wire [7:0] addr,
   input wire ior,
   input wire iow,
   output wire in_boot_mode,

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
    
`define ADDR_7FFD (a[0] && !a[1] && a[14] && !a[15])
`define ADDR_1FFD (a[0] && !a[1] && a[12] && a[15:13]==3'b000)

`define PAGE0 3'b000
`define PAGE1 3'b001
`define PAGE2 3'b010
`define PAGE3 3'b011
`define PAGE4 3'b100
`define PAGE5 3'b101
`define PAGE6 3'b110
`define PAGE7 3'b111

   reg [7:0] bank128 = 8'h00;
   reg [7:0] bankplus3 = 8'h00;
   wire puerto_bloqueado = bank128[5];
   wire [2:0] banco_ram = bank128[2:0];
   wire vrampage = bank128[3];
   wire [1:0] banco_rom = {bankplus3[2],bank128[4]};
   wire amstrad_allram_page_mode = bankplus3[0];
   wire [1:0] plus3_memory_arrangement = bankplus3[2:1];
   
   always @(posedge clk) begin
      if (!mrst_n || !rst_n) begin
         bank128 <= 8'h00;
         bankplus3 <= 8'h00;
      end
      else if (!iorq_n && !wr_n && `ADDR_7FFD && !puerto_bloqueado)
         bank128 <= din;
      else if (!iorq_n && !wr_n && `ADDR_1FFD && !puerto_bloqueado)
         bankplus3 <= din;
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
      
      if (!mreq_n && a[15:14]==2'b00) begin   // la CPU quiere acceder al espacio de ROM, $0000-$3FFF
         if (initial_boot_mode) begin   // en el modo boot, sólo se accede a la ROM interna
            oe_memory_n = 1'b1;
            oe_bootrom_n = 1'b0;
            we2_n = 1'b1;
         end
         else begin  // estamos en modo normal de ejecución

            if (divmmc_is_enabled && (divmmc_is_paged || conmem)) begin  // DivMMC ha entrado en modo automapper o está mapeado a la fuerza
               if (a[13]==1'b0) begin // Si estamos en los primeros 8K
                  if (conmem || !mapram_mode) begin
                     addr_port2 = {6'b011000,a[12:0]};
                     we2_n = 1'b1;  // en este modo, la ROM es intocable
                  end
                  else begin  // mapram mode
                     addr_port2 = {2'b10,4'b0011,a[12:0]};  // pagina 3 de la SRAM del DIVMMC
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
                    
            else if (!amstrad_allram_page_mode) begin   // en el modo normal de paginación, hay 4 bancos de ROMs
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
         end
      end
      
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
      end
      
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
      end

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
      end
      
      else begin
         oe_memory_n = 1'b1;
         oe_bootrom_n = 1'b1;
      end
   end

   // Hay contienda en las páginas 5 y 7 de memoria, que son las dos páginas de pantalla
   always @* begin
     access_to_screen = 1'b0;
     if (!initial_boot_mode) begin
        if (!amstrad_allram_page_mode) begin
           if (a[15:14]==2'b01 || (a[15:14]==2'b11 && (banco_ram==3'd5 || banco_ram==3'd7))) begin
               access_to_screen = 1'b1;
           end
        end
     end
   end

   // Conexiones internas
   wire [7:0] bootrom_dout;
   wire [7:0] ram_dout;

   dp_memory dos_memorias (  // Controlador de memoria, que convierte a la SRAM en una memoria de doble puerto
      .clk(mclk),
      .a1({3'b001,vrampage,1'b1,vramaddr}),
      .a2(addr_port2),
      .oe1_n(1'b0),
      .oe2_n(1'b0),
      .we1_n(1'b1),
      .we2_n(we2_n),
      .din1(8'h00),
      .dout1(vramdout),
      .din2(din),
      .dout2(ram_dout),
      
      .a(sram_addr),  // Interface con la SRAM real
      .d(sram_data),
      .ce_n(),        // Estos pines ya están a GND en el esquemático
      .oe_n(),        // así que no los conecto.
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
      else if (!oe_memory_n) begin
         dout = ram_dout;
         oe_n = 1'b0;
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
         dout = 8'hFF;
         oe_n = 1'b1;
      end
   end

endmodule
