-----------------------------------------------------------------------------------
--!     @Testbench    pipelined_moa_tb
--!     @brief        This testbench verifies the functionality of the pipelined MOA.
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.pipelined_moa_pkg.all;

entity pipelined_moa_tb is
end entity;

architecture pipelined_moa_tb_arch of pipelined_moa_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant N_OPD        : integer := 8;     --! Number of operands
    constant WIDTH        : integer := 8;     --! Bit width of each operand

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal i_clk  : std_logic := '0';                              --! Clock signal
    signal i_rst  : std_logic := '1';                              --! Reset signal
    signal i_data : t_vec(N_OPD - 1 downto 0)(WIDTH - 1 downto 0); --! Input data vector
    signal o_data : std_logic_vector(WIDTH - 1 downto 0);          --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component pipelined_moa
        generic (
            N_OPD : integer;
            WIDTH : integer
        );
        port (
            i_clk  : in std_logic;
            i_rst  : in std_logic;
            i_data : in t_vec(N_OPD - 1 downto 0)(WIDTH - 1 downto 0);
            o_data : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : pipelined_moa
    generic map(
        N_OPD => N_OPD,
        WIDTH => WIDTH
    )
    port map(
        i_clk  => i_clk,
        i_rst  => i_rst,
        i_data => i_data,
        o_data => o_data
    );

    -- Clock generation
    i_clk <= not i_clk after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        i_rst <= '1';
        wait for 2 * i_clk_period;
        i_rst <= '0';

        -- Apply input vectors
        i_data(0) <= std_logic_vector(to_unsigned(1, WIDTH));
        i_data(1) <= std_logic_vector(to_unsigned(2, WIDTH));
        i_data(2) <= std_logic_vector(to_unsigned(3, WIDTH));
        i_data(3) <= std_logic_vector(to_unsigned(4, WIDTH));
        i_data(4) <= std_logic_vector(to_unsigned(5, WIDTH));
        i_data(5) <= std_logic_vector(to_unsigned(6, WIDTH));
        i_data(6) <= std_logic_vector(to_unsigned(7, WIDTH));
        i_data(7) <= std_logic_vector(to_unsigned(8, WIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (N_OPD * i_clk_period);

        -- Check the output
        assert o_data = std_logic_vector(to_unsigned(36, WIDTH))
        report "Test failed: output does not match expected sum"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;