library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity matmult_dot_tb is
end;

architecture matmult_dot_tb_arch of matmult_dot_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant HEIGHT : integer := 3;
    constant WIDTH  : integer := 3;

    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_enable : std_logic := '0';
    signal i_A      : t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);
    signal i_B      : t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);
    signal o_result : t_out_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);

    component matmult_dot
        generic (
            HEIGHT : integer;
            WIDTH  : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_enable : in std_logic;
            i_A      : in t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);
            i_B      : in t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);
            o_result : out t_out_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0)
        );
    end component;
begin

    UUT : matmult_dot
    generic map(
        HEIGHT => HEIGHT,
        WIDTH  => WIDTH
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_enable => i_enable,
        i_A      => i_A,
        i_B      => i_B,
        o_result => o_result
    );

    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    -- Test procedure
    process
    begin
        -- Initialize inputs
        i_reset  <= '1';
        i_enable <= '0';
        wait for 20 ns;
        i_reset <= '0';

        -- Test case 1: simple 1s matrix multiplication
        i_A      <= (others => (others => x"01"));
        i_B      <= (others => (others => x"01"));
        i_enable <= '1';
        wait for clk_period * 10; -- wait for few clock cycles

        -- Test case 2: identity matrix multiplication
        i_A       <= (others => (others => x"00"));
        i_A(0)(0) <= x"01";
        i_A(1)(1) <= x"01";
        i_A(2)(2) <= x"01";

        i_B       <= (others => (others => x"00"));
        i_B(0)(0) <= x"01";
        i_B(1)(1) <= x"01";
        i_B(2)(2) <= x"01";
        wait for clk_period * 10; -- wait for few clock cycles

        -- Test case 3: arbitrary values
        i_A       <= (others => (others => x"01"));
        i_A(0)(1) <= x"02";
        i_A(1)(2) <= x"03";
        i_A(2)(0) <= x"04";

        i_B       <= (others => (others => x"02"));
        i_B(0)(1) <= x"01";
        i_B(1)(2) <= x"03";
        i_B(2)(0) <= x"04";
        wait for clk_period * 10; -- wait for few clock cycles

        -- Test case 4: more complex values
        i_A       <= (others => (others => x"03"));
        i_A(0)(0) <= x"02";
        i_A(1)(1) <= x"04";
        i_A(2)(2) <= x"06";

        i_B       <= (others => (others => x"01"));
        i_B(0)(1) <= x"05";
        i_B(1)(2) <= x"07";
        i_B(2)(0) <= x"09";
        wait for clk_period * 10; -- wait for few clock cycles

        -- Finish simulation
        wait;
    end process;

end architecture;

configuration matmult_dot_tb_conf of matmult_dot_tb is
    for matmult_dot_tb_arch
        for UUT : matmult_dot
            use entity LIB_RTL.matmult_dot(matmult_dot_arch);
        end for;
    end for;
end configuration matmult_dot_tb_conf;