Getting started
===============

Installation guide
------------------

Cloning the repo
^^^^^^^^^^^^^^^^

Open a CMD and run

.. code-block:: bash

   git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL.git

An go to `dev` branch

.. code-block:: bash

   git checkout dev

Setup virtual environment
"""""""""""""""""""""""""

Install package for virtual environement support:

.. code-block:: bash

    apt install python3.10-venv

Then create a virtual environement at the root of the project:

.. code-block:: bash

   python3 -m venv .venv

and the install the package for building the documentation

.. code-block:: bash

   pip install -r requirements.txt

You are now ready to go to build the documentation. Go to the ``DOCS`` folder and run 

.. code-block:: bash

   make html

Open the build ``DOCS/build/index.html``.

Informations
""""""""""""

Synthesizable source code is found in the ``SRC/RTL`` folder.
Testbench source code is found in the ``SRC/BENCH`` folder.

The library ``types_pkg`` is required for all modules.

.. warning::
    All files must be handled as VHDL-2008.
