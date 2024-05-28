-----------------------------------------------------------------------------------
--!     @file    mac_layer_tb
--!     @brief        This testbench verifies the functionality of the pipelined mac 3*3
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @author       Timothée Charrier
-----------------------------------------------------------------------------------

--! Testbench:
--! { signal: [
--!  { name: "clk",  wave: "P.xx", period: 2 },
--!  { name: "reset_n",  wave: "10......" },
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

entity mac_layer_tb is
end entity;

architecture mac_layer_tb_arch of mac_layer_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period : time    := 10 ns; --! Clock period
    constant WAIT_COUNT   : integer := 8;     --! Number clock tics to wait
    constant BITWIDTH     : integer := 8;     --! Bit BITWIDTH of each operand
    constant KERNEL_SIZE  : integer := 3;     --! Kernel Size

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock    : std_logic := '0'; --! Clock signal
    signal reset_n  : std_logic := '1'; --! Reset signal, active at low state
    signal i_enable : std_logic := '0'; --! Enable signal, active at low state
    signal i_X      : t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
    signal i_theta  : t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
    signal o_Y      : std_logic_vector (2 * BITWIDTH - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac_layer
        generic (
            BITWIDTH    : integer;
            KERNEL_SIZE : integer
        );
        port (
            clock    : in std_logic;
            reset_n  : in std_logic;
            i_enable : in std_logic;
            i_X      : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
            i_theta  : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
            o_Y      : out std_logic_vector (2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : mac_layer
    generic map(
        BITWIDTH    => BITWIDTH,
        KERNEL_SIZE => KERNEL_SIZE
    )
    port map(
        clock    => clock,
        reset_n  => reset_n,
        i_enable => i_enable,
        i_X      => i_X,
        i_theta  => i_theta,
        o_Y      => o_Y
    );

    -- Clock generation
    clock <= not clock after i_clk_period / 2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for 2 * i_clk_period;
        reset_n <= '1';

        -- Enable the mac unit
        i_enable <= '1';

        -- Apply input vectors
        i_X        <= (others => std_logic_vector(to_unsigned(1, BITWIDTH)));
        i_theta(0) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_theta(1) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(2) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(3) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(4) <= std_logic_vector(to_unsigned(1, BITWIDTH));
        i_theta(5) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(6) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(7) <= std_logic_vector(to_unsigned(0, BITWIDTH));
        i_theta(8) <= std_logic_vector(to_unsigned(1, BITWIDTH));

        -- Wait for enough time to allow the pipeline to process the inputs
        wait for (WAIT_COUNT * i_clk_period);

        -- Check the output
        assert o_Y = std_logic_vector(to_signed(18, 2 * BITWIDTH))
        report "Test failed: output does not match expected output"
            severity error;

        -- Finish the simulation
        wait;
    end process stimulus;

end architecture;

configuration mac_layer_tb_conf of mac_layer_tb is
    for mac_layer_tb_arch
        for UUT : mac_layer
            use configuration LIB_RTL.mac_layer_conf;
        end for;
    end for;
end configuration mac_layer_tb_conf;