-----------------------------------------------------------------------------------
--!     @File    counter
--!     @brief   This file provides a generic counter component
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity mult_layer is
    generic (
        VECTOR_SIZE : integer := 8 --! Vector Size 
    );
    port (
        i_clk    : in std_logic;                           --! Clock input
        i_reset  : in std_logic;                           --! Reset input
        i_enable : in std_logic;                           --! Input Enable
        i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Input vector A
        i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Input vector B
        o_result : out t_out_vec(VECTOR_SIZE - 1 downto 0) --! Output Vector
    );
end entity mult_layer;

architecture mult_layer_arch of mult_layer is

    --
    -- SIGNALS 
    --

    signal r_A      : t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Signal for i_A
    signal r_B      : t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Signal for i_B
    signal r_result : t_out_vec(VECTOR_SIZE - 1 downto 0); --! Signal for the Output Result

    --
    -- COMPONENTS 
    --

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

    r_A <= i_A;
    r_B <= i_B;

    -- Pipelined Multiplication Layer
    REG_OUT_GEN : for i in 0 to VECTOR_SIZE - 1 generate
        register_gen_inst : register_gen
        generic map(
            BITWIDTH => 16
        )
        port map(
            i_clk    => i_clk,
            i_reset  => i_reset,
            i_enable => i_enable,
            i_data   => std_logic_vector(signed(r_A(i)) * signed(r_B(i))),
            o_data   => r_result(i)
        );
    end generate;

    -- Output Update
    o_result <= r_result;

end architecture;

configuration mult_layer_conf of mult_layer is
    for mult_layer_arch
        for REG_OUT_GEN
            for all : register_gen
                use entity LIB_RTL.register_gen(register_gen_arch);
            end for;
        end for;
    end for;
end configuration mult_layer_conf;