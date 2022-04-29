`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 14:16:16 2014-02-06 by Miguel Angel Rodriguez Jodar
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


module zxuno (
  // Relojes
  input wire sysclk,
  input wire power_on_reset_n,

  // E/S
  output wire [2:0] r,
  output wire [2:0] g,
  output wire [2:0] b,
  output wire hsync,
  output wire vsync,
  output wire csync,
  output wire [1:0] monochrome_switcher,  
  inout wire clkps2,
  inout wire dataps2,
  input wire ear_ext,
  output wire audio_out_left,
  output wire audio_out_right,

  // MIDI
  output wire midi_out,
  input wire clkbd,
  input wire wsbd,
  input wire dabd,

  // UART
  output wire uart_tx,
  input wire uart_rx,
  output wire uart_rts,
  output wire uart_reset,

  // SRAM
  output wire [20:0] sram_addr,
  inout wire [7:0] sram_data,
  output wire sram_we_n,

  // Flash SPI
  output wire flash_cs_n,
  output wire flash_clk,
  output wire flash_di,
  input wire flash_do,

  // SD/MMC
  output wire sd_cs_n,
  output wire sd_clk,
  output wire sd_mosi,
  input wire sd_miso,

  // DB9 JOYSTICK
  input wire joy1up,
  input wire joy1down,
  input wire joy1left,
  input wire joy1right,
  input wire joy1fire1,
  input wire joy1fire2,

  // DB9 JOYSTICK 2
  input wire joy2up,
  input wire joy2down,
  input wire joy2left,
  input wire joy2right,
  input wire joy2fire1,
  input wire joy2fire2,

  // DB9 splitter selector
  output wire joy1fire3,

  // MOUSE
  inout wire mouseclk,
  inout wire mousedata,

  // SCANDOUBLER CTRL
  output wire clk14en_tovga,
  output wire vga_enable,
  output wire scanlines_enable,
  output wire [2:0] freq_option,

  // AD724
  output wire ad724_xtal,
  output wire ad724_mode,
  output wire ad724_enable_gencolorclk
  );

`include "..\common\config.vh"

  parameter FPGA_MODEL = 3'b000;
  parameter MASTERCLK  = 28000000;  
  
  wire wifi_switcher;
  wire joy_splitter;
  
  `ifdef UART_ESP8266_OPTION
  
  reg [22:0] uart_counter = 22'h3FFFFF;
  reg is_uart = 1'b0;
  //reg show_uart = 1'b0;
  reg [0:255] icon_uart = 		{16'b0000000000000000,
										 16'b0000000000000000,
										 16'b0000000000000000,
										 16'b0000000000000000,
										 16'b0000111111110000,
										 16'b0000000000000000,
										 16'b0000011111100000,
										 16'b0000000000000000,
										 16'b0000001111000000,
										 16'b0000000000000000,
										 16'b0000000110000000,
										 16'b0000000110000000, 
										 16'b0000000000000000,
										 16'b0000000000000000,
										 16'b0000000000000000,
										 16'b0000000000000000};

  reg [0:255] icon_no_uart =  {16'b0000011111100000,
										 16'b0000100000010000,
										 16'b0011000000001100,
										 16'b0010000000000100, 
										 16'b0100111111111110,
										 16'b1000000000110010,
										 16'b1000011111100001,
										 16'b1000000110000001,
										 16'b1000001111000001,
										 16'b1000011000000001,
										 16'b1000110110000010,
										 16'b0101100110000010,
										 16'b0011000000000100,
										 16'b0011000000001100,
										 16'b0000110000110000,
										 16'b0000001111000000};
  
  wire pinta_uart = (hcnt >= 249 && hcnt <= 264) && (vcnt >= end_count_v - 21 && vcnt <= end_count_v - 6);
  wire [2:0] ruart = pinta_uart ? wifi_switcher ? icon_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b000 : rula : icon_no_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b111 : rula : rula;
  wire [2:0] guart = pinta_uart ? wifi_switcher ? icon_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b111 : gula : icon_no_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b000 : gula : gula;
  wire [2:0] buart = pinta_uart ? wifi_switcher ? icon_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b000 : bula : icon_no_uart[((vcnt - end_count_v - 27) * 16) + (hcnt - 249)] ? 3'b000 : bula : bula; 
  
  `endif
  
  // Señales del generador de enables de reloj
  wire CPUContention;
  wire [3:0] cpu_speed;
  wire clkcpu_enable;
  wire clk14en, clk7en, clk7en_n, clk35en, clk35en_n, clk175en;
  assign clk14en_tovga = clk14en;

  // Señales de la CPU
  wire mreq_n,iorq_n,rd_n,wr_n,int_n,m1_n,nmi_n,rfsh_n,busak_n;
  wire enable_nmi_n;
  wire [15:0] cpuaddr;
  reg [7:0] cpudin;
  wire [7:0] cpudout;
  wire [7:0] ula_dout;

  // Señales acceso RAM por parte de la ULA
  wire [13:0] vram_addr;
  wire [7:0] vram_dout;

  // Señales acceso RAM por parte de la CPU
  wire [7:0] memory_dout;
  wire oe_romyram;

  // Señales de acceso del AY por parte de la CPU
  wire [7:0] ay_dout;
  wire bc1,bdir;
  wire oe_ay;

  // Señales de acceso a registro de direcciones ZX-Uno
  wire [7:0] zxuno_addr_to_cpu;  // al bus de datos de entrada del Z80
  wire [7:0] zxuno_addr;   // direccion de registro actual
  wire regaddr_changed;    // indica que se ha escrito un nuevo valor en el registro de direcciones
  wire oe_zxunoaddr;     // el dato en el bus de entrada del Z80 es válido
  wire zxuno_regrd;     // Acceso de lectura en el puerto de datos de ZX-Uno
  wire zxuno_regwr;     // Acceso de escritura en el puerto de datos del ZX-Uno
  wire in_boot_mode;   // Vale 1 cuando el sistema está en modo boot (ejecutando la BIOS)

  // Señales de acceso al módulo Flash SPI
  wire [ 7:0] spi_dout;
  wire        oe_spi;
  wire        wait_spi_n;

  // Fuentes de sonido y control del mixer
  wire        mic;
  wire        spk;
  wire [7:0] ay1_audio;
  wire [7:0] ay2_audio;
  wire [7:0] ay1_cha, ay1_chb, ay1_chc;
  wire [7:0] ay2_cha, ay2_chb, ay2_chc;
  wire [7:0] specdrum;
  wire [15:0] midi_left, midi_right;
  wire [7:0] mixer_dout;
  wire oe_mixer;
  wire [ 7:0] saa_out_l, saa_out_r;

  // Interfaz de acceso al teclado
  wire [4:0]  kbdcol;
  wire [7:0]  kbdrow = cpuaddr[15:8];                    // las filas del teclado son A8-A15 de la CPU;
  wire        mrst_n,rst_n;                              // los dos resets suministrados por el teclado
  wire [7:0]  scancode_dout;                             // scancode original desde el teclado PC
  wire        oe_scancode;
  wire [7:0]  keymap_dout;
  wire        oe_keymap;
  wire [7:0]  kbstatus_dout;
  wire        oe_kbstatus;

  wire [13:0] user_fnt;
  wire ff_pressed        = user_fnt[12];
  wire stop_pressed      = user_fnt[11];
  wire prevtrack_pressed = user_fnt[10];
  wire play_pressed      = user_fnt[9];
  wire f1_pressed        = user_fnt[8];
  wire f3_pressed        = user_fnt[7];
  wire f4_pressed        = user_fnt[6];
  wire f6_pressed        = user_fnt[5];   // Establecer marca de 'contador a 0'
  wire f7_pressed        = user_fnt[4];   // PLAY del PZX
  wire f8_pressed        = user_fnt[3];   // REWIND a la marca del 'contador a 0' puesta por usuario con F6
  wire f8_ctrl_pressed   = user_fnt[13];   // REWIND al principio del PZX, o a la última posición marcada en el fichero
  wire f9_pressed        = user_fnt[2];   // STOP del PZX
  wire f11_pressed       = user_fnt[1];   // WiFi
  wire f12_pressed       = user_fnt[0];   // Turbo-boost (28 MHz)

  // Interfaz joystick configurable
  wire oe_joystick;
  wire [5:0] kbd_joy;
  wire [7:0] joystick_dout;
  wire [4:0] kbdcol_to_ula;

  // Configuración ULA
  wire [1:0] timing_mode;
  wire issue2_keyboard;
  wire disable_contention;
  wire access_to_screen;
  wire doc_ext_option; // bit 7 del puerto $FF del Timex
  wire ioreqbank;

  // CoreID
  wire 	     oe_coreid;
  wire [7:0] coreid_dout;

  // Scratch register
  wire 	     oe_scratch;
  wire [7:0] scratch_dout;

  // AD724 control
  wire oe_ad724;
  wire [7:0] ad724_dout;

  // Memory report register
  wire oe_memrep;
  wire [7:0] memrep_dout;
  wire [1:0] total_memory;

  // Multiboot
  wire oe_multiboot;
  wire [7:0] multiboot_dout;

  // Scandoubler control
  wire csync_option;
  wire [7:0] scndblctrl_dout;
  wire oe_scndblctrl;
  wire speed_change_allowed;
  wire turbo_boost = ff_pressed | f12_pressed;
  wire video_output_change;

  // Raster INT control
  wire rasterint_enable;
  wire vretraceint_disable;
  wire [8:0] raster_line;
  wire raster_int_in_progress;
  wire [7:0] rasterint_dout;
  wire oe_rasterint;

  // Device enable options
  wire disable_ay;
  wire disable_turboay;
  wire disable_7ffd;
  wire disable_1ffd;
  wire disable_romsel7f;
  wire disable_romsel1f;
  wire enable_timexmmu;
  wire disable_spisd;
  wire disable_timexscr;
  wire disable_ulaplus;
  wire disable_radas;
  wire disable_specdrum;
  wire disable_mixer;
  wire [7:0] devoptions_dout;
  wire oe_devoptions;

  // NMI events
  wire [7:0] nmievents_dout;
  wire oe_nmievents;
  wire nmispecial_n;
  wire page_configrom_active;

  // Kempston mouse
  wire [7:0] kmouse_dout;
  wire [7:0] mousedata_dout;
  wire [7:0] mousestatus_dout;
  wire oe_kmouse, oe_mousedata, oe_mousestatus;

  // DMA device interface
  wire [7:0] dma_dout;
  wire oe_dma;

  // UART
  wire [7:0] uart_dout;
  wire oe_uart;

  // Disk drive
  wire [7:0] diskdrive_dout;
  wire oe_diskdrive;

  // Lector PZX
  wire [20:0] pzx_addr;
  wire [7:0] pzx_dout;
  wire oe_pzx;
  wire enable_pzx;
  wire pzx_playing;
  wire pzx_output;
  wire in48kmode;
  wire play = play_pressed | f7_pressed;
  wire stop = stop_pressed | f9_pressed;
  wire rewindTo0Counter = f8_pressed;
  wire resetTo0Counter = f6_pressed;
  wire jump = prevtrack_pressed | f8_ctrl_pressed;
  wire [7:0] data_from_pzx;
  wire [7:0] data_to_pzx;
  wire write_data_pzx;
  wire ear = (pzx_playing == 1'b1)? pzx_output : ear_ext;

  // Inyección de 0xFF directo al bus de datos cuando hay un acuse de recibo de interrupción
  wire oe_intack = (iorq_n == 1'b0 && m1_n == 1'b0);

  // Salidas de video de la ULA
  wire [2:0] rula,gula,bula;
  wire [8:0] hcnt, vcnt;
  wire [8:0] end_count_v;

  // Señales a conectar valores de depuracion
  wire [15:0] v16_a, v16_b, v16_c, v16_d, v16_e, v16_f, v16_g, v16_h;
  wire [7:0] v8_a, v8_b, v8_c, v8_d, v8_e, v8_f, v8_g, v8_h;

  // Asignación de dato para la CPU segun la decodificación de todos los dispositivos
  // conectados a ella.
  always @* begin
    case (1'b1)
      oe_intack      : cpudin = 8'hFF;  // valor del bus de datos durante una interrupción enmascarable aceptada
      oe_zxunoaddr   : cpudin = zxuno_addr_to_cpu;
      oe_spi         : cpudin = spi_dout;
      oe_scancode    : cpudin = scancode_dout;
      oe_kbstatus    : cpudin = kbstatus_dout;
      oe_coreid      : cpudin = coreid_dout;
      oe_keymap      : cpudin = keymap_dout;
      oe_scratch     : cpudin = scratch_dout;
      oe_scndblctrl  : cpudin = scndblctrl_dout;
      oe_nmievents   : cpudin = nmievents_dout;
      oe_kmouse      : cpudin = kmouse_dout;
      oe_mousedata   : cpudin = mousedata_dout;
      oe_mousestatus : cpudin = mousestatus_dout;
      oe_rasterint   : cpudin = rasterint_dout;
      oe_devoptions  : cpudin = devoptions_dout;
      oe_romyram     : cpudin = memory_dout;
      oe_multiboot   : cpudin = multiboot_dout;
      oe_mixer       : cpudin = mixer_dout;
      oe_dma         : cpudin = dma_dout;
      oe_ad724       : cpudin = ad724_dout;
      oe_diskdrive   : cpudin = diskdrive_dout;
      oe_pzx         : cpudin = pzx_dout;
      oe_memrep      : cpudin = memrep_dout;
      oe_uart        : cpudin = uart_dout;
      oe_ay          : cpudin = ay_dout;
      oe_joystick    : cpudin = joystick_dout;
      default        : cpudin = ula_dout;  // must always be the last "default" option.
    endcase
  end

  clk_enables enables_de_todos_los_relojes (
    .clk                (sysclk         ),
    .CPUContention      (CPUContention  ),
    .cpu_speed          (cpu_speed      ),
    .clk14en            (clk14en        ),
    .clk7en             (clk7en         ),
    .clk7en_n           (clk7en_n       ),
    .clk35en            (clk35en        ),
    .clk35en_n          (clk35en_n      ),
    .clk175en           (clk175en       ),
    .clkcpu_enable      (clkcpu_enable  ));

  cpu_and_dma el_z80_con_su_dma (
    .m1_n               (m1_n           ),
    .mreq_n             (mreq_n         ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .rfsh_n             (rfsh_n         ),
    .halt_n             (               ),
    .busak_salida_n     (busak_n        ),
    .A                  (cpuaddr        ),
    .dout               (cpudout        ),

    .reset_n            (rst_n & mrst_n & power_on_reset_n),  // cualquiera de los tres resets
    .clk                (sysclk         ),
    .clkcpuen           (clkcpu_enable & wait_spi_n),
    .wait_n             (1'b1           ),
    .int_n              (int_n          ),
    .nmi_n              ((nmi_n | enable_nmi_n)                 /*& nmispecial_n*/),
    .di                 (cpudin         ),

    .zxuno_addr         (zxuno_addr     ),
    .regaddr_changed    (regaddr_changed),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .dmadevicedin       (cpudout        ),
    .dmadevicedout      (dma_dout       ),
    .oe                 (oe_dma         ));

  ula_radas la_ula (
     // Clocks
    .sysclk             (sysclk         ),
    .clk14en            (clk14en        ),
    .clk7en             (clk7en         ),
    .clk7en_n           (clk7en_n       ),
    .clk35en            (clk35en        ),
    .clk35en_n          (clk35en_n      ),
    .CPUContention      (CPUContention  ),
    .rst_n              (mrst_n & rst_n & power_on_reset_n),

    // CPU interface
    .a                  (cpuaddr        ),
    .access_to_contmem  (access_to_screen),
    .mreq_n             (mreq_n         ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .rfsh_n             (rfsh_n         ),
    .int_n              (int_n          ),
    .din                (cpudout        ),
    .dout               (ula_dout       ),
    .rasterint_enable   (rasterint_enable),
    .vretraceint_disable(vretraceint_disable),
    .raster_line        (raster_line    ),
    .raster_int_in_progress(raster_int_in_progress),

// VRAM interface
    .va                 (vram_addr      ),                      // 16KB videoram, 2 pages
    .vramdata           (vram_dout      ),
// ZX-UNO register interface
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .regaddr_changed    (regaddr_changed),

// I/O ports
    .ear                (ear            ),
    .mic                (mic            ),
    .spk                (spk            ),
    .kbd                (kbdcol_to_ula  ),
    .issue2_keyboard    (issue2_keyboard),
    .mode               (timing_mode    ),
    .ioreqbank          (ioreqbank      ),
    .disable_contention (disable_contention),
    .doc_ext_option     (doc_ext_option ),
    .enable_timexmmu    (enable_timexmmu),
    .disable_timexscr   (disable_timexscr),
    .disable_ulaplus    (disable_ulaplus),
    .disable_radas      (disable_radas  ),
    .csync_option       (csync_option   ),

  // Debug
//     .button_up(f4_pressed),
//     .button_down(f3_pressed),
//     .posint(v8_a),

  // Video
    .r                  (rula           ),
    .g                  (gula           ),
    .b                  (bula           ),
    .hcnt               (hcnt           ),
    .vcnt               (vcnt           ),
    .hsync              (hsync          ),
    .vsync              (vsync          ),
    .csync              (csync          ),
    .end_count_v			(end_count_v	 ));

  zxunoregs addr_reg_zxuno (
    .clk(sysclk),

    .rst_n(rst_n & mrst_n & power_on_reset_n),
    .a                  (cpuaddr        ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .din                (cpudout        ),
    .dout               (zxuno_addr_to_cpu),
    .oe                 (oe_zxunoaddr   ),
    .addr               (zxuno_addr     ),
    .read_from_reg      (zxuno_regrd    ),
    .write_to_reg       (zxuno_regwr    ),
    .regaddr_changed    (regaddr_changed));

  flash_and_sd cacharros_con_spi (
    .clk                (sysclk         ),
    .a                  (cpuaddr        ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .addr               (zxuno_addr     ),
    .ior                (zxuno_regrd    ),
    .iow                (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (spi_dout       ),
    .oe                 (oe_spi         ),
    .wait_n             (wait_spi_n     ),

    .in_boot_mode       (in_boot_mode   ),
    .flash_cs_n         (flash_cs_n     ),
    .flash_clk          (flash_clk      ),
    .flash_di           (flash_di       ),
    .flash_do           (flash_do       ),
    .disable_spisd      (disable_spisd  ),
    .sd_cs_n            (sd_cs_n        ),
    .sd_clk             (sd_clk         ),
    .sd_mosi            (sd_mosi        ),
    .sd_miso            (sd_miso        ));

  new_memory bootrom_rom_y_ram (
  // Relojes y reset
    .clk(sysclk),   // Reloj para registros de configuración
    .mrst_n(mrst_n & power_on_reset_n),
    .rst_n(rst_n & power_on_reset_n),

// Interface con la CPU
    .a                  (cpuaddr        ),
    .din                (cpudout        ),                      // proveniente del bus de datos de salida de la CPU
    .dout               (memory_dout    ),                      // hacia el bus de datos de entrada de la CPU
    .oe                 (oe_romyram     ),                      // el dato es valido
    .mreq_n             (mreq_n         ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .m1_n               (m1_n           ),                      // Necesarios para implementar DIVMMC
    .rfsh_n             (rfsh_n         ),
    .busak_n            (busak_n        ),
    .enable_nmi_n       (enable_nmi_n   ),
    .page_configrom_active(page_configrom_active),              // Para habilitar la ROM de ayuda y configuración

// Interface con la ULA
    .vramaddr           (vram_addr      ),
    .vramdout           (vram_dout      ),
    .doc_ext_option     (doc_ext_option ),
    .issue2_keyboard_enabled(issue2_keyboard),
    .timing_mode        (timing_mode    ),
    .disable_contention (disable_contention),
    .access_to_screen   (access_to_screen),
    .ioreqbank          (ioreqbank      ),

// Interface con el bus externo (TO-DO)
    .inhibit_rom        (1'b0           ),
    .din_external       (8'h00          ),

// Interface para registros ZXUNO
    .addr               (zxuno_addr     ),
    .ior                (zxuno_regrd    ),
    .iow                (zxuno_regwr    ),
    .in_boot_mode       (in_boot_mode   ),

// Interface con modulo de habilitacion de opciones
    .disable_7ffd       (disable_7ffd   ),
    .disable_1ffd       (disable_1ffd   ),
    .disable_romsel7f   (disable_romsel7f),
    .disable_romsel1f   (disable_romsel1f),
    .enable_timexmmu (enable_timexmmu   ),

// Interface con el lector PZX
    .pzx_addr           (pzx_addr       ),
    .enable_pzx         (enable_pzx     ),
    .in48kmode          (in48kmode      ),
    .data_from_pzx      (data_from_pzx  ),
    .data_to_pzx        (data_to_pzx    ),
    .write_data_pzx     (write_data_pzx ),

// Interface con la SRAM
    .sram_addr          (sram_addr      ),
    .sram_data          (sram_data      ),
    .sram_we_n          (sram_we_n      ));

  ps2_keyb el_teclado (
    .clk                (sysclk         ),
    .clkps2             (clkps2         ),
    .dataps2            (dataps2        ),
    .rows               (kbdrow         ),
    .cols               (kbdcol         ),
    .joy                (kbd_joy        ),                      // Implementación joystick en teclado numerico
    .rst_out_n          (rst_n          ),                      // esto son salidas, no entradas
    .nmi_out_n          (nmi_n          ),                      // Señales de reset y NMI
    .mrst_out_n         (mrst_n         ),                      // generadas por pulsaciones especiales del teclado
    .user_fnt           (user_fnt       ),                      // funciones de usuario
    .video_output_change(video_output_change),
  //----------------------------
    .zxuno_addr(zxuno_addr),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .regaddr_changed    (regaddr_changed),
    .din                (cpudout        ),
    .keymap_dout        (keymap_dout    ),
    .oe_keymap          (oe_keymap      ),
    .scancode_dout      (scancode_dout  ),
    .oe_scancode        (oe_scancode    ),
    .kbstatus_dout      (kbstatus_dout  ),
    .oe_kbstatus        (oe_kbstatus    ),
    .monochrome_switcher(monochrome_switcher));

  joystick_protocols los_joysticks (
    .clk                (sysclk         ),
  //-- cpu interface
    .a                  (cpuaddr        ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .din                (cpudout        ),
    .dout               (joystick_dout  ),
    .oe                 (oe_joystick    ),
  //-- interface with ZXUNO reg bank
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
  //-- actual joystick and keyboard signals
    .kbdjoy_in          (kbd_joy        ),
    .db9joy1_in({joy1fire2, joy1fire1, joy1up, joy1down, joy1left, joy1right}),
	.db9joy2_in({joy2fire2, joy2fire1, joy2up, joy2down, joy2left, joy2right}),
	.joy1fire3(joy1fire3),
    .kbdcol_in(kbdcol),
    .kbdcol_out(kbdcol_to_ula),
    .vertical_retrace_int_n(int_n), // this is used as base clock for autofire
	 .joy_splitter(joy_splitter)
  );

  coreid identificacion_del_core (
    .clk(sysclk),
    .rst_n(rst_n & mrst_n & power_on_reset_n),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .regaddr_changed    (regaddr_changed),
    .dout               (coreid_dout    ),
    .oe                 (oe_coreid      ));

`ifdef SCRATCH_REGISTER_OPTION
    scratch_register scratch (
    .clk                (sysclk         ),
    .poweron_rst_n      (power_on_reset_n),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (scratch_dout   ),
    .oe                 (oe_scratch     ));
`endif

`ifdef AD724_CONTROL_SUPPORT
  control_ad724 ad724 (
    .clk(sysclk),
    .poweron_rst_n(power_on_reset_n),
    .zxuno_addr(zxuno_addr),
    .zxuno_regrd(zxuno_regrd),
    .zxuno_regwr(zxuno_regwr),
    .din(cpudout),
    .dout(ad724_dout),
    .oe(oe_ad724),
    .ad724_xtal(ad724_xtal),
    .ad724_mode(ad724_mode),
    .ad724_enable_gencolorclk(ad724_enable_gencolorclk)
  );
`else
  assign ad724_xtal = 1'b1;
  assign ad724_mode = 1'b0;
  assign ad724_enable_gencolorclk = 1'b0;
`endif


  control_enable_options device_enables (
    .clk                (sysclk),

    .rst_n              (mrst_n & power_on_reset_n),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (devoptions_dout),
    .oe                 (oe_devoptions  ),
    .disable_ay         (disable_ay     ),
    .disable_turboay    (disable_turboay),
    .disable_7ffd       (disable_7ffd   ),
    .disable_1ffd       (disable_1ffd   ),
    .disable_romsel7f   (disable_romsel7f),
    .disable_romsel1f   (disable_romsel1f),
    .enable_timexmmu    (enable_timexmmu),
    .disable_spisd      (disable_spisd  ),
    .disable_timexscr   (disable_timexscr),
    .disable_ulaplus    (disable_ulaplus),
    .disable_radas      (disable_radas  ),
    .disable_specdrum   (disable_specdrum),
    .disable_mixer      (disable_mixer  ),
	 .joy_splitter       (joy_splitter  ));


  scandoubler_ctrl control_scandoubler (
    .clk                (sysclk         ),
    .a                  (cpuaddr        ),
    .kbd_change_video_output(video_output_change),	// In
    .kbd_turbo_boost    (turbo_boost    ),		// In
    .turbo_boost_allowed(speed_change_allowed),		// In
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (scndblctrl_dout),
    .oe                 (oe_scndblctrl  ),
    .vga_enable         (vga_enable     ),
    .scanlines_enable   (scanlines_enable),
    .freq_option        (freq_option    ),		// Out
    .cpu_speed          (cpu_speed      ),		// Out
    .csync_option       (csync_option   ));


`ifdef RASTER_INTERRUPT_SUPPORT
  rasterint_ctrl control_rasterint (
    .clk                (sysclk),

    .rst_n              (rst_n & mrst_n & power_on_reset_n),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (rasterint_dout ),
    .oe                 (oe_rasterint   ),
    .rasterint_enable   (rasterint_enable),
    .vretraceint_disable(vretraceint_disable),
    .raster_line        (raster_line    ),
    .raster_int_in_progress(raster_int_in_progress));
`endif

  // DESHABILITADO!!!!!!!!!!!!!!!!!!!!!!!!!
//    nmievents nmi_especial_de_antonio (
//        .clk(sysclk),
//        .rst_n(rst_n & mrst_n & power_on_reset_n),
//        //------------------------------
//        .zxuno_addr(zxuno_addr),
//        .zxuno_regrd(zxuno_regrd),
//        //------------------------------
//        .userevents(user_fnt),
//        //------------------------------
//        .a(cpuaddr),
//        .m1_n(m1_n),
//        .mreq_n(mreq_n),
//        .rd_n(rd_n),
//        .dout(nmievents_dout),
//        .oe(oe_nmievents),
//        .nmiout_n(nmispecial_n),
//        .page_configrom_active(page_configrom_active)
//    );

  ps2_mouse_kempston el_raton (
    .clk(sysclk),
    .rst_n(rst_n & mrst_n & power_on_reset_n),

    .clkps2             (mouseclk       ),
    .dataps2            (mousedata      ),
  //---------------------------------
    .a                  (cpuaddr        ),
    .iorq_n             (iorq_n         ),
    .rd_n               (rd_n           ),
    .kmouse_dout        (kmouse_dout    ),
    .oe_kmouse          (oe_kmouse      ),
  //---------------------------------
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .mousedata_dout     (mousedata_dout ),
    .oe_mousedata       (oe_mousedata   ),
    .mousestatus_dout   (mousestatus_dout),
    .oe_mousestatus     (oe_mousestatus ));


`ifdef MULTIBOOT_SUPPORT
  multiboot el_multiboot (
    .clk                (sysclk),

    .rst_n              (rst_n & mrst_n & power_on_reset_n),
    .zxuno_addr         (zxuno_addr     ),
    .regaddr_changed    (regaddr_changed),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (multiboot_dout ),
    .oe                 (oe_multiboot   ));

`endif

`ifdef SPECDRUM_COVOX_SUPPORT
  specdrum the_specdrum (
    .clk                (sysclk),

    .rst_n              (rst_n & mrst_n & power_on_reset_n),
    .a                  (cpuaddr        ),
    .iorq_n             (iorq_n | disable_specdrum),
    .wr_n               (wr_n           ),
    .d                  (cpudout        ),
    .specdrum_out       (specdrum       ));

`endif

  disk_drive el_disco (
    .clk(sysclk),
    .rst_n(rst_n & mrst_n & power_on_reset_n),
    .a(cpuaddr),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .din(cpudout),
    .dout(diskdrive_dout),
    .oe(oe_diskdrive)
  );

`ifdef PZX_PLAYER_OPTION
  pzx_player cassette_digital (
    .clk(sysclk),
    .sram_access_allowed(enable_pzx),
    .rst_n(power_on_reset_n & mrst_n & rst_n),
  //--------------------
    .zxuno_addr(zxuno_addr),
    .zxuno_regrd(zxuno_regrd),
    .zxuno_regwr(zxuno_regwr),
    .din(cpudout),
    .dout(pzx_dout),
    .oe(oe_pzx),
  //--------------------
    .in48kmode(in48kmode),
    .cpu_speed(cpu_speed),
    .memory_register(total_memory),
    .play_in(play),
    .stop_in(stop),
    .rewindTo0Counter_in(rewindTo0Counter),
    .resetTo0Counter_in(resetTo0Counter),
    .jump_in(jump),
    .pulse_out(pzx_output),
    .playing(pzx_playing),
    .speed_change_allowed(speed_change_allowed),
  // -------------------
    .sramaddr(pzx_addr),
    .sramwe(write_data_pzx),
    .sramdin(data_to_pzx),
    .sramdout(data_from_pzx)
  );
`endif

  board_capabilities capreg (
    .clk(sysclk),
    .poweron_rst_n(power_on_reset_n),
    .in_boot_mode(in_boot_mode),
    .zxuno_addr(zxuno_addr),
    .zxuno_regrd(zxuno_regrd),
    .zxuno_regwr(zxuno_regwr),
    .fpga_model(FPGA_MODEL),
    .din(cpudout),
    .dout(memrep_dout),
    .oe(oe_memrep),
    .current_value(total_memory)
  );

///////////////////////////////////
// AY-3-8912 SOUND
///////////////////////////////////
  // BDIR BC2 BC1 MODE
  //   0   1   0  inactive
  //   0   1   1  read
  //   1   1   0  write
  //   1   1   1  address

  assign bdir = (cpuaddr[15] && cpuaddr[1:0]==2'b01 && !iorq_n && !wr_n)? 1'b1 : 1'b0;
  assign bc1 = (cpuaddr[15] && cpuaddr[1:0]==2'b01 && cpuaddr[14] && !iorq_n)? 1'b1 : 1'b0;

  turbosound dos_ays (
    .clk(sysclk),
    .clk35en(clk35en),
    .clk175en(clk175en),
    .disable_ay(disable_ay),
    .disable_turboay(disable_turboay),
    .reset_n(rst_n & mrst_n & power_on_reset_n),
    .bdir(bdir),
    .bc1(bc1),
    .din(cpudout),
    .dout(ay_dout),
    .oe(oe_ay),
    .midi_out(midi_out),
    .audio_out_ay1(ay1_audio),
    .audio_out_ay2(ay2_audio),
    .audio_out_ay1_splitted({ay1_cha, ay1_chb, ay1_chc}),
    .audio_out_ay2_splitted({ay2_cha, ay2_chb, ay2_chc})
	 );
///////////////////////////////////
// SOUND SAA1099
///////////////////////////////////
`ifdef SAA1099
    saa1099s el_saa (
    .clk_sys            (sysclk         ),               // 8 MHz
    .ce                 (clk7en         ),               // 8 MHz
    .rst_n              (rst_n & mrst_n & power_on_reset_n),
    .cs_n               ((cpuaddr[7:0] != 255) | iorq_n),
    .a0                 (cpuaddr[8]     ),               // 0=data, 1=address
    .wr_n               (wr_n           ),
    .din                (cpudout        ),
    .out_l              (saa_out_l      ),
    .out_r              (saa_out_r      ));
`endif

///////////////////////////////////
// SOUND MIXERS
///////////////////////////////////

  // 9-bit mixer to generate different audio levels according to input sources
   panner_and_mixer audio_mix (
    .clk                (sysclk         ),
    .mrst_n             (mrst_n         ),
    .a                  (cpuaddr[7:0]   ),
    .iorq_n             (iorq_n | disable_mixer),
    .rd_n               (rd_n           ),
    .wr_n               (wr_n           ),
    .din                (cpudout        ),
    .dout               (mixer_dout     ),
    .oe                 (oe_mixer       ),
  // Audio sources to mix
    .mic                (mic            ),
    .spk                (spk            ),
    .ear                (ear            ),
    .ay1_cha            (ay1_cha        ),
    .ay1_chb            (ay1_chb        ),
    .ay1_chc            (ay1_chc        ),
    .ay2_cha            (ay2_cha        ),
    .ay2_chb            (ay2_chb        ),
    .ay2_chc            (ay2_chc        ),
    .specdrum           (specdrum       ),
    .midi_left          (midi_left      ),
    .midi_right         (midi_right     ),
    .saa_left           (saa_out_l      ),
    .saa_right          (saa_out_r      ),

// PWM output mixed
    .output_left        (audio_out_left ),
    .output_right       (audio_out_right));


`ifdef MIDI_SYNTH_OPTION
  i2s_decoder i2s_midi (
    .clk(sysclk),
    .sck(clkbd),
    .ws(wsbd),
    .sd(dabd),
    .left_out(midi_left),
    .right_out(midi_right)
  );
`endif

`ifdef UART_ESP8266_OPTION
  // UART para el ESP8266

	`ifdef F11_ESP8266_FEATURE
		assign wifi_switcher = f11_pressed;
		assign uart_reset = (!wifi_switcher && uart_counter == 23'd0) ? 1'b0 : 1'bz;
	`else
		assign wifi_switcher = 1'b1;
		assign uart_reset = 1'bz;
	`endif

  zxunouart #(.CLK(MASTERCLK)) uart_esp8266 (
    .clk                (sysclk         ),
    .zxuno_addr         (zxuno_addr     ),
    .zxuno_regrd        (zxuno_regrd    ),
    .zxuno_regwr        (zxuno_regwr    ),
    .din                (cpudout        ),
    .dout               (uart_dout      ),
    .oe                 (oe_uart        ),
    .uart_tx            (uart_tx        ),
    .uart_rx            (uart_rx        ),
    .uart_rts           (uart_rts       ));
	 
always @(posedge sysclk) begin
	if (~is_uart && uart_counter != 23'd0) begin
		uart_counter = uart_counter - 22'd1;
		if (~uart_rx)
			is_uart <= 1'b1;
	end
	if (is_uart) begin
		if (~uart_rx || ~uart_tx)
			uart_counter = 22'h3FFFFF;			
		else if (uart_counter != 23'd0)
			uart_counter = uart_counter - 22'd1;
	end
end

assign r = pinta_uart && (uart_counter != 23'd0) ? ruart : rula;
assign g = pinta_uart && (uart_counter != 23'd0) ? guart : gula;
assign b = pinta_uart && (uart_counter != 23'd0) ? buart : bula;
	 
`else
  assign uart_tx = 1'b0;
  assign uart_rts = 1'b0;
  assign uart_reset = 1'b0;
`endif

  // Modulo de depuracion
//  debug visor_valores_en_pantalla (
//    .clk(sysclk),
//    .visible(1'b1),
//    .hc(hcnt),
//    .vc(vcnt),
//    .ri(rula),
//    .gi(gula),
//    .bi(bula),
//    .ro(r),
//    .go(g),
//    .bo(b),
//    //////////////////////////
//    .v16_a(v16_a),
//    .v16_b(v16_b),
//    .v16_c(v16_c),
//    .v16_d(v16_d),
//    .v16_e(v16_e),
//    .v16_f(v16_f),
//    .v16_g(v16_g),
//    .v16_h(v16_h),
//    .v8_a(v8_a),
//    .v8_b(v8_b),
//    .v8_c(v8_c),
//    .v8_d(v8_d),
//    .v8_e(v8_e),
//    .v8_f(v8_f),
//    .v8_g(v8_g),
//    .v8_h(v8_h)
//    );


endmodule
