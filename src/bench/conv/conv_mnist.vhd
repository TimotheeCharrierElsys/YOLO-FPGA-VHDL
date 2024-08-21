-----------------------------------------------------------------------------------
--!     @file    conv_mnist
--!     @brief        This testbench verifies the functionality of the conv layer
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity conv_mnist is
end entity;

architecture conv_mnist_arch of conv_mnist is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time      := 10 ns;
    constant USE_MAC_ARCH   : std_logic := '1';
    constant DO_PIPELINE    : std_logic := '1';
    constant BITWIDTH       : integer   := 16;
    constant INPUT_SIZE     : integer   := 28;
    constant CHANNEL_NUMBER : integer   := 1;
    constant KERNEL_SIZE    : integer   := 3;
    constant KERNEL_NUMBER  : integer   := 32;
    constant PADDING        : integer   := 1;
    constant STRIDE         : integer   := 2;
    constant EPSILON        : integer   := 0;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock              : std_logic := '0';
    signal reset_n            : std_logic := '0';
    signal i_sys_enable       : std_logic := '0';
    signal i_data_valid       : std_logic := '0';
    signal i_data             : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_kernel           : t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_bias_conv2d      : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal i_running_mean     : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal i_weight           : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal i_bias_batchnorm2d : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data             : t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data_valid       : std_logic;

    -- File variables
    file output_file : text;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv
        generic (
            USE_MAC_ARCH   : std_logic;
            DO_PIPELINE    : std_logic;
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer;
            KERNEL_NUMBER  : integer;
            PADDING        : integer;
            STRIDE         : integer;
            EPSILON        : integer
        );
        port (
            clock              : in std_logic;
            reset_n            : in std_logic;
            i_sys_enable       : in std_logic;
            i_data_valid       : in std_logic;
            i_data             : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernel           : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias_conv2d      : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_running_mean     : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_weight           : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_bias_batchnorm2d : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data             : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data_valid       : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : conv
    generic map(
        USE_MAC_ARCH   => USE_MAC_ARCH,
        DO_PIPELINE    => DO_PIPELINE,
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE,
        KERNEL_NUMBER  => KERNEL_NUMBER,
        PADDING        => PADDING,
        STRIDE         => STRIDE,
        EPSILON        => EPSILON
    )
    port map(
        clock              => clock,
        reset_n            => reset_n,
        i_sys_enable       => i_sys_enable,
        i_data_valid       => i_data_valid,
        i_data             => i_data,
        i_kernel           => i_kernel,
        i_bias_conv2d      => i_bias_conv2d,
        i_running_mean     => i_running_mean,
        i_weight           => i_weight,
        i_bias_batchnorm2d => i_bias_batchnorm2d,
        o_data             => o_data,
        o_data_valid       => o_data_valid
    );
    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    i_data(0) <= (
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-799, BITWIDTH)), std_logic_vector(to_signed(9054, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(4570, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(347, BITWIDTH)), std_logic_vector(to_signed(9679, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(4570, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(973, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(10879, BITWIDTH)), std_logic_vector(to_signed(1442, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(973, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(5196, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1685, BITWIDTH)), std_logic_vector(to_signed(4257, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(9940, BITWIDTH)), std_logic_vector(to_signed(-121, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(2276, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(243, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(87, BITWIDTH)), std_logic_vector(to_signed(9679, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(8845, BITWIDTH)), std_logic_vector(to_signed(-1581, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(6916, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(9784, BITWIDTH)), std_logic_vector(to_signed(-747, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(1234, BITWIDTH)), std_logic_vector(to_signed(10774, BITWIDTH)), std_logic_vector(to_signed(11348, BITWIDTH)), std_logic_vector(to_signed(2172, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(7750, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(4831, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(1286, BITWIDTH)), std_logic_vector(to_signed(11191, BITWIDTH)), std_logic_vector(to_signed(8950, BITWIDTH)), std_logic_vector(to_signed(-1268, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1476, BITWIDTH)), std_logic_vector(to_signed(8011, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(5196, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(1494, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11244, BITWIDTH)), std_logic_vector(to_signed(1338, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(556, BITWIDTH)), std_logic_vector(to_signed(10670, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(4987, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(2589, BITWIDTH)), std_logic_vector(to_signed(11556, BITWIDTH)), std_logic_vector(to_signed(10409, BITWIDTH)), std_logic_vector(to_signed(-590, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-799, BITWIDTH)), std_logic_vector(to_signed(9158, BITWIDTH)), std_logic_vector(to_signed(11452, BITWIDTH)), std_logic_vector(to_signed(2589, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(3788, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(10566, BITWIDTH)), std_logic_vector(to_signed(-642, BITWIDTH)), std_logic_vector(to_signed(1338, BITWIDTH)), std_logic_vector(to_signed(1755, BITWIDTH)), std_logic_vector(to_signed(1755, BITWIDTH)), std_logic_vector(to_signed(1755, BITWIDTH)), std_logic_vector(to_signed(-1007, BITWIDTH)), std_logic_vector(to_signed(1703, BITWIDTH)), std_logic_vector(to_signed(-851, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(5561, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(10201, BITWIDTH)), std_logic_vector(to_signed(11296, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(9992, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(10097, BITWIDTH)), std_logic_vector(to_signed(6760, BITWIDTH)), std_logic_vector(to_signed(4205, BITWIDTH)), std_logic_vector(to_signed(2016, BITWIDTH)), std_logic_vector(to_signed(4205, BITWIDTH)), std_logic_vector(to_signed(1755, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(973, BITWIDTH)), std_logic_vector(to_signed(7125, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(8585, BITWIDTH)), std_logic_vector(to_signed(10826, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(11504, BITWIDTH)), std_logic_vector(to_signed(9836, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(139, BITWIDTH)), std_logic_vector(to_signed(1390, BITWIDTH)), std_logic_vector(to_signed(6134, BITWIDTH)), std_logic_vector(to_signed(6551, BITWIDTH)), std_logic_vector(to_signed(7907, BITWIDTH)), std_logic_vector(to_signed(2641, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH))),
    (std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)), std_logic_vector(to_signed(-1737, BITWIDTH)))
    );

    i_bias_conv2d      <= (std_logic_vector(to_signed(504, 2 * BITWIDTH)), std_logic_vector(to_signed(786, 2 * BITWIDTH)), std_logic_vector(to_signed(831, 2 * BITWIDTH)), std_logic_vector(to_signed(-477, 2 * BITWIDTH)), std_logic_vector(to_signed(-1337, 2 * BITWIDTH)), std_logic_vector(to_signed(895, 2 * BITWIDTH)), std_logic_vector(to_signed(-518, 2 * BITWIDTH)), std_logic_vector(to_signed(-1283, 2 * BITWIDTH)), std_logic_vector(to_signed(-343, 2 * BITWIDTH)), std_logic_vector(to_signed(-220, 2 * BITWIDTH)), std_logic_vector(to_signed(1220, 2 * BITWIDTH)), std_logic_vector(to_signed(260, 2 * BITWIDTH)), std_logic_vector(to_signed(1190, 2 * BITWIDTH)), std_logic_vector(to_signed(-1247, 2 * BITWIDTH)), std_logic_vector(to_signed(-521, 2 * BITWIDTH)), std_logic_vector(to_signed(-180, 2 * BITWIDTH)), std_logic_vector(to_signed(-358, 2 * BITWIDTH)), std_logic_vector(to_signed(335, 2 * BITWIDTH)), std_logic_vector(to_signed(-393, 2 * BITWIDTH)), std_logic_vector(to_signed(-203, 2 * BITWIDTH)), std_logic_vector(to_signed(-761, 2 * BITWIDTH)), std_logic_vector(to_signed(-780, 2 * BITWIDTH)), std_logic_vector(to_signed(18, 2 * BITWIDTH)), std_logic_vector(to_signed(-580, 2 * BITWIDTH)), std_logic_vector(to_signed(-775, 2 * BITWIDTH)), std_logic_vector(to_signed(68, 2 * BITWIDTH)), std_logic_vector(to_signed(765, 2 * BITWIDTH)), std_logic_vector(to_signed(768, 2 * BITWIDTH)), std_logic_vector(to_signed(-870, 2 * BITWIDTH)), std_logic_vector(to_signed(50, 2 * BITWIDTH)), std_logic_vector(to_signed(275, 2 * BITWIDTH)), std_logic_vector(to_signed(-258, 2 * BITWIDTH)));
    i_running_mean     <= (std_logic_vector(to_signed(514, 2 * BITWIDTH)), std_logic_vector(to_signed(837, 2 * BITWIDTH)), std_logic_vector(to_signed(895, 2 * BITWIDTH)), std_logic_vector(to_signed(-543, 2 * BITWIDTH)), std_logic_vector(to_signed(-1343, 2 * BITWIDTH)), std_logic_vector(to_signed(850, 2 * BITWIDTH)), std_logic_vector(to_signed(-621, 2 * BITWIDTH)), std_logic_vector(to_signed(-1271, 2 * BITWIDTH)), std_logic_vector(to_signed(-219, 2 * BITWIDTH)), std_logic_vector(to_signed(-103, 2 * BITWIDTH)), std_logic_vector(to_signed(1089, 2 * BITWIDTH)), std_logic_vector(to_signed(146, 2 * BITWIDTH)), std_logic_vector(to_signed(1296, 2 * BITWIDTH)), std_logic_vector(to_signed(-1218, 2 * BITWIDTH)), std_logic_vector(to_signed(-624, 2 * BITWIDTH)), std_logic_vector(to_signed(-147, 2 * BITWIDTH)), std_logic_vector(to_signed(-307, 2 * BITWIDTH)), std_logic_vector(to_signed(256, 2 * BITWIDTH)), std_logic_vector(to_signed(-457, 2 * BITWIDTH)), std_logic_vector(to_signed(-19, 2 * BITWIDTH)), std_logic_vector(to_signed(-799, 2 * BITWIDTH)), std_logic_vector(to_signed(-729, 2 * BITWIDTH)), std_logic_vector(to_signed(-40, 2 * BITWIDTH)), std_logic_vector(to_signed(-580, 2 * BITWIDTH)), std_logic_vector(to_signed(-759, 2 * BITWIDTH)), std_logic_vector(to_signed(72, 2 * BITWIDTH)), std_logic_vector(to_signed(782, 2 * BITWIDTH)), std_logic_vector(to_signed(827, 2 * BITWIDTH)), std_logic_vector(to_signed(-879, 2 * BITWIDTH)), std_logic_vector(to_signed(73, 2 * BITWIDTH)), std_logic_vector(to_signed(322, 2 * BITWIDTH)), std_logic_vector(to_signed(-254, 2 * BITWIDTH)));
    i_weight           <= (std_logic_vector(to_signed(14176, 2 * BITWIDTH)), std_logic_vector(to_signed(9536, 2 * BITWIDTH)), std_logic_vector(to_signed(7781, 2 * BITWIDTH)), std_logic_vector(to_signed(8089, 2 * BITWIDTH)), std_logic_vector(to_signed(12391, 2 * BITWIDTH)), std_logic_vector(to_signed(12144, 2 * BITWIDTH)), std_logic_vector(to_signed(13290, 2 * BITWIDTH)), std_logic_vector(to_signed(10662, 2 * BITWIDTH)), std_logic_vector(to_signed(3029, 2 * BITWIDTH)), std_logic_vector(to_signed(6685, 2 * BITWIDTH)), std_logic_vector(to_signed(8257, 2 * BITWIDTH)), std_logic_vector(to_signed(6593, 2 * BITWIDTH)), std_logic_vector(to_signed(4154, 2 * BITWIDTH)), std_logic_vector(to_signed(8891, 2 * BITWIDTH)), std_logic_vector(to_signed(7630, 2 * BITWIDTH)), std_logic_vector(to_signed(5119, 2 * BITWIDTH)), std_logic_vector(to_signed(13756, 2 * BITWIDTH)), std_logic_vector(to_signed(6635, 2 * BITWIDTH)), std_logic_vector(to_signed(13830, 2 * BITWIDTH)), std_logic_vector(to_signed(2910, 2 * BITWIDTH)), std_logic_vector(to_signed(19535, 2 * BITWIDTH)), std_logic_vector(to_signed(14912, 2 * BITWIDTH)), std_logic_vector(to_signed(10804, 2 * BITWIDTH)), std_logic_vector(to_signed(11043, 2 * BITWIDTH)), std_logic_vector(to_signed(8862, 2 * BITWIDTH)), std_logic_vector(to_signed(8360, 2 * BITWIDTH)), std_logic_vector(to_signed(13398, 2 * BITWIDTH)), std_logic_vector(to_signed(10571, 2 * BITWIDTH)), std_logic_vector(to_signed(10946, 2 * BITWIDTH)), std_logic_vector(to_signed(16557, 2 * BITWIDTH)), std_logic_vector(to_signed(16671, 2 * BITWIDTH)), std_logic_vector(to_signed(15781, 2 * BITWIDTH)));
    i_bias_batchnorm2d <= (std_logic_vector(to_signed(-909, 2 * BITWIDTH)), std_logic_vector(to_signed(-118, 2 * BITWIDTH)), std_logic_vector(to_signed(-652, 2 * BITWIDTH)), std_logic_vector(to_signed(-994, 2 * BITWIDTH)), std_logic_vector(to_signed(67, 2 * BITWIDTH)), std_logic_vector(to_signed(-120, 2 * BITWIDTH)), std_logic_vector(to_signed(-684, 2 * BITWIDTH)), std_logic_vector(to_signed(97, 2 * BITWIDTH)), std_logic_vector(to_signed(-799, 2 * BITWIDTH)), std_logic_vector(to_signed(-771, 2 * BITWIDTH)), std_logic_vector(to_signed(-383, 2 * BITWIDTH)), std_logic_vector(to_signed(-304, 2 * BITWIDTH)), std_logic_vector(to_signed(-655, 2 * BITWIDTH)), std_logic_vector(to_signed(-256, 2 * BITWIDTH)), std_logic_vector(to_signed(-31, 2 * BITWIDTH)), std_logic_vector(to_signed(-758, 2 * BITWIDTH)), std_logic_vector(to_signed(-246, 2 * BITWIDTH)), std_logic_vector(to_signed(-884, 2 * BITWIDTH)), std_logic_vector(to_signed(-308, 2 * BITWIDTH)), std_logic_vector(to_signed(-836, 2 * BITWIDTH)), std_logic_vector(to_signed(-1430, 2 * BITWIDTH)), std_logic_vector(to_signed(-253, 2 * BITWIDTH)), std_logic_vector(to_signed(-115, 2 * BITWIDTH)), std_logic_vector(to_signed(-63, 2 * BITWIDTH)), std_logic_vector(to_signed(-258, 2 * BITWIDTH)), std_logic_vector(to_signed(-1415, 2 * BITWIDTH)), std_logic_vector(to_signed(-118, 2 * BITWIDTH)), std_logic_vector(to_signed(-609, 2 * BITWIDTH)), std_logic_vector(to_signed(-117, 2 * BITWIDTH)), std_logic_vector(to_signed(146, 2 * BITWIDTH)), std_logic_vector(to_signed(-766, 2 * BITWIDTH)), std_logic_vector(to_signed(-1031, 2 * BITWIDTH)));

    i_kernel(0)(0) <= (
    (std_logic_vector(to_signed(788, BITWIDTH)), std_logic_vector(to_signed(-886, BITWIDTH)), std_logic_vector(to_signed(-686, BITWIDTH))),
    (std_logic_vector(to_signed(764, BITWIDTH)), std_logic_vector(to_signed(-1110, BITWIDTH)), std_logic_vector(to_signed(845, BITWIDTH))),
    (std_logic_vector(to_signed(-547, BITWIDTH)), std_logic_vector(to_signed(715, BITWIDTH)), std_logic_vector(to_signed(231, BITWIDTH)))
    );
    i_kernel(1)(0) <= (
    (std_logic_vector(to_signed(55, BITWIDTH)), std_logic_vector(to_signed(713, BITWIDTH)), std_logic_vector(to_signed(-112, BITWIDTH))),
    (std_logic_vector(to_signed(822, BITWIDTH)), std_logic_vector(to_signed(-386, BITWIDTH)), std_logic_vector(to_signed(-289, BITWIDTH))),
    (std_logic_vector(to_signed(38, BITWIDTH)), std_logic_vector(to_signed(-403, BITWIDTH)), std_logic_vector(to_signed(-298, BITWIDTH)))
    );
    i_kernel(2)(0) <= (
    (std_logic_vector(to_signed(1103, BITWIDTH)), std_logic_vector(to_signed(191, BITWIDTH)), std_logic_vector(to_signed(-541, BITWIDTH))),
    (std_logic_vector(to_signed(-794, BITWIDTH)), std_logic_vector(to_signed(-864, BITWIDTH)), std_logic_vector(to_signed(-634, BITWIDTH))),
    (std_logic_vector(to_signed(-132, BITWIDTH)), std_logic_vector(to_signed(269, BITWIDTH)), std_logic_vector(to_signed(1248, BITWIDTH)))
    );
    i_kernel(3)(0) <= (
    (std_logic_vector(to_signed(456, BITWIDTH)), std_logic_vector(to_signed(-919, BITWIDTH)), std_logic_vector(to_signed(727, BITWIDTH))),
    (std_logic_vector(to_signed(404, BITWIDTH)), std_logic_vector(to_signed(1625, BITWIDTH)), std_logic_vector(to_signed(1093, BITWIDTH))),
    (std_logic_vector(to_signed(-1336, BITWIDTH)), std_logic_vector(to_signed(-1495, BITWIDTH)), std_logic_vector(to_signed(-784, BITWIDTH)))
    );
    i_kernel(4)(0) <= (
    (std_logic_vector(to_signed(665, BITWIDTH)), std_logic_vector(to_signed(-151, BITWIDTH)), std_logic_vector(to_signed(656, BITWIDTH))),
    (std_logic_vector(to_signed(-707, BITWIDTH)), std_logic_vector(to_signed(1293, BITWIDTH)), std_logic_vector(to_signed(-661, BITWIDTH))),
    (std_logic_vector(to_signed(851, BITWIDTH)), std_logic_vector(to_signed(-513, BITWIDTH)), std_logic_vector(to_signed(-1376, BITWIDTH)))
    );
    i_kernel(5)(0) <= (
    (std_logic_vector(to_signed(878, BITWIDTH)), std_logic_vector(to_signed(-162, BITWIDTH)), std_logic_vector(to_signed(695, BITWIDTH))),
    (std_logic_vector(to_signed(-795, BITWIDTH)), std_logic_vector(to_signed(-599, BITWIDTH)), std_logic_vector(to_signed(-1448, BITWIDTH))),
    (std_logic_vector(to_signed(-553, BITWIDTH)), std_logic_vector(to_signed(698, BITWIDTH)), std_logic_vector(to_signed(334, BITWIDTH)))
    );
    i_kernel(6)(0) <= (
    (std_logic_vector(to_signed(1233, BITWIDTH)), std_logic_vector(to_signed(856, BITWIDTH)), std_logic_vector(to_signed(-803, BITWIDTH))),
    (std_logic_vector(to_signed(-1170, BITWIDTH)), std_logic_vector(to_signed(692, BITWIDTH)), std_logic_vector(to_signed(343, BITWIDTH))),
    (std_logic_vector(to_signed(-1516, BITWIDTH)), std_logic_vector(to_signed(445, BITWIDTH)), std_logic_vector(to_signed(818, BITWIDTH)))
    );
    i_kernel(7)(0) <= (
    (std_logic_vector(to_signed(1459, BITWIDTH)), std_logic_vector(to_signed(-558, BITWIDTH)), std_logic_vector(to_signed(-749, BITWIDTH))),
    (std_logic_vector(to_signed(191, BITWIDTH)), std_logic_vector(to_signed(137, BITWIDTH)), std_logic_vector(to_signed(-1283, BITWIDTH))),
    (std_logic_vector(to_signed(-715, BITWIDTH)), std_logic_vector(to_signed(445, BITWIDTH)), std_logic_vector(to_signed(-290, BITWIDTH)))
    );
    i_kernel(8)(0) <= (
    (std_logic_vector(to_signed(413, BITWIDTH)), std_logic_vector(to_signed(464, BITWIDTH)), std_logic_vector(to_signed(329, BITWIDTH))),
    (std_logic_vector(to_signed(106, BITWIDTH)), std_logic_vector(to_signed(469, BITWIDTH)), std_logic_vector(to_signed(814, BITWIDTH))),
    (std_logic_vector(to_signed(-1608, BITWIDTH)), std_logic_vector(to_signed(29, BITWIDTH)), std_logic_vector(to_signed(-1076, BITWIDTH)))
    );
    i_kernel(9)(0) <= (
    (std_logic_vector(to_signed(-1546, BITWIDTH)), std_logic_vector(to_signed(-428, BITWIDTH)), std_logic_vector(to_signed(-273, BITWIDTH))),
    (std_logic_vector(to_signed(967, BITWIDTH)), std_logic_vector(to_signed(-348, BITWIDTH)), std_logic_vector(to_signed(-995, BITWIDTH))),
    (std_logic_vector(to_signed(1005, BITWIDTH)), std_logic_vector(to_signed(270, BITWIDTH)), std_logic_vector(to_signed(819, BITWIDTH)))
    );
    i_kernel(10)(0) <= (
    (std_logic_vector(to_signed(508, BITWIDTH)), std_logic_vector(to_signed(-876, BITWIDTH)), std_logic_vector(to_signed(169, BITWIDTH))),
    (std_logic_vector(to_signed(559, BITWIDTH)), std_logic_vector(to_signed(-907, BITWIDTH)), std_logic_vector(to_signed(-714, BITWIDTH))),
    (std_logic_vector(to_signed(838, BITWIDTH)), std_logic_vector(to_signed(523, BITWIDTH)), std_logic_vector(to_signed(-417, BITWIDTH)))
    );
    i_kernel(11)(0) <= (
    (std_logic_vector(to_signed(-378, BITWIDTH)), std_logic_vector(to_signed(923, BITWIDTH)), std_logic_vector(to_signed(-768, BITWIDTH))),
    (std_logic_vector(to_signed(625, BITWIDTH)), std_logic_vector(to_signed(807, BITWIDTH)), std_logic_vector(to_signed(-1031, BITWIDTH))),
    (std_logic_vector(to_signed(-1333, BITWIDTH)), std_logic_vector(to_signed(1275, BITWIDTH)), std_logic_vector(to_signed(-79, BITWIDTH)))
    );
    i_kernel(12)(0) <= (
    (std_logic_vector(to_signed(1287, BITWIDTH)), std_logic_vector(to_signed(216, BITWIDTH)), std_logic_vector(to_signed(-9, BITWIDTH))),
    (std_logic_vector(to_signed(1508, BITWIDTH)), std_logic_vector(to_signed(1220, BITWIDTH)), std_logic_vector(to_signed(-967, BITWIDTH))),
    (std_logic_vector(to_signed(150, BITWIDTH)), std_logic_vector(to_signed(810, BITWIDTH)), std_logic_vector(to_signed(797, BITWIDTH)))
    );
    i_kernel(13)(0) <= (
    (std_logic_vector(to_signed(797, BITWIDTH)), std_logic_vector(to_signed(-1202, BITWIDTH)), std_logic_vector(to_signed(-680, BITWIDTH))),
    (std_logic_vector(to_signed(-1245, BITWIDTH)), std_logic_vector(to_signed(123, BITWIDTH)), std_logic_vector(to_signed(1355, BITWIDTH))),
    (std_logic_vector(to_signed(-291, BITWIDTH)), std_logic_vector(to_signed(1233, BITWIDTH)), std_logic_vector(to_signed(-577, BITWIDTH)))
    );
    i_kernel(14)(0) <= (
    (std_logic_vector(to_signed(-1977, BITWIDTH)), std_logic_vector(to_signed(-910, BITWIDTH)), std_logic_vector(to_signed(56, BITWIDTH))),
    (std_logic_vector(to_signed(1053, BITWIDTH)), std_logic_vector(to_signed(-456, BITWIDTH)), std_logic_vector(to_signed(403, BITWIDTH))),
    (std_logic_vector(to_signed(1016, BITWIDTH)), std_logic_vector(to_signed(719, BITWIDTH)), std_logic_vector(to_signed(446, BITWIDTH)))
    );
    i_kernel(15)(0) <= (
    (std_logic_vector(to_signed(627, BITWIDTH)), std_logic_vector(to_signed(1154, BITWIDTH)), std_logic_vector(to_signed(740, BITWIDTH))),
    (std_logic_vector(to_signed(-1452, BITWIDTH)), std_logic_vector(to_signed(-1083, BITWIDTH)), std_logic_vector(to_signed(-460, BITWIDTH))),
    (std_logic_vector(to_signed(132, BITWIDTH)), std_logic_vector(to_signed(-489, BITWIDTH)), std_logic_vector(to_signed(480, BITWIDTH)))
    );
    i_kernel(16)(0) <= (
    (std_logic_vector(to_signed(312, BITWIDTH)), std_logic_vector(to_signed(-658, BITWIDTH)), std_logic_vector(to_signed(144, BITWIDTH))),
    (std_logic_vector(to_signed(491, BITWIDTH)), std_logic_vector(to_signed(1185, BITWIDTH)), std_logic_vector(to_signed(1062, BITWIDTH))),
    (std_logic_vector(to_signed(-306, BITWIDTH)), std_logic_vector(to_signed(1131, BITWIDTH)), std_logic_vector(to_signed(-799, BITWIDTH)))
    );
    i_kernel(17)(0) <= (
    (std_logic_vector(to_signed(235, BITWIDTH)), std_logic_vector(to_signed(-1322, BITWIDTH)), std_logic_vector(to_signed(-189, BITWIDTH))),
    (std_logic_vector(to_signed(-880, BITWIDTH)), std_logic_vector(to_signed(-733, BITWIDTH)), std_logic_vector(to_signed(1113, BITWIDTH))),
    (std_logic_vector(to_signed(-687, BITWIDTH)), std_logic_vector(to_signed(-902, BITWIDTH)), std_logic_vector(to_signed(965, BITWIDTH)))
    );
    i_kernel(18)(0) <= (
    (std_logic_vector(to_signed(691, BITWIDTH)), std_logic_vector(to_signed(1136, BITWIDTH)), std_logic_vector(to_signed(-553, BITWIDTH))),
    (std_logic_vector(to_signed(493, BITWIDTH)), std_logic_vector(to_signed(-100, BITWIDTH)), std_logic_vector(to_signed(-503, BITWIDTH))),
    (std_logic_vector(to_signed(-969, BITWIDTH)), std_logic_vector(to_signed(-764, BITWIDTH)), std_logic_vector(to_signed(-587, BITWIDTH)))
    );
    i_kernel(19)(0) <= (
    (std_logic_vector(to_signed(584, BITWIDTH)), std_logic_vector(to_signed(-150, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH))),
    (std_logic_vector(to_signed(1638, BITWIDTH)), std_logic_vector(to_signed(1041, BITWIDTH)), std_logic_vector(to_signed(1018, BITWIDTH))),
    (std_logic_vector(to_signed(-259, BITWIDTH)), std_logic_vector(to_signed(-1280, BITWIDTH)), std_logic_vector(to_signed(855, BITWIDTH)))
    );
    i_kernel(20)(0) <= (
    (std_logic_vector(to_signed(124, BITWIDTH)), std_logic_vector(to_signed(-629, BITWIDTH)), std_logic_vector(to_signed(-1162, BITWIDTH))),
    (std_logic_vector(to_signed(-15, BITWIDTH)), std_logic_vector(to_signed(-1264, BITWIDTH)), std_logic_vector(to_signed(1297, BITWIDTH))),
    (std_logic_vector(to_signed(-1132, BITWIDTH)), std_logic_vector(to_signed(-769, BITWIDTH)), std_logic_vector(to_signed(443, BITWIDTH)))
    );
    i_kernel(21)(0) <= (
    (std_logic_vector(to_signed(-1104, BITWIDTH)), std_logic_vector(to_signed(240, BITWIDTH)), std_logic_vector(to_signed(-257, BITWIDTH))),
    (std_logic_vector(to_signed(-1065, BITWIDTH)), std_logic_vector(to_signed(-10, BITWIDTH)), std_logic_vector(to_signed(712, BITWIDTH))),
    (std_logic_vector(to_signed(-898, BITWIDTH)), std_logic_vector(to_signed(831, BITWIDTH)), std_logic_vector(to_signed(946, BITWIDTH)))
    );
    i_kernel(22)(0) <= (
    (std_logic_vector(to_signed(1572, BITWIDTH)), std_logic_vector(to_signed(-771, BITWIDTH)), std_logic_vector(to_signed(451, BITWIDTH))),
    (std_logic_vector(to_signed(-783, BITWIDTH)), std_logic_vector(to_signed(1231, BITWIDTH)), std_logic_vector(to_signed(-616, BITWIDTH))),
    (std_logic_vector(to_signed(1223, BITWIDTH)), std_logic_vector(to_signed(100, BITWIDTH)), std_logic_vector(to_signed(-441, BITWIDTH)))
    );
    i_kernel(23)(0) <= (
    (std_logic_vector(to_signed(309, BITWIDTH)), std_logic_vector(to_signed(173, BITWIDTH)), std_logic_vector(to_signed(235, BITWIDTH))),
    (std_logic_vector(to_signed(455, BITWIDTH)), std_logic_vector(to_signed(653, BITWIDTH)), std_logic_vector(to_signed(-1278, BITWIDTH))),
    (std_logic_vector(to_signed(1169, BITWIDTH)), std_logic_vector(to_signed(1465, BITWIDTH)), std_logic_vector(to_signed(1010, BITWIDTH)))
    );
    i_kernel(24)(0) <= (
    (std_logic_vector(to_signed(1115, BITWIDTH)), std_logic_vector(to_signed(-1063, BITWIDTH)), std_logic_vector(to_signed(-664, BITWIDTH))),
    (std_logic_vector(to_signed(1191, BITWIDTH)), std_logic_vector(to_signed(-1606, BITWIDTH)), std_logic_vector(to_signed(830, BITWIDTH))),
    (std_logic_vector(to_signed(-752, BITWIDTH)), std_logic_vector(to_signed(-1067, BITWIDTH)), std_logic_vector(to_signed(759, BITWIDTH)))
    );
    i_kernel(25)(0) <= (
    (std_logic_vector(to_signed(-1384, BITWIDTH)), std_logic_vector(to_signed(-979, BITWIDTH)), std_logic_vector(to_signed(516, BITWIDTH))),
    (std_logic_vector(to_signed(892, BITWIDTH)), std_logic_vector(to_signed(1610, BITWIDTH)), std_logic_vector(to_signed(-201, BITWIDTH))),
    (std_logic_vector(to_signed(-957, BITWIDTH)), std_logic_vector(to_signed(717, BITWIDTH)), std_logic_vector(to_signed(-592, BITWIDTH)))
    );
    i_kernel(26)(0) <= (
    (std_logic_vector(to_signed(-345, BITWIDTH)), std_logic_vector(to_signed(553, BITWIDTH)), std_logic_vector(to_signed(-754, BITWIDTH))),
    (std_logic_vector(to_signed(1065, BITWIDTH)), std_logic_vector(to_signed(736, BITWIDTH)), std_logic_vector(to_signed(-1265, BITWIDTH))),
    (std_logic_vector(to_signed(-1220, BITWIDTH)), std_logic_vector(to_signed(-652, BITWIDTH)), std_logic_vector(to_signed(561, BITWIDTH)))
    );
    i_kernel(27)(0) <= (
    (std_logic_vector(to_signed(-280, BITWIDTH)), std_logic_vector(to_signed(-426, BITWIDTH)), std_logic_vector(to_signed(401, BITWIDTH))),
    (std_logic_vector(to_signed(-878, BITWIDTH)), std_logic_vector(to_signed(-866, BITWIDTH)), std_logic_vector(to_signed(-1066, BITWIDTH))),
    (std_logic_vector(to_signed(1456, BITWIDTH)), std_logic_vector(to_signed(1411, BITWIDTH)), std_logic_vector(to_signed(-387, BITWIDTH)))
    );
    i_kernel(28)(0) <= (
    (std_logic_vector(to_signed(-544, BITWIDTH)), std_logic_vector(to_signed(496, BITWIDTH)), std_logic_vector(to_signed(84, BITWIDTH))),
    (std_logic_vector(to_signed(-1331, BITWIDTH)), std_logic_vector(to_signed(513, BITWIDTH)), std_logic_vector(to_signed(648, BITWIDTH))),
    (std_logic_vector(to_signed(-371, BITWIDTH)), std_logic_vector(to_signed(-421, BITWIDTH)), std_logic_vector(to_signed(888, BITWIDTH)))
    );
    i_kernel(29)(0) <= (
    (std_logic_vector(to_signed(1010, BITWIDTH)), std_logic_vector(to_signed(-122, BITWIDTH)), std_logic_vector(to_signed(1710, BITWIDTH))),
    (std_logic_vector(to_signed(59, BITWIDTH)), std_logic_vector(to_signed(-1079, BITWIDTH)), std_logic_vector(to_signed(748, BITWIDTH))),
    (std_logic_vector(to_signed(-1472, BITWIDTH)), std_logic_vector(to_signed(535, BITWIDTH)), std_logic_vector(to_signed(-1159, BITWIDTH)))
    );
    i_kernel(30)(0) <= (
    (std_logic_vector(to_signed(310, BITWIDTH)), std_logic_vector(to_signed(807, BITWIDTH)), std_logic_vector(to_signed(697, BITWIDTH))),
    (std_logic_vector(to_signed(1074, BITWIDTH)), std_logic_vector(to_signed(-211, BITWIDTH)), std_logic_vector(to_signed(-544, BITWIDTH))),
    (std_logic_vector(to_signed(-1273, BITWIDTH)), std_logic_vector(to_signed(-406, BITWIDTH)), std_logic_vector(to_signed(-804, BITWIDTH)))
    );
    i_kernel(31)(0) <= (
    (std_logic_vector(to_signed(-196, BITWIDTH)), std_logic_vector(to_signed(-301, BITWIDTH)), std_logic_vector(to_signed(396, BITWIDTH))),
    (std_logic_vector(to_signed(1299, BITWIDTH)), std_logic_vector(to_signed(436, BITWIDTH)), std_logic_vector(to_signed(-355, BITWIDTH))),
    (std_logic_vector(to_signed(-789, BITWIDTH)), std_logic_vector(to_signed(-1270, BITWIDTH)), std_logic_vector(to_signed(1108, BITWIDTH)))
    );

    -----------------------------------------------------------------------------------
    -- TEST process
    -----------------------------------------------------------------------------------
    stimulus : process
        variable line_buffer : line;
    begin
        -- Reset the system
        reset_n <= '0';
        wait for i_clk_period/2;
        reset_n <= '1';

        -- Enable the system
        i_sys_enable <= '1';

        i_data_valid <= '1';
        wait for i_clk_period * 2;
        i_data_valid <= '0';

        -- Wait for output to be valid and write to file
        wait until o_data_valid = '1';
        report "End of computation at time " & time'image(now);

        -- Open the file
        file_open(output_file, "conv_output_results.txt", write_mode);

        for k in 0 to KERNEL_NUMBER - 1 loop
            for i in ((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1) downto 0 loop
                for j in ((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1) downto 0 loop
                    write(line_buffer, to_integer(signed(o_data(k)(i)(j))));
                    writeline(output_file, line_buffer);
                end loop;
            end loop;
        end loop;

        -- Close the file
        file_close(output_file);

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration conv_mnist_conf of conv_mnist is
    for conv_mnist_arch
        for UUT : conv
            use configuration LIB_RTL.conv_conf;
        end for;
    end for;
end configuration conv_mnist_conf;