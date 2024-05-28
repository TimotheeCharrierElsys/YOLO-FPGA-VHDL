Getting started
===============

Start by cloning the repo:

  git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL/tree/dev

Source code
-----------

Synthesizable source code is found in the ``SRC/RTL`` folder.
Testbench source code is found in the ``SRC/BENCH`` folder.

The library ``types_pkg`` is required for all modules.


.. warning::
    All files must be handled as VHDL-2008.

Convolution Layer Architectures
===============================

This document describes the three different architectures available for the `conv_layer` entity, which implements a convolution layer using various methods. Each architecture has unique characteristics and dependencies.

1. **Pipelined MAC Architecture**
---------------------------------

**Overview:**
This architecture uses a pipelined Multiply-Accumulate (MAC) unit with a 3x3 kernel. The MAC units are instantiated for each channel, and their outputs are summed together.

**Dependencies:**
- `mac.vhd`
- `mac_layer.vhd`

**Details:**
- Each MAC unit processes one channel of the input data.
- The MAC outputs are accumulated and added to a bias value.
- A counter keeps track of the output validity.

.. image:: fig/architecture-conv_layer_mac_arch.drawio.svg
   :target: fig/architecture-conv_layer_mac_arch.drawio.svg
   :alt: Diagram

2. **Fully Connected Architecture**
------------------------------------

**Overview:**
This architecture uses a fully connected layer approach to perform the convolution operation. It involves an adder tree to sum the results.

**Dependencies:**
- `adder_tree.vhd`
- `fc_layer.vhd`

**Details:**
- Each channel's input data is processed by a fully connected layer.
- The outputs of the fully connected layers are summed and added to the bias.
- The design ensures proper delay handling using a constant `DFF_DELAY`.

.. image:: fig/architecture-conv_layer_fc_arch.drawio.svg
   :target: fig/architecture-conv_layer_fc_arch.drawio.svg
   :alt: Diagram

3. **One MAC per Channel Architecture**
----------------------------------------

**Overview:**
This architecture uses one MAC unit per channel. The MAC units are controlled using a multiplexer that handles the selection of operands and inclusion of bias.

**Dependencies:**
- `mac_w_mux.vhd`

**Details:**
- Each channel has a dedicated MAC unit controlled by a multiplexer.
- The MAC outputs are summed together, and the result is updated based on a selector signal.
- The architecture includes handling of synchronous and asynchronous operations with proper reset logic.

.. image:: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :target: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :alt: Diagram
