-----------------------------------------------------------------------------------
--!     @file       pipelined_mac33
--!     @brief      This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
--!                 with a KERNEL_SIZE x KERNEL_SIZE kernel.
--!                 It performs convolution operations using a 3x3 kernel over the input data.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity pipelined_mac33
--! This entity implements a pipelined Multiply-Accumulate (MAC) unit with a 3x3 kernel.
--!        It performs convolution operations using a 3x3 kernel over the input data.
entity pipelined_mac33 is
    generic (
        BITWIDTH    : integer := 8; --! Bit width of each operand
        KERNEL_SIZE : integer := 3  --! Size of the kernel (ex: 3 for a 3x3 kernel)
    );
    port (
        i_clk    : in std_logic;                                                         --! Clock signal
        i_rst    : in std_logic;                                                         --! Reset signal, active at high state
        i_enable : in std_logic;                                                         --! Enable signal, active at high state
        i_X      : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Input data  (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
        i_theta  : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Kernel data (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
        o_Y      : out std_logic_vector (2 * BITWIDTH - 1 downto 0)                      --! Output result
    );
end pipelined_mac33;

architecture pipelined_mac33_arch of pipelined_mac33 is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit in the pipeline.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac
        generic (
            BITWIDTH : integer --! Bit width of each operand
        );
        port (
            i_clk    : in std_logic;                                   --! Clock signal
            i_rst    : in std_logic;                                   --! Reset signal, active at high state
            i_enable : in std_logic;                                   --! Enable signal, active at high state
            i_A      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
            i_B      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
            i_C      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Accumulation operand
            o_P      : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    pipelined_mac : for i in 0 to KERNEL_SIZE * KERNEL_SIZE - 1 generate

        --! Instantiate the first MAC unit without an accumulation operand.
        first_mac : if i = 0 generate
            first_custom_mac_inst : mac --! Multiply without additions
            generic map(BITWIDTH => BITWIDTH)
            port map(
                i_clk    => i_clk,
                i_rst    => i_rst,
                i_enable => i_enable,
                i_A      => i_X(i),
                i_B      => i_theta(i),
                i_C => (others => '0'),
                o_P      => mac_out(i)
            );
        end generate first_mac;

        --! Instantiate the intermediate MAC units with accumulation of previous results.
        gen_mac : if i > 0 and i < KERNEL_SIZE * KERNEL_SIZE - 1 generate
            gen_mac_inst : mac --! Multiply then add the previous result
            generic map(BITWIDTH => BITWIDTH)
            port map(
                i_clk    => i_clk,
                i_rst    => i_rst,
                i_enable => i_enable,
                i_A      => i_X(i),
                i_B      => i_theta(i),
                i_C      => mac_out(i - 1)(BITWIDTH - 1 downto 0),
                o_P      => mac_out(i)
            );
        end generate gen_mac;

        --! Instantiate the last MAC unit and output the final result.
        last_mac : if i = KERNEL_SIZE * KERNEL_SIZE - 1 generate
            last_mac_inst : mac --! Convolution output is the result of the last MAC unit
            generic map(BITWIDTH => BITWIDTH)
            port map(
                i_clk    => i_clk,
                i_rst    => i_rst,
                i_enable => i_enable,
                i_A      => i_X(i),
                i_B      => i_theta(i),
                i_C      => mac_out(i - 1)(BITWIDTH - 1 downto 0),
                o_P      => o_Y
            );
        end generate last_mac;
    end generate pipelined_mac;

end pipelined_mac33_arch;

configuration pipelined_mac33_conf of pipelined_mac33 is
    for pipelined_mac33_arch
        for pipelined_mac

            for first_mac
                for all : mac
                    use entity LIB_RTL.mac(mac_arch);
                end for;
            end for;

            for gen_mac
                for all : mac
                    use entity LIB_RTL.mac(mac_arch);
                end for;
            end for;

            for last_mac
                for all : mac
                    use entity LIB_RTL.mac(mac_arch);
                end for;
            end for;
        end for;
    end for;
end configuration pipelined_mac33_conf;