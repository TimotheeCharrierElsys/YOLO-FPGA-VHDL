
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity matmult_top_tb is
end;

architecture matmult_top_tb_arch of matmult_top_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant WIDTH    : integer                   := 3;
    constant HEIGHT   : integer                   := 3;
    constant init_col : t_in_vec(0 to HEIGHT - 1) := (x"00", x"02", x"03");
    -- Ports
    signal i_clk    : std_logic                                         := '0';
    signal i_reset  : std_logic                                         := '1';
    signal i_start  : std_logic                                         := '0';
    signal i_A      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0) := (others => init_col);
    signal i_B      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0) := (others => init_col);
    signal o_result : t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);

begin

    UUT : matmult_top
    generic map(
        WIDTH  => WIDTH,
        HEIGHT => HEIGHT
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

configuration matmult_top_tb_conf of matmult_top_tb is
    for matmult_top_tb_arch
        for UUT : matmult_top
            use entity LIB_RTL.matmult_top(matmult_top_arch);
        end for;
    end for;
end configuration matmult_top_tb_conf;