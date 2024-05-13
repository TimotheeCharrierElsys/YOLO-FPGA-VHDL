library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.dotproduct_pkg.all;

entity adder_tb is
end;

architecture adder_tb_arch of adder_tb is

    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    -- Ports
    signal i_clk_s   : std_logic := '0';
    signal i_reset_s : std_logic := '1';
    signal A_s       : std_logic_vector(15 downto 0);
    signal B_s       : std_logic_vector(15 downto 0);
    signal C_s       : std_logic_vector(15 downto 0);

    component adder
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            i_A     : in std_logic_vector(15 downto 0);
            i_B     : in std_logic_vector(15 downto 0);
            o_C     : out std_logic_vector(15 downto 0)
        );
    end component;

begin

    UUT : adder
    port map(
        i_clk   => i_clk_s,
        i_reset => i_reset_s,
        i_A     => A_s,
        i_B     => B_s,
        o_C     => C_s
    );

    i_clk_s   <= not i_clk_s after clk_period/2;
    i_reset_s <= '1' after 10 ns, '0' after 30 ns;
    A_s       <= x"0045";
    B_s       <= x"1020";

end;

configuration adder_tb_conf of adder_tb is
    for adder_tb_arch
        for UUT : adder
            use entity LIB_RTL.adder(adder_arch);
        end for;
    end for;
end configuration adder_tb_conf;