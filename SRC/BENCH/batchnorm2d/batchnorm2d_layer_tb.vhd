-----------------------------------------------------------------------------------
--!     @file    batchnorm2d_layer_tb
--!     @brief        This testbench verifies the functionality of the batchnorm2d_layer module
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity batchnorm2d_layer_tb is
end entity;

architecture batchnorm2d_layer_tb_arch of batchnorm2d_layer_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant BITWIDTH     : integer := 16;
    constant EPSILON      : integer := 0;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic                               := '0';
    signal reset_n      : std_logic                               := '0';
    signal i_sys_enable : std_logic                               := '0';
    signal i_data       : std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0');
    signal i_mean       : std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0');
    signal i_var        : std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0');
    signal i_weight     : std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0');
    signal i_bias       : std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0');
    signal i_valid      : std_logic                               := '0';
    signal o_data       : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_data_valid : std_logic;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component batchnorm2d_layer
        generic (
            BITWIDTH : integer;
            EPSILON  : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_mean       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_var        : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_weight     : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_valid      : in std_logic;
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : batchnorm2d_layer
    generic map(
        BITWIDTH => BITWIDTH,
        EPSILON  => EPSILON
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data,
        i_mean       => i_mean,
        i_var        => i_var,
        i_weight     => i_weight,
        i_bias       => i_bias,
        i_valid      => i_valid,
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
        wait for 3 * i_clk_period;
        reset_n <= '1';

        -- Enable the unit
        i_sys_enable <= '1';

        -- Set values
        i_data   <= std_logic_vector(to_unsigned(150, BITWIDTH));
        i_mean   <= std_logic_vector(to_signed(100, BITWIDTH));
        i_var    <= std_logic_vector(to_signed(60, BITWIDTH));
        i_weight <= std_logic_vector(to_signed(3, BITWIDTH));
        i_bias   <= std_logic_vector(to_signed(1, BITWIDTH));

        i_valid <= '1';
        wait for i_clk_period;
        i_valid <= '0';

        wait until o_data_valid = '1';
        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration batchnorm2d_layer_tb_conf of batchnorm2d_layer_tb is
    for batchnorm2d_layer_tb_arch
        for UUT : batchnorm2d_layer
            use entity LIB_RTL.batchnorm2d_layer(batchnorm2d_layer_arch);
        end for;
    end for;
end configuration batchnorm2d_layer_tb_conf;