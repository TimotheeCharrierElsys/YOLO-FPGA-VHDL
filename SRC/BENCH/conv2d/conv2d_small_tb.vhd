library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity conv2d_small_tb is
end;

architecture conv2d_small_tb_arch of conv2d_small_tb is
    -- Clock period
    constant i_clk_period : time := 5 ns;
    -- Generics
    constant DO_PIPELINE    : std_logic := '1';
    constant BITWIDTH       : integer   := 16;
    constant INPUT_SIZE     : integer   := 5;
    constant CHANNEL_NUMBER : integer   := 3;
    constant KERNEL_SIZE    : integer   := 3;
    constant KERNEL_NUMBER  : integer   := 1;
    constant PADDING        : integer   := 0;
    constant STRIDE         : integer   := 1;
    -- Ports
    signal clock        : std_logic                                                                                                                                           := '0';
    signal reset_n      : std_logic                                                                                                                                           := '0';
    signal i_sys_enable : std_logic                                                                                                                                           := '0';
    signal i_data_valid : std_logic                                                                                                                                           := '0';
    signal i_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)                                      := (others => (others => (others => (others => '0'))));
    signal i_kernel     : t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) := (others => (others => (others => (others => (others => '0')))));
    signal i_bias       : t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_data       : t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data_valid : std_logic;

    component conv2d
        generic (
            DO_PIPELINE    : std_logic;
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer;
            KERNEL_NUMBER  : integer;
            PADDING        : integer;
            STRIDE         : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data_valid : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernel     : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin

    UUT : conv2d
    generic map(
        DO_PIPELINE    => DO_PIPELINE,
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE,
        KERNEL_NUMBER  => KERNEL_NUMBER,
        PADDING        => PADDING,
        STRIDE         => STRIDE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data_valid => i_data_valid,
        i_data       => i_data,
        i_kernel     => i_kernel,
        i_bias       => i_bias,
        o_data       => o_data,
        o_data_valid => o_data_valid
    );

    i_bias <= (others => std_logic_vector(to_signed(-1, BITWIDTH)));

    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n      <= '0';
        i_data_valid <= '0';
        wait for i_clk_period;
        reset_n      <= '1';
        i_sys_enable <= '1';

        i_data(0) <= (
        (std_logic_vector(to_signed(1, 16)), std_logic_vector(to_signed(2, 16)), std_logic_vector(to_signed(3, 16)), std_logic_vector(to_signed(4, 16)), std_logic_vector(to_signed(5, 16))),
        (std_logic_vector(to_signed(6, 16)), std_logic_vector(to_signed(7, 16)), std_logic_vector(to_signed(8, 16)), std_logic_vector(to_signed(9, 16)), std_logic_vector(to_signed(10, 16))),
        (std_logic_vector(to_signed(11, 16)), std_logic_vector(to_signed(12, 16)), std_logic_vector(to_signed(13, 16)), std_logic_vector(to_signed(14, 16)), std_logic_vector(to_signed(15, 16))),
        (std_logic_vector(to_signed(16, 16)), std_logic_vector(to_signed(17, 16)), std_logic_vector(to_signed(18, 16)), std_logic_vector(to_signed(19, 16)), std_logic_vector(to_signed(20, 16))),
        (std_logic_vector(to_signed(21, 16)), std_logic_vector(to_signed(22, 16)), std_logic_vector(to_signed(23, 16)), std_logic_vector(to_signed(24, 16)), std_logic_vector(to_signed(25, 16)))
        );

        i_data(1) <= (
        (std_logic_vector(to_signed(26, 16)), std_logic_vector(to_signed(27, 16)), std_logic_vector(to_signed(28, 16)), std_logic_vector(to_signed(29, 16)), std_logic_vector(to_signed(30, 16))),
        (std_logic_vector(to_signed(31, 16)), std_logic_vector(to_signed(32, 16)), std_logic_vector(to_signed(33, 16)), std_logic_vector(to_signed(34, 16)), std_logic_vector(to_signed(35, 16))),
        (std_logic_vector(to_signed(36, 16)), std_logic_vector(to_signed(37, 16)), std_logic_vector(to_signed(38, 16)), std_logic_vector(to_signed(39, 16)), std_logic_vector(to_signed(40, 16))),
        (std_logic_vector(to_signed(41, 16)), std_logic_vector(to_signed(42, 16)), std_logic_vector(to_signed(43, 16)), std_logic_vector(to_signed(44, 16)), std_logic_vector(to_signed(45, 16))),
        (std_logic_vector(to_signed(46, 16)), std_logic_vector(to_signed(47, 16)), std_logic_vector(to_signed(48, 16)), std_logic_vector(to_signed(49, 16)), std_logic_vector(to_signed(50, 16)))
        );

        i_data(2) <= (
        (std_logic_vector(to_signed(51, 16)), std_logic_vector(to_signed(52, 16)), std_logic_vector(to_signed(53, 16)), std_logic_vector(to_signed(54, 16)), std_logic_vector(to_signed(55, 16))),
        (std_logic_vector(to_signed(56, 16)), std_logic_vector(to_signed(57, 16)), std_logic_vector(to_signed(58, 16)), std_logic_vector(to_signed(59, 16)), std_logic_vector(to_signed(60, 16))),
        (std_logic_vector(to_signed(61, 16)), std_logic_vector(to_signed(62, 16)), std_logic_vector(to_signed(63, 16)), std_logic_vector(to_signed(64, 16)), std_logic_vector(to_signed(65, 16))),
        (std_logic_vector(to_signed(66, 16)), std_logic_vector(to_signed(67, 16)), std_logic_vector(to_signed(68, 16)), std_logic_vector(to_signed(69, 16)), std_logic_vector(to_signed(70, 16))),
        (std_logic_vector(to_signed(71, 16)), std_logic_vector(to_signed(72, 16)), std_logic_vector(to_signed(73, 16)), std_logic_vector(to_signed(74, 16)), std_logic_vector(to_signed(75, 16)))
        );

        -- -- FILTER IDENTITY
        i_kernel(0)(0) <= (
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(1, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)))
        );
        i_kernel(0)(1) <= (
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(1, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)))
        );
        i_kernel(0)(2) <= (
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(1, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)))
        );
        wait for i_clk_period/2;
        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';

        -- Wait for output to be valid and write to file
        wait until o_data_valid = '1';

        -- End simulation
        wait;

    end process stimulus;
end conv2d_small_tb_arch;

configuration conv2d_small_tb_conf of conv2d_small_tb is
    for conv2d_small_tb_arch
        for UUT : conv2d
            use configuration LIB_RTL.conv2d_fc_conf;
        end for;
    end for;
end configuration conv2d_small_tb_conf;