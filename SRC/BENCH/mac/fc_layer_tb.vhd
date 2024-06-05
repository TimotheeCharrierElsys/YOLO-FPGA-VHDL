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
    signal clock        : std_logic := '0';                                                                 --! Clock signal
    signal reset_n      : std_logic := '1';                                                                 --! Reset signal, active at low state
    signal i_sys_enable : std_logic := '0';                                                                 --! Enable signal, active at high state
    signal i_matrix1    : t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix
    signal i_matrix2    : t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix
    signal o_result     : std_logic_vector (2 * BITWIDTH - 1 downto 0);                                     --! Output result

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer;
            MATRIX_SIZE : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_matrix1    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_matrix2    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_matrix1    => i_matrix1,
        i_matrix2    => i_matrix2,
        o_result     => o_result
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
        i_matrix1       <= (others => (others => std_logic_vector(to_unsigned(1, BITWIDTH))));
        i_matrix2(0)(0) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_matrix2(0)(1) <= std_logic_vector(to_unsigned(2, BITWIDTH));
        i_matrix2(0)(2) <= std_logic_vector(to_unsigned(3, BITWIDTH));
        i_matrix2(1)(0) <= std_logic_vector(to_unsigned(4, BITWIDTH));
        i_matrix2(1)(1) <= std_logic_vector(to_unsigned(5, BITWIDTH));
        i_matrix2(1)(2) <= std_logic_vector(to_unsigned(6, BITWIDTH));
        i_matrix2(2)(0) <= std_logic_vector(to_unsigned(7, BITWIDTH));
        i_matrix2(2)(1) <= std_logic_vector(to_unsigned(8, BITWIDTH));
        i_matrix2(2)(2) <= std_logic_vector(to_unsigned(8, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_result = std_logic_vector(to_signed(36, 2 * BITWIDTH))
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