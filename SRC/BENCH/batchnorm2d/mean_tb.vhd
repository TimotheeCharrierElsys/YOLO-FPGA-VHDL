-----------------------------------------------------------------------------------
--!     @file    mean_tb
--!     @brief        This testbench verifies the functionality of the mean module
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity mean_tb is
end entity;

architecture mean_tb_arch of mean_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period                     : time    := 10 ns; --! Clock period
    constant WAIT_COUNT                       : integer := 8;     --! Number clock tics to wait
    constant BITWIDTH                         : integer := 16;    --! Bit BITWIDTH of each operand
    constant INPUT_SIZE                       : integer := 3;     --! Kernel Size
    constant DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 10;    --! Scale factor to compute the division by INPUT_SIZE * INPUT_SIZE
    constant CHANNEL_NUMBER                   : integer := 3;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock          : std_logic := '0';                                                                                               --! Clock signal
    signal reset_n        : std_logic := '1';                                                                                               --! Reset signal, active at low state
    signal i_sys_enable   : std_logic := '0';                                                                                               --! Enable signal, active at high state
    signal i_volume       : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input volume
    signal i_volume_valid : std_logic := '0';                                                                                               --! Input volume valid signal
    signal o_mean         : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                      --! Channel-wise output mean
    signal o_mean_done    : std_logic;                                                                                                      --! Output valid signal

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mean
        generic (
            BITWIDTH                         : integer;
            INPUT_SIZE                       : integer;
            CHANNEL_NUMBER                   : integer;
            DIVISION_SCALE_FACTOR_POWER_OF_2 : integer
        );
        port (
            clock          : in std_logic;
            reset_n        : in std_logic;
            i_sys_enable   : in std_logic;
            i_volume       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_volume_valid : in std_logic;
            o_mean         : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_mean_done    : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : mean
    generic map(
        BITWIDTH                         => BITWIDTH,
        INPUT_SIZE                       => INPUT_SIZE,
        CHANNEL_NUMBER                   => CHANNEL_NUMBER,
        DIVISION_SCALE_FACTOR_POWER_OF_2 => DIVISION_SCALE_FACTOR_POWER_OF_2
    )
    port map(
        clock          => clock,
        reset_n        => reset_n,
        i_sys_enable   => i_sys_enable,
        i_volume       => i_volume,
        i_volume_valid => i_volume_valid,
        o_mean         => o_mean,
        o_mean_done    => o_mean_done
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
        i_volume(0)(0)(0) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_volume(0)(0)(1) <= std_logic_vector(to_unsigned(2, BITWIDTH));
        i_volume(0)(0)(2) <= std_logic_vector(to_unsigned(3, BITWIDTH));
        i_volume(0)(1)(0) <= std_logic_vector(to_unsigned(4, BITWIDTH));
        i_volume(0)(1)(1) <= std_logic_vector(to_unsigned(5, BITWIDTH));
        i_volume(0)(1)(2) <= std_logic_vector(to_unsigned(6, BITWIDTH));
        i_volume(0)(2)(0) <= std_logic_vector(to_unsigned(7, BITWIDTH));
        i_volume(0)(2)(1) <= std_logic_vector(to_unsigned(8, BITWIDTH));
        i_volume(0)(2)(2) <= std_logic_vector(to_unsigned(9, BITWIDTH));

        i_volume(1)(0)(0) <= std_logic_vector(to_unsigned(10, BITWIDTH));
        i_volume(1)(0)(1) <= std_logic_vector(to_unsigned(11, BITWIDTH));
        i_volume(1)(0)(2) <= std_logic_vector(to_unsigned(12, BITWIDTH));
        i_volume(1)(1)(0) <= std_logic_vector(to_unsigned(13, BITWIDTH));
        i_volume(1)(1)(1) <= std_logic_vector(to_unsigned(14, BITWIDTH));
        i_volume(1)(1)(2) <= std_logic_vector(to_unsigned(15, BITWIDTH));
        i_volume(1)(2)(0) <= std_logic_vector(to_unsigned(16, BITWIDTH));
        i_volume(1)(2)(1) <= std_logic_vector(to_unsigned(17, BITWIDTH));
        i_volume(1)(2)(2) <= std_logic_vector(to_unsigned(18, BITWIDTH));

        i_volume(2)(0)(0) <= std_logic_vector(to_unsigned(19, BITWIDTH));
        i_volume(2)(0)(1) <= std_logic_vector(to_unsigned(20, BITWIDTH));
        i_volume(2)(0)(2) <= std_logic_vector(to_unsigned(21, BITWIDTH));
        i_volume(2)(1)(0) <= std_logic_vector(to_unsigned(22, BITWIDTH));
        i_volume(2)(1)(1) <= std_logic_vector(to_unsigned(23, BITWIDTH));
        i_volume(2)(1)(2) <= std_logic_vector(to_unsigned(24, BITWIDTH));
        i_volume(2)(2)(0) <= std_logic_vector(to_unsigned(25, BITWIDTH));
        i_volume(2)(2)(1) <= std_logic_vector(to_unsigned(26, BITWIDTH));
        i_volume(2)(2)(2) <= std_logic_vector(to_unsigned(27, BITWIDTH));

        i_volume_valid <= '1';
        wait for i_clk_period;
        i_volume_valid <= '0';

        -- Wait for enough time to allow the pipeline to process the inputs
        wait until o_mean_done = '1';

        -- Check the output
        assert o_mean(0) = std_logic_vector(to_signed(4, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        assert o_mean(1) = std_logic_vector(to_signed(13, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;
        assert o_mean(2) = std_logic_vector(to_signed(22, BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration mean_tb_conf of mean_tb is
    for mean_tb_arch
        for UUT : mean
            use configuration LIB_RTL.mean_conf;
        end for;
    end for;
end configuration mean_tb_conf;