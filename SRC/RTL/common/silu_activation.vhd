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
        BITWIDTH                         : integer := 16; --! Bit width of each operand
        SCALE_FACTOR_POWER_OF_2          : integer := 10; --! Scale factor for integer computation power (e.g., 10 -> 2**10)
        DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 10  --! Scale factor to compute the division by 6
    );
    port (
        clock        : in std_logic;                                   --! Clock signal
        reset_n      : in std_logic;                                   --! Reset signal, active low
        i_sys_enable : in std_logic;                                   --! Global enable signal, active high
        i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Input data
        o_data       : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output data
    );
end silu_activation;

architecture silu_activation_arch of silu_activation is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant DIVISION_SCALE_FACTOR        : integer := 2 ** DIVISION_SCALE_FACTOR_POWER_OF_2;
    constant HARDSWISH_POSITIVE_THRESHOLD : integer := 3 * 2 ** SCALE_FACTOR_POWER_OF_2;
    constant HARDSWISH_NEGATIVE_THRESHOLD : integer := - 3 * 2 ** SCALE_FACTOR_POWER_OF_2;
    constant HARDSWISH_ADDITION_CONSTANT  : integer := 3 * 2 ** SCALE_FACTOR_POWER_OF_2;
    constant RELU6_POSITIVE_THRESHOLD     : integer := 6 * 2 ** SCALE_FACTOR_POWER_OF_2;
    constant HARDSWISH_DIVISION_FACTOR    : integer := DIVISION_SCALE_FACTOR / 6;

    signal i_data_signed : signed(BITWIDTH - 1 downto 0);

begin

    -- Input conversion for computation
    i_data_signed <= signed(i_data);

    -------------------------------------------------------------------------------------
    -- COMPUTATION PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the computation of the activation function
    process (clock, reset_n)
        variable hardswish_addition       : signed(BITWIDTH - 1 downto 0);     --! Variable to store the computed addition
        variable hardswish_multiplication : signed(2 * BITWIDTH - 1 downto 0); --! Variable to store the multiplication
        variable hardswish_division       : signed(3 * BITWIDTH - 1 downto 0); --! Variable to store the division
    begin
        if reset_n = '0' then
            hardswish_addition       := (others => '0');
            hardswish_multiplication := (others => '0');
            hardswish_division       := (others => '0');
            o_data                   <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                if i_data_signed < HARDSWISH_NEGATIVE_THRESHOLD then -- Test if x < -3 scaled       
                    hardswish_division := (others => '0');

                elsif i_data_signed < HARDSWISH_POSITIVE_THRESHOLD then -- Test if x > -3  and x < 3 scaled
                    -- Compute the x + 3 scaled
                    hardswish_addition := signed(i_data) + to_signed(HARDSWISH_ADDITION_CONSTANT, BITWIDTH);

                    -- Compute x * (x + 3)
                    hardswish_multiplication := signed(i_data) * hardswish_addition;

                    -- Compute x * (x + 3) / 6
                    hardswish_division := hardswish_multiplication * to_signed(HARDSWISH_DIVISION_FACTOR, BITWIDTH);
                    hardswish_division := SHIFT_RIGHT(hardswish_division, DIVISION_SCALE_FACTOR_POWER_OF_2 + SCALE_FACTOR_POWER_OF_2);

                else -- Test if x > 3
                    hardswish_division := resize(i_data_signed, 3 * BITWIDTH);
                end if;

                -- Output update
                o_data <= std_logic_vector(resize(hardswish_division, 2 * BITWIDTH));
            end if;
        end if;
    end process;
end architecture;