-----------------------------------------------------------------------------------
--!     @file       silu_activation
--!     @brief      This entity implements a scaled silu activation function 
--!                 It uses hardswish approximation function.
--!                 See https://arxiv.org/pdf/1905.02244 for more details
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity silu_activation
--! This entity implements an approximated silu activation function.
entity silu_activation is
    generic (
        BITWIDTH          : integer := 16; --! Bit width of each operand (input and output data)
        DATA_SCALE_FACTOR : integer := 12  --! Input data scale factor. For example, a value of 12 means input values are scaled by 2^12.
    );
    port (
        clock        : in std_logic;                               --! Clock signal
        reset_n      : in std_logic;                               --! Reset signal, active low
        i_sys_enable : in std_logic;                               --! Global enable signal, active high
        i_data       : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input data
        o_data       : out std_logic_vector(BITWIDTH - 1 downto 0) --! Output data
    );
end silu_activation;

architecture silu_activation_arch of silu_activation is
    -----------------------------------------------------------------------------------
    -- CONSTANTS
    -----------------------------------------------------------------------------------
    constant DIVISION_SCALE_FACTOR        : integer := 13;                           --! Scale factor used for division in HardSwish approximation
    constant HARDSWISH_POSITIVE_THRESHOLD : integer := 3 * 2 ** DATA_SCALE_FACTOR;   --! Negative threshold for hardswish function
    constant HARDSWISH_NEGATIVE_THRESHOLD : integer := - 3 * 2 ** DATA_SCALE_FACTOR; --! Positive threshold for hardswish function
    constant RELU6_POSITIVE_THRESHOLD     : integer := 6 * 2 ** DATA_SCALE_FACTOR;   --! Positive threshold for relu6 function

    -- Constants for HardSwish calculation
    constant HARDSWISH_ADDITION_CONSTANT_SIGNED : signed(BITWIDTH - 1 downto 0)              := to_signed(3 * 2 ** DATA_SCALE_FACTOR, BITWIDTH);
    constant HARDSWISH_DIVISION_FACTOR_SIGNED   : signed(DIVISION_SCALE_FACTOR - 2 downto 0) := to_signed(2 ** DIVISION_SCALE_FACTOR / 6, DIVISION_SCALE_FACTOR - 1);

begin

    -------------------------------------------------------------------------------------
    -- COMPUTATION PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the computation of the activation function
    process (clock, reset_n)
        variable hardswish_addition       : signed(BITWIDTH - 1 downto 0)     := (others => '0'); --! Variable to store the computed addition
        variable hardswish_multiplication : signed(2 * BITWIDTH - 1 downto 0) := (others => '0'); --! Variable to store the multiplication
        variable hardswish_division       : signed(30 - 1 downto 0)           := (others => '0'); --! Variable to store the division

    begin
        if reset_n = '0' then
            o_data <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                if signed(i_data) < HARDSWISH_NEGATIVE_THRESHOLD then -- Test if x < -3 scaled       
                    o_data <= (others => '0');

                elsif signed(i_data) < HARDSWISH_POSITIVE_THRESHOLD then -- Test if x > -3  and x < 3 scaled
                    -- Compute the x + 3 scaled
                    hardswish_addition := signed(i_data) + HARDSWISH_ADDITION_CONSTANT_SIGNED;

                    -- Compute x + (x + 3) >> DATA_SCALE_FACTOR
                    hardswish_multiplication := hardswish_addition * signed(i_data);
                    hardswish_multiplication :=
                        (hardswish_multiplication'high downto hardswish_multiplication'high - DATA_SCALE_FACTOR + 1 => hardswish_multiplication(hardswish_multiplication'high)) & -- MSB  
                        (hardswish_multiplication(hardswish_multiplication'high downto DATA_SCALE_FACTOR));                                                                       -- LSB

                    -- Compute x * (x + 3) / 6 >> DIVISION_SCALE_FACTOR
                    hardswish_division := resize(hardswish_multiplication, 18) * HARDSWISH_DIVISION_FACTOR_SIGNED;
                    hardswish_division :=
                        (hardswish_division'high downto hardswish_division'high - DIVISION_SCALE_FACTOR + 1 => hardswish_division(hardswish_division'high)) & -- MSB
                        (hardswish_division(hardswish_division'high downto DIVISION_SCALE_FACTOR));                                                           -- LSB

                    -- Output Update
                    o_data <= std_logic_vector(resize(hardswish_division, BITWIDTH));

                else -- Test if x > 3
                    o_data <= i_data;
                end if;
            end if;
        end if;
    end process;
end architecture;