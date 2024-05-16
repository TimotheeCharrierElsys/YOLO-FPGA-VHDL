-----------------------------------------------------------------------------------
--!     @File    counter
--!     @brief   This file provides a generic counter component
--!     @author  TimothÃ©e Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity dotproduct is
    generic (
        VECTOR_SIZE : integer := 8 --! Vector Size 
    );
    port (
        i_clk    : in std_logic;                          --! Clock input
        i_reset  : in std_logic;                          --! Reset input
        i_enable : in std_logic;                          --! Input Enable
        i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input vector A
        i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0); --! Input vector B
        o_result : out t_bit16                            --! Output Vector
    );
end entity dotproduct;

architecture dotproduct_arch of dotproduct is

    -- 
    -- CONSTANTS
    -- 

    constant N_STAGES : integer := integer(ceil(log2(real(VECTOR_SIZE))));

    --
    -- SIGNALS 
    --

    signal r_A           : t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Signal for i_A
    signal r_B           : t_in_vec(VECTOR_SIZE - 1 downto 0);  --! Signal for i_B
    signal r_mult_to_add : t_out_vec(VECTOR_SIZE - 1 downto 0); --! Signal between mult_layer and first addition layer
    signal r_result      : t_bit16;                             --! Output Value

    signal temp1 : t_bit16;
    signal temp2 : t_bit16;
    signal temp3 : t_bit16;
    signal temp4 : t_bit16;
    signal temp5 : t_bit16;
    signal temp6 : t_bit16;

    --
    -- COMPONENTS 
    --

    component mult_layer
        generic (
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_enable : in std_logic;
            i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_out_vec(VECTOR_SIZE - 1 downto 0)
        );
    end component;

begin

    r_A <= i_A;
    r_B <= i_B;

    -- Mutiplication Layer
    mult_layer_inst : mult_layer
    generic map(
        VECTOR_SIZE => VECTOR_SIZE
    )
    port map(
        i_clk    => i_clk,
        i_reset  => i_reset,
        i_enable => i_enable,
        i_A      => r_A,
        i_B      => r_B,
        o_result => r_mult_to_add
    );

    p_sum_seq : process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            temp1    <= (others => '0');
            temp2    <= (others => '0');
            temp3    <= (others => '0');
            temp4    <= (others => '0');
            temp5    <= (others => '0');
            temp6    <= (others => '0');
            r_result <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_enable = '1' then
                temp1 <= std_logic_vector(signed(r_mult_to_add(0)) + signed(r_mult_to_add(1)));
                temp2 <= std_logic_vector(signed(r_mult_to_add(2)) + signed(r_mult_to_add(3)));
                temp3 <= std_logic_vector(signed(r_mult_to_add(4)) + signed(r_mult_to_add(5)));
                temp4 <= std_logic_vector(signed(r_mult_to_add(6)) + signed(r_mult_to_add(7)));

                temp5    <= std_logic_vector(signed(temp1) + signed(temp2));
                temp6    <= std_logic_vector(signed(temp3) + signed(temp4));
                r_result <= std_logic_vector(signed(temp5) + signed(temp6));
            end if;
        end if;
    end process p_sum_seq;

    -- Output Update
    o_result <= r_result;

end architecture;

configuration dotproduct_conf of dotproduct is
    for dotproduct_arch

        for all : mult_layer
            use entity LIB_RTL.mult_layer(mult_layer_arch);
        end for;

    end for;
end configuration dotproduct_conf;