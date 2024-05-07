
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplication_tb is
end;

architecture multiplication_tb_arch of multiplication_tb is

  -- Generics
  -- Ports
  signal A_s : std_logic_vector(7 downto 0);
  signal B_s : std_logic_vector(7 downto 0);
  signal C_s : std_logic_vector(15 downto 0);

begin

  UUT : entity work.multiplication
    port map(
      A => A_s,
      B => B_s,
      C => C_s
    );

  A_s <= x"01";
  B_s <= x"20";

end;

-- configuration multiplication_tb_conf of multiplication_tb is
--   for multiplication_tb_arch
--     for UUT : multiplication
--       use entity LIB_RTL.multiplication(multiplication_arch);
--     end for;
--   end for;
-- end configuration multiplication_tb_conf;