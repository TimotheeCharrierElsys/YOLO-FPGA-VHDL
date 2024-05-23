
Entity: mac
===========


* **File**\ : mac.vhd
* **Brief:**       This entity implements a Multiply-Accumulate (mac) unit.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: mac.svg
   :target: mac.svg
   :alt: Diagram


Description
-----------

Entity      mac
It performs multiplication of two operands followed by an addition
with a third operand.
Entity mac
This entity implements a Multiply-Accumulate (mac) unit.
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
   * - i_clk
     - in
     - std_logic
     - Clock signal
   * - i_rst
     - in
     - std_logic
     - Reset signal, active at high state
   * - i_enable
     - in
     - std_logic
     - Enable signal, active at high state
   * - i_A
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - First multiplication operand
   * - i_B
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Second multiplication operand
   * - i_C
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Accumulation operand
   * - o_P
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output result


Processes
---------


* unnamed: ( i_clk, i_rst )

  * **Description**
    Process
    Handles the synchronous and asynchronous operations of the mac unit.
