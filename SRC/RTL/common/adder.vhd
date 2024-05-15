-----------------------------------------------------------------------------------
--!     @File    adder
--!     @brief   This file provides a generic signed adder component
--!     @date    2024-05-15
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
    generic (
        BITWIDTH : integer := 16 --! Input Size
    );
    port (
        i_clk    : in std_logic;                               --! Clock Input
        i_reset  : in std_logic;                               --! Reset Input
        i_A      : in std_logic_vector(BITWIDTH - 1 downto 0); --! First Input
        i_B      : in std_logic_vector(BITWIDTH - 1 downto 0); --! Second Input
        o_result : out std_logic_vector(BITWIDTH - 1 downto 0) --! Output Result
    );
end entity adder;

architecture adder_arch of adder is

    -- Internal signals for signed representation
    signal A_signed   : signed(BITWIDTH - 1 downto 0); --! Signal for i_A as signed
    signal B_signed   : signed(BITWIDTH - 1 downto 0); --! Signal for i_B as signed
    signal sum_signed : signed(BITWIDTH - 1 downto 0); --! Signal for the sum
    signal result_reg : signed(BITWIDTH - 1 downto 0); --! Register for the output result

begin

    -- Convert std_logic_vector inputs to signed
    A_signed <= signed(i_A);
    B_signed <= signed(i_B);

    -- Perform addition
    sum_signed <= A_signed + B_signed;

    -- Output register process with synchronous reset
    process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            result_reg <= (others => '0'); -- Reset output register to zero
            elsif rising_edge(i_clk) then
            -- Overflow detection and handling
            if (A_signed(BITWIDTH - 1) = B_signed(BITWIDTH - 1)) and (A_signed(BITWIDTH - 1) /= sum_signed(BITWIDTH - 1)) then
                -- Overflow occurred
                if A_signed(BITWIDTH - 1) = '1' then
                    result_reg      <= (others => '1'); -- Set to most negative value on overflow
                    else result_reg <= (others => '0'); -- Set to most positive value on overflow
                end if;
                else result_reg <= sum_signed; -- No overflow, update register with the sum
            end if;
        end if;
    end process;

    -- Convert signed result back to std_logic_vector
    o_result <= std_logic_vector(result_reg);

end architecture adder_arch;