-----------------------------------------------------------------------------------
--!     @Testbench    adder_tree_tb
--!     @brief        This testbench verifies the functionality of the pipelined MOA.
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

--! Tesbench:
--! {
--!   "signal": [
--!     {"name": "clock",    "wave": "N.....", "period": 1},
--!     {"name": "reset_n",    "wave": "10...."},
--!     {"name": "i_sys_enable", "wave": "01...."},
--!     {"name": "i_data",   "wave": "x3....", "data": ["{6,5,4,3,2,1}"]},
--!     {"name": "o_data",   "wave": "x5..4.", "data": ["0","21"]}
--!   ],
--!   "config": { "hscale": 2 }
--! }

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity adder_tree_tb is
end entity;

architecture adder_tree_tb_arch of adder_tree_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant N_OPD        : integer := 6;     --! Number of operands
    constant BITWIDTH     : integer := 8;     --! Bit BITWIDTH of each operand

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic := '0';                                 --! Clock signal
    signal reset_n      : std_logic := '1';                                 --! Reset signal
    signal i_sys_enable : std_logic := '0';                                 --! Reset signal, active at low state
    signal i_data       : t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data vector
    signal o_data       : std_logic_vector(BITWIDTH - 1 downto 0);          --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : adder_tree
    generic map(
        N_OPD    => N_OPD,
        BITWIDTH => BITWIDTH
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

        -- Apply input vectors
        i_data(0) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_data(1) <= std_logic_vector(to_unsigned(2, BITWIDTH));
        i_data(2) <= std_logic_vector(to_unsigned(3, BITWIDTH));
        i_data(3) <= std_logic_vector(to_unsigned(4, BITWIDTH));
        i_data(4) <= std_logic_vector(to_unsigned(5, BITWIDTH));
        i_data(5) <= std_logic_vector(to_unsigned(6, BITWIDTH));
        -- i_data(6) <= std_logic_vector(to_unsigned(7, BITWIDTH));
        -- i_data(7) <= std_logic_vector(to_unsigned(8, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (N_OPD * i_clk_period);

        -- Check the output
        assert o_data = std_logic_vector(to_unsigned(21, BITWIDTH))
        report "Test failed: output does not match expected sum"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration adder_tree_tb_conf of adder_tree_tb is
    for adder_tree_tb_arch
        for UUT : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_pipelined_arch);
        end for;
    end for;
end configuration adder_tree_tb_conf;