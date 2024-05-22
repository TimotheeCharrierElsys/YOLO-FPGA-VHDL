-----------------------------------------------------------------------------------
--!     @Testbench    mac_tb
--!     @brief        This testbench verifies the functionality of the MAC
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.binary_adder_tree_pkg.all;

entity mac_tb is
end entity;

architecture mac_tb_arch of mac_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant N_OPD        : integer := 8;     --! Number of operands
    constant BITWIDTH     : integer := 8;     --! Bit BITWIDTH of each operand

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal i_clk : std_logic := '0';                            --! Clock signal
    signal i_rst : std_logic := '1';                            --! Reset signal
    signal i_A   : std_logic_vector(BITWIDTH - 1 downto 0);     --! First mult operand
    signal i_B   : std_logic_vector(BITWIDTH - 1 downto 0);     --! Second mult operand
    signal i_C   : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Third operand
    signal o_P   : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac
        generic (
            BITWIDTH : integer
        );
        port (
            i_clk : in std_logic;
            i_rst : in std_logic;
            i_A   : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_B   : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_C   : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_P   : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : mac
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        i_clk => i_clk,
        i_rst => i_rst,
        i_A   => i_A,
        i_B   => i_B,
        i_C   => i_C,
        o_P   => o_P
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
        i_A <= std_logic_vector(to_unsigned(5, BITWIDTH));
        i_B <= std_logic_vector(to_unsigned(7, BITWIDTH));
        i_C <= std_logic_vector(to_unsigned(10, 2 * BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (N_OPD * i_clk_period);

        -- Check the output
        assert o_P = std_logic_vector(to_unsigned(45, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration mac_tb_conf of mac_tb is
    for mac_tb_arch
        for UUT : mac
            use entity LIB_RTL.mac(mac_arch);
        end for;
    end for;
end configuration mac_tb_conf;