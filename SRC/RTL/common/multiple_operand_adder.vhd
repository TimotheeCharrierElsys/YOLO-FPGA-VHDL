--!     @File    counter
--!     @brief   This file provides a generic counter component
--!     @author  Timothée Charrier

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity multiple_operand_adder is
    generic (
        BITWIDTH    : integer := 16; --! Bitwidth 
        VECTOR_SIZE : integer := 8   --! Vector Size 
    );
    port (
        i_clk    : in std_logic;                           --! Clock input
        i_reset  : in std_logic;                           --! Reset input
        i_data   : in t_out_vec(VECTOR_SIZE - 1 downto 0); --! Input vector
        o_result : out t_bit16                             --! Output Sum
    );
end entity multiple_operand_adder;

architecture multiple_operand_adder_arch of multiple_operand_adder is

    -- 
    -- CONSTANTS
    -- 

    constant N_STAGES : integer := integer(ceil(log2(real(VECTOR_SIZE))));

    -- 
    -- SIGNALS
    -- 

    signal r_acc : t_out_vec(VECTOR_SIZE - 1 downto 0);

begin

    process (i_clk, i_reset)
    begin
        if (i_reset = '1') then
            r_acc <= (others => (others => '0'));
        elsif rising_edge(i_clk) then
            r_acc(0) <= i_data(0);
            for i in 1 to VECTOR_SIZE - 1 loop
                r_acc(i) <= std_logic_vector(signed(r_acc(i - 1)) + signed(i_data(i)));
            end loop;
        end if;
    end process;

    o_result <= r_acc(VECTOR_SIZE - 1);

end architecture;