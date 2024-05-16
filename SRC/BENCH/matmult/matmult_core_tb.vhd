
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity matmult_core_tb is
end;

architecture matmult_core_tb_arch of matmult_core_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant VECTOR_SIZE : integer := 4;
    -- Ports
    signal i_clk    : std_logic                          := '0';
    signal i_reset  : std_logic                          := '1';
    signal i_start  : std_logic                          := '0';
    signal i_A      : t_in_vec(VECTOR_SIZE - 1 downto 0) := (x"11", x"08", x"05", x"00");
    signal i_B      : t_in_vec(VECTOR_SIZE - 1 downto 0) := (x"77", x"55", x"01", x"05");
    signal o_result : t_bit16;

begin

    UUT : matmult_core
    generic map(
        VECTOR_SIZE => VECTOR_SIZE
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_start  => i_start,
        i_A      => i_A,
        i_B      => i_B,
        o_result => o_result
    );

    i_clk   <= not i_clk after clk_period/2;
    i_reset <= '1' after 10 ns, '0' after 30 ns;
    i_start <= '1' after 50 ns;

end;

configuration matmult_core_tb_conf of matmult_core_tb is
    for matmult_core_tb_arch
        for UUT : matmult_core
            use entity LIB_RTL.matmult_core(matmult_core_arch);
        end for;
    end for;
end configuration matmult_core_tb_conf;