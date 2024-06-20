Convolution Layer Architectures
===============================

This document describes the three different architectures available for the `conv_layer` entity, which implements a convolution layer using various methods. Each architecture has unique characteristics and dependencies.


1. **Fully Connected Architecture**
------------------------------------

**Overview:**
This architecture uses a fully connected layer approach to perform the convolution operation. It involves an adder tree to sum the results.

**Dependencies:**
- `types_pkg.vhd`
- `adder_tree.vhd`
- `fc_layer.vhd`

**Details:**
- Each channel's input data is processed by a fully connected layer.
- The outputs of the fully connected layers are summed and added to the bias.
- The design ensures proper delay handling using a constant `DFF_DELAY` and the design can be fully pipelined or only the output can be pipelined according to needs.

.. image:: fig/architecture-conv_layer_fc_arch.drawio.svg
   :target: fig/architecture-conv_layer_fc_arch.drawio.svg
   :alt: Diagram

2. **One MAC per Channel Architecture**
----------------------------------------

**Overview:**
This architecture uses one MAC unit per channel. The MAC units are controlled using a multiplexer that handles the selection of operands and inclusion of bias.

**Details:**
- Each channel has a dedicated MAC unit controlled by a multiplexer.
- The MAC outputs are summed together, and the result is updated based on a selector signal.
- The architecture includes handling of synchronous and asynchronous operations with proper reset logic.

.. image:: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :target: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :alt: Diagram

3. **Conv layer architecture**
------------------------------

The conv layer instantiate one entity per filter/kernel number to perform the computation. It takes one sliced matrix and kernel per channels. It computes the and return the 
result, while raising a *done flag* according to the computation delay induced by the DFF.

4. **Conv2D architecture**
---------------------------

**Overview:**
The con2d architecture is based on conv_layer and volume_slicer entities.

**Dependencies:**
- `types_pkg.vhd`
- `conv_layer.vhd`
- `mac.vhd`
- `volume_slicer.vhd`

.. image:: fig/architecture-conv2d.drawio.svg
   :target: fig/architecture-conv2d.drawio.svg
   :alt: Diagram

Output Table
------------

This is an example of the output of the conv2d layer where the input image is a 64x64 RGB image. The hyperparameters
used are: *Stride=1*, *Padding=1* and with a *Kernel Size=3*. The output size is a 64x64 gray image.

.. image:: fig/filters/wolf.png

+--------------------+-----------------------------------------------+------------------------------------------+
|     Operation      |                    Kernels                    |               Image result               |
+====================+===============================================+==========================================+
|                    |                                               |                                          |
| Identity           | .. math::                                     | .. image:: fig/filters/identity.png      |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    0 & 1 & 0 \\                               |                                          |
|                    |    0 & 0 & 0                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Ridge              | .. math::                                     | .. image:: fig/filters/ridge.png         |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & -1 & 0 \\                              |                                          |
|                    |    -1 & 4 & -1 \\                             |                                          |
|                    |    0 & -1 & 0                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Edge               | .. math::                                     | .. image:: fig/filters/edge.png          |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -1 & -1 \\                            |                                          |
|                    |    -1 & 8 & -1 \\                             |                                          |
|                    |    -1 & -1 & -1                               |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sharp              | .. math::                                     | .. image:: fig/filters/sharp.png         |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & -1 & 0 \\                              |                                          |
|                    |    -1 & 5 & -1 \\                             |                                          |
|                    |    0 & -1 & 0                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Blur               | .. math::                                     | .. image:: fig/filters/blur.png          |
|                    |                                               |                                          |
|                    |    \frac{1}{9}                                |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    1 & 1 & 1 \\                               |                                          |
|                    |    1 & 1 & 1 \\                               |                                          |
|                    |    1 & 1 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Gaussian (3x3)     | .. math::                                     | .. image:: fig/filters/gaussian_33.png   |
|                    |                                               |                                          |
|                    |    \frac{1}{16}                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    1 & 2 & 1 \\                               |                                          |
|                    |    2 & 4 & 2 \\                               |                                          |
|                    |    1 & 2 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Emboss             | .. math::                                     | .. image:: fig/filters/emboss.png        |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -2 & -1 & 0 \\                             |                                          |
|                    |    -1 & 1 & 1 \\                              |                                          |
|                    |    0 & 1 & 2                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sobel X            | .. math::                                     | .. image:: fig/filters/sobel_x.png       |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -2 & 0 & 2 \\                              |                                          |
|                    |    -1 & 0 & 1                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sobel Y            | .. math::                                     | .. image:: fig/filters/sobel_y.png       |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -2 & -1 \\                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    1 & 2 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Prewitt X          | .. math::                                     | .. image:: fig/filters/prewitt_x.png     |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -1 & 0 & 1                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Prewitt Y          | .. math::                                     | .. image:: fig/filters/prewitt_y.png     |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -1 & -1 \\                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    1 & 1 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Laplacian          | .. math::                                     | .. image:: fig/filters/laplacian.png     |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & 1 & 0 \\                               |                                          |
|                    |    1 & -4 & 1 \\                              |                                          |
|                    |    0 & 1 & 0                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Laplacian Diagonal | .. math::                                     | .. image:: fig/filters/laplacian_diag.png|
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    1 & 1 & 1 \\                               |                                          |
|                    |    1 & -8 & 1 \\                              |                                          |
|                    |    1 & 1 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Random (3x3)       | .. math::                                     | .. image:: fig/filters/random_33.png     |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -10 & 2 & -9 \\                            |                                          |
|                    |    4 & 7 & -7 \\                              |                                          |
|                    |    -4 & 9 & -4                                |                                          |
|                    |    \end{bmatrix}                              |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+