library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity maxpool2d_tb is
end;

architecture maxpool2d_tb_arch of maxpool2d_tb is
    -- Clock period
    constant i_clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH       : integer := 16;
    constant INPUT_SIZE     : integer := 3;
    constant CHANNEL_NUMBER : integer := 3;
    constant KERNEL_SIZE    : integer := 3;
    constant PADDING        : integer := 2;
    constant STRIDE         : integer := 2;

    -- Ports
    signal clock        : std_logic                                                                                                      := '0';
    signal reset_n      : std_logic                                                                                                      := '0';
    signal i_sys_enable : std_logic                                                                                                      := '0';
    signal i_data_valid : std_logic                                                                                                      := '0';
    signal i_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) := (others => (others => (others => (others => '0'))));
    signal o_data       : t_volume(CHANNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_data_valid : std_logic;

    component maxpool2d
        generic (
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer;
            PADDING        : integer;
            STRIDE         : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid : in std_logic;
            o_data       : out t_volume(CHANNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin

    UUT : maxpool2d
    generic map(
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE,
        PADDING        => PADDING,
        STRIDE         => STRIDE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data,
        i_data_valid => i_data_valid,
        o_data       => o_data,
        o_data_valid => o_data_valid
    );
    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
        variable line_buffer : line;
    begin
        -- Reset the system
        reset_n      <= '0';
        i_data_valid <= '0';
        wait for i_clk_period;
        reset_n      <= '1';
        i_sys_enable <= '1';

        i_data(0) <= (
        (std_logic_vector(to_signed(12, 16)), std_logic_vector(to_signed(-5, 16)), std_logic_vector(to_signed(7, 16))),
        (std_logic_vector(to_signed(3, 16)), std_logic_vector(to_signed(-20, 16)), std_logic_vector(to_signed(9, 16))),
        (std_logic_vector(to_signed(-15, 16)), std_logic_vector(to_signed(25, 16)), std_logic_vector(to_signed(14, 16)))
        );

        i_data(1) <= (
        (std_logic_vector(to_signed(-11, 16)), std_logic_vector(to_signed(6, 16)), std_logic_vector(to_signed(-7, 16))),
        (std_logic_vector(to_signed(18, 16)), std_logic_vector(to_signed(-22, 16)), std_logic_vector(to_signed(13, 16))),
        (std_logic_vector(to_signed(5, 16)), std_logic_vector(to_signed(-9, 16)), std_logic_vector(to_signed(20, 16)))
        );

        i_data(2) <= (
        (std_logic_vector(to_signed(8, 16)), std_logic_vector(to_signed(-4, 16)), std_logic_vector(to_signed(10, 16))),
        (std_logic_vector(to_signed(-14, 16)), std_logic_vector(to_signed(19, 16)), std_logic_vector(to_signed(-21, 16))),
        (std_logic_vector(to_signed(16, 16)), std_logic_vector(to_signed(-3, 16)), std_logic_vector(to_signed(23, 16)))
        );
        wait for i_clk_period/2;
        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';
        -- End simulation
        wait;

    end process stimulus;
end maxpool2d_tb_arch;

configuration maxpool2d_tb_conf of maxpool2d_tb is
    for maxpool2d_tb_arch
        for UUT : maxpool2d
            use configuration LIB_RTL.maxpool2d_conf;
        end for;
    end for;
end configuration maxpool2d_tb_conf;