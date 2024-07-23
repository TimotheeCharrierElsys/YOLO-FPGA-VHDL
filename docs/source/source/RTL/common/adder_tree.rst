
Entity: adder_tree
==================


* **File**\ : adder_tree.vhd
* **File:**        adder_tree
* **Brief:**       This file provides an adder tree entity and architecture
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: adder_tree.svg
   :target: adder_tree.svg
   :alt: Diagram


Description
-----------

Entity adder_tree
This entity implements a pipelined multi-operand adder (MOA).
It sums multiple operands using a tree structure, reducing the number of inputs
by half in each stage until the final sum is obtained.

Generics
--------

.. list-table::
   :header-rows: 1

   * - Generic name
     - Type
     - Value
     - Description
   * - N_OPD
     - integer
     - 12
     - Number of operands
   * - BITWIDTH
     - integer
     - 8
     - Bit width of each operand


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
     - Reset signal, active at low state
   * - i_data
     - in
     - t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input data vector
   * - o_data
     - out
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Output data


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - r_next
     - t_mat(0 to N_STAGES)(0 to (2 ** N_STAGES) - 1)(BITWIDTH - 1 downto 0)
     - Next state of the pipeline registers
   * - r_reg
     - t_mat(0 to N_STAGES)(0 to (2 ** N_STAGES) - 1)(BITWIDTH - 1 downto 0)


Constants
---------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Value
     - Description
   * - N_STAGES
     - integer
     - integer(ceil(log2(real(N_OPD))))
     - Number of stages required to complete the addition process.


Processes
---------


* pipeline_control: ( clock, reset_n )

  * **Description**
    Process
    Handles the synchronous and asynchronous operations of the pipelined adder.
