-----------------------------------------------------------------------------------
--!     @Testbench    square_root_tb
--!     @brief        This testbench verifies the functionality of the square_root.
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity square_root_tb is
end;

architecture square_root_tb_arch of square_root_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant clock_period : time    := 5 ns;
    constant BITWIDTH     : integer := 16;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal clock        : std_logic := '0';
    signal reset_n      : std_logic := '0';
    signal i_sys_enable : std_logic := '0';
    signal i_data       : std_logic_vector(BITWIDTH - 1 downto 0);
    signal o_data       : std_logic_vector(BITWIDTH/2 - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component square_root
        generic (
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector (BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector (BITWIDTH/2 - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : square_root
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data,
        o_data       => o_data
    );

    -- Clock generation
    clock <= not clock after clock_period/2;

    -------------------------------------------------------------------------------------
    -- TEST PROCESS
    -------------------------------------------------------------------------------------
    stimulus : process
    begin
        -- Reset the system
        reset_n <= '0';
        wait for 2 * clock_period;
        reset_n <= '1';

        -- Enable
        i_sys_enable <= '1';
        wait for clock_period/2;

        for i in 0 to 65534 loop
            i_data <= std_logic_vector(to_signed(i, BITWIDTH));
            wait for clock_period;
        end loop;

        wait;
    end process stimulus;

end;

configuration square_root_tb_conf of square_root_tb is
    for square_root_tb_arch
        for UUT : square_root
            use entity LIB_RTL.square_root(square_root_arch);
        end for;
    end for;
end configuration square_root_tb_conf;