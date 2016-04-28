-- *****************************************************************************************
-- Standard libraries
-- Version 0.2
-- Modified 02.12.2006
-- Designed by Ruslan Lepetenok
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package std_library is

type log2array_type is array(0 to 1024) of integer;
constant fn_log2   : log2array_type := (
0,0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  others => 10);
  
constant fn_log2x  : log2array_type := (
0,1,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
  others => 10);

-- *********************************************************************************  
function fn_det_x(d : std_logic_vector) return boolean;
function fn_det_x(d : std_logic) return boolean;  

function fn_xor_vect(vect : std_logic_vector) return std_logic;
function fn_or_vect(vect : std_logic_vector) return std_logic;
function fn_and_vect(vect : std_logic_vector) return std_logic;

function fn_to_integer(vect : std_logic_vector) return integer;
function fn_to_integer(d : std_logic) return integer;
function fn_to_std_logic_vector(int : integer; width : integer) return std_logic_vector;
function fn_to_std_logic_vector_signed(int : integer; width : integer) return std_logic_vector;
function fn_to_std_logic(b : boolean) return std_logic;

function fn_dcd(vect : std_logic_vector) return std_logic_vector;  
function fn_mux(sel : std_logic_vector; vect : std_logic_vector) return std_logic;      

function "+" (vect : std_logic_vector; int : integer) return std_logic_vector;
function "+" (vect : std_logic_vector; d : std_logic) return std_logic_vector;
function "+" (vect_a : std_logic_vector; vect_b : std_logic_vector) return std_logic_vector;

function "-" (vect : std_logic_vector; int : integer) return std_logic_vector;
function "-" (int : integer; vect : std_logic_vector) return std_logic_vector;
function "-" (vect : std_logic_vector; d : std_logic) return std_logic_vector;
function "-" (vect_a : std_logic_vector; vect_b : std_logic_vector) return std_logic_vector;

end std_library;  

package body std_library is

function fn_det_x(d : std_logic_vector) return boolean is
variable result : boolean;
begin
 result := FALSE;
-- pragma translate_off
 result := is_x(d);
-- pragma translate_on
 return (result);
end fn_det_x;

function fn_det_x(d : std_logic) return boolean is
variable result : boolean;
begin
 result := FALSE;
-- pragma translate_off
 result := is_x(d);
-- pragma translate_on
 return (result);
end fn_det_x;	
	

function fn_xor_vect(vect : std_logic_vector) return std_logic is
variable temp : std_logic;
begin
 temp := '0';
 for i in vect'range loop 
  temp := temp xor vect(i); 
 end loop;
 return(temp);
end fn_xor_vect;

function fn_or_vect(vect : std_logic_vector) return std_logic is
variable temp : std_logic;
begin
 temp := '0';
 for i in vect'range loop 
  temp := temp or vect(i); 
 end loop;
 return(temp);
end fn_or_vect;

function fn_and_vect(vect : std_logic_vector) return std_logic is
variable temp : std_logic;
begin
 temp := '1';
 for i in vect'range loop 
  temp := temp and vect(i); 
 end loop;
 return(temp);
end fn_and_vect;


function fn_to_integer(vect : std_logic_vector) return integer is
begin
 if (not fn_det_x(vect)) then 
  return(to_integer(unsigned(vect)));
 else 
  return(0); 
 end if;
end fn_to_integer;

function fn_to_integer(d : std_logic) return integer is
begin
 if (not fn_det_x(d)) then 
  if (d = '1') then 
   return(1);
  else 
   return(0); 
  end if;
 else 
  return(0); 
 end if;
end fn_to_integer;

function fn_to_std_logic_vector(int : integer; width : integer) return std_logic_vector is
variable temp : std_logic_vector(width-1 downto 0);
begin
  temp := std_logic_vector(to_unsigned(int, width));
  return(temp);
end fn_to_std_logic_vector;

function fn_to_std_logic_vector_signed(int : integer; width : integer) return std_logic_vector is
variable temp : std_logic_vector(width-1 downto 0);
begin
 temp := std_logic_vector(to_signed(int, width));
 return(temp);
end fn_to_std_logic_vector_signed;

function fn_to_std_logic(b : boolean) return std_logic is
begin
 if (b) then 
  return('1'); 
 else 
  return('0'); 
 end if;
end fn_to_std_logic;


function fn_dcd(vect : std_logic_vector) return std_logic_vector is
variable result : std_logic_vector((2**vect'length)-1 downto 0);
variable i : integer range result'range;
begin
 result := (others => '0'); 
 i := 0;
 if (not fn_det_x(vect)) then 
  i := to_integer(unsigned(vect)); 
 end if;
 result(i) := '1';
 return(result);
end fn_dcd;


function fn_mux(sel : std_logic_vector; vect : std_logic_vector) return std_logic is      
variable result : std_logic_vector(vect'length-1 downto 0);
variable i : integer range result'range;
begin
 result := vect; 
 i := 0;
 if (not fn_det_x(sel)) then 
  i := to_integer(unsigned(sel)); 
 end if;
 return(result(i));
end fn_mux;

-- >>>>

function "+" (vect_a : std_logic_vector; vect_b : std_logic_vector) return std_logic_vector is
variable tmp_a : std_logic_vector(vect_a'length-1 downto 0);
variable tmp_b : std_logic_vector(vect_b'length-1 downto 0);
begin
 if (not (fn_det_x(vect_a) or fn_det_x(vect_b))) then
  return(std_logic_vector(unsigned(vect_a) + unsigned(vect_b)));
-- pragma translate_off
 else
  tmp_a := (others =>'X'); 
  tmp_b := (others =>'X');
  if (tmp_a'length > tmp_b'length) then 
   return(tmp_a); 
  else 
   return(tmp_b); 
  end if;
-- pragma translate_on
  end if;
end "+";

function "+" (vect : std_logic_vector; int : integer) return std_logic_vector is
variable temp : std_logic_vector(vect'length-1 downto 0);
begin
 if (not fn_det_x(vect)) then
  return(std_logic_vector(unsigned(vect) + int));
-- pragma translate_off
 else 
  temp := (others =>'X'); 
 return(temp);
-- pragma translate_on
 end if;
end "+";

function "+" (vect : std_logic_vector; d : std_logic) return std_logic_vector is
variable tmp_a : std_logic_vector(vect'length-1 downto 0);
variable tmp_b : std_logic_vector(0 downto 0);
begin
 tmp_b(0) := d;
 if (not (fn_det_x(vect) or fn_det_x(d))) then 
  return(std_logic_vector(unsigned(vect) + unsigned(tmp_b)));
-- pragma translate_off
 else 
  tmp_b := (others =>'X'); 
  return(tmp_b); 
-- pragma translate_on
 end if;
end "+";

function "-" (vect_a : std_logic_vector; vect_b : std_logic_vector) return std_logic_vector is
variable tmp_a : std_logic_vector(vect_a'length-1 downto 0);
variable tmp_b : std_logic_vector(vect_b'length-1 downto 0);
begin
 if (not (fn_det_x(vect_a) or fn_det_x(vect_b))) then
  return(std_logic_vector(unsigned(vect_a) - unsigned(vect_b)));
-- pragma translate_off
 else
  tmp_a := (others =>'X'); tmp_b := (others =>'X');
  if (tmp_a'length > tmp_b'length) then 
   return(tmp_a); 
  else 
   return(tmp_b); 
  end if; 
-- pragma translate_on
 end if;
end "-";

function "-" (vect : std_logic_vector; int : integer) return std_logic_vector is
variable temp : std_logic_vector(vect'length-1 downto 0);
begin
 if (not fn_det_x(vect)) then
  return(std_logic_vector(unsigned(vect) - int));
-- pragma translate_off
 else 
  temp := (others =>'X'); 
  return(temp); 
-- pragma translate_on
 end if;
end "-";

function "-" (int : integer; vect : std_logic_vector) return std_logic_vector is
variable temp : std_logic_vector(vect'length-1 downto 0);
begin
 if (not fn_det_x(vect)) then
  return(std_logic_vector(int - unsigned(vect)));
-- pragma translate_off
 else 
  temp := (others =>'X'); 
  return(temp); 
-- pragma translate_on
 end if;
end "-";

function "-" (vect : std_logic_vector; d : std_logic) return std_logic_vector is
variable tmp_a : std_logic_vector(vect'length-1 downto 0);
variable tmp_b : std_logic_vector(0 downto 0);
begin
 tmp_b(0) := d;
 if (not (fn_det_x(vect) or fn_det_x(d))) then 
  return(std_logic_vector(unsigned(vect) - unsigned(tmp_b)));
-- pragma translate_off
 else tmp_a := (others =>'X'); 
  return(tmp_a); 
-- pragma translate_on
 end if;
end "-";

end std_library;	
