library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity spi is
port
 (
  reset       : in std_logic;
  sysclk      : in std_logic;
  cpu_wr      : in std_logic;
  cpu_rd      : in std_logic;
  cpu_cs      : in std_logic;
  cpu_addr    : in std_logic_vector(2 downto 0);
  data_in     : in std_logic_vector(7 downto 0);
  data_out    :out std_logic_vector(7 downto 0);
  buf_full    :out std_logic;
  buf_emty    :out std_logic;
  spi_o       :out std_logic;
  spi_i       : in std_logic;
  sck_out     :out std_logic;
  ss_n        :out std_logic_vector(1 downto 0)
 );
end spi;
architecture b of spi is
 type state_type is (idle,shift,stop);
 signal state             : state_type;
 signal out_reg           : std_logic_vector(7 downto 0):=(others=>'0');
 signal in_reg            : std_logic_vector(7 downto 0):=(others=>'0');
 signal clkdiv_cnt        : std_logic_vector(3 downto 0):=(others=>'0');
 signal bit_cnt           : std_logic_vector(2 downto 0):=(others=>'0');
 signal empty_s           : std_logic;
 signal full_s            : std_logic;
 signal sck_o             : std_logic;

begin
   sck_out  <= sck_o;
   buf_full <= full_s;
   buf_emty <= empty_s;
   process(sysclk)
   begin
       if (sysclk'event and sysclk = '1') then
         if (reset = '1') then
             ss_n        <= (others=>'1');
             data_out    <= (others=>'0');
             out_reg     <= (others=>'0');
             clkdiv_cnt  <= (others=>'0');
             bit_cnt     <= (others=>'0');
             in_reg      <= (others=>'0');
             empty_s     <= '1';
             full_s      <= '0';
             spi_o       <= '1';
             sck_o       <= '0'; --sck idle low  --1
             state       <= idle;
         else
          if (cpu_cs = '1' and cpu_wr = '1') then  -- wr to spi
              case cpu_addr is
                 when "000" =>
                   ss_n <= data_in(1 downto 0);    -- cpu_addr base+0x00 will set slave 0 to 3
                 when "001" =>                     -- cpu_addr base+0x01 will put data into spi out reg
                  if (full_s='0') then
                      out_reg <= data_in ;
                      full_s  <= '1';              -- set full flag starts tx
                  end if;
                 when others =>
                   null;
              end case;
          end if;
          if (cpu_cs = '1' and cpu_rd = '1') then  -- read base+0x00 sets empty flag
             if (cpu_addr =  "000")then
                 empty_s     <= '1';
             end if;
          end if;
          case state is
            when idle =>
                if (full_s='1') then
                    state      <= shift;
                    spi_o      <= out_reg(7);                -- msb out first
                    out_reg    <= out_reg(6 downto 0) & '0'; -- shift the reg and appends '0' to lsb
                    sck_o      <= '0';
                end if;
            when shift =>
                 clkdiv_cnt <= clkdiv_cnt + '1';
                 if (clkdiv_cnt ="0111") then
                     in_reg     <= in_reg(6 downto 0) & spi_i;
                 end if;
                 if (clkdiv_cnt(2 downto 0)="111") then
                     sck_o      <= not sck_o;
                 end if;
                 if (clkdiv_cnt = "1111") then
                     spi_o      <= out_reg(7);
                     out_reg    <= out_reg(6 downto 0) & '0';
                     bit_cnt    <= bit_cnt + '1';
                 end if;
                 if (bit_cnt="111" and clkdiv_cnt = "1111") then
                     state      <= stop;
                     sck_o      <= '1';
                     spi_o      <= '1';
                 end if;
            when stop =>
                 data_out    <= in_reg;
                 state       <= idle;
                 full_s      <= '0';
                 empty_s     <= '0';
                 sck_o       <= '0'; -- '1'
                 spi_o       <= '1';
                 clkdiv_cnt  <= (others=>'0');
                 bit_cnt     <= (others=>'0');
                 in_reg      <= (others=>'0');
            when others =>
                 state      <= idle;
            end case;
        end if;
       end if;
   end process;
end b;