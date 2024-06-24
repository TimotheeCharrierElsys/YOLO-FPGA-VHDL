-----------------------------------------------------------------------------------
--!     @file       maxpool2d
--!     @brief      This entity implements a max pooling using maxpool2d_layer units
--!     @details    This entity takes an input matrix volume and applies maxpool2d
--!                 producing an output matrix.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity maxpool2d
--! This entity implements a maxpool
entity maxpool2d is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        INPUT_SIZE     : integer := 5; --! Width and Height of the input
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the input
        KERNEL_SIZE    : integer := 3; --! Size of the kernel
        PADDING        : integer := 1; --! Padding value
        STRIDE         : integer := 2  --! Stride value 
    );
    port (
        clock        : in std_logic;                                                                                                                                                                                         --! Clock signal
        reset_n      : in std_logic;                                                                                                                                                                                         --! Reset signal, active low
        i_sys_enable : in std_logic;                                                                                                                                                                                         --! System enable signal, active high                                                                                                                                                     
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                                                                    --! Input data (CHANNEL_NUMBER x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_data_valid : in std_logic;                                                                                                                                                                                         --! Data valid signal, active high
        o_data       : out t_volume(CHANNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(BITWIDTH - 1 downto 0); --! Output data
        o_data_valid : out std_logic                                                                                                                                                                                         --! Output valid signal
    );
end maxpool2d;

architecture maxpool2d_arch of maxpool2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input_data    : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Matrix volume with input padded on all channels
    signal sliced_input_volume  : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);             --! Sliced volume for maxpool2d_layer input
    signal maxpool2d_result     : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                                    --! Output result of the maxpool2d_layer
    signal maxpool2d_start      : std_logic;                                                                                                                    --! Signal to start maxpool
    signal maxpool2d_layer_done : std_logic;                                                                                                                    --! Signal indicating maxpooling layer completion
    signal row_index            : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current row index
    signal col_index            : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current column index

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            CHANNEL_NUMBER    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);
            o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
        );
    end component;

    component maxpool2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data_valid : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    padding_process : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, CHANNEL_NUMBER, PADDING, BITWIDTH);
    end process padding_process;

    -------------------------------------------------------------------------------------
    -- MATRIX VOLUME SLICER
    -------------------------------------------------------------------------------------
    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER    => CHANNEL_NUMBER,
        KERNEL_SIZE       => KERNEL_SIZE,
        PADDING           => PADDING,
        STRIDE            => STRIDE,
        OUTPUT_SIZE       => OUTPUT_SIZE
    )
    port map(
        clock                   => clock,
        reset_n                 => reset_n,
        i_sys_enable            => i_sys_enable,
        i_data                  => padded_input_data,
        i_data_valid            => i_data_valid,
        i_last_computation_done => maxpool2d_layer_done,
        o_data                  => sliced_input_volume,
        o_done                  => o_data_valid,
        o_computation_start     => maxpool2d_start,
        o_current_row           => row_index,
        o_current_col           => col_index
    );

    -------------------------------------------------------------------------------------
    -- MAXPOOL LAYER INSTANTIATION
    -------------------------------------------------------------------------------------
    maxpool2d_layer_inst : maxpool2d_layer
    generic map(
        BITWIDTH       => BITWIDTH,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        KERNEL_SIZE    => KERNEL_SIZE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data_valid => maxpool2d_start,
        i_data       => sliced_input_volume,
        o_data       => maxpool2d_result,
        o_data_valid => maxpool2d_layer_done
    );

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (RESET ACTIVE LOW)
    -------------------------------------------------------------------------------------
    --! Process handling synchronous and asynchronous operations of the maxpool2d
    maxpool2d_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            o_data <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                -- Update output
                if (maxpool2d_layer_done = '1') then
                    for i in 0 to CHANNEL_NUMBER - 1 loop
                        o_data(i)(to_integer(unsigned(row_index)))(to_integer(unsigned(col_index))) <= maxpool2d_result(i);
                    end loop;
                end if;
            end if;
        end if;
    end process maxpool2d_control;

end architecture;

configuration maxpool2d_conf of maxpool2d is
    for maxpool2d_arch

        for all : maxpool2d_layer
            use entity LIB_RTL.maxpool2d_layer(maxpool2d_layer_arch);
        end for;

        for all : volume_slice
            use entity LIB_RTL.volume_slice(volume_slice_arch);
        end for;
    end for;
end configuration maxpool2d_conf;