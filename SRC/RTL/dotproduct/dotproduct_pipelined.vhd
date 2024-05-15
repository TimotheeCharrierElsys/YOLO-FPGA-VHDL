-----------------------------------------------------------------------------------
--!     @File    dotproduct_pipelined_top
--!     @brief   This file provides the top level to compute the dot product of two vectors
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pack.all;

entity dotproduct_pipelined_top is
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
end entity dotproduct_pipelined_top;

architecture dotproduct_pipelined_top_arch of dotproduct_pipelined_top is

    -- 
    -- SIGNALS
    --
    signal partial_sum : t_int_vec(VECTOR_SIZE - 1 downto 0);
    signal sum_reg     : t_bit16;
    signal reg         : t_bit16;
    signal sum         : integer;
begin

    -- 
    -- ASYNC SEQUENTIAL PROCESS
    -- 
    stage_process : process (i_clk, i_reset) is
    begin
        if i_reset = '1' then
            partial_sum <= (others => 0);
            sum_reg     <= (others => '0');
            reg         <= (others => '0');
            sum         <= 0;
        elsif rising_edge(i_clk) then

            -- Stage 1: Compute partial products
            for i in 0 to VECTOR_SIZE - 1 loop
                partial_sum(i) <= to_integer(signed(i_A(i))) * to_integer(signed(i_B(i)));
            end loop;

            -- Stage 2: Sum the partial products
            sum <= 0;
            for i in 0 to VECTOR_SIZE - 1 loop
                sum <= sum + partial_sum(i);
            end loop;

            -- Stage 3: Assign the sum to the register
            reg <= std_logic_vector(to_signed(sum, 16));
        end if;
    end process stage_process;

    o_result <= reg;
end architecture dotproduct_pipelined_top_arch;