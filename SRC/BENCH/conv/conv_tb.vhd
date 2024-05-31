
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity conv_tb is
end;

architecture conv_tb_arch of conv_tb is
    -- Clock period
    constant i_clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH       : integer := 8;
    constant INPUT_SIZE     : integer := 3;
    constant CHANNEL_NUMBER : integer := 3;
    constant KERNEL_SIZE    : integer := 3;
    constant KERNEL_NUMBER  : integer := 1;
    constant PADDING        : integer := 1;
    constant STRIDE         : integer := 1;
    -- Ports
    signal clock    : std_logic := '0';
    signal reset_n  : std_logic := '0';
    signal i_enable : std_logic := '1';
    signal i_data   : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_kernel : t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_bias   : t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_data   : t_mat((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Output data
    signal o_valid  : std_logic;

    component conv
        generic (
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer;
            KERNEL_NUMBER  : integer;
            PADDING        : integer;
            STRIDE         : integer
        );
        port (
            clock    : in std_logic;
            reset_n  : in std_logic;
            i_enable : in std_logic;
            i_data   : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernel : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias   : in t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data   : out t_mat((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Output data
            o_valid  : out std_logic
        );
    end component;
begin

    UUT : conv
    generic map(
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE,
        KERNEL_NUMBER  => KERNEL_NUMBER,
        PADDING        => PADDING,
        STRIDE         => STRIDE
    )
    port map(
        clock    => clock,
        reset_n  => reset_n,
        i_enable => i_enable,
        i_data   => i_data,
        i_kernel => i_kernel,
        i_bias   => i_bias,
        o_data   => o_data,
        o_valid  => o_valid
    );

    i_data(0) <= (
    (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(3, BITWIDTH))),
    (std_logic_vector(to_signed(4, BITWIDTH)), std_logic_vector(to_signed(5, BITWIDTH)), std_logic_vector(to_signed(6, BITWIDTH))),
    (std_logic_vector(to_signed(7, BITWIDTH)), std_logic_vector(to_signed(8, BITWIDTH)), std_logic_vector(to_signed(9, BITWIDTH))));

    i_data(1) <= (
    (std_logic_vector(to_signed(-1, BITWIDTH)), std_logic_vector(to_signed(-2, BITWIDTH)), std_logic_vector(to_signed(-3, BITWIDTH))),
    (std_logic_vector(to_signed(-4, BITWIDTH)), std_logic_vector(to_signed(-5, BITWIDTH)), std_logic_vector(to_signed(-6, BITWIDTH))),
    (std_logic_vector(to_signed(-7, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(-9, BITWIDTH)))
    );

    i_data(2) <= (
    (std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(11, BITWIDTH)), std_logic_vector(to_signed(12, BITWIDTH))),
    (std_logic_vector(to_signed(13, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(15, BITWIDTH))),
    (std_logic_vector(to_signed(16, BITWIDTH)), std_logic_vector(to_signed(17, BITWIDTH)), std_logic_vector(to_signed(18, BITWIDTH))));

    i_kernel(0)(0) <= (
    (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH))));

    i_kernel(0)(1) <= i_kernel(0)(0);
    i_kernel(0)(2) <= i_kernel(0)(0);

    i_bias <= (others => std_logic_vector(to_signed(0, BITWIDTH)));

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

        -- Enable the system
        i_enable <= '1';
        wait for 6 * 10 * i_clk_period;
    end process stimulus;

end;

configuration conv_tb_conf of conv_tb is
    for conv_tb_arch
        for UUT : conv
            use entity LIB_RTL.conv(conv_arch);
        end for;
    end for;
end configuration conv_tb_conf;