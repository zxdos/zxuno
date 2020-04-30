--
-- vencode.vhd
--   RGB to NTSC video encoder
--   Revision 1.00
--
-- Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity vencode is
	port(
		clk21m_i			: in    std_logic;
		reset_i			: in    std_logic;

		-- video input
		videoR_i			: in    std_logic_vector(  5 downto 0 );
		videoG_i			: in    std_logic_vector(  5 downto 0 );
		videoB_i			: in    std_logic_vector(  5 downto 0 );
		videohs_n_i		: in    std_logic;
		videovs_n_i		: in    std_logic;

		-- video output
		videoY_o			: out   std_logic_vector(  5 downto 0 );
		videoC_o			: out   std_logic_vector(  5 downto 0 );
		videoV_o			: out   std_logic_vector(  5 downto 0 )
	);
end entity;

architecture rtl of vencode is

    signal videoY_s        : std_logic_vector(  5 downto 0 );
    signal videoC_s        : std_logic_vector(  5 downto 0 );
    signal videoV_s        : std_logic_vector(  5 downto 0 );

    signal seq_s           : std_logic_vector(  2 downto 0 );

    signal burphase_s      : std_logic;
    signal vcounter_s      : std_logic_vector(  8 downto 0 );
    signal hcounter_s      : std_logic_vector( 11 downto 0 );
    signal window_v_s      : std_logic;
    signal window_h_s      : std_logic;
    signal window_c_s      : std_logic;
    signal tableadr_s      : std_logic_vector(  4 downto 0 );
    signal tabledat_s      : std_logic_vector(  7 downto 0 );
    signal pal_det_cnt_s   : std_logic_vector(  8 downto 0 );
    signal pal_mode_s      : std_logic;

    signal ivideor_s       : std_logic_vector(  5 downto 0 );
    signal ivideog_s       : std_logic_vector(  5 downto 0 );
    signal ivideob_s       : std_logic_vector(  5 downto 0 );

    signal Y_s             : std_logic_vector(  7 downto 0 );
    signal C_s             : std_logic_vector(  7 downto 0 );
    signal V_s             : std_logic_vector(  7 downto 0 );

    signal c0_s            : std_logic_vector(  7 downto 0 );
    signal y1_s            : std_logic_vector( 13 downto 0 );
    signal y2_s            : std_logic_vector( 13 downto 0 );
    signal y3_s            : std_logic_vector( 13 downto 0 );
    signal u1_s            : std_logic_vector( 13 downto 0 );
    signal u2_s            : std_logic_vector( 13 downto 0 );
    signal u3_s            : std_logic_vector( 13 downto 0 );
    signal v1_s            : std_logic_vector( 13 downto 0 );
    signal v2_s            : std_logic_vector( 13 downto 0 );
    signal v3_s            : std_logic_vector( 13 downto 0 );
    signal w1_s            : std_logic_vector( 13 downto 0 );
    signal w2_s            : std_logic_vector( 13 downto 0 );
    signal w3_s            : std_logic_vector( 13 downto 0 );

    signal ivideovs_n_s    : std_logic;
    signal ivideohs_n_s    : std_logic;

    constant vref_c           : std_logic_vector(  7 downto 0 ) := x"3b";
    constant cent_c           : std_logic_vector(  7 downto 0 ) := x"80";

    type typtable_t is array (0 to 31) of std_logic_vector(7 downto 0);
    constant table : typtable_t :=(
        x"00", x"fa", x"0c", x"ee", x"18", x"e7", x"18", x"e7",
        x"18", x"e7", x"18", x"e7", x"18", x"e7", x"18", x"e7",
        x"18", x"e7", x"18", x"ee", x"0c", x"fa", x"00", x"00",
        x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"
    );

begin

    videoY_o <= videoY_s;
    videoC_o <= videoC_s;
    videoV_o <= videoV_s;

    --  Y = +0.299R +0.587G +0.114B
    -- +U = +0.615R -0.518G -0.097B (  0)
    -- +V = +0.179R -0.510G +0.331B ( 60)
    -- +W = -0.435R +0.007G +0.428B (120)
    -- -U = -0.615R +0.518G +0.097B (180)
    -- -V = -0.179R +0.510G -0.331B (240)
    -- -W = +0.435R -0.007G -0.428B (300)

    y_s <=  (('0' & y1_s(11 downto 5)) + (('0' & y2_s(11 downto 5)) + ('0' & y3_s(11 downto 5))) + vref_c);

    v_s <=  y_s(7 downto 0)   + c0_s(7 downto 0) when seq_s = "110" else   --  +u
            y_s(7 downto 0)   + c0_s(7 downto 0) when seq_s = "101" else   --  +v
            y_s(7 downto 0)   + c0_s(7 downto 0) when seq_s = "100" else   --  +w
            y_s(7 downto 0)   - c0_s(7 downto 0) when seq_s = "010" else   --  -u
            y_s(7 downto 0)   - c0_s(7 downto 0) when seq_s = "001" else   --  -v
            y_s(7 downto 0)   - c0_s(7 downto 0);                          --  -w

    c_s <=  cent_c            + c0_s(7 downto 0) when seq_s = "110" else   --  +u
            cent_c            + c0_s(7 downto 0) when seq_s = "101" else   --  +v
            cent_c            + c0_s(7 downto 0) when seq_s = "100" else   --  +w
            cent_c            - c0_s(7 downto 0) when seq_s = "010" else   --  -u
            cent_c            - c0_s(7 downto 0) when seq_s = "001" else   --  -v
            cent_c            - c0_s(7 downto 0);                          --  -w


    c0_s <= (x"00" + ('0' & u1_s(11 downto 5)) - ('0' & u2_s(11 downto 5)) - ('0' & u3_s(11 downto 5))) when seq_s(1) = '1' else
            (x"00" + ('0' & v1_s(11 downto 5)) - ('0' & v2_s(11 downto 5)) + ('0' & v3_s(11 downto 5))) when seq_s(0) = '1' else
            (x"00" - ('0' & w1_s(11 downto 5)) + ('0' & w2_s(11 downto 5)) + ('0' & w3_s(11 downto 5)));

    y1_s <= (x"18" * ivideor_s); -- hex(0.299*(2*0.714*256/3.3)*0.72*16) = $17.d
    y2_s <= (x"2f" * ivideog_s); -- hex(0.587*(2*0.714*256/3.3)*0.72*16) = $2e.d
    y3_s <= (x"09" * ivideob_s); -- hex(0.114*(2*0.714*256/3.3)*0.72*16) = $09.1

    u1_s <= (x"32" * ivideor_s); -- hex(0.615*(2*0.714*256/3.3)*0.72*16) = $31.0
    u2_s <= (x"29" * ivideog_s); -- hex(0.518*(2*0.714*256/3.3)*0.72*16) = $29.5
    u3_s <= (x"08" * ivideob_s); -- hex(0.097*(2*0.714*256/3.3)*0.72*16) = $07.b

    v1_s <= (x"0f" * ivideor_s); -- hex(0.179*(2*0.714*256/3.3)*0.72*16) = $0e.4
    v2_s <= (x"28" * ivideog_s); -- hex(0.510*(2*0.714*256/3.3)*0.72*16) = $28.a
    v3_s <= (x"1a" * ivideob_s); -- hex(0.331*(2*0.714*256/3.3)*0.72*16) = $1a.6

    w1_s <= (x"24" * ivideor_s); -- hex(0.435*(2*0.714*256/3.3)*0.72*16) = $22.b
    w2_s <= (x"01" * ivideog_s); -- hex(0.007*(2*0.714*256/3.3)*0.72*16) = $00.8
    w3_s <= (x"22" * ivideob_s); -- hex(0.428*(2*0.714*256/3.3)*0.72*16) = $22.2

    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            ivideovs_n_s <= videovs_n_i;
            ivideohs_n_s <= videohs_n_i;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- clock phase : 3.58mhz(1fsc) = 21.48mhz(6fsc) / 6
    -- seq_s : (7) 654 (3) 210
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if videohs_n_i = '0' and ivideohs_n_s = '1' then
                seq_s <= "110";
            elsif( seq_s(1 downto 0) = "00" )then
                seq_s <= seq_s - 2;
            else
                seq_s <= seq_s - 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- horizontal counter : msx_x=0[hcounter_s=100h], msx_x=511[hcounter_s=4ff]
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if videohs_n_i = '0' and ivideohs_n_s = '1' then
                hcounter_s <= x"000";
            else
                hcounter_s <= hcounter_s + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- vertical counter : msx_y=0[vcounter_s=22h], msx_y=211[vcounter_s=f5h]
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if videovs_n_i = '1' and ivideovs_n_s = '0' then
                vcounter_s <= (others => '0');
                burphase_s <= '0';
            elsif videohs_n_i = '0' and ivideohs_n_s = '1' then
                vcounter_s <= vcounter_s + 1;
                burphase_s <= burphase_s xor (not hcounter_s(1)); -- hcounter_s:1364/1367
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- vertical display window
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if vcounter_s = (x"22" - x"10" - 1) then
                window_v_s <= '1';
            elsif(  ((vcounter_s = 262-7) and (pal_mode_s = '0')) or
                    ((vcounter_s = 312-7) and (pal_mode_s = '1')) )then
                window_v_s <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- horizontal display window
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if( hcounter_s = (x"100" - x"030" - 1) )then
                window_h_s <= '1';
            elsif( hcounter_s = (x"4ff" + x"030" - 1) )then
                window_h_s <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- color burst window
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if( (window_v_s = '0') or (hcounter_s = x"0cc") )then
                window_c_s <= '0';
            elsif( window_v_s = '1' and (hcounter_s = x"06c") )then
                window_c_s <= '1';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- color burst table pointer
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if( window_c_s = '0' )then
                tableadr_s <= (others => '0');
            elsif( seq_s = "101" or seq_s = "001" )then
                tableadr_s <= tableadr_s + 1;
            end if;
        end if;
    end process;

    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            tabledat_s <= table(conv_integer(tableadr_s));
        end if;
    end process;

    --------------------------------------------------------------------------
    -- video encode
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if (videovs_n_i xor videohs_n_i) = '1' then
                videoY_s <= (others => '0');
                videoC_s <= cent_c(7 downto 2);
                videoV_s <= (others => '0');
            elsif window_v_s = '1' and window_h_s = '1' then
                videoY_s <= y_s(7 downto 2);
                videoC_s <= c_s(7 downto 2);
                videoV_s <= v_s(7 downto 2);
            else
                videoY_s <= vref_c(7 downto 2);
                if seq_s(1 downto 0) = "10" then
                    videoC_s <= cent_c(7 downto 2);
                    videoV_s <= vref_c(7 downto 2);
                elsif burphase_s = '1' then
                    videoC_s <= cent_c(7 downto 2) + tabledat_s(7 downto 2);
                    videoV_s <= vref_c(7 downto 2) + tabledat_s(7 downto 2);
                else
                    videoC_s <= cent_c(7 downto 2) - tabledat_s(7 downto 2);
                    videoV_s <= vref_c(7 downto 2) - tabledat_s(7 downto 2);
                end if;
            end if;
        end if;
    end process;

    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if (videovs_n_i xor videohs_n_i) = '1' then
                -- hold
            elsif window_v_s = '1' and window_h_s = '1' then
                if hcounter_s(0) = '0' then
                    ivideor_s <= videoR_i;
                    ivideog_s <= videoG_i;
                    ivideob_s <= videoB_i;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- pal auto detection
    --------------------------------------------------------------------------
    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if    videovs_n_i = '1' and ivideovs_n_s = '0' then
                pal_det_cnt_s <= (others => '0');
            elsif videohs_n_i = '0' and ivideohs_n_s = '1' then
                pal_det_cnt_s <= pal_det_cnt_s + 1;
            end if;
        end if;
    end process;

    process( clk21m_i )
    begin
        if rising_edge(clk21m_i) then
            if videovs_n_i = '1' and ivideovs_n_s = '0' then
                if pal_det_cnt_s > 300 then
                    pal_mode_s <= '1';
                else
                    pal_mode_s <= '0';
                end if;
            end if;
        end if;
    end process;
end rtl;
