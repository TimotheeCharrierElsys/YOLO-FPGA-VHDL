
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pack.all;

entity dotproduct_top_tb is
end;

architecture dotproduct_top_tb_arch of dotproduct_top_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant VECTOR_SIZE : integer := 4;
    -- Ports
    signal i_clk_s    : std_logic                          := '0';
    signal i_reset_s  : std_logic                          := '1';
    signal i_A_s      : t_in_vec(VECTOR_SIZE - 1 downto 0) := (x"11", x"08", x"05", x"00");
    signal i_B_s      : t_in_vec(VECTOR_SIZE - 1 downto 0) := (x"77", x"55", x"01", x"05");
    signal o_result_s : t_bit16;

    component dotproduct_top
        generic (
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_bit16
        );
    end component;

begin

    UUT : dotproduct_top
    generic map(
        VECTOR_SIZE => VECTOR_SIZE
    )
    port map(
        i_clk    => i_clk_s,
        i_reset  => i_reset_s,
        i_A      => i_A_s,
        i_B      => i_B_s,
        o_result => o_result_s
    );

    i_clk_s   <= not i_clk_s after clk_period/2;
    i_reset_s <= '1' after 10 ns, '0' after 30 ns;

end;

configuration dotproduct_top_tb_conf of dotproduct_top_tb is
    for dotproduct_top_tb_arch
        for UUT : dotproduct_top
            use entity LIB_RTL.dotproduct_top(dotproduct_top_arch);
        end for;
    end for;
end configuration dotproduct_top_tb_conf;