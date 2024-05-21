library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.convolution_pkg.all;

entity convolution_tb is
end entity convolution_tb;

architecture convolution_tb_arch of convolution_tb is
    -- Clock period
    constant clk_period : time := 10 ns; -- Corrected the period to 10 ns for typical simulations
    -- Generics
    constant BITWIDTH    : integer := 8;
    constant IMG_WIDTH   : integer := 8;
    constant IMG_HEIGHT  : integer := 8;
    constant KERNEL_SIZE : integer := 3;

    -- Ports
    signal i_clk    : std_logic := '0';
    signal i_rst    : std_logic := '0';
    signal i_img    : t_mat(0 to IMG_WIDTH - 1)(0 to IMG_HEIGHT - 1)(0 to BITWIDTH - 1);
    signal i_kernel : t_mat(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(0 to BITWIDTH - 1);
    signal o_result : t_mat(0 to (IMG_WIDTH - KERNEL_SIZE)/2)(0 to (IMG_HEIGHT - KERNEL_SIZE)/2)(0 to BITWIDTH - 1);

    component convolution
        generic (
            BITWIDTH    : integer;
            IMG_WIDTH   : integer;
            IMG_HEIGHT  : integer;
            KERNEL_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_rst    : in std_logic;
            i_img    : in t_mat(0 to IMG_WIDTH - 1)(0 to IMG_HEIGHT - 1)(0 to BITWIDTH - 1);
            i_kernel : in t_mat(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(0 to BITWIDTH - 1);
            o_result : out t_mat(0 to (IMG_WIDTH - KERNEL_SIZE)/2)(0 to (IMG_HEIGHT - KERNEL_SIZE)/2)(0 to BITWIDTH - 1)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : convolution
    generic map(
        BITWIDTH    => BITWIDTH,
        IMG_WIDTH   => IMG_WIDTH,
        IMG_HEIGHT  => IMG_HEIGHT,
        KERNEL_SIZE => KERNEL_SIZE
    )
    port map(
        i_clk    => i_clk,
        i_rst    => i_rst,
        i_img    => i_img,
        i_kernel => i_kernel,
        o_result => o_result
    );
    -- Clock generation
    i_clk <= not i_clk after clk_period/2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Initialize input feature map and kernel
        for i in 0 to IMG_WIDTH - 1 loop
            for j in 0 to IMG_HEIGHT - 1 loop
                i_img(i)(j) <= std_logic_vector(to_signed(i + j, BITWIDTH));
            end loop;
        end loop;

        i_kernel <= (
            (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH))),
            (std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH))),
            (std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)))
            );

        -- Reset the system
        i_rst <= '1';
        wait for 2 * clk_period;
        i_rst <= '0';

        -- Allow some time for processing
        wait for 100 * clk_period;

        -- Check the output
        -- (Expected values should be computed based on your kernel and input feature map)

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture convolution_tb_arch;

configuration convolution_tb_conf of convolution_tb is
    for convolution_tb_arch
        for UUT : convolution
            use entity LIB_RTL.convolution(convolution_arch);
        end for;
    end for;
end configuration convolution_tb_conf;