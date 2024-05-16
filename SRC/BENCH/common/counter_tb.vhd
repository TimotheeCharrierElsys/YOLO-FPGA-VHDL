
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity counter_tb is
end;

architecture counter_tb_arch of counter_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant BITWIDTH   : integer := 4;
    constant INIT_VALUE : integer := 2;
    -- Ports
    signal i_clk        : std_logic := '0';
    signal i_reset      : std_logic := '0';
    signal i_enable     : std_logic := '0';
    signal i_init_value : std_logic := '0';
    signal o_count      : std_logic_vector(BITWIDTH - 1 downto 0);

    component counter
        generic (
            BITWIDTH   : integer;
            INIT_VALUE : integer
        );
        port (
            i_clk        : in std_logic;
            i_reset      : in std_logic;
            i_enable     : in std_logic;
            i_init_value : in std_logic;
            o_count      : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;
begin

    UUT : counter
    generic map(
        BITWIDTH   => BITWIDTH,
        INIT_VALUE => INIT_VALUE
    )
    port map(
        i_clk        => i_clk,
        i_reset      => i_reset,
        i_enable     => i_enable,
        i_init_value => i_init_value,
        o_count      => o_count
    );

    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    i_reset      <= '1' after 20 ns, '0' after 40 ns;
    i_enable     <= '1' after 50 ns;
    i_init_value <= '1' after 50 ns, '0' after 60 ns;

end;

configuration counter_tb_conf of counter_tb is
    for counter_tb_arch
        for UUT : counter
            use entity LIB_RTL.counter(counter_arch);
        end for;
    end for;
end configuration counter_tb_conf;