-----------------------------------------------------------------------------------
--!     @file    variance_tb
--!     @brief        This testbench verifies the functionality of the variance module
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity variance_tb is
end entity;

architecture variance_tb_arch of variance_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time    := 10 ns; --! Clock period
    constant WAIT_COUNT     : integer := 8;     --! Number clock tics to wait
    constant BITWIDTH       : integer := 16;    --! Bit BITWIDTH of each operand
    constant MATRIX_SIZE    : integer := 2;     --! Kernel Size
    constant CHANNEL_NUMBER : integer := 2;     --! Number of channels

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock           : std_logic := '0';                                                                                                 --! Clock signal
    signal reset_n         : std_logic := '1';                                                                                                 --! Reset signal, active at low state
    signal i_sys_enable    : std_logic := '0';                                                                                                 --! Enable signal, active at high state
    signal i_volume        : t_volume(CHANNEL_NUMBER - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input volume
    signal i_volume_valid  : std_logic := '0';                                                                                                 --! Input volume valid signal
    signal o_variance      : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                    --! Channel-wise output variance
    signal o_variance_done : std_logic;                                                                                                        --! Output valid signal

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component variance
        generic (
            BITWIDTH       : integer;
            MATRIX_SIZE    : integer;
            CHANNEL_NUMBER : integer
        );
        port (
            clock           : in std_logic;
            reset_n         : in std_logic;
            i_sys_enable    : in std_logic;
            i_volume        : in t_volume(CHANNEL_NUMBER - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_volume_valid  : in std_logic;
            o_variance      : out t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_variance_done : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : variance
    generic map(
        BITWIDTH       => BITWIDTH,
        MATRIX_SIZE    => MATRIX_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER
    )
    port map(
        clock           => clock,
        reset_n         => reset_n,
        i_sys_enable    => i_sys_enable,
        i_volume        => i_volume,
        i_volume_valid  => i_volume_valid,
        o_variance      => o_variance,
        o_variance_done => o_variance_done
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
        wait for 2 * i_clk_period;
        reset_n <= '1';

        -- Enable the mac unit
        i_sys_enable <= '1';

        -- Apply input vectors
        i_volume(0)(0)(0) <= std_logic_vector(to_signed(-574, BITWIDTH));
        i_volume(0)(0)(1) <= std_logic_vector(to_signed(291, BITWIDTH));
        i_volume(0)(1)(0) <= std_logic_vector(to_signed(-241, BITWIDTH));
        i_volume(0)(1)(1) <= std_logic_vector(to_signed(856, BITWIDTH));

        i_volume(1)(0)(0) <= std_logic_vector(to_signed(-566, BITWIDTH));
        i_volume(1)(0)(1) <= std_logic_vector(to_signed(221, BITWIDTH));
        i_volume(1)(1)(0) <= std_logic_vector(to_signed(599, BITWIDTH));
        i_volume(1)(1)(1) <= std_logic_vector(to_signed(-107, BITWIDTH));

        i_volume_valid <= '1';
        wait for i_clk_period;
        i_volume_valid <= '0';

        -- Wait for enough time to allow the pipeline to process the inputs
        wait until o_variance_done = '1';

        -- Check the output
        assert o_variance(0) = std_logic_vector(to_signed(294354, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        assert o_variance(1) = std_logic_vector(to_signed(183511, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        wait for i_clk_period * 5;

        -- Apply input vectors
        i_volume(0)(0)(0) <= std_logic_vector(to_signed(789, BITWIDTH));
        i_volume(0)(0)(1) <= std_logic_vector(to_signed(123, BITWIDTH));
        i_volume(0)(1)(0) <= std_logic_vector(to_signed(-741, BITWIDTH));
        i_volume(0)(1)(1) <= std_logic_vector(to_signed(-652, BITWIDTH));

        i_volume(1)(0)(0) <= std_logic_vector(to_signed(250, BITWIDTH));
        i_volume(1)(0)(1) <= std_logic_vector(to_signed(500, BITWIDTH));
        i_volume(1)(1)(0) <= std_logic_vector(to_signed(-960, BITWIDTH));
        i_volume(1)(1)(1) <= std_logic_vector(to_signed(27, BITWIDTH));

        i_volume_valid <= '1';
        wait for i_clk_period;
        i_volume_valid <= '0';

        -- Wait for enough time to allow the pipeline to process the inputs
        wait until o_variance_done = '1';

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration variance_tb_conf of variance_tb is
    for variance_tb_arch
        for UUT : variance
            use configuration LIB_RTL.variance_conf;
        end for;
    end for;
end configuration variance_tb_conf;