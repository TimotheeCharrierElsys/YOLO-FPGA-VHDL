-----------------------------------------------------------------------------------
--!     @file    fc_layer_tb
--!     @brief        This testbench verifies the functionality of the pipelined mac 3*3
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity fc_layer_tb is
end entity;

architecture fc_layer_tb_arch of fc_layer_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant WAIT_COUNT   : integer := 8;     --! Number clock tics to wait
    constant BITWIDTH     : integer := 8;     --! Bit BITWIDTH of each operand
    constant MATRIX_SIZE  : integer := 3;     --! Kernel Size

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock    : std_logic := '0'; --! Clock signal
    signal reset_n  : std_logic := '1'; --! Reset signal, active at low state
    signal i_enable : std_logic := '0'; --! Enable signal, active at low state
    signal i_data   : t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_weight : t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_sum    : std_logic_vector (2 * BITWIDTH - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer;
            MATRIX_SIZE : integer
        );
        port (
            clock    : in std_logic;
            reset_n  : in std_logic;
            i_enable : in std_logic;
            i_data   : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_weight : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_sum    : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : fc_layer
    generic map(
        BITWIDTH    => BITWIDTH,
        MATRIX_SIZE => MATRIX_SIZE
    )
    port map(
        clock    => clock,
        reset_n  => reset_n,
        i_enable => i_enable,
        i_data   => i_data,
        i_weight => i_weight,
        o_sum    => o_sum
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
        i_enable <= '1';

        -- Apply input vectors
        i_data         <= (others => (others => std_logic_vector(to_unsigned(1, BITWIDTH))));
        i_weight(0)(0) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_weight(0)(1) <= std_logic_vector(to_unsigned(2, BITWIDTH));
        i_weight(0)(2) <= std_logic_vector(to_unsigned(3, BITWIDTH));
        i_weight(1)(0) <= std_logic_vector(to_unsigned(4, BITWIDTH));
        i_weight(1)(1) <= std_logic_vector(to_unsigned(5, BITWIDTH));
        i_weight(1)(2) <= std_logic_vector(to_unsigned(6, BITWIDTH));
        i_weight(2)(0) <= std_logic_vector(to_unsigned(7, BITWIDTH));
        i_weight(2)(1) <= std_logic_vector(to_unsigned(8, BITWIDTH));
        i_weight(2)(2) <= std_logic_vector(to_unsigned(8, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_sum = std_logic_vector(to_signed(36, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration fc_layer_tb_conf of fc_layer_tb is
    for fc_layer_tb_arch
        for UUT : fc_layer
            use configuration LIB_RTL.fc_layer_conf;
        end for;
    end for;
end configuration fc_layer_tb_conf;