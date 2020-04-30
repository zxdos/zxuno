-------------------------------------------------------------------------------
--
-- PCM Sound Controller
--
-- $Id: pcm_sound.vhd,v 1.1 2006/02/20 00:21:14 arnim Exp $
--
-- FSM to initialize the AC97 controller core. The audio samples are copied
-- periodically to the codec after initialization.
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
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
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pcm_sound is
  port (
    -- System Interface -------------------------------------------------------
    clk_i              : in  std_logic;
    reset_n_i          : in  std_logic;
    -- PCM Audio Interface ----------------------------------------------------
    pcm_left_i         : in  signed(8 downto 0);
    pcm_right_i        : in  signed(8 downto 0);
    -- AC97 Codec Interface ---------------------------------------------------
    bit_clk_pad_i      : in  std_logic;
    sync_pad_o         : out std_logic;
    sdata_pad_o        : out std_logic;
    sdata_pad_i        : in  std_logic;
    ac97_reset_pad_n_o : out std_logic;
    -- Diagnostic Interface ---------------------------------------------------
    led_o              : out std_logic_vector(5 downto 0);
    dpy0_a_o           : out std_logic;
    dpy0_b_o           : out std_logic;
    dpy0_c_o           : out std_logic;
    dpy0_d_o           : out std_logic;
    dpy0_e_o           : out std_logic;
    dpy0_f_o           : out std_logic;
    dpy0_g_o           : out std_logic;
    dpy1_a_o           : out std_logic;
    dpy1_b_o           : out std_logic;
    dpy1_c_o           : out std_logic;
    dpy1_d_o           : out std_logic;
    dpy1_e_o           : out std_logic;
    dpy1_f_o           : out std_logic;
    dpy1_g_o           : out std_logic
  );
end pcm_sound;


architecture rtl of pcm_sound is

  component ac97_top
    port (
      -- Global Interface -----------------------------------------------------
      clk_i             : in  std_logic;
      rst_i             : in  std_logic;
      -- Wishbone Slave Interface ---------------------------------------------
      wb_data_i         : in  std_logic_vector(31 downto 0);
      wb_data_o         : out std_logic_vector(31 downto 0);
      wb_addr_i         : in  std_logic_vector(31 downto 0);
      wb_sel_i          : in  std_logic_vector( 3 downto 0);
      wb_we_i           : in  std_logic;
      wb_cyc_i          : in  std_logic;
      wb_stb_i          : in  std_logic;
      wb_ack_o          : out std_logic;
      wb_err_o          : out std_logic;
      -- Misc Signals ---------------------------------------------------------
      int_o             : out std_logic;
      dma_req_o         : out std_logic_vector( 8 downto 0);
      dma_ack_i         : in  std_logic_vector( 8 downto 0);
      -- Suspend Resume Interface ---------------------------------------------
      suspended_o       : out std_logic;
      -- AC97 Codec Interface -------------------------------------------------
      bit_clk_pad_i     : in  std_logic;
      sync_pad_o        : out std_logic;
      sdata_pad_o       : out std_logic;
      sdata_pad_i       : in  std_logic;
      ac97_reset_pad_n_o: out std_logic
    );
  end component;


  subtype  reg_t is std_logic_vector(6 downto 0);
  constant reg_csr_c      : reg_t := "0000000";  -- 00h
  constant reg_occ0_c     : reg_t := "0000100";  -- 04h
  constant reg_crac_c     : reg_t := "0010000";  -- 10h
  constant reg_intm_c     : reg_t := "0010100";  -- 14h
  constant reg_ints_c     : reg_t := "0011000";  -- 18h
  constant reg_och0_c     : reg_t := "0100000";  -- 20h
  constant reg_och1_c     : reg_t := "0100100";  -- 24h

  constant codec_mv_c     : reg_t := "0000010";  -- 02h
  constant codec_pcm_v_c  : reg_t := "0011000";  -- 18h
  constant codec_gpr_c    : reg_t := "0100000";  -- 20h
  constant codec_status_c : reg_t := "0100110";  -- 26h

  type   cycle_t is (IDLE,
                     SETUP_ISM,
                     COLD_RESET,
                     REQUEST_STATUS, INT_STATUS, READ_STATUS_INTS, READ_STATUS,
                     MV_WRITE,   MV_INT,   MV_INTS,
                     PCMV_WRITE, PCMV_INT, PCMV_INTS,
                     GPR_WRITE,  GPR_INT,  GPR_INTS,
                     INTM_CH01_WRITE,
                     OCC0_WRITE,
                     POLL_INT,
                     CH0_WRITE, CH1_WRITE, POLL_READ_INTS);
  signal cycle_s,
         cycle_q             : cycle_t;

  type   set_dpy_t is (DPY_IDLE,
                       DPY_SETUP_ISM,
                       DPY_COLD_RESET,
                       DPY_POLL_STATUS,
                       DPY_MV_WRITE,
                       DPY_PCMV_WRITE,
                       DPY_GPR_WRITE,
                       DPY_INTM_CH01_WRITE,
                       DPY_OCC0_WRITE,
                       DPY_CH_WRITE);
  signal set_dpy_s : set_dpy_t;

  type   access_t is (IDLE, WRITE_REG, READ_REG);
  signal access_s,
         access_q  : access_t;

  signal wb_data_to_ac97_s,
         wb_data_from_ac97_s : std_logic_vector(31 downto 0);
  signal wb_addr_s           : std_logic_vector(31 downto 0);
  signal wb_sel_s            : std_logic_vector( 3 downto 0);
  signal wb_we_s             : std_logic;
  signal wb_cyc_s            : std_logic;
  signal wb_stb_s            : std_logic;
  signal wb_ack_s            : std_logic;

  signal int_s               : std_logic;

  signal reg_read_s,
         reg_read_q,
         reg_write_s,
         reg_write_q         : boolean;

  signal tog_led_s           : boolean;
  signal dpy1_a_q,
         dpy1_d_q            : std_logic;

  signal gnd9_s              : std_logic_vector( 8 downto 0);

begin

  gnd9_s <= (others => '0');


  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --   Implements the sequential elements.
  --
  seq: process (clk_i, reset_n_i)
  begin
    if reset_n_i = '0' then
      cycle_q       <= IDLE;
      access_q      <= IDLE;
      reg_read_q    <= false;
      reg_write_q   <= false;
      dpy1_a_q      <= '0';
      dpy1_d_q      <= '0';

    elsif clk_i'event and clk_i = '1' then
      cycle_q       <= cycle_s;
      access_q      <= access_s;

      if not reg_read_q then
        reg_read_q  <= false;
      elsif reg_read_s and access_q = IDLE then
        reg_read_q  <= true;
      end if;

      if not reg_write_q then
        reg_write_q <= false;
      elsif reg_write_s and access_q = IDLE then
        reg_write_q <= true;
      end if;

      if tog_led_s then
        dpy1_a_q <= not dpy1_a_q;
        dpy1_d_q <= dpy1_a_q;
      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------

  dpy1_a_o <= dpy1_a_q;
  dpy1_d_o <= dpy1_d_q;


  -----------------------------------------------------------------------------
  -- Process cycle
  --
  -- Purpose:
  --   Generates the Wishbone Interface sequence to run the AC97 Codec.
  --
  cycle: process (cycle_q,
                  wb_data_from_ac97_s,
                  wb_ack_s,
                  int_s,
                  pcm_left_i, pcm_right_i)
    variable reg_addr_v : std_logic_vector(6 downto 0);
  begin
    -- default assignments
    cycle_s           <= cycle_q;
    wb_data_to_ac97_s <= (others => '0');
    reg_addr_v        := (others => '0');
    reg_read_s        <= false;
    reg_write_s       <= false;
    set_dpy_s         <= DPY_IDLE;
    led_o             <= (others => '0');
    tog_led_s         <= false;

    case cycle_q is
      when IDLE =>
        cycle_s   <= SETUP_ISM;
        set_dpy_s <= DPY_SETUP_ISM;

      -- Enable Codec Register Access IRQ in ISM ------------------------------
      when SETUP_ISM =>
        -- enable interrupt for
        --   codec register write done
        --   codec register read done
        reg_addr_v := reg_intm_c;
        wb_data_to_ac97_s(1) <= '1';
        wb_data_to_ac97_s(0) <= '1';

        if wb_ack_s = '1' then
          cycle_s     <= COLD_RESET;
          set_dpy_s   <= DPY_COLD_RESET;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;

      -- Perform a Cold Reset -------------------------------------------------
      when COLD_RESET =>
        reg_addr_v := reg_csr_c;
        wb_data_to_ac97_s(0) <= '1';

        if wb_ack_s = '1' then
          cycle_s     <= REQUEST_STATUS;
          set_dpy_s   <= DPY_POLL_STATUS;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;

      -- Poll Codec Status ----------------------------------------------------
      when REQUEST_STATUS =>
        reg_addr_v := reg_crac_c;
        wb_data_to_ac97_s(31) <= '1';
        wb_data_to_ac97_s(22 downto 16) <= codec_status_c;

        if wb_ack_s = '1' then
          cycle_s     <= INT_STATUS;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;
      --
      when INT_STATUS =>
        if int_s = '1' then
          cycle_s  <= READ_STATUS_INTS;
        else
          led_o(1) <= '1';
        end if;
      --
      when READ_STATUS_INTS =>
        reg_addr_v := reg_ints_c;

        if wb_ack_s = '1' then
          cycle_s    <= READ_STATUS;
        else
          reg_read_s <= true;
          led_o(2)   <= '1';
        end if;
      --
      when READ_STATUS =>
        reg_addr_v := reg_crac_c;

        if wb_ack_s = '1' then
          if wb_data_from_ac97_s(3 downto 1) = "111" then
            cycle_s   <= MV_WRITE;
            set_dpy_s <= DPY_MV_WRITE;
          else
            cycle_s   <= REQUEST_STATUS;
          end if;

          led_o(4)    <= '1';
        else
          reg_read_s  <= true;
          led_o(3)    <= '1';
        end if;

      -- Set Codec Master Volume ----------------------------------------------
      when MV_WRITE =>
        reg_addr_v := reg_crac_c;
        wb_data_to_ac97_s(22 downto 16) <= codec_mv_c;
        -- write all-0 as data

        if wb_ack_s = '1' then
          cycle_s     <= MV_INT;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;
      --
      when MV_INT =>
        if int_s = '1' then
          cycle_s     <= MV_INTS;
        else
          led_o(1)    <= '1';
        end if;
      --
      when MV_INTS =>
        reg_addr_v := reg_ints_c;

        if wb_ack_s = '1' then
          cycle_s    <= PCMV_WRITE;
          set_dpy_s  <= DPY_PCMV_WRITE;
        else
          reg_read_s <= true;
          led_o(2)   <= '1';
        end if;

      -- Set Codec PCM Volume -------------------------------------------------
      when PCMV_WRITE =>
        reg_addr_v := reg_crac_c;
        wb_data_to_ac97_s(22 downto 16) <= codec_pcm_v_c;
        -- write 0808h
        wb_data_to_ac97_s(15 downto  0) <= "0000100000001000";

        if wb_ack_s = '1' then
          cycle_s     <= PCMV_INT;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;
      --
      when PCMV_INT =>
        if int_s = '1' then
          cycle_s  <= PCMV_INTS;
        else
          led_o(1) <= '1';
        end if;
      --
      when PCMV_INTS =>
        reg_addr_v := reg_ints_c;

        if wb_ack_s = '1' then
          cycle_s     <= GPR_WRITE;
          set_dpy_s   <= DPY_GPR_WRITE;
        else
          reg_read_s  <= true;
          led_o(2)    <= '1';
        end if;

      -- Set Code General Purpose Register ------------------------------------
      when GPR_WRITE =>
        reg_addr_v := reg_crac_c;
        wb_data_to_ac97_s(22 downto 16) <= codec_gpr_c;
        wb_data_to_ac97_s(0) <= '1';  -- 3D bypassed

        if wb_ack_s = '1' then
          cycle_s     <= GPR_INT;
        else
          reg_write_s <= true;
          led_o(0)    <= '1';
        end if;
      --
      when GPR_INT =>
        if int_s = '1' then
          cycle_s  <= GPR_INTS;
        else
          led_o(1) <= '1';
        end if;
      --
      when GPR_INTS =>
        reg_addr_v := reg_ints_c;

        if wb_ack_s = '1' then
          cycle_s    <= OCC0_WRITE;
          set_dpy_s  <= DPY_OCC0_WRITE;
        else
          reg_read_s <= true;
          led_o(2)   <= '1';
        end if;

      -- Configure Channel 0/1 ------------------------------------------------
      when OCC0_WRITE =>
        reg_addr_v := reg_occ0_c;
        -- channel 1: front right channel
        --            threshold: FIFO empty
        --            sample size 18 bit
        --            enable channel
        wb_data_to_ac97_s(15 downto 8) <= "00110101";
        -- channel 0: front left channel
        --            threshold: FIFO empty
        --            sample size 18 bit
        --            enable channel
        wb_data_to_ac97_s( 7 downto 0) <= "00110101";

        if wb_ack_s = '1' then
          cycle_s     <= INTM_CH01_WRITE;
          set_dpy_s   <= DPY_INTM_CH01_WRITE;
        else
          reg_write_s <= true;
        end if;

      -- Enable Channel 0 FIFO Threshold IRQ in INTM --------------------------
      when INTM_CH01_WRITE =>
        reg_addr_v := reg_intm_c;
        wb_data_to_ac97_s(2) <= '1';

        if wb_ack_s = '1' then
          -- do first write to channels and trigger IRQ sequence
          cycle_s     <= CH0_WRITE;
          set_dpy_s   <= DPY_CH_WRITE;
        else
          reg_write_s <= true;
        end if;

      -- Write PCM Data to Channel 0 ------------------------------------------
      when CH0_WRITE =>
        reg_addr_v := reg_och0_c;
        wb_data_to_ac97_s(17 downto 0) <= pcm_left_i(8) &
                                          std_logic_vector(pcm_left_i(7 downto 0)) &
                                          "000000000";

        if wb_ack_s = '1' then
          cycle_s     <= CH1_WRITE;
          tog_led_s   <= true;
        else
          reg_write_s <= true;
        end if;

      -- Write PCM Data to Channel 1 ------------------------------------------
      when CH1_WRITE =>
        reg_addr_v := reg_och1_c;
        wb_data_to_ac97_s(17 downto 0) <= pcm_right_i(8) &
                                          std_logic_vector(pcm_right_i(7 downto 0)) &
                                          "000000000";

        if wb_ack_s = '1' then
          cycle_s     <= POLL_READ_INTS;
        else
          reg_write_s <= true;
        end if;

      -- Poll for Channel 0 FIFO Threshold IRQ --------------------------------
      when POLL_INT =>
        if int_s = '1' then
          cycle_s   <= CH0_WRITE;
        end if;

      -- Read Interrupt Status ------------------------------------------------
      when POLL_READ_INTS =>
        reg_addr_v := reg_ints_c;

        if wb_ack_s = '1' then
          cycle_s    <= POLL_INT;
        else
          reg_read_s <= true;
        end if;

      when others =>
        null;

    end case;

    -- build Wishbone address
    wb_addr_s(31 downto 7) <= (others => '0');
    wb_addr_s( 6 downto 0) <= reg_addr_v;
  end process cycle;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process access_p
  --
  -- Purpose:
  --   FSM to generate a Wishbone access.
  --
  access_p: process (access_q,
                     reg_read_s, reg_read_q,
                     reg_write_s, reg_write_q,
                     wb_ack_s)
    variable start_read_v,
             start_write_v : boolean;
  begin
    -- default assignments
    access_s <= access_q;
    wb_sel_s <= (others => '1');
    wb_we_s  <= '0';
    wb_cyc_s <= '0';
    wb_stb_s <= '0';

    -- edge detectors
    start_read_v  := reg_read_s and not reg_read_q;
    start_write_v := reg_write_s and not reg_write_q;

    case access_q is
      when IDLE =>
        if start_read_v then
          access_s <= READ_REG;
        end if;

        if start_write_v then
          access_s <= WRITE_REG;
        end if;

      when READ_REG =>
        wb_cyc_s <= '1';
        wb_stb_s <= '1';

        if wb_ack_s = '1' then
          access_s <= IDLE;
        end if;

      when WRITE_REG =>
        wb_cyc_s <= '1';
        wb_stb_s <= '1';
        wb_we_s  <= '1';

        if wb_ack_s = '1' then
          access_s <= IDLE;
        end if;

      when others =>
        null;
    end case;
  end process access_p;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- AC97 Codec Controller
  -----------------------------------------------------------------------------
  ac97_top_b : ac97_top
    port map (
      clk_i              => clk_i,
      rst_i              => reset_n_i,
      wb_data_i          => wb_data_to_ac97_s,
      wb_data_o          => wb_data_from_ac97_s,
      wb_addr_i          => wb_addr_s,
      wb_sel_i           => wb_sel_s,
      wb_we_i            => wb_we_s,
      wb_cyc_i           => wb_cyc_s,
      wb_stb_i           => wb_stb_s,
      wb_ack_o           => wb_ack_s,
      wb_err_o           => open,
      int_o              => int_s,
      dma_req_o          => open,
      dma_ack_i          => gnd9_s,
      suspended_o        => open,
      bit_clk_pad_i      => bit_clk_pad_i,
      sync_pad_o         => sync_pad_o,
      sdata_pad_o        => sdata_pad_o,
      sdata_pad_i        => sdata_pad_i,
      ac97_reset_pad_n_o => ac97_reset_pad_n_o
    );


  -----------------------------------------------------------------------------
  -- Process dpy
  --
  -- Purpose:
  --   Decode and visualize display message.
  --
  dpy: process (clk_i, reset_n_i)
  begin
    if reset_n_i = '0' then
      dpy0_a_o <= '1';
      dpy0_b_o <= '1';
      dpy0_c_o <= '1';
      dpy0_d_o <= '1';
      dpy0_e_o <= '1';
      dpy0_f_o <= '1';
      dpy0_g_o <= '0';

    elsif clk_i'event and clk_i = '1' then
      case set_dpy_s is
        when DPY_SETUP_ISM =>
          dpy0_a_o <= '0';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '0';
          dpy0_e_o <= '0';
          dpy0_f_o <= '0';
          dpy0_g_o <= '0';
        when DPY_COLD_RESET =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '1';
          dpy0_c_o <= '0';
          dpy0_d_o <= '1';
          dpy0_e_o <= '1';
          dpy0_f_o <= '0';
          dpy0_g_o <= '1';
        when DPY_POLL_STATUS =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '1';
          dpy0_e_o <= '0';
          dpy0_f_o <= '0';
          dpy0_g_o <= '1';
        when DPY_MV_WRITE =>
          dpy0_a_o <= '0';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '0';
          dpy0_e_o <= '0';
          dpy0_f_o <= '1';
          dpy0_g_o <= '1';
        when DPY_PCMV_WRITE =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '0';
          dpy0_c_o <= '1';
          dpy0_d_o <= '1';
          dpy0_e_o <= '0';
          dpy0_f_o <= '1';
          dpy0_g_o <= '1';
        when DPY_GPR_WRITE =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '0';
          dpy0_c_o <= '1';
          dpy0_d_o <= '1';
          dpy0_e_o <= '1';
          dpy0_f_o <= '1';
          dpy0_g_o <= '1';
        when DPY_INTM_CH01_WRITE =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '0';
          dpy0_e_o <= '0';
          dpy0_f_o <= '0';
          dpy0_g_o <= '0';
        when DPY_OCC0_WRITE =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '1';
          dpy0_e_o <= '1';
          dpy0_f_o <= '1';
          dpy0_g_o <= '1';
        when DPY_CH_WRITE =>
          dpy0_a_o <= '1';
          dpy0_b_o <= '1';
          dpy0_c_o <= '1';
          dpy0_d_o <= '1';
          dpy0_e_o <= '0';
          dpy0_f_o <= '1';
          dpy0_g_o <= '1';

        when others =>
          null;

      end case;
    end if;
  end process dpy;
  --
  -----------------------------------------------------------------------------


--  dpy1_a_o <= '0';
  dpy1_b_o <= '0';
  dpy1_c_o <= '0';
--  dpy1_d_o <= '0';
  dpy1_e_o <= '0';
  dpy1_f_o <= '0';
  dpy1_g_o <= '0';

end rtl;
