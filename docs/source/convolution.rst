Convolution Layer Architectures
===============================

This document describes the three different architectures available for the `conv_layer` entity, which implements a convolution layer using various methods. Each architecture has unique characteristics and dependencies.


1. **Fully Connected Architecture**
------------------------------------

**Overview:**
This architecture uses a fully connected layer approach to perform the convolution operation. It involves an adder tree to sum the results.

**Dependencies:**
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

**Dependencies:**
- `mac_w_mux.vhd`

**Details:**
- Each channel has a dedicated MAC unit controlled by a multiplexer.
- The MAC outputs are summed together, and the result is updated based on a selector signal.
- The architecture includes handling of synchronous and asynchronous operations with proper reset logic.

.. image:: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :target: fig/architecture-conv_layer_one_mac_arch.drawio.svg
   :alt: Diagram



Output Table
------------

This is an example of a table containing matrices in reStructuredText (reST) for Sphinx documentation.

+--------------------+-----------------------------------------------+------------------------------------------+
|     Operation      |                    Kernels                    |               Image result               |
+====================+===============================================+==========================================+
|                    |                                               |                                          |
| Identity           | .. math::                                     | .. image:: fig/filter_identity.png       |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    0 & 1 & 0 \\                               |                                          |
|                    |    0 & 0 & 0                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Ridge              | .. math::                                     | .. image:: fig/filter_ridge.png          |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & -1 & 0 \\                              |                                          |
|                    |    -1 & 4 & -1 \\                             |                                          |
|                    |    0 & -1 & 0                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Edge               | .. math::                                     | .. image:: fig/filter_edge.png           |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -1 & -1 \\                            |                                          |
|                    |    -1 & 8 & -1 \\                             |                                          |
|                    |    -1 & -1 & -1                               |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sharp              | .. math::                                     | .. image:: fig/filter_sharp.png          |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & -1 & 0 \\                              |                                          |
|                    |    -1 & 5 & -1 \\                             |                                          |
|                    |    0 & -1 & 0                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Blur               | .. math::                                     | .. image:: fig/filter_blur.png           |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    \frac{1}{9} & \frac{1}{9} & \frac{1}{9} \\ |                                          |
|                    |    \frac{1}{9} & \frac{1}{9} & \frac{1}{9} \\ |                                          |
|                    |    \frac{1}{9} & \frac{1}{9} & \frac{1}{9}    |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Gaussian (3x3)     | .. math::                                     | .. image:: fig/filter_gaussian_33.png    |
|                    |                                               |                                          |
|                    |    \frac{1}{16}                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    1 & 2 & 1 \\                               |                                          |
|                    |    2 & 4 & 2 \\                               |                                          |
|                    |    1 & 2 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Emboss             | .. math::                                     | .. image:: fig/filter_emboss.png         |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -2 & -1 & 0 \\                             |                                          |
|                    |    -1 & 1 & 1 \\                              |                                          |
|                    |    0 & 1 & 2                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sobel X            | .. math::                                     | .. image:: fig/filter_sobel_x.png        |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -2 & 0 & 2 \\                              |                                          |
|                    |    -1 & 0 & 1                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Sobel Y            | .. math::                                     | .. image:: fig/filter_sobel_y.png        |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -2 & -1 \\                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    1 & 2 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Prewitt X          | .. math::                                     | .. image:: fig/filter_prewitt_x.png      |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -1 & 0 & 1 \\                              |                                          |
|                    |    -1 & 0 & 1                                 |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Prewitt Y          | .. math::                                     | .. image:: fig/filter_prewitt_y.png      |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    -1 & -1 & -1 \\                            |                                          |
|                    |    0 & 0 & 0 \\                               |                                          |
|                    |    1 & 1 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Laplacian          | .. math::                                     | .. image:: fig/filter_laplacian.png      |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    0 & 1 & 0 \\                               |                                          |
|                    |    1 & -4 & 1 \\                              |                                          |
|                    |    0 & 1 & 0                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Laplacian Diagonal | .. math::                                     | .. image:: fig/filter_laplacian_diag.png |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    1 & 1 & 1 \\                               |                                          |
|                    |    1 & -8 & 1 \\                              |                                          |
|                    |    1 & 1 & 1                                  |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Random (3x3)       | .. math::                                     | .. image:: fig/filter_random_33.png      |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    rand1 & rand2 & rand3 \\                   |                                          |
|                    |    rand4 & rand5 & rand6 \\                   |                                          |
|                    |    rand7 & rand8 & rand9                      |                                          |
|                    |    \end{bmatrix}                              |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+
| Test               | .. math::                                     | .. image:: fig/filter_test.png           |
|                    |                                               |                                          |
|                    |    \begin{bmatrix}                            |                                          |
|                    |    11 & 11 & 11 \\                            |                                          |
|                    |    11 & 11 & 11 \\                            |                                          |
|                    |    11 & 11 & 11                               |                                          |
|                    |    \end{bmatrix}                              |                                          |
|                    |                                               |                                          |
+--------------------+-----------------------------------------------+------------------------------------------+