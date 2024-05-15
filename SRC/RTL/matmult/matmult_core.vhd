-----------------------------------------------------------------------------------
--!     @File    matmult_core
--!     @brief   This file provides the top level to compute the col product
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pack.all;

entity matmult_core is
    generic (
        VECTOR_SIZE : integer := 3 --! Vector Size
    );
    port (
        i_clk    : in std_logic;                          --! Clock Input
        i_reset  : in std_logic;                          --! Reset Input
        i_start  : in std_logic;                          --! Start Input Signal
        i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input Matrix A
        i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input Matrix B
        o_result : out t_bit16                            --! Output Matrix
    );
end entity matmult_core;

architecture matmult_core_arch of matmult_core is

    -- 
    -- SIGNALS
    --

    signal r_count : integer range 0 to VECTOR_SIZE;

    signal r_start  : std_logic;
    signal r_A      : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal r_B      : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal r_result : t_bit16_signed;

begin

    p_matmult_core : process (i_clk, i_reset) is
    begin
        if i_reset = '1' then
            r_count  <= 0;
            r_result <= (others => '0');

            elsif rising_edge(i_clk) then
            if (r_start = '1') then
                if r_count < VECTOR_SIZE then
                    r_result     <= r_result + signed(r_A(r_count)) * signed(r_B(r_count));
                    r_count      <= r_count + 1;
                    else r_count <= 0;
                end if;
            end if;
        end if;
    end process p_matmult_core;

    r_start  <= i_start;
    r_A      <= i_A;
    r_B      <= i_B;
    o_result <= std_logic_vector(r_result);

end architecture matmult_core_arch;