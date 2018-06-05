-- Port to ZX-UNO and modifications by Quest 2016
-- A simulation model of VIC20 hardware
-- Copyright (c) MikeJ - March 2003
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email vic20@fpgaarcade.com
--
--
-- Revision list
--
-- version 002 spartan3e release
-- version 001 initial release

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity VIC20 is
  port (
    --
    I_PS2_CLK             : in    std_logic;
    I_PS2_DATA            : in    std_logic;
    --
    O_VIDEO_R             : inout   std_logic_vector(2 downto 0);
    O_VIDEO_G             : inout   std_logic_vector(2 downto 0);
    O_VIDEO_B             : inout   std_logic_vector(2 downto 0);
    O_HSYNC               : inout   std_logic;
    O_VSYNC               : inout   std_logic;
    --
    D_VIDEO_R             : out   std_logic_vector(2 downto 0);
    D_VIDEO_G             : out   std_logic_vector(2 downto 0);
    D_VIDEO_B             : out   std_logic_vector(2 downto 0);
    D_HSYNC               : out   std_logic;
    D_VSYNC               : out   std_logic;
    --
    O_AUDIO_L             : out   std_logic;
    O_AUDIO_R             : out   std_logic;
	 
    O_NTSC            	  : out   std_logic;
    O_PAL             	  : out   std_logic;	 
    --
    I_SW                  : in    std_logic_vector(4 downto 0);
    LED                   : out std_logic;
    EAR                   : in std_logic;
    --
    I_CLK_REF             : in    std_logic

    );
end;

architecture RTL of VIC20 is
    -- default
    constant K_OFFSET : std_logic_vector (4 downto 0) := "10000"; -- h position of screen to centre on your telly
    -- lunar lander is WAY off to the left

 -- 1 = enable cartridge
	 constant Cartridge : std_logic := '1';	 

    signal I_RESET_L          : std_logic;
    signal clk_8              : std_logic;
    signal clk_ref            : std_logic;
    signal ena_4              : std_logic;
    signal reset_l_sampled    : std_logic;
    -- cpu
    signal c_ena              : std_logic;
    signal c_din              : std_logic_vector(7 downto 0);
	 
    signal c_addr             : unsigned(15 downto 0);
    signal c_dout             : unsigned(7 downto 0);
	 
    signal c_addrT             : std_logic_vector(23 downto 0); --T65
    signal c_doutT             : std_logic_vector(7 downto 0);	 -- T65
	 	 
    signal c_rw_l             : std_logic;
    signal c_irq_l            : std_logic;
    signal c_nmi_l            : std_logic;
    --
    signal io_sel_l           : std_logic_vector(3 downto 0);
    signal blk_sel_l          : std_logic_vector(7 downto 0);
    signal ram_sel_l          : std_logic_vector(7 downto 0);

    -- vic
    signal vic_addr           : std_logic_vector(13 downto 0);
    signal vic_oe_l           : std_logic;
    signal vic_dout           : std_logic_vector( 7 downto 0);
    signal vic_din            : std_logic_vector(11 downto 0);
    signal p2_h               : std_logic;
    signal ena_1mhz           : std_logic;
    signal vic_audio          : std_logic_vector( 3 downto 0);
    signal audio_pwm          : std_logic;
    signal via1_dout          : std_logic_vector( 7 downto 0);
    signal via2_dout          : std_logic_vector( 7 downto 0);
    -- video system
    signal v_addr             : std_logic_vector(13 downto 0);
    signal v_data             : std_logic_vector( 7 downto 0);
    signal v_data_oe_l        : std_logic;
    signal v_data_read_mux    : std_logic_vector( 7 downto 0);
    signal v_data_read_muxr   : std_logic_vector( 7 downto 0);
    signal v_rw_l             : std_logic;
    signal col_ram_sel_l      : std_logic;

    -- ram
    signal ram0_dout          : std_logic_vector(7 downto 0);
    signal ram45_dout         : std_logic_vector(7 downto 0);
    signal ram67_dout         : std_logic_vector(7 downto 0);
    --
    signal col_ram_dout       : std_logic_vector(7 downto 0);

    signal char_rom_dout      : std_logic_vector(7 downto 0);
    signal basic_rom_dout     : std_logic_vector(7 downto 0);
    signal kernal_rom_dout    : std_logic_vector(7 downto 0);

    signal ext_rom_din        : std_logic_vector(7 downto 0);
    signal expansion_din      : std_logic_vector(7 downto 0);
    signal expansion_nmi_l    : std_logic;
    signal expansion_irq_l    : std_logic;

    signal blk1_dout: std_logic_vector(7 downto 0);
    signal blk2_dout: std_logic_vector(7 downto 0);
    signal blk3_dout: std_logic_vector(7 downto 0);

    -- VIAs
    signal via1_nmi_l         : std_logic;
    signal via1_pa_in         : std_logic_vector(7 downto 0);
    signal via1_pa_out        : std_logic_vector(7 downto 0);

    signal via2_irq_l         : std_logic;

    signal cass_write         : std_logic;
    signal cass_read          : std_logic;
    signal cass_motor         : std_logic;
    signal cass_sw            : std_logic;
	 signal cass_n					: std_logic;

    signal keybd_col_out      : std_logic_vector(7 downto 0);
    signal keybd_col_in       : std_logic_vector(7 downto 0);
    signal keybd_col_oe_l     : std_logic_vector(7 downto 0);
    signal keybd_row_in       : std_logic_vector(7 downto 0);
    signal keybd_restore      : std_logic;

    signal joy                : std_logic_vector(3 downto 0);
    signal light_pen          : std_logic;

    signal serial_srq_in      : std_logic;
    signal serial_atn_out_l   : std_logic; -- the vic does not listen to atn_in
    signal serial_clk_out_l   : std_logic;
    signal serial_clk_in      : std_logic;
    signal serial_data_out_l  : std_logic;
    signal serial_data_in     : std_logic;

    -- user port
    signal user_port_cb1_in   : std_logic;
    signal user_port_cb1_out  : std_logic;
    signal user_port_cb1_oe_l : std_logic;
    signal user_port_cb2_in   : std_logic;
    signal user_port_cb2_out  : std_logic;
    signal user_port_cb2_oe_l : std_logic;
    signal user_port_in       : std_logic_vector(7 downto 0);
    signal user_port_out      : std_logic_vector(7 downto 0);
    signal user_port_oe_l     : std_logic_vector(7 downto 0);
    -- misc
    signal sw_reg             : std_logic_vector(3 downto 0);
    signal cart_data          : std_logic_vector(7 downto 0);
	 signal cart2_data         : std_logic_vector(7 downto 0);
	 signal cart3_data         : std_logic_vector(7 downto 0);

    signal video_r            : std_logic_vector(3 downto 0);
    signal video_g            : std_logic_vector(3 downto 0);
    signal video_b            : std_logic_vector(3 downto 0);
    signal hsync              : std_logic;
    signal vsync              : std_logic;
    signal csync              : std_logic;
    signal video_r_x2         : std_logic_vector(3 downto 0);
    signal video_g_x2         : std_logic_vector(3 downto 0);
    signal video_b_x2         : std_logic_vector(3 downto 0);
    signal hsync_x2           : std_logic;
    signal vsync_x2           : std_logic;
	 signal blanking           : std_logic;
	 signal blanking_x2        : std_logic;	
	 
	 signal scanSW : std_logic_vector(6 downto 0); --q	
	 
  SIGNAL   inff    : STD_LOGIC_VECTOR(1 DOWNTO 0); -- input flip flops
  CONSTANT cnt_max : INTEGER := (33000000/50)-1 ;  -- 33MHz and 1/20ms=50Hz
  SIGNAL   count   : INTEGER range 0 to cnt_max := 0; 
  constant prueb : integer := 30;
	 
    signal clk_4          : std_logic;	 
    signal ena_4b          : std_logic;	 
  
  	 signal we0           : std_logic; 
	 signal we1           : std_logic; 
	 signal we2           : std_logic; 
	 signal we3           : std_logic; 
	 signal we4           : std_logic; 
	 signal we5           : std_logic; 
  
    signal EXP8K : std_logic;
  
    signal P_RESET: std_logic;
	 
begin

    D_VIDEO_R <= O_VIDEO_R;
    D_VIDEO_G <= O_VIDEO_G;
    D_VIDEO_B <= O_VIDEO_B;
    D_VSYNC <= O_VSYNC;
    D_HSYNC <= O_HSYNC;

	EXP8K <= not scanSW(5);
    
	O_NTSC <= '0';
	O_PAL <= '1';
 
   expansion_din <= cart_data when (scanSW(1) = '1' and blk_sel_l(5) = '0') 
					    else cart2_data when (scanSW(2) = '1' and blk_sel_l(5) = '0')
						 else cart3_data when (scanSW(3) = '1' and blk_sel_l(5) = '0') else x"FF";
  
  
  -- <= c_rw_l;
  -- <= v_rw_l;
  expansion_nmi_l <= '1';
  expansion_irq_l <= '1';
  -- <= ram_sel_l;
  -- <= io_sel_l;
  -- <= reset_l_sampled;
  -- user port
  user_port_cb1_in <= '0';
  user_port_cb2_in <= '0';
  user_port_in <= x"00";
  -- <= user_port_out
  -- <= user_port_out_oe_l

  -- tape
  cass_n <= EAR; 
  cass_read <= not cass_n; 
  cass_sw <= '0'; -- motor off 

  -- serial
  serial_srq_in <= '0';
  serial_clk_in <= '0';
  serial_data_in <= '0';
  -- <= serial_atn_out_l;
  -- <= serial_clk_out_l;
  -- <= serial_data_out_l

  -- joy
  --  joy <= "1111"; -- 0 up, 1 down, 2 left,  3 right
  --  light_pen <= '1'; -- also used for fire button
  joy <= I_SW(3 downto 0);		--  "1111"; -- 0 up, 1 down, 2 left,  3 right
  light_pen <= I_SW(4);  		-- was '1'; -- also used for fire button
  --
  --
  --
  I_RESET_L <= '1';
  
  reset_l_sampled <= P_RESET and not scanSW(4); --manual reset (F12)
  --

  u_clocks : entity work.relojes
    port map (
      I_CLK_REF         => I_CLK_REF,
      I_RESET_L         => I_RESET_L,
      --
      O_CLK_REF         => clk_ref,
      --
      O_ENA             => ena_4,
      O_CLK             => clk_8,
		
      O_RESET_L         => P_RESET
      );

  c_ena <= ena_1mhz and ena_4; -- clk ena
  
  clkdiv2: process(clk_8)
  begin
    if clk_8'event AND clk_8 = '1' then
      ena_4b <= not ena_4b;
      clk_4 <= not clk_4;
    end if;
  end process;

  c_addr <=  unsigned(c_addrT(15 downto 0)); --T65 
  c_dout <=  unsigned(c_doutT); --T65

  cpu : entity work.T65
      port map (
          Mode    => "00",
          Res_n   => reset_l_sampled,
          Enable  => ena_1mhz, --c_ena,
          Clk     => clk_4, --clk_8,
          Rdy     => '1',
          Abort_n => '1',
          IRQ_n   => c_irq_l,
          NMI_n   => c_nmi_l,
          SO_n    => '1',
          R_W_n   => c_rw_l,
          Sync    => open,
          EF      => open,
          MF      => open,
          XF      => open,
          ML_n    => open,
          VP_n    => open,
          VDA     => open,
          VPA     => open,
          A       => c_addrT,
          DI      => c_din,
          DO      => c_doutT
      );

--  cpu : entity work.R65C02 --R65V02
--      port map (
--          Reset   => reset_l_sampled,
--          Clk     => clk_4, --clk_8,
--          Enable  => ena_1mhz, --c_ena,
--          NMI_n   => c_nmi_l,
--          IRQ_n   => c_irq_l,
--          DI      => unsigned(c_din),
--          DO      => c_dout,			 
--          ADDR    => c_addr,			 
--          nwe     => c_rw_l,
--          Sync    => open,
--          sync_irq  => open
--      );


  vic : entity work.VIC20_VIC
    generic map (
      K_OFFSET        => K_OFFSET
      )
    port map (
      I_RW_L          => v_rw_l,

      I_ADDR          => v_addr(13 downto 0),
      O_ADDR          => vic_addr(13 downto 0),

      I_DATA          => vic_din,
      O_DATA          => vic_dout,
      O_DATA_OE_L     => vic_oe_l,
      --
      O_AUDIO         => vic_audio,

      O_VIDEO_R       => video_r(3 downto 1),
      O_VIDEO_G       => video_g(3 downto 1),
      O_VIDEO_B       => video_b(3 downto 1),

      O_HSYNC         => hsync,
      O_VSYNC         => vsync,
      O_COMP_SYNC_L   => csync,
--		O_BLANK         => blanking,
      --
      --
      I_LIGHT_PEN     => light_pen,
      I_POTX          => '0',
      I_POTY          => '0',

      O_ENA_1MHZ      => ena_1mhz,
      O_P2_H          => p2_h,
      ENA_4           => ena_4,
      CLK             => clk_8
      );

  via1 : entity work.M6522
    port map (
      I_RS            => std_logic_vector(c_addr(3 downto 0)),
      I_DATA          => v_data(7 downto 0),
      O_DATA          => via1_dout,
      O_DATA_OE_L     => open,

      I_RW_L          => c_rw_l,
      I_CS1           => c_addr(4),
      I_CS2_L         => io_sel_l(0),

      O_IRQ_L         => via1_nmi_l, -- note, not open drain

      I_CA1           => keybd_restore,
      I_CA2           => cass_motor,
      O_CA2           => cass_motor,
      O_CA2_OE_L      => open,

      I_PA            => via1_pa_in,
      O_PA            => via1_pa_out,
      O_PA_OE_L       => open,

      -- port b
      I_CB1           => user_port_cb1_in,
      O_CB1           => user_port_cb1_out,
      O_CB1_OE_L      => user_port_cb1_oe_l,

      I_CB2           => user_port_cb2_in,
      O_CB2           => user_port_cb2_out,
      O_CB2_OE_L      => user_port_cb2_oe_l,

      I_PB            => user_port_in,
      O_PB            => user_port_out,
      O_PB_OE_L       => user_port_oe_l,

      I_P2_H          => p2_h,
      RESET_L         => reset_l_sampled,
      ENA_4           => ena_4,
      CLK             => clk_8
      );

  serial_atn_out_l <= via1_pa_out(7);
  via1_pa_in(7) <= via1_pa_out(7);
  via1_pa_in(6) <= cass_sw;
  via1_pa_in(5) <= light_pen;
  via1_pa_in(4) <= joy(2);
  via1_pa_in(3) <= joy(1);
  via1_pa_in(2) <= joy(0);
  via1_pa_in(1) <= serial_data_in;
  via1_pa_in(0) <= serial_clk_in;

  via2 : entity work.M6522
    port map (
      I_RS            => std_logic_vector(c_addr(3 downto 0)),
      I_DATA          => v_data(7 downto 0),
      O_DATA          => via2_dout,
      O_DATA_OE_L     => open,

      I_RW_L          => c_rw_l,
      I_CS1           => c_addr(5),
      I_CS2_L         => io_sel_l(0),

      O_IRQ_L         => via2_irq_l, -- note, not open drain

      I_CA1           => cass_read,
      I_CA2           => serial_clk_out_l,
      O_CA2           => serial_clk_out_l,
      O_CA2_OE_L      => open,

      I_PA            => keybd_row_in,
      O_PA            => open,
      O_PA_OE_L       => open,

      -- port b
      I_CB1           => serial_srq_in,
      O_CB1           => open,
      O_CB1_OE_L      => open,

      I_CB2           => serial_data_out_l,
      O_CB2           => serial_data_out_l,
      O_CB2_OE_L      => open,

      I_PB            => keybd_col_in,
      O_PB            => keybd_col_out,
      O_PB_OE_L       => keybd_col_oe_l,

      I_P2_H          => p2_h,
      RESET_L         => reset_l_sampled,
      ENA_4           => ena_4,
      CLK             => clk_8
      );

  p_keybd_col_in : process(keybd_col_out, keybd_col_oe_l, joy)
  begin
    for i in 0 to 6 loop
      keybd_col_in(i) <= keybd_col_out(i);
    end loop;

    if (keybd_col_oe_l(7) = '0') then
      keybd_col_in(7) <= keybd_col_out(7);
    else
      keybd_col_in(7) <= joy(3);
    end if;
  end process;
  cass_write <= keybd_col_out(3);

  keybd : entity work.VIC20_PS2_IF
    port map (

      I_PS2_CLK       => I_PS2_CLK,
      I_PS2_DATA      => I_PS2_DATA,

      I_COL           => keybd_col_out,
      O_ROW           => keybd_row_in,
      O_RESTORE       => keybd_restore,

      I_ENA_1MHZ      => ena_1mhz,
      I_P2_H          => p2_h,
      RESET_L         => '1',
      ENA_4           => ena_4,
      CLK             => clk_8
		  ,scanSW 	=> scanSW --q
      );

  p_irq_resolve : process(expansion_irq_l, expansion_nmi_l,
                          via2_irq_l, via1_nmi_l)
  begin
    c_irq_l <= '1';
    if (expansion_irq_l = '0') or (via2_irq_l = '0') then
      c_irq_l <= '0';
    end if;

    c_nmi_l <= '1';
    if (expansion_nmi_l = '0') or (via1_nmi_l = '0') then
      c_nmi_l <= '0';
    end if;
  end process;

  --
  -- decode
  --
  p_io_addr_decode : process(c_addr)
  begin

    io_sel_l <= "1111";
    if (c_addr(15 downto 13) = "100") then -- blk4
      case c_addr(12 downto 10) is
        when "000" => io_sel_l <= "1111";
        when "001" => io_sel_l <= "1111";
        when "010" => io_sel_l <= "1111";
        when "011" => io_sel_l <= "1111";
        when "100" => io_sel_l <= "1110";
        when "101" => io_sel_l <= "1101"; -- col
        when "110" => io_sel_l <= "1011";
        when "111" => io_sel_l <= "0111";
        when others => null;
      end case;
    end if;
  end process;

  p_blk_addr_decode : process(c_addr)
  begin
    blk_sel_l <= "11111111";
    case c_addr(15 downto 13) is
      when "000" => blk_sel_l <= "11111110";
      when "001" => blk_sel_l <= "11111101";
      when "010" => blk_sel_l <= "11111011";
      when "011" => blk_sel_l <= "11110111";
      when "100" => blk_sel_l <= "11101111";
      when "101" => blk_sel_l <= "11011111"; -- Cart
      when "110" => blk_sel_l <= "10111111"; -- basic
      when "111" => blk_sel_l <= "01111111"; -- kernal
      when others => null;
    end case;
  end process;

  p_v_mux : process(c_addr, c_dout, c_rw_l, p2_h, vic_addr, v_data_read_mux,
                         blk_sel_l, io_sel_l)
  begin
    -- simplified data source mux
    if (p2_h = '0') then
      v_addr(13 downto 0) <= vic_addr(13 downto 0);
      v_data <= v_data_read_mux(7 downto 0);
      v_rw_l <= '1';
      col_ram_sel_l <= '1'; -- colour ram has dedicated mux for vic, so disable
    else -- cpu
      v_addr(13 downto 0) <= blk_sel_l(4) & std_logic_vector(c_addr(12 downto 0));
      v_data <= std_logic_vector(c_dout);
      v_rw_l <= c_rw_l;
      col_ram_sel_l <= io_sel_l(1);
    end if;

  end process;

  p_ram_addr_decode : process(v_addr, blk_sel_l, p2_h)
  begin
    ram_sel_l <= "11111111";
    if ((p2_h = '1') and (blk_sel_l(0) = '0')) or -- cpu
       ((p2_h = '0') and (v_addr(13) = '1')) then
      case v_addr(12 downto 10) is
        when "000" => ram_sel_l <= "11111110";
        when "001" => ram_sel_l <= "11111101";
        when "010" => ram_sel_l <= "11111011";
        when "011" => ram_sel_l <= "11110111";
        when "100" => ram_sel_l <= "11101111";
        when "101" => ram_sel_l <= "11011111";
        when "110" => ram_sel_l <= "10111111";
        when "111" => ram_sel_l <= "01111111";
        when others => null;
      end case;
    end if;
  end process;

  p_vic_din_mux : process(p2_h, col_ram_dout, v_data)
  begin
    if (p2_h = '0') then
      vic_din(11 downto 8) <= col_ram_dout(3 downto 0);
    else
      vic_din(11 downto 8) <= v_data(3 downto 0);
    end if;

    vic_din(7 downto 0) <= v_data(7 downto 0);
  end process;

  p_v_read_mux : process(col_ram_sel_l, ram_sel_l, blk_sel_l, vic_oe_l, v_addr,
                         col_ram_dout, ram0_dout, ram45_dout, ram67_dout,
                         vic_dout, char_rom_dout,
                         v_data_read_muxr)
  begin
    -- simplified data read mux
    -- nasty if statement but being lazy
    -- these are exclusive, but the tools may not spot this.

    v_data_oe_l <= '1';
    if (col_ram_sel_l = '0') then
      v_data_read_mux <= "0000" & col_ram_dout(3 downto 0);
      v_data_oe_l     <= '0';
    elsif (vic_oe_l = '0') then
      v_data_read_mux <= vic_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(0) = '0') then
      v_data_read_mux <= ram0_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(4) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(5) = '0') then
      v_data_read_mux <= ram45_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(6) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (ram_sel_l(7) = '0') then
      v_data_read_mux <= ram67_dout;
      v_data_oe_l     <= '0';
    elsif (v_addr(13 downto 12) = "00") then
      v_data_read_mux <= char_rom_dout;
      v_data_oe_l     <= '0';
    else
      -- emulate floating bus
      --v_data_read_mux <= "XXXXXXXX";
      v_data_read_mux <= v_data_read_muxr;
    end if;

  end process;

  p_v_bus_hold : process
  begin
    wait until rising_edge(clk_4);
    v_data_read_muxr <= v_data_read_mux;
  end process;
 --
 
  p_cpu_read_mux : process(p2_h, c_addr, io_sel_l, ram_sel_l, blk_sel_l,
                           v_data_read_mux, via1_dout, via2_dout, v_data_oe_l,
                           basic_rom_dout, kernal_rom_dout, expansion_din,
									blk1_dout, blk2_dout, blk3_dout)
  begin

    if (p2_h = '0') then -- vic is on the bus
      --c_din <= "XXXXXXXX";
      c_din <= "00000000";
    elsif (io_sel_l(0) = '0') and (c_addr(4) = '1') then -- blk4
      c_din <= via1_dout;
    elsif (io_sel_l(0) = '0') and (c_addr(5) = '1') then -- blk4
      c_din <= via2_dout;
	 elsif (blk_sel_l(1) = '0' and EXP8K = '1') then
      c_din <= blk1_dout;
    elsif (blk_sel_l(2) = '0' and EXP8K = '1') then
      c_din <= blk2_dout;
    elsif (blk_sel_l(5) = '0') then
      c_din <= expansion_din;
    elsif (blk_sel_l(6) = '0') then
      c_din <= basic_rom_dout;
    elsif (blk_sel_l(7) = '0') then
      c_din <= kernal_rom_dout;
    elsif (v_data_oe_l = '0') then
      c_din <= v_data_read_mux;
    else
      c_din <= "11111111";
    end if;
  end process;
  --
  -- main memory
  --
 
  we0 <= (not ram_sel_l(0)) and (not v_rw_l );
 
  rams0 : entity work.DistRAM
	 generic map (
    addr_width_g => 10,
    data_width_g => 8
    )
    port map (
	   clk_i    => clk_8,
		ena	=> ena_4,
      a_i => v_addr(9 downto 0), 
		we_i => we0,
      d_i    => v_data,
      d_o   => ram0_dout
      );

  we1 <= ((not ram_sel_l(4)) or (not ram_sel_l(5))) and (not v_rw_l );
  
  rams45 : entity work.DistRAM
	 generic map (
    addr_width_g => 11,
    data_width_g => 8
    )
    port map (
	   clk_i    => clk_8,
		ena	=> ena_4,
      a_i => v_addr(10 downto 0), 
		we_i => we1,
      d_i    => v_data,
      d_o   => ram45_dout
      );

  we2 <= ((not ram_sel_l(6)) or (not ram_sel_l(7))) and (not v_rw_l );
  
  rams67 : entity work.DistRAM
	 generic map (
    addr_width_g => 11,
    data_width_g => 8
    )
    port map (
	   clk_i    => clk_8,
		ena	=> ena_4,
      a_i => v_addr(10 downto 0), 
		we_i => we2,
      d_i    => v_data,
      d_o   => ram67_dout
      );

  we3 <= (not col_ram_sel_l) and (not v_rw_l );
   
  col_ram : entity work.DistRAM
	 generic map (
    addr_width_g => 10,
    data_width_g => 8
    )
    port map (
	   clk_i    => clk_8,
		ena	=> ena_4,
      a_i => v_addr(9 downto 0), 
		we_i => we3,
      d_i    => v_data(7 downto 0),
      d_o   => col_ram_dout(7 downto 0)
      );
			
-------------------------------------------------------------------------		

--8k 1		
  blk1_inst : entity work.VIC20_RAM8
    port map
    (
      V_ADDR => std_logic_vector(c_addr(12 downto 0)),
      DIN    => v_data,
      DOUT   => blk1_dout,
      V_RW_L => v_rw_l,
      CS_L   => blk_sel_l(1),
      ENA    => ena_4,
      CLK    => clk_8	 
    );	 	
	 
--8k 2		
  blk2_inst : entity work.VIC20_RAM8
    port map
    (
      V_ADDR => std_logic_vector(c_addr(12 downto 0)),
      DIN    => v_data,
      DOUT   => blk2_dout,
      V_RW_L => v_rw_l,
      CS_L   => blk_sel_l(2),
      ENA    => ena_4,
      CLK    => clk_8	 
    );		
	
  --
  -- roms
  --
  char_rom : entity work.VIC20_CHAR_ROM
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => v_addr(11 downto 0),
      DATA        => char_rom_dout
      );

  basic_rom : entity work.VIC20_BASIC_ROM
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => std_logic_vector(c_addr(12 downto 0)),
      DATA        => basic_rom_dout
      );

  kernal_rom : entity work.VIC20_KERNAL_ROM
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => std_logic_vector(c_addr(12 downto 0)),
      DATA        => kernal_rom_dout
      );
		
  --
  -- cart slots 0xA000-0xBFFF (8K)
  --
  
  --1st cartridge
  cartridge_rom : entity work.VIC20_CARTRIDGE 
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => std_logic_vector(c_addr(12 downto 0)),
      DATA        => cart_data
      );
		
  --2nd cartridge, for swap
  cartridge2_rom : entity work.VIC20_CARTRIDGE2 
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => std_logic_vector(c_addr(12 downto 0)),
      DATA        => cart2_data
      );	

  --3rd cartridge, for swap
  cartridge3_rom : entity work.VIC20_CARTRIDGE3 
    port map (
      CLK         => clk_8,
      ENA         => ena_4,
      ADDR        => std_logic_vector(c_addr(12 downto 0)),
      DATA        => cart3_data
      );			
		
  --
  -- scan doubler
  --
  u_dblscan : entity work.VIC20_DBLSCAN
    port map (
      I_R               => video_r,
      I_G               => video_g,
      I_B               => video_b,
      I_HSYNC           => hsync,
      I_VSYNC           => vsync,
		I_BLANK           => blanking,
      --
      O_R               => video_r_x2,
      O_G               => video_g_x2,
      O_B               => video_b_x2,
      O_HSYNC           => hsync_x2,
      O_VSYNC           => vsync_x2,
		O_BLANK           => blanking_x2,
      --
      ENA               => ena_4,
      CLK               => clk_8
    );
  --

 p_video_ouput : process
  begin
    wait until rising_edge(clk_8);
	  if (scanSW(0) = '1') then   -- was sw_reg(0)
			O_VIDEO_R <= video_r_x2(3 downto 1);
			O_VIDEO_G <= video_g_x2(3 downto 1);
			O_VIDEO_B <= video_b_x2(3 downto 1);
			O_HSYNC   <= hSync_X2;
			O_VSYNC   <= vSync_X2;
	  else
			--O_LED(0) <= '0';
			O_VIDEO_R <= video_r(3 downto 1);
			O_VIDEO_G <= video_g(3 downto 1);
			O_VIDEO_B <= video_b(3 downto 1);
			--O_HSYNC   <= hSync;
			--O_VSYNC   <= vSync;
			O_HSYNC   <= cSync;
			O_VSYNC   <= '1';
	  end if;
  end process;

  --
  -- Audio
  --
  u_dac : entity work.dac
    generic map(
      msbi_g => 3
    )
    port  map(
      clk_i   => clk_ref,
      res_n_i => reset_l_sampled,
      dac_i   => vic_audio,
      dac_o   => audio_pwm
    );

  O_AUDIO_L <= audio_pwm;
  O_AUDIO_R <= audio_pwm;
  
  LED <= EXP8K; --on = +16k expanded VIC20, off = not expanded
  
------------multiboot---------------

	multiboot: entity work.multiboot
	port map(
		clk_icap		      => clk_8,
		REBOOT				=> scanSW(6) --mreset key combo
	);	
  
  
end RTL;
