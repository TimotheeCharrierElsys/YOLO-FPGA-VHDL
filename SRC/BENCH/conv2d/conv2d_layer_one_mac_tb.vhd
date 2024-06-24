-----------------------------------------------------------------------------------
--!     @file         conv2d_layer_one_mac_tb
--!     @brief        This testbench verifies the functionality of the conv layer
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity conv2d_layer_one_mac_tb is
end entity;

architecture conv2d_layer_one_mac_tb_arch of conv2d_layer_one_mac_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time    := 10 ns; --! Clock period
    constant WAIT_COUNT     : integer := 15;    --! Number clock tics to wait
    constant BITWIDTH       : integer := 8;     --! Bit BITWIDTH of each operand
    constant CHANNEL_NUMBER : integer := 3;     --! Number of channels
    constant KERNEL_SIZE    : integer := 3;     --! Kernel Size

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic := '0';                                                                                                 --! Clock signal
    signal reset_n      : std_logic := '1';                                                                                                 --! Reset signal, active at low state
    signal i_sys_enable : std_logic := '0';                                                                                                 --! Enable signal, active at high state
    signal i_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input image
    signal i_valid      : std_logic := '0';
    signal i_kernels    : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input kernels
    signal i_bias       : std_logic_vector(BITWIDTH - 1 downto 0);                                                                          --! Input bias
    signal o_result     : std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                      --! Output result
    signal o_valid      : std_logic;                                                                                                        --! Valid signal

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_valid      : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_valid      : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : conv2d_layer
    generic map(
        BITWIDTH       => BITWIDTH,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_valid      => i_valid,
        i_data       => i_data,
        i_kernels    => i_kernels,
        i_bias       => i_bias,
        o_result     => o_result,
        o_valid      => o_valid
    );

    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    -- Apply input vectors
    i_bias <= std_logic_vector(to_signed(1, BITWIDTH));

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for i_clk_period/2;
        reset_n <= '1';

        -- Enable the mac unit
        i_sys_enable <= '1';

        i_data(0) <= (
        (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(3, BITWIDTH))),
        (std_logic_vector(to_signed(4, BITWIDTH)), std_logic_vector(to_signed(5, BITWIDTH)), std_logic_vector(to_signed(6, BITWIDTH))),
        (std_logic_vector(to_signed(7, BITWIDTH)), std_logic_vector(to_signed(8, BITWIDTH)), std_logic_vector(to_signed(9, BITWIDTH)))
        );

        i_data(1) <= (
        (std_logic_vector(to_signed(-1, BITWIDTH)), std_logic_vector(to_signed(-2, BITWIDTH)), std_logic_vector(to_signed(-3, BITWIDTH))),
        (std_logic_vector(to_signed(-4, BITWIDTH)), std_logic_vector(to_signed(-5, BITWIDTH)), std_logic_vector(to_signed(-6, BITWIDTH))),
        (std_logic_vector(to_signed(-7, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(-9, BITWIDTH)))
        );

        i_data(2) <= (
        (std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(11, BITWIDTH)), std_logic_vector(to_signed(12, BITWIDTH))),
        (std_logic_vector(to_signed(13, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(15, BITWIDTH))),
        (std_logic_vector(to_signed(16, BITWIDTH)), std_logic_vector(to_signed(17, BITWIDTH)), std_logic_vector(to_signed(18, BITWIDTH)))
        );

        i_kernels(0) <= (
        (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)))
        );

        i_kernels(1) <= (
        (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)))
        );

        i_kernels(2) <= (
        (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)))
        );

        wait for i_clk_period/2;

        i_valid <= '1';
        wait for i_clk_period/2;
        i_valid <= '0';

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_result = std_logic_vector(to_signed(-2, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration conv2d_layer_one_mac_tb_conf of conv2d_layer_one_mac_tb is
    for conv2d_layer_one_mac_tb_arch
        for UUT : conv2d_layer
            use configuration LIB_RTL.conv2d_layer_one_mac_conf;
        end for;
    end for;
end configuration conv2d_layer_one_mac_tb_conf;