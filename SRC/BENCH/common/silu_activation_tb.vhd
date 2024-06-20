
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity silu_activation_tb is
end;

architecture bench of silu_activation_tb is
    -- Clock period
    constant clock_period : time := 5 ns;
    -- Generics
    constant BITWIDTH                         : integer := 16;
    constant SCALE_FACTOR_POWER_OF_2          : integer := 10;
    constant DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 10;
    -- Ports
    signal clock        : std_logic := '0';
    signal reset_n      : std_logic := '0';
    signal i_sys_enable : std_logic := '0';
    signal i_data       : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_data       : std_logic_vector(2 * BITWIDTH - 1 downto 0);
begin

    silu_activation_inst : entity work.silu_activation
        generic map(
            BITWIDTH                         => BITWIDTH,
            SCALE_FACTOR_POWER_OF_2          => SCALE_FACTOR_POWER_OF_2,
            DIVISION_SCALE_FACTOR_POWER_OF_2 => DIVISION_SCALE_FACTOR_POWER_OF_2
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_data       => i_data,
            o_data       => o_data
        );

    clock <= not clock after clock_period/2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for 2 * clock_period;
        reset_n <= '1';

        -- Enable
        i_sys_enable <= '1';
        wait for clock_period/2;

        for i in -7000 to 7000 loop
            i_data <= std_logic_vector(to_signed(i, BITWIDTH));
            wait for clock_period;
        end loop;

        wait;
    end process stimulus;

end;