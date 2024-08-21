-----------------------------------------------------------------------------------
--!     @Testbench    pipeline_tb
--!     @brief        This testbench verifies the functionality of the pipeline.
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity pipeline_tb is
end entity;

architecture pipeline_tb_arch of pipeline_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant N_STAGES     : integer := 6;     --! Number of operands

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic := '0'; --! Clock signal
    signal reset_n      : std_logic := '1'; --! Reset signal
    signal i_sys_enable : std_logic := '0'; --! Reset signal, active at low state
    signal i_data       : std_logic;        --! Input data vector
    signal o_data       : std_logic;        --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component pipeline
        generic (
            N_STAGES : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic;
            o_data       : out std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : pipeline
    generic map(
        N_STAGES => N_STAGES
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data,
        o_data       => o_data
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

        -- Enable
        i_sys_enable <= '1';
        i_data       <= '1';
        wait for i_clk_period/2;
        i_data <= '0';
        wait for i_clk_period * (N_STAGES + 1);
        i_data <= '1';
        wait for i_clk_period/2;
        i_data <= '0';
        wait for i_clk_period * (N_STAGES + 1);
        wait;
    end process stimulus;

end architecture;

configuration pipeline_tb_conf of pipeline_tb is
    for pipeline_tb_arch
        for UUT : pipeline
            use entity LIB_RTL.pipeline(pipeline_arch);
        end for;
    end for;
end configuration pipeline_tb_conf;