-----------------------------------------------------------------------------------
--!     @file    batchnorm2d_tb
--!     @brief        This testbench verifies the functionality of the batchnorm2d module
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity batchnorm2d_tb is
end entity;

architecture batchnorm2d_tb_arch of batchnorm2d_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time    := 10 ns; --! Clock period
    constant BITWIDTH       : integer := 16;    --! Bit width of each operand
    constant INPUT_SIZE     : integer := 3;     --! Width and Height of the input
    constant CHANNEL_NUMBER : integer := 3;     --! Number of channels in the input
    constant EPSILON        : integer := 0;     --! A small value  added for numerical stability.

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock          : std_logic := '0';
    signal reset_n        : std_logic := '0';
    signal i_sys_enable   : std_logic := '0';
    signal i_data_valid   : std_logic := '0';
    signal i_data         : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_running_mean : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_running_var  : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_weight       : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_bias         : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal o_data         : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal o_data_valid   : std_logic;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component batchnorm2d
        generic (
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            EPSILON        : integer
        );
        port (
            clock          : in std_logic;
            reset_n        : in std_logic;
            i_sys_enable   : in std_logic;
            i_data         : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_running_mean : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_running_var  : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_weight       : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias         : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid   : in std_logic;
            o_data         : out t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data_valid   : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : batchnorm2d
    generic map(
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        EPSILON        => EPSILON
    )
    port map(
        clock          => clock,
        reset_n        => reset_n,
        i_sys_enable   => i_sys_enable,
        i_data         => i_data,
        i_running_mean => i_running_mean,
        i_running_var  => i_running_var,
        i_weight       => i_weight,
        i_bias         => i_bias,
        i_data_valid   => i_data_valid,
        o_data         => o_data,
        o_data_valid   => o_data_valid
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
        wait for 3 * i_clk_period;
        reset_n <= '1';

        -- Enable the unit
        i_sys_enable <= '1';

        -- Set values
        i_data(0) <= (
        (std_logic_vector(to_signed(100, BITWIDTH)), std_logic_vector(to_signed(200, BITWIDTH)), std_logic_vector(to_signed(300, BITWIDTH))),
        (std_logic_vector(to_signed(400, BITWIDTH)), std_logic_vector(to_signed(500, BITWIDTH)), std_logic_vector(to_signed(600, BITWIDTH))),
        (std_logic_vector(to_signed(700, BITWIDTH)), std_logic_vector(to_signed(800, BITWIDTH)), std_logic_vector(to_signed(900, BITWIDTH))));

        i_data(1) <= (
        (std_logic_vector(to_signed(1000, BITWIDTH)), std_logic_vector(to_signed(1200, BITWIDTH)), std_logic_vector(to_signed(2300, BITWIDTH))),
        (std_logic_vector(to_signed(400, BITWIDTH)), std_logic_vector(to_signed(8500, BITWIDTH)), std_logic_vector(to_signed(3600, BITWIDTH))),
        (std_logic_vector(to_signed(4700, BITWIDTH)), std_logic_vector(to_signed(5800, BITWIDTH)), std_logic_vector(to_signed(4900, BITWIDTH))));

        i_data(2) <= (
        (std_logic_vector(to_signed(100, BITWIDTH)), std_logic_vector(to_signed(110, BITWIDTH)), std_logic_vector(to_signed(120, BITWIDTH))),
        (std_logic_vector(to_signed(130, BITWIDTH)), std_logic_vector(to_signed(140, BITWIDTH)), std_logic_vector(to_signed(150, BITWIDTH))),
        (std_logic_vector(to_signed(160, BITWIDTH)), std_logic_vector(to_signed(170, BITWIDTH)), std_logic_vector(to_signed(180, BITWIDTH))));

        i_running_mean <= (others => std_logic_vector(to_unsigned(100, BITWIDTH)));
        i_running_var  <= (others => std_logic_vector(to_unsigned(50, BITWIDTH)));
        i_weight       <= (others => std_logic_vector(to_signed(3, BITWIDTH)));
        i_bias         <= (others => std_logic_vector(to_signed(1, BITWIDTH)));

        i_data_valid <= '1';
        wait for i_clk_period;
        i_data_valid <= '0';

        wait until o_data_valid = '1';
        wait until o_data_valid = '1';
        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration batchnorm2d_tb_conf of batchnorm2d_tb is
    for batchnorm2d_tb_arch
        for UUT : batchnorm2d
            use entity LIB_RTL.batchnorm2d(batchnorm2d_arch);
        end for;
    end for;
end configuration batchnorm2d_tb_conf;