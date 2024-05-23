-----------------------------------------------------------------------------------
--!     @file    conv_layer_tb
--!     @brief        This testbench verifies the functionality of the pipelined mac 3*3
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

--! Testbench:
--! { signal: [
--!  { name: "clk",  wave: "P.xx", period: 2 },
--!  { name: "i_rst",  wave: "10......" },
--!  { name: "i_enable",  wave: "01......" },
--!  { name: "i_X", wave: "x=......", data: ["{{1 1 1} {1 1 1} {1 1 1}}"] },
--!  { name: "i_theta", wave: "x=......", data: ["{{1 0 0} {0 1 0} {0 0 1}}"] },
--!  { name: "o_Y", wave: "2.345...", data: ["0","1","2","3"] }
--! ],
--!  head:{
--!     text:'Expected Output',
--!     tick:0,
--!     every:2
--!   }}

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity conv_layer_tb is
end entity;

architecture conv_layer_tb_arch of conv_layer_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time    := 10 ns; --! Clock period
    constant WAIT_COUNT     : integer := 15;     --! Number clock tics to wait
    constant BITWIDTH       : integer := 8;     --! Bit BITWIDTH of each operand
    constant CHANNEL_NUMBER : integer := 3;     --! Number of channels
    constant KERNEL_SIZE    : integer := 3;     --! Kernel Size

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal i_clk     : std_logic := '0'; --! Clock signal
    signal i_rst     : std_logic := '1'; --! Reset signal, active at high state
    signal i_enable  : std_logic := '0'; --! Enable signal, active at high state
    signal i_image   : t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
    signal i_kernels : t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
    signal i_bias    : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_Y       : std_logic_vector(2 * BITWIDTH - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            i_clk     : in std_logic;
            i_rst     : in std_logic;
            i_enable  : in std_logic;
            i_image   : in t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
            i_kernels : in t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
            i_bias    : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_Y       : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : conv_layer
    generic map(
        BITWIDTH       => BITWIDTH,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE
    )
    port map(
        i_clk     => i_clk,
        i_rst     => i_rst,
        i_enable  => i_enable,
        i_image   => i_image,
        i_kernels => i_kernels,
        i_bias    => i_bias,
        o_Y       => o_Y
    );

    -- Clock generation
    i_clk <= not i_clk after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        i_rst <= '1';
        wait for 2 * i_clk_period;
        i_rst <= '0';

        -- Enable the mac unit
        i_enable <= '1';

        -- Apply input vectors
        i_image      <= (others => (others => std_logic_vector(to_unsigned(1, BITWIDTH))));
        i_kernels(0) <= (others => std_logic_vector(to_unsigned(0, BITWIDTH)));
        i_kernels(1) <= (others => std_logic_vector(to_unsigned(1, BITWIDTH)));
        i_kernels(2) <= (others => std_logic_vector(to_unsigned(2, BITWIDTH)));
        i_bias       <= std_logic_vector(to_unsigned(10, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_Y = std_logic_vector(to_signed(37, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
        severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration conv_layer_tb_conf of conv_layer_tb is
    for conv_layer_tb_arch
        for UUT : conv_layer
            use configuration LIB_RTL.conv_layer_conf;
        end for;
    end for;
end configuration conv_layer_tb_conf;