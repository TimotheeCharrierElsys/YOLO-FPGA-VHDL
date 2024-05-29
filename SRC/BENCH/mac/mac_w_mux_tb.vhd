-----------------------------------------------------------------------------------
-- Entity:       mac_w_mux
-- Description:  This entity implements a Multiply-Accumulate (MAC) unit. It performs
--               multiplication of two operands followed by an addition with a third operand.
-- Author:       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity mac_w_mux is
end entity mac_w_mux;

architecture mac_w_mux_arch of mac_w_mux is
    -- CONSTANTS
    constant clock_period : time    := 10 ns; -- Clock period
    constant BITWIDTH     : integer := 8;     -- Bit width of each operand

    -- SIGNALS
    signal clock         : std_logic := '0';                            --! Clock signal
    signal reset_n       : std_logic := '1';                            --! Reset signal, active low
    signal i_enable      : std_logic := '0';                            --! Enable signal, active high
    signal i_sel         : std_logic := '1';                            --! Select signal
    signal i_multiplier1 : std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplier operand
    signal i_multiplier2 : std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplier operand
    signal i_bias        : std_logic_vector(BITWIDTH - 1 downto 0);     --! Third operand
    signal o_result      : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Output data

    -- COMPONENTS
    component mac_w_mux
        generic (
            BITWIDTH : integer
        );
        port (
            clock         : in std_logic;
            reset_n       : in std_logic;
            i_enable      : in std_logic;
            i_sel         : in std_logic;
            i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_bias        : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -- UNIT UNDER TEST (UUT)
    UUT : mac_w_mux
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        clock         => clock,
        reset_n       => reset_n,
        i_enable      => i_enable,
        i_sel         => i_sel,
        i_multiplier1 => i_multiplier1,
        i_multiplier2 => i_multiplier2,
        i_bias        => i_bias,
        o_result      => o_result
    );

    -- Clock generation
    clock <= not clock after clock_period / 2;

    -- TEST PROCESS
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for 2 * clock_period;
        reset_n <= '1';

        -- Apply input vectors
        i_multiplier1 <= std_logic_vector(to_signed(5, BITWIDTH));
        i_multiplier2 <= std_logic_vector(to_signed(7, BITWIDTH));
        i_bias        <= std_logic_vector(to_signed(10, BITWIDTH));

        -- MUX select output
        i_sel <= '0';

        -- Enable the MAC
        i_enable <= '1';

        -- Check the output with sel = 0
        wait for (clock_period);
        assert o_result = std_logic_vector(to_signed(35, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        i_sel <= '1';

        -- Check the output with sel = 1
        wait for (clock_period);
        assert o_result = std_logic_vector(to_signed(45, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        i_enable <= '0';
        -- Finish the simulation
        wait;
    end process stimulus;

end architecture mac_w_mux_arch;

configuration mac_w_mux_conf of mac_w_mux is
    for mac_w_mux_arch
        for UUT : mac_w_mux
            use entity LIB_RTL.mac_w_mux(mac_w_mux_arch);
        end for;
    end for;
end configuration mac_w_mux_conf;