-----------------------------------------------------------------------------------
--!     @brief   Perform a multiplication between two 8 bits numbers
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplication is
  port (
    A : in std_logic_vector(7 downto 0);  --! First Input
    B : in std_logic_vector(7 downto 0);  --! Second input
    C : out std_logic_vector(15 downto 0) --! Output
  );
end entity multiplication;

architecture multiplication_arch of multiplication is
  signal A_u : unsigned(7 downto 0);
  signal B_u : unsigned(7 downto 0);
  signal C_u : unsigned(15 downto 0);

begin

  A_u <= unsigned(A);
  B_u <= unsigned(B);
  C_u <= A_u * B_u;

  C <= std_logic_vector(C_u);
end architecture;