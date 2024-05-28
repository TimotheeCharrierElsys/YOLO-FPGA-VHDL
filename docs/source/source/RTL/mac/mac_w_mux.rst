
Entity: mac_w_mux
=================


* **File**\ : mac_w_mux.vhd
* **Brief:**       This entity implements a Multiply-Accumulate (MAC) unit.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: mac_w_mux.svg
   :target: mac_w_mux.svg
   :alt: Diagram


Description
-----------

Entity      mac_w_mux
It performs multiplication of two operands followed by an addition
with a third operand.
Entity mac_w_mux
This entity implements a Multiply-Accumulate (MAC) unit.
It multiplies two operands and then adds a third operand.

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
   * - i_enable
     - in
     - std_logic
     - Enable signal, active at high state
   * - i_sel
     - in
     - std_logic
     - Select signal for the MUX (1 for (bias + mult), 0 for (output + mult))
   * - i_multiplier1
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - First multiplication operand
   * - i_multiplier2
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Second multiplication operand
   * - i_bias
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Input bias value
   * - o_result
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output result value


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - mac_out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)


Processes
---------


* unnamed: ( clock, reset_n )

  * **Description**
    Process
    Handles the synchronous and asynchronous operations of the MAC unit.
