-----------------------------------------------------------------------------------
--!     @File    convolution
--!     @brief   This file provides the top level to compute the convolution of two matrices
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity convolution is
    generic (
        HEIGHT : integer := 3; --! Matrix Height
        WIDTH  : integer := 3
    );
    port (
        i_clk    : in std_logic;                                          --! Clock input
        i_reset  : in std_logic;                                          --! Reset input
        i_A      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);  --! Input matrix A
        i_B      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);  --! Input matrix B
        o_result : out t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0) --! Output for the convolution result
    );
end entity convolution;

architecture convolution_arch of convolution is

    -- 
    -- SIGNALS
    signal r_A    : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
    signal r_B    : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
    signal result : t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);

begin

    r_A <= i_A;
    r_B <= i_B;

    -- 
    -- ASYNC SEQUENTIAL PROCESS
    -- 
    p_convolution : process (i_clk, i_reset) is
    begin
        if i_reset = '1' then
            -- Reset output matrix
            for i in 0 to HEIGHT - 1 loop
                for j in 0 to WIDTH - 1 loop
                    result(i)(j) <= (others => '0');
                end loop;
            end loop;
        elsif rising_edge(i_clk) then
            -- Compute convolution
            result <= convolution(r_A, r_B, HEIGHT, WIDTH);
        end if;
    end process p_convolution;

    -- Output update
    o_result <= result;

end architecture convolution_arch;