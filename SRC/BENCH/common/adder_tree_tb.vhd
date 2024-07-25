-----------------------------------------------------------------------------------
--!     @Testbench    adder_tree_tb
--!     @brief        This testbench verifies the functionality of the adder tree.
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

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
    constant i_clk_period : time      := 10 ns;
    constant DO_PIPELINE  : std_logic := '1';
    constant NUM_OPERANDS : integer   := 8;
    constant BITWIDTH     : integer   := 8;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic                                               := '0'; --! Clock signal
    signal reset_n      : std_logic                                               := '1'; --! Reset signal
    signal i_sys_enable : std_logic                                               := '0'; --! Reset signal, active at low state
    signal i_operands   : t_vec(NUM_OPERANDS - 1 downto 0)(BITWIDTH - 1 downto 0) := (
    std_logic_vector(to_signed(0, BITWIDTH)),
    std_logic_vector(to_signed(1, BITWIDTH)),
    std_logic_vector(to_signed(2, BITWIDTH)),
    std_logic_vector(to_signed(3, BITWIDTH)),
    std_logic_vector(to_signed(4, BITWIDTH)),
    std_logic_vector(to_signed(5, BITWIDTH)),
    std_logic_vector(to_signed(6, BITWIDTH)),
    std_logic_vector(to_signed(7, BITWIDTH)));
    signal o_result : std_logic_vector(BITWIDTH - 1 downto 0); --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            DO_PIPELINE  : std_logic;
            NUM_OPERANDS : integer;
            BITWIDTH     : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_operands   : in t_vec(NUM_OPERANDS - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : adder_tree
    generic map(
        DO_PIPELINE  => DO_PIPELINE,
        NUM_OPERANDS => NUM_OPERANDS,
        BITWIDTH     => BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_operands   => i_operands,
        o_result     => o_result
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
        wait for 2.5 * i_clk_period;

        if DO_PIPELINE = '1' then
            assert o_result = std_logic_vector(to_signed(0, BITWIDTH))
            report "Output not reset correctly"
                severity error;
        end if;
        reset_n <= '1';

        -- Enable
        i_sys_enable <= '1';

        if DO_PIPELINE = '1' then
            wait for 3 * i_clk_period + 1 ns;
        end if;

        assert o_result = std_logic_vector(to_signed(28, BITWIDTH))
        report "Output do not match expected value"
            severity error;
        -- Finish the simulation
        wait;
    end process stimulus;
end architecture;