library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity adder_tb is
end entity;

architecture adder_tb_arch of adder_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH : integer := 16;
    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_A      : std_logic_vector(BITWIDTH - 1 downto 0);
    signal i_B      : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_result : std_logic_vector(BITWIDTH - 1 downto 0);

    component adder
        generic (
            BITWIDTH : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_A      : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_B      : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin

    UUT : adder
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_A      => i_A,
        i_B      => i_B,
        o_result => o_result
    );

    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    -- Stimulus process
    stimulus_process : process
    begin
        -- Initialize inputs
        i_reset <= '1';
        i_A     <= (others => '0');
        i_B     <= (others => '0');
        wait for 20 ns;

        i_reset <= '0';
        wait for 20 ns;

        -- Test Case 1: Adding zero
        i_A <= x"0000";
        i_B <= x"0000";
        wait for clk_period;

        -- Test Case 2: Simple addition without overflow
        i_A <= x"1111";
        i_B <= x"2222";
        wait for clk_period;

        -- Test Case 3: Simple addition with negative numbers
        i_A <= std_logic_vector(to_signed(-4096, BITWIDTH));
        i_B <= std_logic_vector(to_signed(-2048, BITWIDTH));
        wait for clk_period;

        -- Test Case 4: Addition with overflow
        i_A <= std_logic_vector(to_signed(32760, BITWIDTH));
        i_B <= std_logic_vector(to_signed(10, BITWIDTH));
        wait for clk_period;

        -- Test Case 5: Another addition with overflow
        i_A <= std_logic_vector(to_signed(-32760, BITWIDTH));
        i_B <= std_logic_vector(to_signed(-10, BITWIDTH));
        wait for clk_period;

        -- Wait and finish
        wait for 100 ns;
        assert false report "End of simulation" severity failure;
    end process;

end architecture adder_tb_arch;

configuration adder_tb_conf of adder_tb is
    for adder_tb_arch
        for UUT : adder
            use entity LIB_RTL.adder(adder_arch);
        end for;
    end for;
end configuration adder_tb_conf;