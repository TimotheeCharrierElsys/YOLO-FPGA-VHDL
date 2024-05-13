-----------------------------------------------------------------------------------
--!     @brief   Perform a multiplication between two 8 bits numbers
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplication is
    port (
        i_clk   : in std_logic;                     --! Clock input
        i_reset : in std_logic;                     --! Reset input
        i_A     : in std_logic_vector(7 downto 0);  --! First Input
        i_B     : in std_logic_vector(7 downto 0);  --! Second input
        o_C     : out std_logic_vector(15 downto 0) --! Output
    );
end entity multiplication;

architecture multiplication_arch of multiplication is
    signal A_u : unsigned(7 downto 0);
    signal B_u : unsigned(7 downto 0);
    signal C_u : unsigned(15 downto 0);
    signal reg : unsigned(15 downto 0);

begin

    -- multiplication
    A_u <= unsigned(i_A);
    B_u <= unsigned(i_B);
    C_u <= A_u * B_u;

    process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            reg <= (others => '0');
        elsif rising_edge(i_clk) then
            reg <= C_u;
        end if;
    end process;

    -- output update
    o_C <= std_logic_vector(reg);

end architecture;