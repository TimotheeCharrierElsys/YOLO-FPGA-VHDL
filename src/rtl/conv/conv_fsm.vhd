-----------------------------------------------------------------------------------
--!	@file		conv_fsm.vhd
--!	@brief		This entity implements the FSM for the Conv Operation.
--!	@author		Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity conv_fsm is
    generic (
        KERNEL_SIZE       : integer := 3; --! Size of the kernel
        INPUT_CHANNELS    : integer := 3; --! Number of channels in the input
        OUTPUT_SIZE       : integer := 3  --! Size of the output
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic; --! System enable signal, active high     

        -- Control Inputs
        i_start                  : in std_logic;                          --! Start signal
        i_current_row_conv2d     : in integer range 0 to KERNEL_SIZE - 1; --! Current row of the Conv2d Kernel Operation
        i_current_col_conv2d     : in integer range 0 to KERNEL_SIZE - 1; --! Current column of the Conv2d Kernel Operation
        i_current_channel_conv2d : in integer range 0 to INPUT_CHANNELS;  --! Current channel of the Conv2d Kernel Operation

        i_current_row_win : in integer range 0 to OUTPUT_SIZE - 1; --! Current Position of the Window
        i_current_col_win : in integer range 0 to OUTPUT_SIZE - 1; --! Current Position of the Window

        -- Control Outputs
        o_valid_mac   : out std_logic; --! Valid signal for the MAC
        o_valid_adder : out std_logic; --! Valid signal for the Adder
        o_valid_bn    : out std_logic; --! Valid signal for the BatchNorm2d
        o_clear_mac   : out std_logic; --! Clear signal for the MAC
        o_clear_adder : out std_logic; --! Clear signal for the Adder
        o_conv2d_done : out std_logic; --! Conv2D Done Flag
        o_done        : out std_logic  --! Output Done Flag
    );
end entity conv_fsm;

architecture conv_fsm_arch of conv_fsm is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type type_state is (idle, start, mac, adder, batchnorm, silu, output_update, done); --! States of the FSM

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal current_state : type_state; --! Current state of the FSM
    signal next_state    : type_state; --! Next state of the FSM

begin

    -------------------------------------------------------------------------------------
    -- SEQ PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            current_state <= idle;

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                current_state <= next_state;
            else
                current_state <= idle;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- COMB PROCESS for NEXT_STATE
    -------------------------------------------------------------------------------------
    process (all)
    begin
        case current_state is

            when idle =>
                if i_start = '1' then
                    next_state <= start;
                else
                    next_state <= idle;
                end if;

            when start =>
                next_state <= mac;

            when mac =>
                if i_current_row_conv2d = KERNEL_SIZE - 1 and i_current_col_conv2d = KERNEL_SIZE - 1 then
                    next_state <= adder;
                else
                    next_state <= mac;
                end if;

            when adder =>
                if i_current_channel_conv2d = INPUT_CHANNELS then
                    next_state <= batchnorm;
                else
                    next_state <= adder;
                end if;

            when batchnorm =>
                next_state <= silu;

            when silu =>
                next_state <= output_update;

            when output_update =>
                if i_current_row_win = OUTPUT_SIZE - 1 and i_current_col_win = OUTPUT_SIZE - 1 then
                    next_state <= done;
                else
                    next_state <= start;
                end if;

            when done =>
                next_state <= idle;

        end case;
    end process;

    -------------------------------------------------------------------------------------
    -- COMB PROCESS for output updates
    -------------------------------------------------------------------------------------
    process (all)
    begin
        -- Default Values
        o_valid_mac   <= '0';
        o_valid_adder <= '0';
        o_valid_bn    <= '0';
        o_clear_mac   <= '0';
        o_clear_adder <= '0';
        o_conv2d_done <= '0';
        o_done        <= '0';

        case current_state is
            when idle =>
                -- Clear the MAC and adder when in idle
                o_clear_mac   <= '1';
                o_clear_adder <= '1';

            when start =>
                -- CLear the MAC and adder
                o_clear_mac   <= '1';
                o_clear_adder <= '1';

            when mac =>
                -- Enable the MAC and clear the adder
                o_valid_mac   <= '1';
                o_clear_adder <= '1';

            when adder =>
                -- Enable the adder
                o_valid_adder <= '1';

            when batchnorm =>
                -- Enable the batchnorm
                o_valid_bn <= '1';

            when silu =>

            when output_update =>
                -- Raise Conv2D Done Flag
                o_conv2d_done <= '1';

            when done =>
                -- Raise Output Done Flag
                o_done <= '1';

        end case;
    end process;
end architecture;