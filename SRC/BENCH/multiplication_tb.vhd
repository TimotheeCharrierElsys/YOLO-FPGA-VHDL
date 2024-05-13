library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.dotproduct_pkg.all;

entity multiplication_tb is
end;

architecture multiplication_tb_arch of multiplication_tb is

    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    -- Ports
    signal i_clk_s   : std_logic := '0';
    signal i_reset_s : std_logic := '1';
    signal A_s       : std_logic_vector(7 downto 0);
    signal B_s       : std_logic_vector(7 downto 0);
    signal C_s       : std_logic_vector(15 downto 0);

    component multiplication
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            i_A     : in std_logic_vector(7 downto 0);
            i_B     : in std_logic_vector(7 downto 0);
            o_C     : out std_logic_vector(15 downto 0)
        );
    end component;

begin

    UUT : multiplication
    port map(
        i_clk   => i_clk_s,
        i_reset => i_reset_s,
        i_A     => A_s,
        i_B     => B_s,
        o_C     => C_s
    );

    i_clk_s   <= not i_clk_s after clk_period/2;
    i_reset_s <= '1' after 10 ns, '0' after 30 ns;
    A_s       <= x"45";
    B_s       <= x"20";

end;

configuration multiplication_tb_conf of multiplication_tb is
    for multiplication_tb_arch
        for UUT : multiplication
            use entity LIB_RTL.multiplication(multiplication_arch);
        end for;
    end for;
end configuration multiplication_tb_conf;