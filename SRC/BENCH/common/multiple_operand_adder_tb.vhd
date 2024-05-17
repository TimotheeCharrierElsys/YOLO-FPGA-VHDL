
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity multiple_operand_adder_tb is
end;

architecture multiple_operand_adder_tb_arch of multiple_operand_adder_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH    : integer := 16;
    constant VECTOR_SIZE : integer := 8;
    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_data   : t_out_vec(VECTOR_SIZE - 1 downto 0);
    signal o_result : t_bit16;

    component multiple_operand_adder
        generic (
            BITWIDTH    : integer;
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_data   : in t_out_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_bit16
        );
    end component;

begin

    UUT : multiple_operand_adder
    generic map(
        BITWIDTH    => BITWIDTH,
        VECTOR_SIZE => VECTOR_SIZE
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_data   => i_data,
        o_result => o_result
    );

    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    i_reset <= '1' after 20 ns, '0' after 40 ns;
    i_data  <= (x"0000", x"0001", x"0002", x"0003", x"0004", x"0005", x"0006", x"0007");

end;

configuration multiple_operand_adder_tb_conf of multiple_operand_adder_tb is
    for multiple_operand_adder_tb_arch
        for UUT : multiple_operand_adder
            use entity LIB_RTL.multiple_operand_adder(multiple_operand_adder_arch);
        end for;
    end for;
end configuration multiple_operand_adder_tb_conf;