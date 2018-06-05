LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY mult_infer IS
PORT (
a: IN SIGNED (15 DOWNTO 0);
b: IN SIGNED (15 DOWNTO 0);
result: OUT SIGNED (31 DOWNTO 0)
);
END mult_infer;
ARCHITECTURE rtl OF mult_infer IS
BEGIN
result <= a * b;
END rtl;
