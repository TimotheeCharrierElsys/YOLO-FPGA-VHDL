
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity convolution_tb is
end;

architecture convolution_tb_arch of convolution_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant HEIGHT   : integer                   := 3;
    constant WIDTH    : integer                   := 3;
    constant init_col : t_in_vec(0 to HEIGHT - 1) := (x"00", x"02", x"03");
    -- Ports
    signal i_clk    : std_logic                                         := '0';
    signal i_reset  : std_logic                                         := '0';
    signal i_A      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0) := (others => init_col);
    signal i_B      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0) := (others => init_col);
    signal o_result : t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);

    component convolution
        generic (
            HEIGHT : integer;
            WIDTH  : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_A      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
            i_B      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
            o_result : out t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0)
        );
    end component;
begin

    UUT : convolution
    generic map(
        HEIGHT => HEIGHT,
        WIDTH  => WIDTH
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

    i_reset <= '1' after 20 ns, '0' after 40 ns;

end;

configuration convolution_tb_conf of convolution_tb is
    for convolution_tb_arch
        for UUT : convolution
            use entity LIB_RTL.convolution(convolution_arch);
        end for;
    end for;
end configuration convolution_tb_conf;