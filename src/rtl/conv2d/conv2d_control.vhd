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
        i_current_row_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
        i_current_col_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
        i_current_channel_conv2d : in integer range 0 to INPUT_CHANNELS;

        i_current_row_win : in integer range 0 to INPUT_PADDED_SIZE - 1;
        i_current_col_win : in integer range 0 to INPUT_PADDED_SIZE - 1;

        -- Control Outputs
        o_valid_mac   : out std_logic;
        o_valid_adder : out std_logic;
        o_valid_bn    : out std_logic;
        o_clear_mac   : out std_logic;
        o_clear_adder : out std_logic;
        o_conv2d_done : out std_logic;
        o_done        : out std_logic
    );
end entity conv2d_control;

architecture conv2d_control_arch of conv2d_control is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type type_state is (idle, start, mac, adder, batchnorm, silu, output_update, done);

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
                -- Enable the MAC and  clear the adder
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