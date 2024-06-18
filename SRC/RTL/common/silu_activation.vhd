library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity silu_activation is
    generic (
        BITWIDTH     : integer := 16;     --! Bit width of each operand
        SCALE_FACTOR : integer := 2 ** 10 --! Scale factor for integer computation
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

    constant a : integer := 2 ** 5;
    constant b : integer := 2 ** 8;
    constant c : integer := 512;

    signal i_data_int : integer;

begin

    i_data_int <= to_integer(unsigned(i_data));

    -------------------------------------------------------------------------------------
    -- PROCESS
    -------------------------------------------------------------------------------------
    silu_computation_process : process (clock, reset_n)
        variable polynomial_computation : integer;
    begin
        if reset_n = '0' then
            o_data <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                -- Computation
                polynomial_computation := (a * i_data_int * i_data_int + b * i_data_int + c);

                -- Output update
                if i_data_int >= to_unsigned(SCALE_FACTOR, BITWIDTH) then
                    o_data <= std_logic_vector(to_unsigned(SCALE_FACTOR, 2 * BITWIDTH));
                else
                    o_data <= std_logic_vector(to_unsigned(polynomial_computation, 2 * BITWIDTH));
                end if;

            end if;
        end if;
    end process silu_computation_process;

end architecture;