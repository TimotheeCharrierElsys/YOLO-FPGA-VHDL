-----------------------------------------------------------------------------------
--!     @Testbench    volume_slice_tb
--!     @brief        This testbench verifies the functionality of the volume_slice
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity volume_slice_tb is
end entity;

architecture volume_slice_tb_arch of volume_slice_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period      : time    := 10 ns; --! Clock period
    constant NUM_REPEATS       : integer := 26;
    constant KERNEL_SIZE       : integer := 3;
    constant BITWIDTH          : integer := 8;
    constant INPUT_SIZE        : integer := 5;
    constant CHANNEL_NUMBER    : integer := 3;
    constant STRIDE            : integer := 1;
    constant PADDING           : integer := 1;
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output  

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock                   : std_logic := '0';
    signal reset_n                 : std_logic := '0';
    signal i_sys_enable            : std_logic := '0';
    signal i_data                  : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_data_valid            : std_logic := '0';
    signal i_last_computation_done : std_logic := '0';
    signal o_data                  : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_done                  : std_logic;
    signal o_computation_start     : std_logic;
    signal o_current_row           : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
    signal o_current_col           : std_logic_vector(OUTPUT_SIZE - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            CHANNEL_NUMBER    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(OUTPUT_SIZE - 1 downto 0);
            o_current_col           : out std_logic_vector(OUTPUT_SIZE - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER    => CHANNEL_NUMBER,
        KERNEL_SIZE       => KERNEL_SIZE,
        PADDING           => PADDING,
        STRIDE            => STRIDE,
        OUTPUT_SIZE       => OUTPUT_SIZE
    )
    port map(
        clock                   => clock,
        reset_n                 => reset_n,
        i_sys_enable            => i_sys_enable,
        i_data                  => i_data,
        i_data_valid            => i_data_valid,
        i_last_computation_done => i_last_computation_done,
        o_data                  => o_data,
        o_done                  => o_done,
        o_computation_start     => o_computation_start,
        o_current_row           => o_current_row,
        o_current_col           => o_current_col
    );

    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    i_data(0) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(3, BITWIDTH)), std_logic_vector(to_signed(4, BITWIDTH)), std_logic_vector(to_signed(5, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(6, BITWIDTH)), std_logic_vector(to_signed(7, BITWIDTH)), std_logic_vector(to_signed(8, BITWIDTH)), std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(11, BITWIDTH)), std_logic_vector(to_signed(12, BITWIDTH)), std_logic_vector(to_signed(13, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(15, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(16, BITWIDTH)), std_logic_vector(to_signed(17, BITWIDTH)), std_logic_vector(to_signed(18, BITWIDTH)), std_logic_vector(to_signed(19, BITWIDTH)), std_logic_vector(to_signed(20, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(21, BITWIDTH)), std_logic_vector(to_signed(22, BITWIDTH)), std_logic_vector(to_signed(23, BITWIDTH)), std_logic_vector(to_signed(24, BITWIDTH)), std_logic_vector(to_signed(25, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

    i_data(1) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-1, BITWIDTH)), std_logic_vector(to_signed(-2, BITWIDTH)), std_logic_vector(to_signed(-3, BITWIDTH)), std_logic_vector(to_signed(-4, BITWIDTH)), std_logic_vector(to_signed(-5, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-6, BITWIDTH)), std_logic_vector(to_signed(-7, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(-9, BITWIDTH)), std_logic_vector(to_signed(-10, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-11, BITWIDTH)), std_logic_vector(to_signed(-12, BITWIDTH)), std_logic_vector(to_signed(-13, BITWIDTH)), std_logic_vector(to_signed(-14, BITWIDTH)), std_logic_vector(to_signed(-15, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-16, BITWIDTH)), std_logic_vector(to_signed(-17, BITWIDTH)), std_logic_vector(to_signed(-18, BITWIDTH)), std_logic_vector(to_signed(-19, BITWIDTH)), std_logic_vector(to_signed(-20, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-21, BITWIDTH)), std_logic_vector(to_signed(-22, BITWIDTH)), std_logic_vector(to_signed(-23, BITWIDTH)), std_logic_vector(to_signed(-24, BITWIDTH)), std_logic_vector(to_signed(-25, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

    i_data(2) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(11, BITWIDTH)), std_logic_vector(to_signed(12, BITWIDTH)), std_logic_vector(to_signed(13, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(15, BITWIDTH)), std_logic_vector(to_signed(16, BITWIDTH)), std_logic_vector(to_signed(17, BITWIDTH)), std_logic_vector(to_signed(18, BITWIDTH)), std_logic_vector(to_signed(19, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(20, BITWIDTH)), std_logic_vector(to_signed(21, BITWIDTH)), std_logic_vector(to_signed(22, BITWIDTH)), std_logic_vector(to_signed(23, BITWIDTH)), std_logic_vector(to_signed(24, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(25, BITWIDTH)), std_logic_vector(to_signed(26, BITWIDTH)), std_logic_vector(to_signed(27, BITWIDTH)), std_logic_vector(to_signed(28, BITWIDTH)), std_logic_vector(to_signed(29, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(30, BITWIDTH)), std_logic_vector(to_signed(31, BITWIDTH)), std_logic_vector(to_signed(32, BITWIDTH)), std_logic_vector(to_signed(33, BITWIDTH)), std_logic_vector(to_signed(34, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for i_clk_period;
        reset_n      <= '1';
        i_sys_enable <= '1';
        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';
        wait for 2 * i_clk_period;

        for i in 1 to NUM_REPEATS loop
            i_last_computation_done <= '1';
            wait for i_clk_period;
            i_last_computation_done <= '0';
            wait for 2 * i_clk_period;
        end loop;

        wait for 10 * i_clk_period;

        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';
        wait for 2 * i_clk_period;

        for i in 1 to NUM_REPEATS loop
            i_last_computation_done <= '1';
            wait for i_clk_period;
            i_last_computation_done <= '0';
            wait for 2 * i_clk_period;
        end loop;

        wait for 10 * i_clk_period;
    end process stimulus;

end architecture;

configuration volume_slice_tb_conf of volume_slice_tb is
    for volume_slice_tb_arch
        for UUT : volume_slice
            use configuration LIB_RTL.volume_slice_conf;
        end for;
    end for;
end configuration volume_slice_tb_conf;