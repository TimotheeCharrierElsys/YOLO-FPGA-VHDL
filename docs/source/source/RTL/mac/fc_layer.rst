
Entity: fc_layer
================


* **File**\ : fc_layer.vhd
* **File:**        fc_layer
* **Brief:**       This entity implements a pipelined fully connected layer.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: fc_layer.svg
   :target: fc_layer.svg
   :alt: Diagram


Description
-----------

It performs multiplication and then additions
Entity fc_layer
This entity implements a full connected layer layer using an adder tree.

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
   * - MATRIX_SIZE
     - integer
     - 3
     - Input Maxtrix Size (squared)


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
     - Reset signal, active low
   * - i_sys_enable
     - in
     - std_logic
     - Global enable signal, active high
   * - i_matrix1
     - in
     - t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - First input matrix
   * - i_matrix2
     - in
     - t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Second input matrix
   * - o_result
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output matrix dot product


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - r_mult_to_add
     - t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0)
     - Signal between the multiplications and the additions
   * - flatten_i_matrix1
     - t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Flattened i_matrix1
   * - flatten_i_matrix2
     - t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Flattened i_matrix2
   * - r_sum
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output signal register


Processes
---------


* comb_proc: ( i_matrix1, i_matrix2 )

Instantiations
--------------


* adder_tree_inst: adder_tree
