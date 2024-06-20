Getting started
===============

Installation guide
------------------

Cloning the repo
^^^^^^^^^^^^^^^^

Open a CMD and run

.. code-block:: bash

   git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL/tree/dev

Installing WSL2
^^^^^^^^^^^^^^^

.. hint::
    Not required, only if needed or for Linux environment

Open a PowerShell as administrator and run

.. code-block:: bash

   wls --install

Then follow the instructions.

Installing dependencies
"""""""""""""""""""""""

Install GHDL

.. code-block:: bash

    sudo apt install gtkwave ghdl

Install Python3 (after running a `sudo apt update` and `sudo apt upgrade`):

.. code-block:: bash

    sudo apt install python3-pip

Then, cocotb can be installed by running

.. code-block:: bash
   
    pip3 install cocotb

You are now ready to go!

Installing dependencies for documentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Open a bash terminal and run

.. code-block:: bash

   pip install -r requirements.txt

Source code
-----------

Synthesizable source code is found in the ``SRC/RTL`` folder.
Testbench source code is found in the ``SRC/BENCH`` folder.

The library ``types_pkg`` is required for all modules.


.. warning::
    All files must be handled as VHDL-2008.
