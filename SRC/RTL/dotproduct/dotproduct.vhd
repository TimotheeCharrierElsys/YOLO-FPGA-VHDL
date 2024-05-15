-----------------------------------------------------------------------------------
--!     @File    dotproduct_top
--!     @brief   This file provides the top level to compute the dot product of two vectors
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pack.all;

entity dotproduct_top is
    generic (
        VECTOR_SIZE : integer := 4 --! Vector Size (default is 4)
    );
    port (
        i_clk    : in std_logic;                          --! Clock input
        i_reset  : in std_logic;                          --! Reset input
        i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input vector A
        i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input vector B
        o_result : out t_bit16                            --! Output for the dot product result
    );
end entity dotproduct_top;

architecture dotproduct_top_arch of dotproduct_top is

    -- 
    -- SIGNALS
    signal r_A : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal r_B : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal sum : t_bit16;

begin

    r_A <= i_A;
    r_B <= i_b;

    -- 
    -- ASYNC SEQUENTIAL PROCESS
    -- 
    p_dotproduct_top : process (i_clk, i_reset) is
    begin
        if i_reset = '1' then
            sum <= (others => '0');
        elsif rising_edge(i_clk) then
            sum <= dotproduct(r_A, r_B); -- Compute the dot product 
        end if;
    end process p_dotproduct_top;

    -- Output update
    o_result <= sum;

end architecture dotproduct_top_arch;