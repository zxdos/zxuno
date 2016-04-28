-- TV Interface Adapter (TIA)
-- Copyright 2006, 2010 Retromaster
--
--  This file is part of A2601.
--
--  A2601 is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License,
--  or any later version.
--
--  A2601 is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with A2601.  If not, see <http://www.gnu.org/licenses/>.
--

library ieee;
use ieee.std_logic_1164.all;       

entity lfsr6 is
   port(clk: in std_logic;
          prst: in std_logic;
          cnt: in std_logic;
          o: out std_logic_vector(5 downto 0)
       );
end lfsr6;

architecture arch of lfsr6 is 
    
    signal d: std_logic_vector(5 downto 0);
    signal prst_l: std_logic := '1';

begin

    o <= d;

    process(clk, prst)  
    begin           
        
        if (clk'event and clk = '1') then           
            if (prst = '1' and prst_l = '0') then 
                prst_l <= '1'; 
            elsif (cnt = '1') then                      
                prst_l <= '0';      
            end if;             
        end if;             
        
        if (clk'event and clk = '1') then           
            if (cnt = '1') then
                if (prst_l = '1') then 
                    d <= "000000";                                      
                else 
                    d <= (d(0) xnor d(1)) & d(5 downto 1);
                end if;                             
            end if;
        end if;
        
    end process;

end arch;

library ieee;
use ieee.std_logic_1164.all;       

entity cntr2 is
   port(clk: in std_logic;
          rst: in std_logic;    
          en: in std_logic;       
          o: out std_logic_vector(1 downto 0)
       );
end cntr2;

architecture arch of cntr2 is 
    
    signal d: std_logic_vector(1 downto 0) := "00";
    
begin

    o <= d;

    process(clk, rst)
    begin
--      if (rst = '1') then 
--          d <= "00";
        if (clk'event and clk = '1') then       
            if (rst = '1') then 
                d <= "00";
            elsif (en = '1') then 
                case d is 
                    when "00" => d <= "10";
                    when "10" => d <= "11";                                             
                    when "11" => d <= "01";
                    when "01" => d <= "00";
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
end arch;

library ieee;
use ieee.std_logic_1164.all;       
use ieee.numeric_std.all;

entity cntr3 is
   port(clk: in std_logic;  
          rst: in std_logic;    
          en: in std_logic;
          o: out std_logic_vector(2 downto 0)
       );
end cntr3;

architecture arch of cntr3 is 
    
    signal d: unsigned(2 downto 0) := "000";
    
begin

    o <= std_logic_vector(d);
    
    process(clk, rst)
    begin       
        if (clk'event and clk = '1') then
            if (rst = '1') then 
                d <= "000";
            elsif (en = '1') then           
                d <= d + 1;
            end if;
        end if;
    end process;
    
end arch;

library ieee;
use ieee.std_logic_1164.all;       
use ieee.numeric_std.all;

use work.TIA_common.all;

entity audio is 
    port(clk: in std_logic;       
          cnt: in std_logic;
          freq: in std_logic_vector(4 downto 0);
          ctrl: in std_logic_vector(3 downto 0);
          ao: out std_logic
         );
end audio;

architecture arch of audio is 
    
    signal dvdr: unsigned(4 downto 0) := "00000";
    signal sr4: std_logic_vector(3 downto 0) := "0000";
    signal sr5: std_logic_vector(4 downto 0) := "00000";
    signal sr5_tap: std_logic;
    signal sr4_in: std_logic;   
    signal sr5_in: std_logic;       
    signal sr4_cnt: std_logic;  
    signal sr5_cnt: std_logic;      
    
begin

    process(clk)
    begin 
        if (clk'event and clk = '1') then           
            if (cnt = '1') then                 
                if (sr4_cnt = '1') then 
                    sr4 <= sr4_in & sr4(3 downto 1);
                end if;
                if (sr5_cnt = '1') then 
                    sr5 <= sr5_in & sr5(4 downto 1);
                end if;             
                if (dvdr = unsigned(freq)) then 
                    dvdr <= "00000";
                else 
                    dvdr <= dvdr + 1;
                end if;
            end if;
        end if;                     
    end process;    
    
    sr5_in <= '1' when 
        (ctrl = "0000") or 
        (sr5_tap = '1') or      
        (sr5 = "00000" and (ctrl(0) = '1' or ctrl(1) = '1' or sr4 = "1111"))
        else '0';
        
    sr4_in <= '1' when 
        (ctrl = "0000") or 
        (ctrl(3 downto 2) = "00" and (sr4 = "1111" or ((sr4(1) xnor sr4(0)) = '1'))) or
        (ctrl(3 downto 2) = "11" and (sr4(3 downto 1) = "101" or sr4(1) = '0')) or
        (ctrl(3 downto 2) = "01" and sr4(3) = '0') or
        (ctrl(3 downto 2) = "10" and sr5(0) = '1') 
        else '0';
    
    sr5_tap <= sr5(0) xor sr4(0) when (ctrl(1 downto 0) = "00") else sr5(0) xor sr5(3);             
    
    sr5_cnt <= '1' when (dvdr = unsigned(freq)) else '0';  -- CHECKME
        
    sr4_cnt <= '1' when 
        (dvdr = unsigned(freq) and (
            (ctrl(1 downto 0) = "10" and sr5(4 downto 1) = "0001") or 
            (ctrl(1 downto 0) = "11" and sr5(0) = '1')  or
            (ctrl(1) = '0')))
        else '0';
        
    ao <= sr4(0);

end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity player is
   port(clk: in std_logic;
          prst: in std_logic;
          count: in std_logic;
          nusiz: in std_logic_vector(2 downto 0);
          reflect: in std_logic;
          grpnew: in std_logic_vector(7 downto 0);
          grpold: in std_logic_vector(7 downto 0);
          vdel: in std_logic;
          pix: out std_logic
       );
end player;

architecture arch of player is 

    component cntr2 is
        port(clk: in std_logic;
              rst: in std_logic;
              en: in std_logic;
              o: out std_logic_vector(1 downto 0)
             );
    end component;

    component cntr3 is
        port(clk: in std_logic;
             rst: in std_logic;
              en: in std_logic;
              o: out std_logic_vector(2 downto 0)
             );
    end component;
    
    component lfsr6 is
        port(clk: in std_logic;
              prst: in std_logic;
              cnt: in std_logic;
              o: out std_logic_vector(5 downto 0)
             );
    end component;

    signal lfsr_out: std_logic_vector(5 downto 0);
    signal lfsr_rst: std_logic;
    signal lfsr_cnt: std_logic;

    signal cntr_out: std_logic_vector(1 downto 0);
    signal cntr_rst: std_logic;
    signal cntr_en: std_logic;
    
    signal scan_out: std_logic_vector(2 downto 0);
    signal scan_clk: std_logic := '0';
    signal scan_en: std_logic := '0';   
    signal scan_cnt: std_logic;
        
    signal start: std_logic := '0';

    signal scan_adr: std_logic_vector(2 downto 0);
    
    signal pix_sel: std_logic_vector(1 downto 0);

    signal ph0: std_logic;
    signal ph1: std_logic;
    signal ph1_edge: std_logic;

begin

    lfsr: lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
    cntr: cntr2 port map(clk, cntr_rst, cntr_en, cntr_out);
    scan: cntr3 port map(clk, '0', scan_cnt, scan_out); 

    ph0 <= '1' when (cntr_out = "00") else '0';
    ph1_edge <= '1' when (cntr_out = "10") else '0';
    ph1 <= '1' when (cntr_out = "11") else '0';

    cntr_rst <= prst;
    cntr_en <= count;

    lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';
    lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';

    process(clk, count)
    begin
        if (clk'event and clk = '1' and count = '1') then
            if (ph1_edge = '1') then
                if (lfsr_out = "101101") or
                    ((lfsr_out = "111000") and ((nusiz = "001") or (nusiz = "011"))) or
                    ((lfsr_out = "101111") and ((nusiz = "011") or (nusiz = "010") or (nusiz = "110"))) or
                    ((lfsr_out = "111001") and ((nusiz = "100") or (nusiz = "110"))) then
                    start <= '1';
                else
                    start <= '0';
                end if;
            end if;
        end if;
    end process;

    process(clk, scan_clk, start, scan_out, count)
    begin
        if (clk'event and clk = '1' and count = '1') then
            if (scan_clk = '1') then
                if (start = '1') then
                    scan_en <= '1';
                elsif (scan_out = "111") then
                    scan_en <= '0';
                end if;
            end if;
        end if;
    end process;

    process (clk, ph0, ph1, count)
    begin
        if (clk'event and clk = '1' and count = '1') then
            if (nusiz = "111") then
                scan_clk <= ph1;
            elsif (nusiz = "101") then
                scan_clk <= ph0 or ph1;
            else
                scan_clk <= '1';
            end if;
        end if;
    end process;

    scan_adr <= scan_out when reflect = '1' else not scan_out;

    scan_cnt <= scan_en and scan_clk and count;

    pix_sel <= scan_en & vdel;
    with pix_sel select pix <=
        grpnew(to_integer(unsigned(scan_adr))) when "10",
        grpold(to_integer(unsigned(scan_adr))) when "11",
        '0' when others;

end arch;

library ieee;
use ieee.std_logic_1164.all;       

entity missile is
   port(clk: in std_logic;
          prst: in std_logic;       
          count: in std_logic;        
          enable: in std_logic;
          nusiz: in std_logic_vector(2 downto 0);
          size: in std_logic_vector(1 downto 0);
          pix: out std_logic
       );
end missile;

architecture arch of missile is 

    component cntr2 is
        port(clk: in std_logic;
              rst: in std_logic;
              en: in std_logic;           
              o: out std_logic_vector(1 downto 0)
             );
    end component;

    component lfsr6 is
        port(clk: in std_logic;
              prst: in std_logic;
              cnt: in std_logic;
              o: out std_logic_vector(5 downto 0)
             );
    end component;
    
    signal lfsr_out: std_logic_vector(5 downto 0);
    signal lfsr_rst: std_logic;
    signal lfsr_cnt: std_logic;
    
    signal cntr_out: std_logic_vector(1 downto 0);
    signal cntr_rst: std_logic;
    signal cntr_en: std_logic;
    
    signal start1: std_logic := '0';    
    signal start2: std_logic := '0';
        
    signal ph1: std_logic;
    signal ph1_edge: std_logic;
    
begin

    lfsr: lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
    cntr: cntr2 port map(clk, cntr_rst, cntr_en, cntr_out); 
        
    ph1_edge <= '1' when (cntr_out = "10") else '0';
    ph1 <= '1' when (cntr_out = "11") else '0';
    
    cntr_rst <= prst;
    cntr_en <= count;
    
    lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';       
    lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';
    
    process(clk)
    begin 
        if (clk'event and clk = '1') then                       
            if (ph1_edge = '1') then            
                if (lfsr_out = "101101") or
                    ((lfsr_out = "111000") and ((nusiz = "001") or (nusiz = "011"))) or 
                    ((lfsr_out = "101111") and ((nusiz = "011") or (nusiz = "010") or (nusiz = "110"))) or 
                    ((lfsr_out = "111001") and ((nusiz = "100") or (nusiz = "110"))) then                   
                    start1 <= '1';                  
                else 
                    start1 <= '0';
                end if;

                start2 <= start1;
            end if;
        end if;
    end process;
                            
    pix <= '1' when 
        (enable = '1' and (
            (start1 = '1' and (
                (size(1) = '1') or 
                (ph1 = '1') or 
                (cntr_out(0) = '1' and size(0) = '1'))) or
            (start2 = '1' and size = "11")))                            
        else '0';
            
end arch;

-- XYZ
library ieee;
use ieee.std_logic_1164.all;       
use ieee.numeric_std.all;

entity paddle is
   port(clk: in std_logic;
        value: in std_logic_vector(7 downto 0);
        rst: in std_logic;       
        o: out std_logic
     );
end paddle;

architecture arch of paddle is 
begin
	process(clk, rst)
		variable cnt: integer range 0 to 190;
	begin 
		if( rst = '1' ) then
			-- map -128..127 -> 190..0
			cnt := to_integer(96 + signed(value)/2 + signed(value)/4);
	   elsif (clk'event and clk = '1') then
			if(cnt /= 190) then
				cnt := cnt + 1;
			end if;
      end if;

		-- return 1 if counter has "discharged"
		if(cnt = 190) then
			o <= '1';
		else
			o <= '0';
		end if;
	end process;
end arch;

library ieee;
use ieee.std_logic_1164.all;       

entity ball is
   port(clk: in std_logic;        
          prst: in std_logic;
          count: in std_logic;        
          ennew: in std_logic;
          enold: in std_logic;
          vdel: in std_logic;
          size: in std_logic_vector(1 downto 0);
          pix: out std_logic
       );
end ball;

architecture arch of ball is 

    component cntr2 is
        port(clk: in std_logic;
              rst: in std_logic;
              en: in std_logic;           
              o: out std_logic_vector(1 downto 0)
             );
    end component;

    component lfsr6 is
        port(clk: in std_logic;           
              prst: in std_logic;
              cnt: in std_logic;
              o: out std_logic_vector(5 downto 0)
             );
    end component;
    
    signal lfsr_out: std_logic_vector(5 downto 0);
    signal lfsr_rst: std_logic;
    signal lfsr_cnt: std_logic;
    
    signal cntr_out: std_logic_vector(1 downto 0);
    signal cntr_rst: std_logic;
    signal cntr_en: std_logic;          
    
    signal start1: std_logic := '0';    
    signal start2: std_logic := '0';
    

    signal ph1: std_logic;
    signal ph1_edge: std_logic;
    
begin

    lfsr: lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
    cntr: cntr2 port map(clk, cntr_rst, cntr_en, cntr_out);
    
    ph1_edge <= '1' when (cntr_out = "10") else '0';
    ph1 <= '1' when (cntr_out = "11") else '0';
    
    cntr_rst <= prst;
    cntr_en <= count;
    
    lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';       
    lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';
    
    process(clk)
    begin 
        if (clk'event and clk = '1') then           
            if (ph1_edge = '1') then            
                if (lfsr_out = "101101") or (prst = '1') then
                    start1 <= '1';                  
                else 
                    start1 <= '0';
                end if;
                
                start2 <= start1;
            end if;
        end if;
    end process;            
                
    pix <= '1' when 
        ((ennew = '1' and vdel = '0') or (enold = '1' and vdel = '1')) and (
            (start1 = '1' and (
                (size(1) = '1') or 
                (ph1 = '1') or 
                (cntr_out(0) = '1' and size(0) = '1'))) or
            (start2 = '1' and size = "11"))                         
        else '0';                                               

end arch;

library ieee;
use ieee.std_logic_1164.all;       

entity mux20 is 
    port(i: in std_logic_vector(19 downto 0);
          a: in std_logic_vector(4 downto 0);
          o: out std_logic
         );
end mux20; 

architecture arch of mux20 is 
begin
    with a select o <=
        i(0) when "00000",
        i(1) when "00001",
        i(2) when "00010",
        i(3) when "00011",
        i(11) when "00100",
        i(10) when "00101",
        i(9) when "00110",
        i(8) when "00111",
        i(7) when "01000",
        i(6) when "01001",
        i(5) when "01010",
        i(4) when "01011",
        i(12) when "01100",
        i(13) when "01101",
        i(14) when "01110",
        i(15) when "01111",
        i(16) when "10000",
        i(17) when "10001",
        i(18) when "10010",
        i(19) when "10011",
        '-' when others;            
end arch;

library ieee;
use ieee.std_logic_1164.all;       
use ieee.numeric_std.all;      

use work.TIA_common.all;
use work.TIA_NTSCLookups.all;

entity TIA is
    port(vid_clk: in std_logic;       
         cs: in std_logic;
         r: in std_logic;
         a: in std_logic_vector(5 downto 0);
         d: inout std_logic_vector(7 downto 0);
         colu: out std_logic_vector(6 downto 0);
         csyn: out std_logic;
         hsyn: out std_logic;
         vsyn: out std_logic;
         rgbx2: out std_logic_vector(23 downto 0);
         cv: out std_logic_vector(7 downto 0) := "00000000";
         rdy: out std_logic;
         ph0: out std_logic;
         ph1: out std_logic;
         au0: out std_logic;
         au1: out std_logic;
         av0: out std_logic_vector(3 downto 0);
         av1: out std_logic_vector(3 downto 0);
         paddle_0: in std_logic_vector(7 downto 0);
         paddle_1: in std_logic_vector(7 downto 0);
         paddle_2: in std_logic_vector(7 downto 0);
         paddle_3: in std_logic_vector(7 downto 0);
         paddle_ena: in std_logic;
         inpt4: in std_logic;
         inpt5: in std_logic;
         pal: in std_logic := '0'
        );
end TIA;

architecture arch of TIA is

	COMPONENT VGA_SCANDBL
	PORT(
		I : IN std_logic_vector(6 downto 0);
		I_HSYNC : IN std_logic;
		I_VSYNC : IN std_logic;
		CLK : IN std_logic;
		CLK_X2 : IN std_logic;          
		O : OUT std_logic_vector(6 downto 0);
		O_HSYNC : OUT std_logic;
		O_VSYNC : OUT std_logic
		);
	END COMPONENT;	
	
	COMPONENT VGAColorTable
	PORT(
		clk : IN std_logic;
		lum : IN std_logic_vector(3 downto 0);
		hue : IN std_logic_vector(3 downto 0);
		mode : IN std_logic_vector(1 downto 0);          
		outColor : OUT std_logic_vector(23 downto 0)
		);
	END COMPONENT;	

    component cntr2 is
        port(clk: in std_logic;
             rst: in std_logic;
             en: in std_logic;
             o: out std_logic_vector(1 downto 0)
            );
    end component;

    component lfsr6 is
        port(clk: in std_logic;
              prst: in std_logic;
              cnt: in std_logic;
              o: out std_logic_vector(5 downto 0)
             );
    end component;

    component audio is
        port(clk: in std_logic;
             cnt: in std_logic;
             freq: in std_logic_vector(4 downto 0);
             ctrl: in std_logic_vector(3 downto 0);
             ao: out std_logic
            );
    end component;

    component player is
        port(clk: in std_logic;
             prst: in std_logic;
             count: in std_logic;
             nusiz: in std_logic_vector(2 downto 0);
             reflect: in std_logic;
             grpnew: in std_logic_vector(7 downto 0);
             grpold: in std_logic_vector(7 downto 0);
             vdel: in std_logic;
             pix: out std_logic
            );
    end component;

    component missile is
        port(clk: in std_logic;
              prst: in std_logic;
              count: in std_logic;
              enable: in std_logic;
              nusiz: in std_logic_vector(2 downto 0);
              size: in std_logic_vector(1 downto 0);
              pix: out std_logic
             );
    end component;

    component ball is
        port(clk: in std_logic;
             prst: in std_logic;
             count: in std_logic;
             ennew: in std_logic;
             enold: in std_logic;
             vdel: in std_logic;
             size: in std_logic_vector(1 downto 0);
             pix: out std_logic
            );
    end component;

    component mux20 is
        port(i: in std_logic_vector(19 downto 0);
             a: in std_logic_vector(4 downto 0);
             o: out std_logic
            );
    end component;

	 component paddle is
			port(clk: in std_logic;
				  value: in std_logic_vector(7 downto 0);
				  rst: in std_logic;       
				  o: out std_logic
			);
    end component;

    signal h_lfsr_out: std_logic_vector(5 downto 0);
    signal h_lfsr_rst: std_logic;
    signal h_lfsr_cnt: std_logic;

    signal h_cntr_out: std_logic_vector(1 downto 0);
    signal h_cntr_rst: std_logic;

    signal hsync: std_logic := '0';
    signal cburst: std_logic := '0';
    signal hblank: std_logic := '1';
    signal hmove: std_logic := '0';
    signal hmove_set: std_logic;
    signal hmove_cntr: unsigned(3 downto 0) := "1111";
    signal hmove_cntr_sl: std_logic_vector(3 downto 0);

    signal p0_rst: std_logic;
    signal p0_nusiz: std_logic_vector(2 downto 0) := "000";
    signal p0_reflect: std_logic;
    signal p0_grpnew: std_logic_vector(7 downto 0);
    signal p0_grpold: std_logic_vector(7 downto 0);
    signal p0_vdel: std_logic := '0';
    signal p0_pix: std_logic;
    signal p0_colu: std_logic_vector(6 downto 0) := "0000000";
    signal p0_hmove: std_logic_vector(3 downto 0);
    signal p0_count: std_logic;
    signal p0_ec: std_logic := '0';

    signal p1_rst: std_logic;
    signal p1_nusiz: std_logic_vector(2 downto 0) := "000";
    signal p1_reflect: std_logic;
    signal p1_grpnew: std_logic_vector(7 downto 0);
    signal p1_grpold: std_logic_vector(7 downto 0);
    signal p1_vdel: std_logic := '0';
    signal p1_pix: std_logic;
    signal p1_colu: std_logic_vector(6 downto 0) := "0000000";
    signal p1_hmove: std_logic_vector(3 downto 0);
    signal p1_count: std_logic;
    signal p1_ec: std_logic := '0';

    signal m0_rst: std_logic;
    signal m0_enable: std_logic;
    signal m0_size: std_logic_vector(1 downto 0) := "00";
    signal m0_pix: std_logic;
    signal m0_hmove: std_logic_vector(3 downto 0);
    signal m0_count: std_logic;
    signal m0_ec: std_logic := '0';

    signal m1_rst: std_logic;
    signal m1_enable: std_logic;
    signal m1_size: std_logic_vector(1 downto 0) := "00";
    signal m1_pix: std_logic;
    signal m1_hmove: std_logic_vector(3 downto 0);
    signal m1_count: std_logic;
    signal m1_ec: std_logic := '0';

    signal bl_rst: std_logic;
    signal bl_ennew: std_logic;
    signal bl_enold: std_logic;
    signal bl_vdel: std_logic := '0';
    signal bl_size: std_logic_vector(1 downto 0);
    signal bl_pix: std_logic;
    signal bl_hmove: std_logic_vector(3 downto 0);
    signal bl_count: std_logic;
    signal bl_ec: std_logic := '0';

    signal pf_gr: std_logic_vector(19 downto 0);
    signal pf_adr: unsigned(4 downto 0) := "00000";
    signal pf_pix: std_logic;
    signal pf_mux_out: std_logic;
    signal pf_reflect: std_logic;
    signal pf_score: std_logic;
    signal pf_priority: std_logic := '0';
    signal pf_colu: std_logic_vector(6 downto 0) := "0000000";

    signal bk_colu: std_logic_vector(6 downto 0) := "0000000";

    signal a0_freq: std_logic_vector(4 downto 0);
    signal a0_ctrl: std_logic_vector(3 downto 0);
    signal a0_vol: std_logic_vector(3 downto 0) := "0000";

    signal a1_freq: std_logic_vector(4 downto 0);
    signal a1_ctrl: std_logic_vector(3 downto 0);
    signal a1_vol: std_logic_vector(3 downto 0) := "0000";

    signal wsync: std_logic := '0';

    signal vsync: std_logic := '0';
    signal vblank: std_logic := '0';
    signal center: std_logic := '0';
    signal pf_cnt: std_logic := '0';

    signal cx: std_logic_vector(14 downto 0) := "000000000000000";
    signal cx_clr: std_logic;

    signal clk_dvdr: std_logic_vector(1 downto 0) := "01";
    signal phi0: std_logic := '0';
    signal phi1: std_logic := '1';

    signal inpt45_len: std_logic := '0';
    signal inpt45_rst: std_logic;
    signal inpt4_l: std_logic := '1';
    signal inpt5_l: std_logic := '1';

    signal au_cnt: std_logic;

    signal sec_dl: std_logic_vector(1 downto 0) := "00";
    signal sec: std_logic;

    signal hh0: std_logic;
    signal hh0_edge: std_logic;
    signal hh1: std_logic;
    signal hh1_edge: std_logic;

    signal clk, clkx2: std_logic;

    signal sync: std_logic;
    signal blank: std_logic;

    signal int_colu: std_logic_vector(6 downto 0) := "0000000";
    signal lum_lu: unsigned(7 downto 0);
    signal col_lut_idx: std_logic_vector(7 downto 0);
    signal col_lu: unsigned(7 downto 0);

    signal vid_clk_dvdr: unsigned(3 downto 0) := "0000";
	 
	  signal vga_colu: std_logic_vector(6 downto 0);

     signal inpt03_chg: std_logic;
	  signal inpt0: std_logic;
	  signal inpt1: std_logic;
	  signal inpt2: std_logic;
	  signal inpt3: std_logic;

begin
    paddle0: paddle port map(hsync, paddle_0, inpt03_chg, inpt0);
    paddle1: paddle port map(hsync, paddle_1, inpt03_chg, inpt1);
    paddle2: paddle port map(hsync, paddle_2, inpt03_chg, inpt2);
    paddle3: paddle port map(hsync, paddle_3, inpt03_chg, inpt3);

    h_cntr: cntr2 port map(clk, h_cntr_rst, '1', h_cntr_out);
    lfsr: lfsr6 port map(clk, h_lfsr_rst, h_lfsr_cnt, h_lfsr_out);
    pf_mux: mux20 port map(pf_gr, std_logic_vector(pf_adr), pf_mux_out);

    hh0_edge <= '1' when (h_cntr_out = "01") else '0';
    hh0 <= '1' when (h_cntr_out = "00") else '0';
    hh1_edge <= '1' when (h_cntr_out = "10") else '0';
    hh1 <= '1' when (h_cntr_out = "11") else '0';

    aud0: audio port map(clk, au_cnt, a0_freq, a0_ctrl, au0);
    aud1: audio port map(clk, au_cnt, a1_freq, a1_ctrl, au1);

    av0 <= a0_vol;
    av1 <= a1_vol;

    au_cnt <= '1' when (h_lfsr_out = "110111" or h_lfsr_out = "101100") and (h_lfsr_cnt = '1') else '0';

    h_lfsr_rst <= '1' when (h_lfsr_out = "010100") else '0';
    h_lfsr_cnt <= '1' when (hh1_edge = '1') else '0';
    h_cntr_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RSYNC) else '0';

    h_decode: process(clk, h_lfsr_out)
    begin
        if (clk'event and clk = '1') then
            if (hh1_edge = '1') then
                case h_lfsr_out is
                    when "111100" =>
                        hsync <= '1';
                    when "110111" =>
                        hsync <= '0';
                        cburst <= '1';
                    when "001111" =>
                        cburst <= '0';
                    when "111001" =>
                        pf_cnt <= '1';
                    when "011100" =>
                        hblank <= hmove;
                    when "010111" =>
                        hblank <= '0';
                    when "101001" =>
                        center <= '0';
                    when "010100" =>
                        hblank <= '1';
                        pf_cnt <= '0';
                    when "011000" =>
                        center <= '1';
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if (clk'event and clk = '1') then
            if (h_lfsr_out = "010111") and (hh1_edge = '1') then
                hmove <= '0';
            elsif (hmove_set = '1') then
                hmove <= '1';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if (clk'event and clk = '1') then
            if (h_lfsr_out = "000000" and hh1_edge = '1') then
                wsync <= '0';
            elsif (r = '0') and (cs = '1') and (a = A_WSYNC) then
                wsync <= '1';
            end if;
        end if;
    end process;

    csyn <= (vsync nand hsync) and (vsync or hsync);
--    vsyn <= vsync;
--    hsyn <= hsync;

    rdy <= '0' when (wsync = '1') else '1';

    p0: player
        port map(clk, p0_rst, p0_count, p0_nusiz, p0_reflect,
                    p0_grpnew, p0_grpold, p0_vdel, p0_pix);

    p1: player
        port map(clk, p1_rst, p1_count, p1_nusiz, p1_reflect,
                    p1_grpnew, p1_grpold, p1_vdel, p1_pix);

    m0: missile
        port map(clk, m0_rst, m0_count, m0_enable, p0_nusiz, m0_size, m0_pix);

    m1: missile
        port map(clk, m1_rst, m1_count, m1_enable, p1_nusiz, m1_size, m1_pix);

    bl: ball
        port map(clk, bl_rst, bl_count, bl_ennew, bl_enold, bl_vdel, bl_size, bl_pix);

    pf_output: process(clk, h_lfsr_cnt)
    begin
        if (clk'event and clk = '1') then
            if (h_lfsr_cnt = '1') then
                if (pf_cnt = '1') then
                    if (pf_adr = "10011") and (center = '0') and (pf_reflect = '0') then
                        pf_adr <= "00000";
                    elsif (pf_reflect = '1') and (center = '1') and not (pf_adr = "00000") then
                        pf_adr <= pf_adr - 1;
                    elsif not (pf_adr = "10011") then
                        pf_adr <= pf_adr + 1;
                    end if;
                else
                    pf_adr <= "00000";
                end if;

                pf_pix <= pf_mux_out;
            end if;
        end if;
    end process;

    p0_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RESP0) and (phi0 = '0') else '0';
    p1_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RESP1) and (phi0 = '0') else '0';
    m0_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RESM0) and (phi0 = '0') else '0';
    m1_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RESM1) and (phi0 = '0') else '0';
    bl_rst <= '1' when (r = '0') and (cs = '1') and (a = A_RESBL) and (phi0 = '0') else '0';

    p0_count <= '1' when (hblank = '0') or (p0_ec = '1' and hh0 = '1') else '0';
    p1_count <= '1' when (hblank = '0') or (p1_ec = '1' and hh0 = '1') else '0';
    m0_count <= '1' when (hblank = '0') or (m0_ec = '1' and hh0 = '1') else '0';
    m1_count <= '1' when (hblank = '0') or (m1_ec = '1' and hh0 = '1') else '0';
    bl_count <= '1' when (hblank = '0') or (bl_ec = '1' and hh0 = '1') else '0';

    hmove_set <= '1' when (a = A_HMOVE) and (r = '0') and (cs = '1') else '0';
    cx_clr <= '1' when (a = A_CXCLR) and (r = '0') and (cs = '1') else '0';

    inpt45_rst <= '1' when (a = A_VBLANK) and (r = '0') and (cs = '1') else '0';

    process(clk, phi1, a, d, r, cs, cx, inpt45_len, inpt4_l, inpt4, inpt5_l, inpt5)
    begin
        if (r = '1') and (cs = '1') then
            d(5 downto 0) <= "000000";

            case a(3 downto 0) is
                when A_CXM0P =>
                    d(7 downto 6) <= cx(1 downto 0);
                when A_CXM1P =>
                    d(7 downto 6) <= cx(3 downto 2);
                when A_CXP0FB =>
                    d(7 downto 6) <= cx(5 downto 4);
                when A_CXP1FB =>
                    d(7 downto 6) <= cx(7 downto 6);
                when A_CXM0FB =>
                    d(7 downto 6) <= cx(9 downto 8);
                when A_CXM1FB =>
                    d(7 downto 6) <= cx(11 downto 10);
                when A_CXBLPF =>
                    d(7) <= cx(12);
                    d(6) <= 'Z';
                when A_CXPPMM =>
                    d(7 downto 6) <= cx(14 downto 13);
					 when A_INPT0 =>
						  if(paddle_ena = '1') then
								d(7) <= inpt0;
						  else
						 		d(7) <= '1';
						  end if;
                    d(6) <= '0';
                when A_INPT1 =>
						  if(paddle_ena = '1') then
								d(7) <= inpt1;
						  else
						 		d(7) <= '1';
						  end if;
                    d(6) <= '0';
                when A_INPT2 =>
						  if(paddle_ena = '1') then
								d(7) <= inpt2;
						  else
						 		d(7) <= '1';
						  end if;
                    d(6) <= '0';
                when A_INPT3 =>
						  if(paddle_ena = '1') then
								d(7) <= inpt3;
						  else
						 		d(7) <= '1';
						  end if;
                    d(6) <= '0';
                when A_INPT4 =>
                    if (inpt45_len = '1') then
                        d(7) <= inpt4_l;
                    else
                        d(7) <= inpt4;
                    end if;
                    --d(6) <= 'Z';
                    d(6) <= '0';
                when A_INPT5 =>
                    if (inpt45_len = '1') then
                        d(7) <= inpt5_l;
                    else
                        d(7) <= inpt5;
                    end if;
                    --d(6) <= 'Z';
                    d(6) <= '0';
                when others =>
                    d(7 downto 6) <= "--";
            end case;
        else
            d <= "ZZZZZZZZ";
        end if;

        if (phi1'event and phi1 = '0') then
            if (r = '0') and (cs = '1') then
                case a is
                    when A_VSYNC =>
                        vsync <= d(1);
                    when A_VBLANK =>
                        inpt03_chg <= d(7);
                        inpt45_len <= d(6);
                        vblank <= d(1);
                    when A_PF0 =>
                        pf_gr(3 downto 0) <= d(7 downto 4);
                    when A_PF1 =>
                        pf_gr(11 downto 4) <= d;
                    when A_PF2 =>
                        pf_gr(19 downto 12) <= d;
                    when A_CTRLPF =>
                        pf_reflect <= d(0);
                        pf_score <= d(1);
                        pf_priority <= d(2);
                        bl_size <= d(5 downto 4);
                    when A_NUSIZ0 =>
                        p0_nusiz <= d(2 downto 0);
                        m0_size <= d(5 downto 4);
                    when A_NUSIZ1 =>
                        p1_nusiz <= d(2 downto 0);
                        m1_size <= d(5 downto 4);
                    when A_HMCLR =>
                        p0_hmove <= "0000";
                        p1_hmove <= "0000";
                        m0_hmove <= "0000";
                        m1_hmove <= "0000";
                        bl_hmove <= "0000";
                    when A_HMP0 =>
                        p0_hmove <= d(7 downto 4);
                    when A_HMP1 =>
                        p1_hmove <= d(7 downto 4);
                    when A_HMM0 =>
                        m0_hmove <= d(7 downto 4);
                    when A_HMM1 =>
                        m1_hmove <= d(7 downto 4);
                    when A_HMBL =>
                        bl_hmove <= d(7 downto 4);
                    when A_ENAM0 =>
                        m0_enable <= d(1);
                    when A_ENAM1 =>
                        m1_enable <= d(1);
                    when A_ENABL =>
                        bl_enold <= bl_ennew;
                        bl_ennew <= d(1);
                    when A_GRP0 =>
                        p1_grpold <= p1_grpnew;
                        p0_grpnew <= d;
                    when A_GRP1 =>
                        p0_grpold <= p0_grpnew;
                        p1_grpnew <= d;
                    when A_REFP0 =>
                        p0_reflect <= d(3);
                    when A_REFP1 =>
                        p1_reflect <= d(3);
                    when A_VDELP0 =>
                        p0_vdel <= d(0);
                    when A_VDELP1 =>
                        p1_vdel <= d(0);
                    when A_VDELBL =>
                        bl_vdel <= d(0);
                    when A_COLUP0 =>
                        p0_colu <= d(7 downto 1);
                    when A_COLUP1 =>
                        p1_colu <= d(7 downto 1);
                    when A_COLUPF =>
                        pf_colu <= d(7 downto 1);
                    when A_COLUBK =>
                        bk_colu <= d(7 downto 1);
                    when A_AUDF0 =>
                        a0_freq <= d(4 downto 0);
                    when A_AUDF1 =>
                        a1_freq <= d(4 downto 0);
                    when A_AUDC0 =>
                        a0_ctrl <= d(3 downto 0);
                    when A_AUDC1 =>
                        a1_ctrl <= d(3 downto 0);
                    when A_AUDV0 =>
                        a0_vol <= d(3 downto 0);
                    when A_AUDV1 =>
                        a1_vol <= d(3 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    output: process(
        clk, hblank, pf_priority, p0_pix, p1_pix, m0_pix, m1_pix,
        bl_pix, pf_pix, p0_colu, p1_colu, pf_colu, bk_colu)
    begin
        if (clk = '1' and clk'event) then
            if (hblank = '1' or vblank = '1') then
                int_colu <= "0000000";
            elsif (pf_priority = '0') then
                if (p0_pix = '1' or m0_pix = '1') then
                    int_colu <= p0_colu;
                elsif (p1_pix = '1' or m1_pix = '1') then
                    int_colu <= p1_colu;
                elsif (pf_pix = '1' or bl_pix = '1') then
                    int_colu <= pf_colu;
                else
--                    int_colu <= "0110010";
                    int_colu <= bk_colu;
                end if;
            else
                if (pf_pix = '1' or bl_pix = '1') then
                    int_colu <= pf_colu;
                elsif (p0_pix = '1' or m0_pix = '1') then
                    int_colu <= p0_colu;
                elsif (p1_pix = '1' or m1_pix = '1') then
                    int_colu <= p1_colu;
                else
--                    int_colu <= "0110010";
                    int_colu <= bk_colu;
                end if;
            end if;
        end if;
    end process;

    colu <= int_colu;

    sec_delay: process(clk, r)
    begin
        if (clk'event and clk = '1') then
            if (hmove_set = '1') then
                sec_dl(1) <= '1';
            elsif (sec = '1') then
                sec_dl(1) <= '0';
            end if;

            if (hh0_edge = '1') then
                sec_dl(0) <= sec_dl(1);
            elsif (hh1_edge = '1') then
                sec <= sec_dl(0);
            end if;
        end if;
    end process;

    hmove_cntr_sl <= std_logic_vector(hmove_cntr);

    motion: process(clk, r, hmove_set)
    begin

        if (clk'event and clk = '1') then
            if (hh1_edge = '1') then
                if (sec = '1') then
                    hmove_cntr <= hmove_cntr + 1;
                end if;

                if (p0_hmove(3) /= hmove_cntr(3)) and
                    (p0_hmove(2 downto 0) = hmove_cntr_sl(2 downto 0)) then
                    p0_ec <= '0';
                elsif (sec = '1') then
                    p0_ec <= '1';
                end if;

                if (p1_hmove(3) /= hmove_cntr(3)) and
                    (p1_hmove(2 downto 0) = hmove_cntr_sl(2 downto 0)) then
                    p1_ec <= '0';
                elsif (sec = '1') then
                    p1_ec <= '1';
                end if;

                if (m0_hmove(3) /= hmove_cntr(3)) and
                    (m0_hmove(2 downto 0) = hmove_cntr_sl(2 downto 0)) then
                    m0_ec <= '0';
                elsif (sec = '1') then
                    m0_ec <= '1';
                end if;

                if (m1_hmove(3) /= hmove_cntr(3)) and
                    (m1_hmove(2 downto 0) = hmove_cntr_sl(2 downto 0)) then
                    m1_ec <= '0';
                elsif (sec = '1') then
                    m1_ec <= '1';
                end if;

                if (bl_hmove(3) /= hmove_cntr(3)) and
                    (bl_hmove(2 downto 0) = hmove_cntr_sl(2 downto 0)) then
                    bl_ec <= '0';
                elsif (sec = '1') then
                    bl_ec <= '1';
                end if;

                if not (hmove_cntr = "0000") then
                    hmove_cntr <= hmove_cntr + 1;
                end if;
            end if;
        end if;
    end process;

    collision: process(clk, cx_clr)
    begin
        if (clk'event and clk = '1') then
            if (cx_clr = '1') then
                cx <= "000000000000000";
            else
                if (m0_pix = '1' and p0_pix = '1') then
                    cx(0) <= '1';
                end if;
                if (m0_pix = '1' and p1_pix = '1') then
                    cx(1) <= '1';
                end if;
                if (m1_pix = '1' and p1_pix = '1') then
                    cx(2) <= '1';
                end if;
                if (m1_pix = '1' and p0_pix = '1') then
                    cx(3) <= '1';
                end if;
                if (bl_pix = '1' and p0_pix = '1') then
                    cx(4) <= '1';
                end if;
                if (pf_pix = '1' and p0_pix = '1') then
                    cx(5) <= '1';
                end if;
               if (bl_pix = '1' and p1_pix = '1') then
                    cx(6) <= '1';
                end if;
                if (pf_pix = '1' and p1_pix = '1') then
                    cx(7) <= '1';
                end if;
                if (bl_pix = '1' and m0_pix = '1') then
                    cx(8) <= '1';
                end if;
                if (pf_pix = '1' and m0_pix = '1') then
                    cx(9) <= '1';
                end if;
               if (bl_pix = '1' and m1_pix = '1') then
                    cx(10) <= '1';
                end if;
                if (pf_pix = '1' and m1_pix = '1') then
                    cx(11) <= '1';
                end if;
                if (pf_pix = '1' and bl_pix = '1') then
                    cx(12) <= '1';
                end if;
                if (m0_pix = '1' and m1_pix = '1') then
                    cx(13) <= '1';
                end if;
                if (p0_pix = '1' and p1_pix = '1') then
                    cx(14) <= '1';
                end if;
            end if;
        end if;
    end process;

    ph0 <= phi0;
    ph1 <= phi1;

    process(clk)
    begin
        if (clk'event and clk = '1') then
            if (h_lfsr_out = "010100" and hh1_edge = '1') then
                clk_dvdr <= "01";
                phi0 <= '0';
                phi1 <= '0';
            else
                case clk_dvdr is
                    when "00" =>
                        clk_dvdr <= "01";
                        phi0 <= '0';
                        phi1 <= '1';
                    when "01" =>
                        clk_dvdr <= "11";
                        phi0 <= '0';
                        phi1 <= '0';
                    when "11" =>
                        clk_dvdr <= "00";
                        phi0 <= '1';
                        phi1 <= '1';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    process(clk, inpt45_rst, inpt45_len, inpt4, inpt5)
    begin
        if (clk'event and clk = '1') then
            if (inpt45_rst = '1') then
                inpt4_l <= '1';
                inpt5_l <= '1';
            elsif (inpt45_len = '1') then
                if (inpt4 = '0') then
                    inpt4_l <= '0';
                end if;
                if (inpt5 = '0') then
                    inpt5_l <= '0';
                end if;
            end if;
        end if;
    end process;

    sync <= hsync xor vsync;
    blank <= hblank or vblank;

    process(vid_clk, vid_clk_dvdr)
    begin
        if (vid_clk'event and vid_clk = '1') then
            vid_clk_dvdr <= vid_clk_dvdr + 1;
        end if;
    end process;

    clk <= vid_clk_dvdr(3);
    clkx2 <= vid_clk_dvdr(2);
	 
	Inst_VGA_SCANDBL: VGA_SCANDBL PORT MAP(
		I => int_colu,
		I_HSYNC => hsync,
		I_VSYNC => vsync,
		O => vga_colu,
		O_HSYNC => hsyn,
		O_VSYNC => vsyn,
		CLK => clk,
		CLK_X2 => clkx2
	);	
	
	Inst_VGAColorTable: VGAColorTable PORT MAP(
		clk => clkx2,
		lum => '0' & vga_colu(2 downto 0),
		hue => vga_colu(6 downto 3),
		mode => '0' & pal,	-- 00 = NTSC, 01 = PAL
		outColor => rgbx2
	);	
		
--      O_VIDEO_R(3 downto 1) <= video_r_x2;
--      O_VIDEO_G(3 downto 1) <= video_g_x2;
--      O_VIDEO_B(3 downto 2) <= video_b_x2;	
--      O_HSYNC   <= hsync_x2;
--      O_VSYNC   <= vsyn;		 

    col_lut_idx <=
        "0001" & (not vid_clk_dvdr(3)) & vid_clk_dvdr(2) & vid_clk_dvdr(1) & vid_clk_dvdr(0) when (cburst = '1') else
        int_colu(6 downto 3) & (not vid_clk_dvdr(3)) & vid_clk_dvdr(2) & vid_clk_dvdr(1) & vid_clk_dvdr(0);

    col_lu <= col_lut(to_integer(unsigned(col_lut_idx)));
    lum_lu <= lum_lut(to_integer(unsigned(int_colu(2 downto 0))));

    -- Composite video output
    process(vid_clk)
    begin
        if (vid_clk'event and vid_clk = '1') then
            if (sync = '1') then
                cv <= std_logic_vector(sync_level);
            elsif (cburst = '1') then
                cv <= std_logic_vector(blank_level + col_lu);
            elsif (blank = '1') then
                cv <= std_logic_vector(blank_level);
            else
                cv <= std_logic_vector(lum_lu + col_lu);
            end if;
        end if;
    end process;

end arch;
