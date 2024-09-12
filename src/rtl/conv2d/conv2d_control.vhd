-----------------------------------------------------------------------------------
--!	@file		header
--!	@brief		This entity implements a header file.
--!	@author		Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity conv2d_control is
    generic (
        KERNEL_SIZE       : integer := 3;
        INPUT_PADDED_SIZE : integer := 3;
        INPUT_CHANNELS    : integer := 3;
        OUTPUT_SIZE       : integer := 3
    );
    port (
        clock        : in std_logic;
        reset_n      : in std_logic;
        i_sys_enable : in std_logic;

        -- Control Inputs
        i_start                  : in std_logic;
        i_done_conv2d            : in std_logic;
        i_current_row_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
        i_current_col_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
        i_current_channel_conv2d : in integer range 0 to INPUT_CHANNELS;

        i_current_row_win : in integer range 0 to INPUT_PADDED_SIZE - 1;
        i_current_col_win : in integer range 0 to INPUT_PADDED_SIZE - 1;

        -- Control Outputs
        o_valid_mac     : out std_logic;
        o_valid_adder   : out std_logic;
        o_valid_bn      : out std_logic;
        o_clear_mac     : out std_logic;
        o_clear_adder   : out std_logic;
        o_change_window : out std_logic;
        o_done          : out std_logic
    );
end entity conv2d_control;

architecture conv2d_control_arch of conv2d_control is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type type_state is (idle, start, mac, adder, batchnorm_silu, done);

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal current_state : type_state;
    signal next_state    : type_state;

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
                if i_current_row_win = OUTPUT_SIZE - 1 and i_current_col_win = OUTPUT_SIZE - 1 then
                    next_state <= done;
                else
                    next_state <= mac;
                end if;

            when mac =>

                if i_current_row_conv2d = KERNEL_SIZE - 1 and i_current_col_conv2d = KERNEL_SIZE - 1 then
                    next_state <= adder;
                else
                    next_state <= mac;
                end if;

            when adder =>

                if i_current_channel_conv2d = INPUT_CHANNELS then
                    next_state <= batchnorm_silu;
                else
                    next_state <= adder;
                end if;

            when batchnorm_silu =>
                if i_done_conv2d = '1' then
                    next_state <= start;
                else
                    next_state <= batchnorm_silu;
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
        o_valid_mac     <= '0';
        o_valid_adder   <= '0';
        o_valid_bn      <= '0';
        o_clear_mac     <= '0';
        o_clear_adder   <= '0';
        o_change_window <= '0';
        o_done          <= '0';

        case current_state is
            when idle =>
                -- Clear the MAC and adder when in idle
                o_clear_mac   <= '1';
                o_clear_adder <= '1';

            when start =>
                -- Change to the next sliding window
                o_change_window <= '1';

            when mac =>
                -- Enable the MAC and  clear the adder
                o_valid_mac   <= '1';
                o_clear_adder <= '1';

            when adder =>
                -- Enable the adder
                o_valid_adder <= '1';

            when batchnorm_silu =>
                -- Enable the batchnorm2d
                o_valid_bn <= '1';

            when done =>
                -- Raise Output Done Flag
                o_done <= '1';

        end case;
    end process;
end architecture;