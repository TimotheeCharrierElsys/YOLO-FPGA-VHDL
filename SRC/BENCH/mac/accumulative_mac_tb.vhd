-----------------------------------------------------------------------------------
--!     @Testbench    accumulative_mac_tb
--!     @brief        This testbench verifies the functionality of the accumulative mac
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity accumulative_mac_tb is
end entity;

architecture accumulative_mac_tb_arch of accumulative_mac_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period      : time      := 10 ns; --! Clock period
    constant WAIT_COUNT        : integer   := 8;     --! Number clock tics to wait
    constant DO_MULTIPLICATION : std_logic := '0';   --! 
    constant INTPUT_WIDTH      : integer   := 8;     --! Bit width of input operands
    constant OUTPUT_WIDTH      : integer   := 16;    --! Bit width of output result

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic := '0';                            --! Clock signal
    signal reset_n      : std_logic := '1';                            --! Reset signal, active at low state
    signal i_sys_enable : std_logic := '0';                            --! Enable signal, active at high state
    signal i_clear      : std_logic := '0';                            --! Clear signal, active high
    signal i_enable     : std_logic := '0';                            --! Input enable, active high
    signal i_operand1   : std_logic_vector(INTPUT_WIDTH - 1 downto 0); --! First mult operand
    signal i_operand2   : std_logic_vector(INTPUT_WIDTH - 1 downto 0); --! Second mult operand
    signal o_result     : std_logic_vector(OUTPUT_WIDTH - 1 downto 0); --! Output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component accumulative_mac
        generic (
            DO_MULTIPLICATION : std_logic;
            INTPUT_WIDTH      : integer;
            OUTPUT_WIDTH      : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_clear      : in std_logic;
            i_enable     : in std_logic;
            i_operand1   : in std_logic_vector(INTPUT_WIDTH - 1 downto 0);
            i_operand2   : in std_logic_vector(INTPUT_WIDTH - 1 downto 0);
            o_result     : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : accumulative_mac
    generic map(
        DO_MULTIPLICATION => DO_MULTIPLICATION,
        INTPUT_WIDTH      => INTPUT_WIDTH,
        OUTPUT_WIDTH      => OUTPUT_WIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_clear      => i_clear,
        i_enable     => i_enable,
        i_operand1   => i_operand1,
        i_operand2   => i_operand2,
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
        wait for 15 ns;
        reset_n <= '1';

        -- Enable the mac unit
        i_sys_enable <= '1';
        i_enable     <= '1';

        -- Apply input vectors
        i_operand1 <= std_logic_vector(to_signed(5, INTPUT_WIDTH));
        i_operand2 <= std_logic_vector(to_signed(7, INTPUT_WIDTH));

        wait for i_clk_period + 1 ns;

        -- Check the output
        assert o_result = std_logic_vector(to_signed(35, OUTPUT_WIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        wait for i_clk_period;

        i_clear <= '1';
        wait for i_clk_period;
        i_clear <= '0';
        wait for i_clk_period/2;

        assert o_result = std_logic_vector(to_signed(0, OUTPUT_WIDTH))
        report "Test failed: output not cleared correctly"
            severity error;

        wait for i_clk_period;
        i_enable <= '0';

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration accumulative_mac_tb_conf of accumulative_mac_tb is
    for accumulative_mac_tb_arch
        for UUT : accumulative_mac
            use entity LIB_RTL.accumulative_mac(accumulative_mac_arch);
        end for;
    end for;
end configuration accumulative_mac_tb_conf;