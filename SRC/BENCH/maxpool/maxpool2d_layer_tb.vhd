-----------------------------------------------------------------------------------
--!     @file    maxpool2d_layer_tb
--!     @brief        This testbench verifies the functionality of the conv layer
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity maxpool2d_layer_tb is
end entity;

architecture maxpool2d_layer_tb_arch of maxpool2d_layer_tb is
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
    signal i_data_valid : std_logic := '0';                                                                                                 --! Input valid signal
    signal i_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input volume
    signal o_data       : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                        --! Output volume result
    signal o_data_valid : std_logic;                                                                                                        --! Valid signal

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component maxpool2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data_valid : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : maxpool2d_layer
    generic map(
        BITWIDTH       => BITWIDTH,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data_valid => i_data_valid,
        i_data       => i_data,
        o_data       => o_data,
        o_data_valid => o_data_valid
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
        wait for i_clk_period/2;
        reset_n <= '1';

        -- Enable the mac unit
        i_sys_enable <= '1';

        i_data(0) <= (
        (std_logic_vector(to_signed(-10, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH))),
        (std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(40, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(-20, BITWIDTH)))
        );

        i_data(1) <= (
        (std_logic_vector(to_signed(-10, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH))),
        (std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(40, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(-20, BITWIDTH)))
        );

        i_data(2) <= (
        (std_logic_vector(to_signed(-10, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH))),
        (std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(40, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(-20, BITWIDTH)))
        );

        wait for i_clk_period/2;

        i_data_valid <= '1';
        wait for i_clk_period/2;
        i_data_valid <= '0';
        -- Check the output
        assert o_data(0) = std_logic_vector(to_signed(40 - 2, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        assert o_data(1) = std_logic_vector(to_signed(40 - 2, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        assert o_data(2) = std_logic_vector(to_signed(40 - 2, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        wait for i_clk_period;

        i_data(0) <= (
        (std_logic_vector(to_signed(45, BITWIDTH)), std_logic_vector(to_signed(-50, BITWIDTH)), std_logic_vector(to_signed(100, BITWIDTH))),
        (std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(5, BITWIDTH)), std_logic_vector(to_signed(-6, BITWIDTH))),
        (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(40, BITWIDTH)))
        );

        wait for i_clk_period/2;

        i_data_valid <= '1';
        wait for i_clk_period/2;
        i_data_valid <= '0';

        assert o_data(0) = std_logic_vector(to_signed(100 - 2, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration maxpool2d_layer_tb_conf of maxpool2d_layer_tb is
    for maxpool2d_layer_tb_arch
        for UUT : maxpool2d_layer
            use entity LIB_RTL.maxpool2d_layer(maxpool2d_layer_arch);
        end for;
    end for;
end configuration maxpool2d_layer_tb_conf;