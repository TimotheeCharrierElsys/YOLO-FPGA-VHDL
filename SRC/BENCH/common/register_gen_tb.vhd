library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;

entity register_gen_tb is
end;

architecture register_gen_tb_arch of register_gen_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH : integer := 16;
    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_reset  : std_logic := '0';
    signal i_enable : std_logic := '0';
    signal i_data   : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_data   : std_logic_vector(BITWIDTH - 1 downto 0);

    component register_gen
        generic (
            BITWIDTH : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_enable : in std_logic;
            i_data   : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_data   : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;
begin

    UUT : register_gen
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_enable => i_enable,
        i_data   => i_data,
        o_data   => o_data
    );

    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    i_reset  <= '1' after 20 ns, '0' after 40 ns;
    i_enable <= '1' after 50 ns;
    i_data   <= x"0000", x"FFFF" after 60 ns;

end;

configuration register_gen_tb_conf of register_gen_tb is
    for register_gen_tb_arch
        for UUT : register_gen
            use entity LIB_RTL.register_gen(register_gen_arch);
        end for;
    end for;
end configuration register_gen_tb_conf;