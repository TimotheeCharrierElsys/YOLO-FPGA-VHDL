-----------------------------------------------------------------------------------
--!     @Testbench    accumulative_mac_tb
--!     @brief        This testbench verifies the functionality of the accumulative mac
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity accumulative_mac_tb is
end entity;

architecture accumulative_mac_tb_arch of accumulative_mac_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant WAIT_COUNT   : integer := 8;     --! Number clock tics to wait
    constant BITWIDTH     : integer := 8;     --! Bit BITWIDTH of each operand

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock         : std_logic := '0';                            --! Clock signal
    signal reset_n       : std_logic := '1';                            --! Reset signal, active at low state
    signal i_sys_enable  : std_logic := '0';                            --! Enable signal, active at high state
    signal i_clear       : std_logic := '0';                            --! Clear signal, active high
    signal i_multiplier1 : std_logic_vector(BITWIDTH - 1 downto 0);     --! First mult operand
    signal i_multiplier2 : std_logic_vector(BITWIDTH - 1 downto 0);     --! Second mult operand
    signal o_result      : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component accumulative_mac_tb
        generic (
            BITWIDTH : integer
        );
        port (
            clock         : in std_logic;
            reset_n       : in std_logic;
            i_sys_enable  : in std_logic;
            i_clear       : in std_logic;
            i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : accumulative_mac_tb
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        clock         => clock,
        reset_n       => reset_n,
        i_sys_enable  => i_sys_enable,
        i_clear       => i_clear,
        i_multiplier1 => i_multiplier1,
        i_multiplier2 => i_multiplier2,
        o_result      => o_result
    );
    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for 2 * i_clk_period;
        reset_n <= '1';

        -- Enable the mac unit
        i_sys_enable <= '1';

        -- Apply input vectors
        i_multiplier1 <= std_logic_vector(to_signed(5, BITWIDTH));
        i_multiplier2 <= std_logic_vector(to_signed(7, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_result = std_logic_vector(to_signed(45, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        i_clear <= '1';
        wait for i_clk_period;
        i_clear <= '0';
        wait for i_clk_period;

        assert o_result = std_logic_vector(to_signed(0, 2 * BITWIDTH))
        report "Test failed: output not cleared correctly"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration accumulative_mac_tb_conf of accumulative_mac_tb is
    for accumulative_mac_tb_arch
        for UUT : accumulative_mac_tb
            use entity LIB_RTL.accumulative_mac_tb(accumulative_mac_tb_arch);
        end for;
    end for;
end configuration accumulative_mac_tb_conf;