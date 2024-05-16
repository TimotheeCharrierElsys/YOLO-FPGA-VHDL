
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity add_layer_tb is
end;

architecture add_layer_tb_arch of add_layer_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant VECTOR_SIZE : integer := 8;
    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_enable : std_logic := '0';
    signal i_A      : t_out_vec(VECTOR_SIZE - 1 downto 0);
    signal i_B      : t_out_vec(VECTOR_SIZE - 1 downto 0);
    signal o_result : t_out_vec(VECTOR_SIZE - 1 downto 0);

    component add_layer
        generic (
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_enable : in std_logic;
            i_A      : in t_out_vec(VECTOR_SIZE - 1 downto 0);
            i_B      : in t_out_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_out_vec(VECTOR_SIZE - 1 downto 0)
        );
    end component;
begin

    UUT : add_layer
    generic map(
        VECTOR_SIZE => VECTOR_SIZE
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

    i_reset  <= '1' after 20 ns, '0' after 40 ns;
    i_enable <= '1' after 50 ns;
    i_A      <= (x"0000", x"0001", x"0002", x"0003", x"0004", x"0005", x"0006", x"0007");
    i_B      <= (x"0000", x"0001", x"0002", x"0003", x"0004", x"0005", x"0006", x"0007");

end;

configuration add_layer_tb_conf of add_layer_tb is
    for add_layer_tb_arch
        for UUT : add_layer
            use entity LIB_RTL.add_layer(add_layer_arch);
        end for;
    end for;
end configuration add_layer_tb_conf;