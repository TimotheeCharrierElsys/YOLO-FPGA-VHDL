
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity dotproduct_tb is
end;

architecture dotproduct_tb_arch of dotproduct_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant VECTOR_SIZE : integer := 8;
    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_enable : std_logic := '0';
    signal i_A      : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal i_B      : t_in_vec(VECTOR_SIZE - 1 downto 0);
    signal o_result : t_bit16;

    component dotproduct
        generic (
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_enable : in std_logic;
            i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_bit16
        );
    end component;
begin

    UUT : dotproduct
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

    i_A <= (x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07");
    i_B <= (x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07");

end;

configuration dotproduct_tb_conf of dotproduct_tb is
    for dotproduct_tb_arch
        for UUT : dotproduct
            use entity LIB_RTL.dotproduct(dotproduct_arch);
        end for;
    end for;
end configuration dotproduct_tb_conf;