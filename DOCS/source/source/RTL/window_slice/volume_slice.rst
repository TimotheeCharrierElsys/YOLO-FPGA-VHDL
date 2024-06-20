
Entity: volume_slice
====================


* **File**\ : volume_slice.vhd
* **File:**        volume_slice
* **Brief:**       This file provides a volume slicing entity
* **Details:**     This entity takes an input matrix volume and slices a window
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: volume_slice.svg
   :target: volume_slice.svg
   :alt: Diagram


Description
-----------

for each channel from it based on the specified row and column indices.
It outputs the sliced window as a separate volume matrix.
Entity volume_slice
This entity takes an input matrix volume and slices a window for each channel from it based on the specified row and column indices.
It outputs the sliced window as a separate volume matrix.

Generics
--------

.. list-table::
   :header-rows: 1

   * - Generic name
     - Type
     - Value
     - Description
   * - BITWIDTH
     - integer
     - 8
     - Bit width of each operand
   * - INPUT_PADDED_SIZE
     - integer
     - 7
     - Width and Height of the input
   * - CHANNEL_NUMBER
     - integer
     - 3
     - Number of channels in the input
   * - KERNEL_SIZE
     - integer
     - 3
     - Size of the kernel
   * - PADDING
     - integer
     - 1
     - Padding value
   * - STRIDE
     - integer
     - 2
     - Stride value
   * - OUTPUT_SIZE
     - integer
     - 3
     - Output size of the global volume


Ports
-----

.. list-table::
   :header-rows: 1

   * - Port name
     - Direction
     - Type
     - Description
   * - clock
     - in
     - std_logic
     - Clock signal
   * - reset_n
     - in
     - std_logic
     - Reset signal, active at low state
   * - i_sys_enable
     - in
     - std_logic
     - System enable signal, active at high state
   * - i_data
     - in
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input matrix volume
   * - i_data_valid
     - in
     - std_logic
     - Input valid signal
   * - i_last_computation_done
     - in
     - std_logic
     - Feedback signal for last computation done
   * - o_data
     - out
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Output sliced matrix volume
   * - o_done
     - out
     - std_logic
     - Output valid signal
   * - o_computation_start
     - out
     - std_logic
     - Signal to start the next computation
   * - o_current_row
     - out
     - std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
     - Current row index
   * - o_current_col
     - out
     - std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
     - Current column index


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - current_row
     - integer range 0 to OUTPUT_SIZE - 1
     - Current row counter for slicing
   * - current_col
     - integer range 0 to OUTPUT_SIZE - 1
     - Current column counter for slicing
   * - start_processing
     - std_logic
     - Signal to start processing
   * - data_valid_previous_state
     - std_logic
     - Previous state of the data_valid signal
   * - sliced_output_data
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Buffer for output data
   * - o_done_previous_state
     - std_logic


Processes
---------


* state_control: ( clock, reset_n )
