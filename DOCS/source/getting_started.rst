Getting started
***************

Installation guide
##################

Setup WSL
=========

1. Install WSL with Ubuntu 24.04 in a powershell:

   .. code-block:: powershell

      wsl --install -d Ubuntu-24.04

2. Open a new WSL Linux terminal and update the package list, then upgrade the packages:

   .. code-block:: bash

      sudo apt update && sudo apt upgrade && sudo apt install make && sudo apt install gcc && sudo apt-get install libz-dev

Install OSS CAD Suite
----------------------

`OSS CAD Suite <https://github.com/YosysHQ/oss-cad-suite-build>`__ is a binary software distribution for RTL synthesis, formal hardware verification, place & route, FPGA programming, and testing with support for HDLs like Verilog or VHDL. Follow these steps to install it:

1. Download the OSS CAD Suite:

   .. code-block:: bash

      wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2024-07-22/oss-cad-suite-linux-x64-20240722.tgz

2. Create a directory named `Utils` and extract the downloaded file into this directory:

   .. code-block:: bash

      mkdir Utils && tar -xzf oss-cad-suite-linux-x64-20240722.tgz -C Utils

3. To use OSS CAD Suite, run 

   .. code-block:: bash

      source /Utils/oss-cad-suite/environment

Cloning the repo
================

Open a terminal and run

.. code-block:: bash

   git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL.git

An go to `dev` branch

.. code-block:: bash

   git checkout dev

Setup virtual environment
=========================

Install package for virtual environement support:

.. code-block:: bash

    apt install python3.12-venv

Then create a virtual environement at the root of the project:

.. code-block:: bash

   python3.12 -m venv .venv

Activate it:

.. code-block:: bash

   source .venv/bin/activate

and the install the package for building the documentation

.. code-block:: bash

   pip install -r requirements.txt

You are now ready to go to build the documentation. Go to the ``DOCS`` folder and run 

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
