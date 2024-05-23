-----------------------------------------------------------------------------------
--!     @file       conv_layer
--!     @brief      This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
--!                 with a 3x3 kernel.
--!                 It performs conv_layer operations using a 3x3 kernel over the input data.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity conv_layer
--! This entity implements a conv_layer unit
entity conv_layer is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the image
        KERNEL_SIZE    : integer := 3  --! Size of the kernel (ex: 3 for a 3x3 kernel)
    );
    port (
        i_clk     : in std_logic;                                                                                 --! Clock signal
        i_rst     : in std_logic;                                                                                 --! Reset signal, active at high state
        i_enable  : in std_logic;                                                                                 --! Enable signal, active at high state
        i_image   : in t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Input data  CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
        i_kernels : in t_mat(0 to CHANNEL_NUMBER - 1)(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Kernel data CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
        i_bias    : in std_logic_vector(BITWIDTH - 1 downto 0);                                                   --! Input bias value
        o_Y       : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                               --! Output value
    );
end conv_layer;

architecture conv_layer_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(0 to CHANNEL_NUMBER - 1)(2 * BITWIDTH - 1 downto 0);
    signal r_count : integer;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component pipelined_mac33
        generic (
            BITWIDTH    : integer;
            KERNEL_SIZE : integer
        );
        port (
            i_clk    : in std_logic;                                                         --! Clock signal
            i_rst    : in std_logic;                                                         --! Reset signal, active at high state
            i_enable : in std_logic;                                                         --! Enable signal, active at high state
            i_X      : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Input data  (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
            i_theta  : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Kernel data (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
            o_Y      : out std_logic_vector (2 * BITWIDTH - 1 downto 0)                      --! Output result
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    conv_layer : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the pipelined_mac33 units
        gen_pipelined_mac33 : pipelined_mac33
        generic map(
            BITWIDTH    => BITWIDTH,
            KERNEL_SIZE => KERNEL_SIZE
        )
        port map(
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_enable => i_enable,
            i_X      => i_image(i),
            i_theta  => i_kernels(i),
            o_Y      => mac_out(i)
        );
    end generate conv_layer;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset high)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the mac unit.
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Reset output register to zeros
            o_Y     <= (others => '0');
            r_count <= 0;

            elsif rising_edge(i_clk) then
            if (i_enable = '1') then
                r_count <= r_count + 1;

                if r_count = KERNEL_SIZE * KERNEL_SIZE then
                    r_count <= 0;
                    o_Y     <= std_logic_vector(signed(mac_out(0)) + signed(mac_out(1)) + signed(mac_out(2)) + signed(i_bias));
                end if;
            end if;
        end if;
    end process;

end conv_layer_arch;

configuration conv_layer_conf of conv_layer is
    for conv_layer_arch
        for conv_layer

            for all : pipelined_mac33
                use configuration LIB_RTL.pipelined_mac33_conf;
            end for;

        end for;
    end for;
end configuration conv_layer_conf;