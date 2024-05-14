-----------------------------------------------------------------------------------
--!     @File    dotproduct_pipelined_top
--!     @brief   This file provides the top level to compute the dot product of two vectors
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.dotproduct_pkg.all;

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
    signal mult_reg : t_out_vec(VECTOR_SIZE - 1 downto 0);
    signal sum_reg  : t_bit16;
    signal reg      : t_bit16;
begin
    -- Stage process: Computes one multiplication and one addition
    stage_process : process (i_clk, i_reset) is
        variable mult : t_out_vec(VECTOR_SIZE - 1 downto 0);
        variable sum  : t_bit16 := (others => '0');
    begin
        if i_reset = '1' then
            mult_reg <= (others => (others => '0'));
            sum_reg  <= (others => '0');
            reg      <= (others => '0');
        elsif rising_edge(i_clk) then
            sum := (others => '0');
            for i in 0 to VECTOR_SIZE - 1 loop
                mult(i) := std_logic_vector(signed(i_A(i)) * signed(i_B(i)));
                mult_reg(i) <= mult(i);
                sum_reg     <= sum;
                sum := std_logic_vector(signed(sum_reg) + signed(mult_reg(i)));
            end loop;
            reg <= sum_reg;
        end if;
    end process stage_process;

    o_result <= reg;

end architecture dotproduct_pipelined_top_arch;