Getting started
***************

Installation guide
##################

Setup WSL
=========

1. Install WSL with Ubuntu 24.04 in a powershell:

   .. code-block:: powershell

      wsl --install -d Ubuntu-24.04

Cloning the repo
================

1. Open a terminal and run

   .. code-block:: bash

      git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL.git

2. Go to `dev` branch

   .. code-block:: bash

      cd YOLO-FPGA-VHDL && git checkout dev

3. Install the requirements for the project

   .. code-block:: bash

      cd script && sudo chmod u+x wsl_setup.sh && ./wsl_setup.sh

.. tip::

   `OSS CAD Suite <https://github.com/YosysHQ/oss-cad-suite-build>`__ is a binary software distribution for RTL synthesis, formal hardware verification, place & route, FPGA programming, and testing with support for HDLs like Verilog or VHDL.
   To use OSS CAD Suite, run 

   .. code-block:: bash

      source /Utils/oss-cad-suite/environment

Setup virtual environment and build documentation
=================================================

1. Create a virtual environment at **the root of the project**:

   .. code-block:: bash

      python3.12 -m venv .venv

2. Activate it:

   .. code-block:: bash

      source .venv/bin/activate

3. Install the package for building the documentation

   .. code-block:: bash

      pip install -r requirements.txt

You are now ready to go to build the documentation. Go to the ``docs`` folder and run 

.. code-block:: bash

   make html

Open the build ``DOCS/build/index.html``.

Informations
============

Synthesizable source code is found in the ``SRC/RTL`` folder.
Testbench source code is found in the ``SRC/BENCH`` folder.

The library ``types_pkg`` is required for all modules.

.. warning::
    All files must be handled as VHDL-2008.
