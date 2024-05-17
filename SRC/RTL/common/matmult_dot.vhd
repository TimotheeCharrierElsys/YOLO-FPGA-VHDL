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

entity matmult_dot is
    generic (
        HEIGHT : integer := 8; --! Matrix W 
        WIDTH  : integer := 8  --! Matrix H 
    );
    port (
        i_clk    : in std_logic;                                          --! Clock input
        i_reset  : in std_logic;                                          --! Reset input
        i_enable : in std_logic;                                          --! Input Enable
        i_A      : in t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);  --! Input Matrix A
        i_B      : in t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);  --! Input vector B
        o_result : out t_out_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0) --! Output Matrix
    );
end entity matmult_dot;

architecture matmult_dot_arch of matmult_dot is

    --
    -- SIGNALS 
    --

    signal r_A      : t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);  --! Signal for i_A
    signal r_B      : t_in_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0);  --! Signal for i_B
    signal r_result : t_out_mat(HEIGHT - 1 downto 0)(WIDTH - 1 downto 0); --! Signal for the Output Result

begin

    r_A <= i_A;
    r_B <= i_B;

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            for i in 0 to HEIGHT - 1 loop
                for j in 0 to WIDTH - 1 loop
                    r_result(i)(j) <= dotproduct(r_A(i), r_B(i));
                end loop;
            end loop;
        end if;
    end process;

    -- Output Update
    o_result <= r_result;

end architecture;