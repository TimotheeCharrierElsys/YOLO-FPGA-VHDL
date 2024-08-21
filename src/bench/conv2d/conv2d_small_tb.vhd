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
    constant USE_MAC_ARCH   : std_logic := '1';
    constant DO_PIPELINE    : std_logic := '0';
    constant BITWIDTH       : integer   := 16;
    constant INPUT_SIZE     : integer   := 5;
    constant CHANNEL_NUMBER : integer   := 3;
    constant KERNEL_SIZE    : integer   := 3;
    constant KERNEL_NUMBER  : integer   := 1;
    constant PADDING        : integer   := 1;
    constant STRIDE         : integer   := 1;
    -- Ports
    signal clock        : std_logic                                                                                                                                           := '0';
    signal reset_n      : std_logic                                                                                                                                           := '0';
    signal i_sys_enable : std_logic                                                                                                                                           := '0';
    signal i_data_valid : std_logic                                                                                                                                           := '0';
    signal i_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)                                      := (others => (others => (others => (others => '0'))));
    signal i_kernel     : t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) := (others => (others => (others => (others => (others => '0')))));
    signal i_bias       : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data       : t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data_valid : std_logic;

    component conv2d
        generic (
            USE_MAC_ARCH   : std_logic;
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
            i_bias       : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data       : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin

    UUT : conv2d
    generic map(
        USE_MAC_ARCH   => USE_MAC_ARCH,
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

    i_bias <= (others => std_logic_vector(to_signed(-1, 2 * BITWIDTH)));

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
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(100, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16))),
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(0, 16)))
        );

        i_data(1) <= (
        (std_logic_vector(to_signed(152, 16)), std_logic_vector(to_signed(253, 16)), std_logic_vector(to_signed(26, 16)), std_logic_vector(to_signed(165, 16)), std_logic_vector(to_signed(239, 16))),
        (std_logic_vector(to_signed(31, 16)), std_logic_vector(to_signed(10, 16)), std_logic_vector(to_signed(98, 16)), std_logic_vector(to_signed(85, 16)), std_logic_vector(to_signed(80, 16))),
        (std_logic_vector(to_signed(42, 16)), std_logic_vector(to_signed(29, 16)), std_logic_vector(to_signed(121, 16)), std_logic_vector(to_signed(65, 16)), std_logic_vector(to_signed(125, 16))),
        (std_logic_vector(to_signed(109, 16)), std_logic_vector(to_signed(55, 16)), std_logic_vector(to_signed(209, 16)), std_logic_vector(to_signed(117, 16)), std_logic_vector(to_signed(41, 16))),
        (std_logic_vector(to_signed(248, 16)), std_logic_vector(to_signed(86, 16)), std_logic_vector(to_signed(89, 16)), std_logic_vector(to_signed(198, 16)), std_logic_vector(to_signed(155, 16)))
        );

        i_data(2) <= (
        (std_logic_vector(to_signed(-81, 16)), std_logic_vector(to_signed(190, 16)), std_logic_vector(to_signed(-205, 16)), std_logic_vector(to_signed(108, 16)), std_logic_vector(to_signed(-201, 16))),
        (std_logic_vector(to_signed(-12, 16)), std_logic_vector(to_signed(64, 16)), std_logic_vector(to_signed(249, 16)), std_logic_vector(to_signed(-125, 16)), std_logic_vector(to_signed(229, 16))),
        (std_logic_vector(to_signed(51, 16)), std_logic_vector(to_signed(-121, 16)), std_logic_vector(to_signed(-235, 16)), std_logic_vector(to_signed(73, 16)), std_logic_vector(to_signed(-89, 16))),
        (std_logic_vector(to_signed(18, 16)), std_logic_vector(to_signed(132, 16)), std_logic_vector(to_signed(-167, 16)), std_logic_vector(to_signed(60, 16)), std_logic_vector(to_signed(-242, 16))),
        (std_logic_vector(to_signed(-14, 16)), std_logic_vector(to_signed(250, 16)), std_logic_vector(to_signed(9, 16)), std_logic_vector(to_signed(90, 16)), std_logic_vector(to_signed(-203, 16)))
        );

        -- -- FILTER IDENTITY
        i_kernel(0)(0) <= (
        (std_logic_vector(to_signed(-3, 16)), std_logic_vector(to_signed(8, 16)), std_logic_vector(to_signed(4, 16))),
        (std_logic_vector(to_signed(-6, 16)), std_logic_vector(to_signed(-7, 16)), std_logic_vector(to_signed(10, 16))),
        (std_logic_vector(to_signed(1, 16)), std_logic_vector(to_signed(-10, 16)), std_logic_vector(to_signed(-2, 16)))
        );
        i_kernel(0)(1) <= (
        (std_logic_vector(to_signed(9, 16)), std_logic_vector(to_signed(3, 16)), std_logic_vector(to_signed(-4, 16))),
        (std_logic_vector(to_signed(5, 16)), std_logic_vector(to_signed(-8, 16)), std_logic_vector(to_signed(6, 16))),
        (std_logic_vector(to_signed(-9, 16)), std_logic_vector(to_signed(7, 16)), std_logic_vector(to_signed(-5, 16)))
        );
        i_kernel(0)(2) <= (
        (std_logic_vector(to_signed(0, 16)), std_logic_vector(to_signed(2, 16)), std_logic_vector(to_signed(-3, 16))),
        (std_logic_vector(to_signed(-6, 16)), std_logic_vector(to_signed(4, 16)), std_logic_vector(to_signed(-7, 16))),
        (std_logic_vector(to_signed(8, 16)), std_logic_vector(to_signed(-1, 16)), std_logic_vector(to_signed(10, 16)))
        );

        wait for i_clk_period/2;
        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';

        -- Wait for output to be valid
        wait until o_data_valid = '1';

        assert o_data(0)(0)(0) = std_logic_vector(to_signed(-951, 2 * BITWIDTH))
        report "Output do not match expected value -951 - Gotten = " & integer'image(to_integer(signed(o_data(0)(0)(0))))
            severity error;

        assert o_data(0)(0)(1) = std_logic_vector(to_signed(-3022, 2 * BITWIDTH))
        report "Output do not match expected value -3022 - Gotten = " & integer'image(to_integer(signed(o_data(0)(0)(1))))
            severity error;

        assert o_data(0)(0)(2) = std_logic_vector(to_signed(641, 2 * BITWIDTH))
        report "Output do not match expected value 641 - Gotten = " & integer'image(to_integer(signed(o_data(0)(0)(2))))
            severity error;

        assert o_data(0)(0)(3) = std_logic_vector(to_signed(-1041, 2 * BITWIDTH))
        report "Output do not match expected value -1041 - Gotten = " & integer'image(to_integer(signed(o_data(0)(0)(3))))
            severity error;

        assert o_data(0)(0)(4) = std_logic_vector(to_signed(-1805, 2 * BITWIDTH))
        report "Output do not match expected value -1805 - Gotten = " & integer'image(to_integer(signed(o_data(0)(0)(4))))
            severity error;

        assert o_data(0)(1)(0) = std_logic_vector(to_signed(-649, 2 * BITWIDTH))
        report "Output do not match expected value -649 - Gotten = " & integer'image(to_integer(signed(o_data(0)(1)(0))))
            severity error;

        assert o_data(0)(1)(1) = std_logic_vector(to_signed(559, 2 * BITWIDTH))
        report "Output do not match expected value 559 - Gotten = " & integer'image(to_integer(signed(o_data(0)(1)(1))))
            severity error;

        assert o_data(0)(1)(2) = std_logic_vector(to_signed(-3011, 2 * BITWIDTH))
        report "Output do not match expected value -3011 - Gotten = " & integer'image(to_integer(signed(o_data(0)(1)(2))))
            severity error;

        assert o_data(0)(1)(3) = std_logic_vector(to_signed(1026, 2 * BITWIDTH))
        report "Output do not match expected value 1026 - Gotten = " & integer'image(to_integer(signed(o_data(0)(1)(3))))
            severity error;

        assert o_data(0)(1)(4) = std_logic_vector(to_signed(-814, 2 * BITWIDTH))
        report "Output do not match expected value -814 - Gotten = " & integer'image(to_integer(signed(o_data(0)(1)(4))))
            severity error;

        assert o_data(0)(2)(0) = std_logic_vector(to_signed(-3831, 2 * BITWIDTH))
        report "Output do not match expected value -3831 - Gotten = " & integer'image(to_integer(signed(o_data(0)(2)(0))))
            severity error;

        assert o_data(0)(2)(1) = std_logic_vector(to_signed(8638, 2 * BITWIDTH))
        report "Output do not match expected value 8638 - Gotten = " & integer'image(to_integer(signed(o_data(0)(2)(1))))
            severity error;

        assert o_data(0)(2)(2) = std_logic_vector(to_signed(-1709, 2 * BITWIDTH))
        report "Output do not match expected value -1709 - Gotten = " & integer'image(to_integer(signed(o_data(0)(2)(2))))
            severity error;

        assert o_data(0)(2)(3) = std_logic_vector(to_signed(3254, 2 * BITWIDTH))
        report "Output do not match expected value 3254 - Gotten = " & integer'image(to_integer(signed(o_data(0)(2)(3))))
            severity error;

        assert o_data(0)(2)(4) = std_logic_vector(to_signed(2247, 2 * BITWIDTH))
        report "Output do not match expected value 2247 - Gotten = " & integer'image(to_integer(signed(o_data(0)(2)(4))))
            severity error;

        assert o_data(0)(3)(0) = std_logic_vector(to_signed(3507, 2 * BITWIDTH))
        report "Output do not match expected value 3507 - Gotten = " & integer'image(to_integer(signed(o_data(0)(3)(0))))
            severity error;

        assert o_data(0)(3)(1) = std_logic_vector(to_signed(-6115, 2 * BITWIDTH))
        report "Output do not match expected value -6115 - Gotten = " & integer'image(to_integer(signed(o_data(0)(3)(1))))
            severity error;

        assert o_data(0)(3)(2) = std_logic_vector(to_signed(2924, 2 * BITWIDTH))
        report "Output do not match expected value 2924 - Gotten = " & integer'image(to_integer(signed(o_data(0)(3)(2))))
            severity error;

        assert o_data(0)(3)(3) = std_logic_vector(to_signed(-2109, 2 * BITWIDTH))
        report "Output do not match expected value -2109 - Gotten = " & integer'image(to_integer(signed(o_data(0)(3)(3))))
            severity error;

        assert o_data(0)(3)(4) = std_logic_vector(to_signed(246, 2 * BITWIDTH))
        report "Output do not match expected value 246 - Gotten = " & integer'image(to_integer(signed(o_data(0)(3)(4))))
            severity error;

        assert o_data(0)(4)(0) = std_logic_vector(to_signed(-1750, 2 * BITWIDTH))
        report "Output do not match expected value -1750 - Gotten = " & integer'image(to_integer(signed(o_data(0)(4)(0))))
            severity error;

        assert o_data(0)(4)(1) = std_logic_vector(to_signed(2689, 2 * BITWIDTH))
        report "Output do not match expected value 2689 - Gotten = " & integer'image(to_integer(signed(o_data(0)(4)(1))))
            severity error;

        assert o_data(0)(4)(2) = std_logic_vector(to_signed(661, 2 * BITWIDTH))
        report "Output do not match expected value 661 - Gotten = " & integer'image(to_integer(signed(o_data(0)(4)(2))))
            severity error;

        assert o_data(0)(4)(3) = std_logic_vector(to_signed(2526, 2 * BITWIDTH))
        report "Output do not match expected value 2526 - Gotten = " & integer'image(to_integer(signed(o_data(0)(4)(3))))
            severity error;

        assert o_data(0)(4)(4) = std_logic_vector(to_signed(-1257, 2 * BITWIDTH))
        report "Output do not match expected value -1257 - Gotten = " & integer'image(to_integer(signed(o_data(0)(4)(4))))
            severity error;

        -- End simulation
        wait;

    end process stimulus;
end conv2d_small_tb_arch;

configuration conv2d_small_tb_conf of conv2d_small_tb is
    for conv2d_small_tb_arch
        for UUT : conv2d
            use configuration LIB_RTL.conv2d_conf;
        end for;
    end for;
end configuration conv2d_small_tb_conf;